using System.Collections.Generic;
using System.Text;
using UnityEngine;
using UnityEngine.UI;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Uml
{
    public sealed partial class UmlCanvas
    {
        private const float InspectorWidth = 320f;
        private RectTransform _inspector;
        private RectTransform _inspectorBody;
        private RectTransform _inspectorContent;
        private Text _inspectorToggleText;
        private bool _inspectorCollapsed;

        private float InspectorActiveWidth => _inspectorCollapsed ? CollapsedSidebarWidth : InspectorWidth;

        private void BuildInspector()
        {
            var go = new GameObject("Inspector", typeof(RectTransform));
            _inspector = (RectTransform)go.transform;
            _inspector.SetParent(_root, false);
            _inspector.anchorMin = new Vector2(1f, 0f);
            _inspector.anchorMax = new Vector2(1f, 1f);
            _inspector.pivot = new Vector2(1f, 1f);
            _inspector.offsetMin = new Vector2(-InspectorWidth, 8f);
            _inspector.offsetMax = new Vector2(0f, -70f);
            go.AddComponent<Image>().color = new Color(0.12f, 0.13f, 0.16f, 0.97f);

            var bodyGo = new GameObject("Body", typeof(RectTransform));
            _inspectorBody = (RectTransform)bodyGo.transform;
            _inspectorBody.SetParent(_inspector, false);
            _inspectorBody.anchorMin = Vector2.zero;
            _inspectorBody.anchorMax = Vector2.one;
            _inspectorBody.offsetMin = Vector2.zero;
            _inspectorBody.offsetMax = Vector2.zero;

            var viewportGo = new GameObject("Viewport", typeof(RectTransform));
            var viewport = (RectTransform)viewportGo.transform;
            viewport.SetParent(_inspectorBody, false);
            viewport.anchorMin = Vector2.zero;
            viewport.anchorMax = Vector2.one;
            viewport.offsetMin = Vector2.zero;
            viewport.offsetMax = Vector2.zero;
            viewportGo.AddComponent<RectMask2D>();

            var scroll = go.AddComponent<ScrollRect>();
            scroll.horizontal = false;
            scroll.vertical = true;
            scroll.movementType = ScrollRect.MovementType.Clamped;
            scroll.scrollSensitivity = 24f;
            scroll.viewport = viewport;

            var contentGo = new GameObject("Content", typeof(RectTransform));
            _inspectorContent = (RectTransform)contentGo.transform;
            _inspectorContent.SetParent(viewport, false);
            _inspectorContent.anchorMin = new Vector2(0f, 1f);
            _inspectorContent.anchorMax = new Vector2(1f, 1f);
            _inspectorContent.pivot = new Vector2(0.5f, 1f);
            _inspectorContent.anchoredPosition = Vector2.zero;
            scroll.content = _inspectorContent;

            BuildInspectorToggle();
            ApplyInspectorCollapse();
            RefreshInspector();
        }

        private void BuildInspectorToggle()
        {
            var go = new GameObject("InspectorCollapse", typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(_inspector, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0f, 1f);
            rt.pivot = new Vector2(0f, 1f);
            rt.sizeDelta = new Vector2(CollapsedSidebarWidth, 44f);
            rt.anchoredPosition = Vector2.zero;
            var img = go.AddComponent<Image>();
            img.color = new Color(0.18f, 0.22f, 0.28f, 1f);
            var btn = go.AddComponent<Button>();
            btn.targetGraphic = img;
            btn.onClick.AddListener(() =>
            {
                _inspectorCollapsed = !_inspectorCollapsed;
                ApplyInspectorCollapse();
                Flash(_inspectorCollapsed ? "right sidebar collapsed" : "right sidebar expanded");
            });
            _inspectorToggleText = MakeText(rt, "", Vector2.zero, rt.sizeDelta, 18,
                new Color(0.92f, 0.95f, 1f, 1f), TextAnchor.MiddleCenter);
            _inspectorToggleText.raycastTarget = false;
        }

        private void ApplyInspectorCollapse()
        {
            if (_inspector == null) return;
            _inspector.offsetMin = new Vector2(-InspectorActiveWidth, 8f);
            if (_inspectorBody != null) _inspectorBody.gameObject.SetActive(!_inspectorCollapsed);
            if (_inspectorToggleText != null) _inspectorToggleText.text = _inspectorCollapsed ? "<" : ">";
        }

        private void RefreshInspector()
        {
            if (_inspectorContent == null) return;
            for (int i = _inspectorContent.childCount - 1; i >= 0; i--)
                Destroy(_inspectorContent.GetChild(i).gameObject);

            const float w = InspectorWidth;
            float y = -12f;
            MakeText(_inspectorContent, "Properties", new Vector2(12f, y), new Vector2(w - 24f, 24f), 16,
                new Color(0.88f, 0.92f, 0.98f, 1f), TextAnchor.MiddleLeft).fontStyle = FontStyle.Bold;
            y -= 34f;

            if (!_selectedId.IsValid || !_model.TryGet(_selectedId, out var el))
            {
                MakeText(_inspectorContent, "Select an element to edit its properties.", new Vector2(12f, y),
                    new Vector2(w - 24f, 44f), 13, new Color(0.62f, 0.68f, 0.78f, 1f), TextAnchor.UpperLeft);
                _inspectorContent.sizeDelta = new Vector2(0f, 160f);
                return;
            }

            MakeText(_inspectorContent, el.Kind.ToString(), new Vector2(12f, y), new Vector2(w - 24f, 20f), 13,
                new Color(0.62f, 0.68f, 0.78f, 1f), TextAnchor.MiddleLeft);
            y -= 28f;

            InspectorLabel("Name", ref y);
            var nameInput = MakeInput(_inspectorContent, new Vector2(12f, y), w - 24f, el.Name, "name");
            y -= 44f;

            InputField langInput = null;
            InputField stereoInput = null;
            System.Func<bool> abstractInput = () => el.IsAbstract;
            if (KindInfo.IsClassifier(el.Kind))
            {
                InspectorLabel("Implementation language", ref y);
                langInput = MakeInput(_inspectorContent, new Vector2(12f, y), w - 24f, el.Language, "C# / TypeScript / Python");
                y -= 44f;

                InspectorLabel("Stereotype", ref y);
                stereoInput = MakeInput(_inspectorContent, new Vector2(12f, y), w - 24f, el.Stereotype, "entity, service, controller");
                y -= 44f;

                if (el.Kind == ElementKind.Class)
                {
                    abstractInput = MakeCheckbox(_inspectorContent, new Vector2(12f, y), "abstract", el.IsAbstract);
                    y -= 34f;
                }
            }

            InspectorLabel("Description", ref y);
            var descInput = MakeMultilineInput(_inspectorContent, new Vector2(12f, y), w - 24f, 70f,
                el.Description, "UML/product description");
            y -= 84f;

            InspectorLabel("Code docs", ref y);
            var docInput = MakeMultilineInput(_inspectorContent, new Vector2(12f, y), w - 24f, 84f,
                el.CodeDoc, "Source-code comment emitted above this element");
            y -= 98f;

            InspectorLabel("Deep link", ref y);
            MakeText(_inspectorContent, DeepLinkIdentity.Marker(el.DeepLinkCode), new Vector2(12f, y),
                new Vector2(w - 24f, 18f), 12, new Color(0.86f, 0.89f, 0.94f, 1f), TextAnchor.MiddleLeft);
            y -= 18f;
            MakeText(_inspectorContent, el.DeepLinkUuid ?? "", new Vector2(12f, y),
                new Vector2(w - 24f, 18f), 10, new Color(0.62f, 0.68f, 0.78f, 1f), TextAnchor.MiddleLeft);
            y -= 24f;
            var embedInput = MakeCheckbox(_inspectorContent, new Vector2(12f, y), "embed in generated docs",
                el.EmbedDeepLinkCode);
            y -= 34f;

            InputField itemsInput = null;
            if (SupportsItemList(el.Kind))
            {
                InspectorLabel(ItemLabel(el.Kind), ref y);
                itemsInput = MakeMultilineInput(_inspectorContent, new Vector2(12f, y), w - 24f, 104f,
                    JoinLines(el.Items), "One item per line");
                y -= 118f;
            }

            if (KindInfo.IsClassifier(el.Kind))
            {
                MakeText(_inspectorContent, MemberSummary(el), new Vector2(12f, y), new Vector2(w - 24f, 20f), 12,
                    new Color(0.62f, 0.68f, 0.78f, 1f), TextAnchor.MiddleLeft);
                y -= 30f;
            }

            if (KindInfo.IsDiagramNode(el.Kind) && el.Kind != ElementKind.Note)
            {
                InspectorAspectRow(el, _selectedId, ref y);
            }

            var id = _selectedId;
            void Save()
            {
                if (!_model.TryGet(id, out var cur)) return;
                string nextName = string.IsNullOrWhiteSpace(nameInput.text) ? cur.Name : nameInput.text.Trim();
                if (nextName != cur.Name) _ctl.Rename(id, nextName);
                if (KindInfo.IsClassifier(cur.Kind))
                {
                    _ctl.SetMeta(id, langInput != null ? langInput.text : cur.Language,
                        stereoInput != null ? stereoInput.text : cur.Stereotype);
                    if (cur.Kind == ElementKind.Class && abstractInput() != cur.IsAbstract)
                        _ctl.SetAbstract(id, abstractInput());
                }
                _ctl.SetDescription(id, descInput.text);
                _ctl.SetCodeDoc(id, docInput.text);
                if (embedInput() != cur.EmbedDeepLinkCode)
                    _ctl.SetEmbedDeepLinkCode(id, embedInput());
                if (itemsInput != null) _ctl.SetPropertyItems(id, SplitLines(itemsInput.text));
                RebuildFromModel();
                SetSelected(id);
                Flash("properties saved");
            }

            MakeButton(_inspectorContent, "Save", new Vector2(12f, y), new Vector2(72f, 30f),
                new Color(0.18f, 0.46f, 0.30f, 1f), Save);
            MakeButton(_inspectorContent, "Full editor", new Vector2(92f, y), new Vector2(100f, 30f),
                new Color(0.20f, 0.34f, 0.42f, 1f), () => OpenNodeEditModal(id, Input.mousePosition));
            MakeButton(_inspectorContent, "Style", new Vector2(200f, y), new Vector2(68f, 30f),
                new Color(0.24f, 0.28f, 0.34f, 1f), () => ShowStyleEditor(id, Input.mousePosition));
            y -= 40f;

            if (KindInfo.IsDiagramNode(el.Kind) && el.Kind != ElementKind.Note)
            {
                MakeButton(_inspectorContent, "View code", new Vector2(12f, y), new Vector2(94f, 30f),
                    new Color(0.20f, 0.42f, 0.52f, 1f), () => GenerateCodeForElement(id));
                MakeButton(_inspectorContent, "VS Code", new Vector2(114f, y), new Vector2(84f, 30f),
                    new Color(0.24f, 0.28f, 0.34f, 1f), () => EditCodeInVsCode(id));
                MakeButton(_inspectorContent, "Trace", new Vector2(206f, y), new Vector2(70f, 30f),
                    new Color(0.30f, 0.24f, 0.42f, 1f), () => ShowTraceView(id));
                y -= 40f;
            }

            _inspectorContent.sizeDelta = new Vector2(0f, Mathf.Max(240f, -y + 20f));
        }

        private void InspectorLabel(string text, ref float y)
        {
            MakeText(_inspectorContent, text, new Vector2(12f, y), new Vector2(InspectorWidth - 24f, 18f), 12,
                new Color(0.62f, 0.68f, 0.78f, 1f), TextAnchor.MiddleLeft);
            y -= 20f;
        }

        private bool SupportsItemList(ElementKind kind) => KindInfo.HasPropertyRows(kind);

        private static string ItemLabel(ElementKind kind) => kind switch
        {
            ElementKind.Dropdown => "Options",
            ElementKind.List => "List items",
            ElementKind.Table => "Columns",
            ElementKind.Tree => "Tree rows",
            ElementKind.Tabs => "Tabs",
            ElementKind.Menu => "Menu items",
            ElementKind.Toolbar => "Toolbar actions",
            ElementKind.Breadcrumb => "Breadcrumb items",
            ElementKind.Card => "Card lines",
            ElementKind.SysmlRequirement => "Requirement properties",
            ElementKind.SysmlBlock or ElementKind.SysmlValueType or ElementKind.SysmlConstraintBlock
                or ElementKind.SysmlProxyPort or ElementKind.SysmlFullPort or ElementKind.SysmlParameter => "SysML properties",
            ElementKind.BpmnEvent or ElementKind.BpmnActivity or ElementKind.BpmnGateway
                or ElementKind.BpmnDataObject or ElementKind.BpmnDataStore or ElementKind.BpmnPool
                or ElementKind.BpmnLane or ElementKind.BpmnChoreographyTask or ElementKind.BpmnConversation => "BPMN properties",
            ElementKind.DmnDecision or ElementKind.DmnInputData or ElementKind.DmnBusinessKnowledge
                or ElementKind.DmnKnowledgeSource or ElementKind.DmnDecisionService or ElementKind.DmnTextAnnotation => "DMN properties",
            ElementKind.ArchiBusinessActor or ElementKind.ArchiBusinessProcess
                or ElementKind.ArchiApplicationComponent or ElementKind.ArchiApplicationService
                or ElementKind.ArchiDataObject or ElementKind.ArchiNode or ElementKind.ArchiDevice
                or ElementKind.ArchiSystemSoftware or ElementKind.ArchiTechnologyService
                or ElementKind.ArchiCapability or ElementKind.ArchiOutcome or ElementKind.ArchiRequirement
                or ElementKind.ArchiPrinciple or ElementKind.ArchiWorkPackage or ElementKind.ArchiDeliverable
                or ElementKind.ArchiPlateau or ElementKind.ArchiGap => "ArchiMate properties",
            ElementKind.UafOperationalNode or ElementKind.UafService or ElementKind.UafResource or ElementKind.UafCapability => "UAF properties",
            ElementKind.TogafArchitectureBuildingBlock or ElementKind.TogafArchitecturePhase => "TOGAF properties",
            ElementKind.ZachmanCell => "Zachman coordinates",
            _ => KindInfo.IsEaNotationNode(kind) ? "Notation properties" : "Items",
        };

        private string MemberSummary(ModelElement el)
        {
            int attrs = 0, ops = 0;
            foreach (var childId in el.ChildIds)
                if (_model.TryGet(childId, out var c))
                {
                    if (c.Kind == ElementKind.Field) attrs++;
                    else if (c.Kind == ElementKind.Function) ops++;
                }
            return $"{attrs} attributes, {ops} operations";
        }

        private static string JoinLines(IReadOnlyList<string> items)
        {
            if (items == null || items.Count == 0) return "";
            var sb = new StringBuilder();
            for (int i = 0; i < items.Count; i++)
            {
                if (i > 0) sb.Append('\n');
                sb.Append(items[i]);
            }
            return sb.ToString();
        }

        private static List<string> SplitLines(string text)
        {
            var list = new List<string>();
            if (string.IsNullOrWhiteSpace(text)) return list;
            foreach (var raw in text.Replace("\r\n", "\n").Split('\n'))
                if (!string.IsNullOrWhiteSpace(raw))
                    list.Add(raw.Trim());
            return list;
        }
    }
}
