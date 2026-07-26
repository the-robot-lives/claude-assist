"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import {
  DndContext,
  DragOverlay,
  KeyboardSensor,
  PointerSensor,
  closestCorners,
  useDroppable,
  useSensor,
  useSensors,
  type DragEndEvent,
  type DragOverEvent,
  type DragStartEvent,
} from "@dnd-kit/core";
import {
  SortableContext,
  sortableKeyboardCoordinates,
  useSortable,
  verticalListSortingStrategy,
} from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";
import { useOrg } from "@/context/org";
import { api, type Item, type ItemInput, type ItemQueue } from "@/lib/api";
import { useMutation } from "@/lib/use-api";
import { toast } from "sonner";
import { PriorityDot, toPriorityLevel, Chip, type ChipVariant, Key, Avatar, StatusTag } from "@/components/ui";

// item_type → chip variant. Unmapped types (todo, subtask, research) fall
// back to the neutral "default" chip rather than inventing new variants.
const TYPE_CHIP: Record<string, ChipVariant> = { bug: "bug", story: "story", epic: "epic", task: "task" };
function chipVariantForType(t: string): ChipVariant {
  return TYPE_CHIP[t] ?? "default";
}

// ── Lexicographic rank helpers ───────────────────────────────────────────────
// The backend stores `rank` as an opaque string and orders lexicographically
// (see Item.rank / ItemInput.rank — backend `Map.take` allowlist includes rank).
// We compute a string strictly between the moved item's new neighbors so the
// persisted order survives reloads. Works on any existing rank format because
// lexicographic ordering is format-agnostic; generated strings stay in the
// printable-ASCII range ([!..~]) with floor 33 to avoid control chars/spaces.

const RANK_MID = "G"; // ~middle of the printable range; used to grow a rank (append).
const RANK_FLOOR = 33; // '!'

function lexMidpoint(a: string, b: string): string {
  // Precondition: a < b. Returns m with a < m < b.
  let i = 0;
  while (i < a.length && i < b.length && a.charCodeAt(i) === b.charCodeAt(i)) i++;
  const aCode = i < a.length ? a.charCodeAt(i) : -1; // -1 ⇒ a is a proper prefix of b
  const bCode = i < b.length ? b.charCodeAt(i) : 127; // 127 ⇒ b exhausted past a (b prefix of a — impossible when a < b)
  if (aCode === -1) {
    // a is a prefix of b: m = a + (char strictly less than b[i]).
    if (bCode > RANK_FLOOR) return a + String.fromCharCode(RANK_FLOOR);
    // b[i] is at the floor — no smaller printable char; recurse past it.
    return a + b[i] + lexMidpoint("", b.slice(i + 1));
  }
  if (bCode - aCode > 1) {
    // gap at position i: bump a[i] by one.
    return a.slice(0, i) + String.fromCharCode(aCode + 1);
  }
  // consecutive at i (no gap): carry a[i] (== b[i]-1) and append a mid char.
  // m shares prefix a[0..i] with a; at i, m[i]=a[i] < b[i] ⇒ m < b, and m is
  // longer than a ⇒ m > a.
  return a.slice(0, i) + a[i] + RANK_MID;
}

function rankBetween(prev?: string | null, next?: string | null): string {
  if (prev && next) {
    if (prev >= next) return prev + RANK_MID; // out-of-order guard; still > prev
    return lexMidpoint(prev, next);
  }
  if (prev) return prev + RANK_MID; // append after predecessor
  if (next) return lexMidpoint("", next); // prepend before successor
  return RANK_MID; // fresh column
}

export default function BoardPage() {
  const params = useParams<{ orgId: string; boardId: string }>();
  const { currentOrg } = useOrg();
  const orgId = currentOrg?.id || params.orgId;
  const boardId = params.boardId;

  const [board, setBoard] = useState<ItemQueue | null>(null);
  const [items, setItems] = useState<Item[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeId, setActiveId] = useState<string | null>(null);

  // Live mirror of `items` so DnD handlers can read synchronous current state.
  const itemsRef = useRef<Item[]>(items);
  itemsRef.current = items;

  // Captured at dragStart: source stage, index within it, and full snapshot for revert.
  const dragSource = useRef<{ stageId: string | null; index: number; snapshot: Item } | null>(null);
  // useMutation.revert only receives the error; hand it the snapshot via this ref.
  const revertSnapshot = useRef<Item | null>(null);

  useEffect(() => {
    if (!orgId || !boardId) return;
    setLoading(true);
    Promise.all([
      api.getQueue(orgId, boardId).then((r) => setBoard(r.queue)).catch(() => setBoard(null)),
      api.listItems(orgId, { queue_id: boardId }).then((r) => setItems(r.items)).catch(() => setItems([])),
    ]).finally(() => setLoading(false));
  }, [orgId, boardId]);

  const stages = useMemo(
    () => (board?.stages || []).slice().sort((a, b) => a.position - b.position),
    [board],
  );
  const stageIds = useMemo(() => new Set(stages.map((s) => s.id)), [stages]);

  const stageIdOf = (id: string, list: Item[] = itemsRef.current): string | null => {
    const it = list.find((i) => i.id === id);
    return it ? it.stage_id ?? null : null;
  };

  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 6 } }),
    useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates }),
  );

  // Persist a stage/rank move. Optimistic state is applied in the drag handler;
  // on failure, useMutation calls revert → restore the pre-drag snapshot.
  const persistMove = useMutation<{ item: Item }, { itemId: string; patch: ItemInput }>(
    (input) => api.updateItem(orgId, input.itemId, input.patch),
    {
      revert: (err: Error) => {
        const snap = revertSnapshot.current;
        if (snap) setItems((prev) => prev.map((i) => (i.id === snap.id ? snap : i)));
        toast.error(err.message);
      },
    },
  );

  const activeItem = activeId ? items.find((i) => i.id === activeId) ?? null : null;

  function handleDragStart(e: DragStartEvent) {
    const id = String(e.active.id);
    setActiveId(id);
    const list = itemsRef.current;
    const item = list.find((i) => i.id === id);
    if (!item) {
      dragSource.current = null;
      return;
    }
    const stageId = item.stage_id ?? null;
    const stageList = list.filter((i) => (i.stage_id ?? null) === stageId);
    dragSource.current = { stageId, index: stageList.findIndex((i) => i.id === id), snapshot: item };
  }

  function handleDragOver(e: DragOverEvent) {
    const { active, over } = e;
    if (!over) return;
    const activeId = String(active.id);
    const overId = String(over.id);
    const list = itemsRef.current;
    const activeStage = stageIdOf(activeId, list);
    if (activeStage == null) return;
    const overStage = stageIds.has(overId) ? overId : stageIdOf(overId, list);
    if (overStage == null || overStage === activeStage) return;
    // Cross-column live preview: flip the card into the over column so the
    // target SortableContext picks it up and the user sees the move.
    setItems((prev) => prev.map((i) => (i.id === activeId ? { ...i, stage_id: overStage } : i)));
  }

  function handleDragEnd(e: DragEndEvent) {
    const { over } = e;
    setActiveId(null);
    const src = dragSource.current;
    dragSource.current = null;

    if (!src) return;

    if (!over) {
      // Drag canceled: undo any cross-column preview back to the source snapshot.
      setItems((prev) => prev.map((i) => (i.id === src.snapshot.id ? src.snapshot : i)));
      return;
    }

    const activeId = src.snapshot.id;
    const overId = String(over.id);
    const list = itemsRef.current;
    const moving = list.find((i) => i.id === activeId);
    if (!moving) return;

    const overIsStage = stageIds.has(overId);
    const targetStage: string | null = overIsStage ? overId : stageIdOf(overId, list) ?? src.stageId;

    // Compute the committed ordering synchronously.
    const without = list.filter((i) => i.id !== activeId);
    const targetList = without.filter((i) => (i.stage_id ?? null) === (targetStage ?? null));
    let gIdx: number;
    if (overIsStage) {
      gIdx = targetList.length === 0 ? without.length : without.indexOf(targetList[targetList.length - 1]) + 1;
    } else {
      const overCard = targetList.find((i) => i.id === overId);
      gIdx = overCard ? without.indexOf(overCard) : without.length;
    }
    const updatedItem: Item = { ...moving, stage_id: targetStage || undefined };
    const next = [...without];
    next.splice(gIdx, 0, updatedItem);

    const newList = next.filter((i) => (i.stage_id ?? null) === (targetStage ?? null));
    const finalIndex = newList.findIndex((i) => i.id === activeId);
    const crossColumn = (src.stageId ?? null) !== (targetStage ?? null);

    // No-op within-column drop (same position): commit nothing.
    if (!crossColumn && src.index === finalIndex) {
      setItems(next);
      return;
    }

    // Recompute rank from the new neighbors and persist.
    const prevRank = finalIndex > 0 ? newList[finalIndex - 1].rank : undefined;
    const nextRank = finalIndex < newList.length - 1 ? newList[finalIndex + 1].rank : undefined;
    updatedItem.rank = rankBetween(prevRank, nextRank);
    setItems(next);

    const patch: ItemInput = crossColumn
      ? { stage_id: targetStage || undefined, rank: updatedItem.rank }
      : { rank: updatedItem.rank };

    revertSnapshot.current = src.snapshot;
    persistMove
      .trigger({ itemId: activeId, patch })
      .then((res) => {
        // Reconcile with the server's authoritative item.
        setItems((prev) => prev.map((i) => (i.id === activeId ? res.item : i)));
      })
      .catch(() => {
        /* revert handled by useMutation via revertSnapshot */
      });
  }

  if (loading) return <div className="p-8 font-mono text-sm text-mut">loading board…</div>;
  if (!board) return <div className="p-8 font-mono text-sm text-mut">board not found.</div>;

  return (
    <div className="px-4 py-6">
      <header className="mb-6">
        <Link href={`/app/${orgId}/items`} className="font-mono text-xs text-mut hover:text-acc">
          ← boards
        </Link>
        <h1 className="mt-1 font-mono text-2xl font-bold tracking-tight text-ink">{board.name}</h1>
        <div className="mt-1.5 flex flex-wrap items-center gap-2">
          {board.methodology && <Chip variant="scope">{board.methodology}</Chip>}
          <span className="text-xs tabular-nums text-mut">{items.length} items</span>
        </div>
        <p className="mt-2 flex items-baseline gap-1.5 text-[11.5px] text-mut">
          <StatusTag tone="info" />
          drag cards between columns to change stage · reorder within a column to set rank
        </p>
      </header>

      <DndContext
        sensors={sensors}
        collisionDetection={closestCorners}
        onDragStart={handleDragStart}
        onDragOver={handleDragOver}
        onDragEnd={handleDragEnd}
      >
        <div className="flex gap-3 overflow-x-auto pb-4">
          {stages.map((stage) => {
            const cards = items.filter((i) => (i.stage_id ?? null) === stage.id);
            return <Column key={stage.id} stage={stage} cards={cards} />;
          })}
        </div>

        <DragOverlay dropAnimation={null}>
          {activeItem ? (
            <div className="rounded-card shadow-glow">
              <CardView item={activeItem} />
            </div>
          ) : null}
        </DragOverlay>
      </DndContext>
    </div>
  );
}

function Column({ stage, cards }: { stage: NonNullable<ItemQueue["stages"]>[number]; cards: Item[] }) {
  const { setNodeRef, isOver } = useDroppable({ id: stage.id });
  const overLimit = stage.wip_limit ? cards.length > stage.wip_limit : false;
  return (
    <div
      className={`flex w-72 shrink-0 flex-col overflow-hidden rounded-panel border bg-panel shadow-card ${
        isOver ? "border-acc ring-2 ring-acc/30" : "border-line"
      }`}
    >
      <div className="flex items-baseline gap-2 border-b border-line2 bg-panel2 px-3.5 py-2.5">
        <h3 className="font-mono text-[11px] font-bold uppercase tracking-[0.12em] text-ink">{stage.name}</h3>
        <span className="text-[11px] tabular-nums text-faint">{cards.length}</span>
        <span className={`ml-auto text-[10px] ${overLimit ? "font-bold text-warn" : "text-faint"}`}>
          {stage.wip_limit ? `wip ${cards.length}/${stage.wip_limit}` : "∞"}
        </span>
      </div>
      <div ref={setNodeRef} className="flex min-h-[4rem] flex-col gap-2.5 p-2.5">
        <SortableContext items={cards.map((c) => c.id)} strategy={verticalListSortingStrategy}>
          {cards.map((it) => (
            <BoardCard key={it.id} item={it} />
          ))}
        </SortableContext>
        {cards.length === 0 && <p className="px-1 py-4 text-center text-xs text-faint">empty</p>}
      </div>
    </div>
  );
}

// Presentational card body (shared by the live card and the drag overlay).
function CardView({ item }: { item: Item }) {
  const level = toPriorityLevel(item.priority) ?? "lo";
  const est = item.estimate != null && item.estimate !== "" ? `${item.estimate} pt` : null;
  return (
    <div className="rounded-card border border-line bg-panel2 p-2.5 shadow-card">
      <div className="mb-1.5 flex items-center gap-2">
        <PriorityDot level={level} />
        <Key>{item.key || item.id.slice(0, 8)}</Key>
        <Chip variant={chipVariantForType(item.item_type)}>{item.item_type}</Chip>
      </div>
      <div className="mb-2 text-[12.5px] leading-snug text-ink">{item.title}</div>
      <div className="flex items-center gap-2">
        <Avatar name={item.assignee} title={item.assignee || "unassigned"} />
        {est && <span className="ml-auto text-[10.5px] tabular-nums text-faint">{est}</span>}
      </div>
    </div>
  );
}

function BoardCard({ item }: { item: Item }) {
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } = useSortable({ id: item.id });
  return (
    <div
      ref={setNodeRef}
      style={{
        transform: CSS.Translate.toString(transform),
        transition,
        opacity: isDragging ? 0.35 : 1,
      }}
      {...attributes}
      {...listeners}
      className={`touch-none cursor-grab rounded-card active:cursor-grabbing ${isDragging ? "ring-1 ring-acc" : ""}`}
    >
      <CardView item={item} />
    </div>
  );
}
