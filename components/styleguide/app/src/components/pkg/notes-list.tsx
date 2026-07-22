import React from 'react';

interface Note {
  swatch?: string;
  label?: React.ReactNode;
  text?: React.ReactNode;
}

interface StyleGuideNotesListProps {
  notes: Note[];
}

// ⟦𓊜𓏸𓉁𓍤⟧ StyleGuideNotesList :: auto-generated pointer for public function StyleGuideNotesList
export function StyleGuideNotesList({ notes }: StyleGuideNotesListProps) {
  return (
    <ul className="sg-notes">
      {notes.map((n, i) => (
        <li key={i}>
          {n.swatch && <span className="sg-notes-swatch" style={{ background: n.swatch }} />}
          <span className="sg-notes-label">{n.label}</span>
          <span>{n.text}</span>
        </li>
      ))}
    </ul>
  );
}
