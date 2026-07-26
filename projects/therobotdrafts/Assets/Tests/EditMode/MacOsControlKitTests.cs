using NUnit.Framework;
using TheRobotDraft.Uml.Chrome;
using UnityEngine;
using UnityEngine.UI;
// Concept D theme tokens must stay locked to the nav-redesign HTML demo.

namespace TheRobotDraft.Authoring.Tests
{
    /// <summary>
    /// Structural EditMode tests for the full from-scratch macOS control kit.
    /// Covers every role and the construction helpers used by shared form builders.
    /// </summary>
    public class MacOsControlKitTests
    {
        private GameObject _root;

        [SetUp]
        public void SetUp()
        {
            MacOsControlKit.ResetCachesForTests();
            _root = new GameObject("ControlKitTestRoot", typeof(RectTransform));
        }

        [TearDown]
        public void TearDown()
        {
            if (_root != null) Object.DestroyImmediate(_root);
            MacOsControlKit.ResetCachesForTests();
        }

        [Test]
        public void StyleFor_PrimaryButton_IsSlicedWithSprite()
        {
            var style = MacOsControlKit.StyleFor(MacOsControlKit.Role.PrimaryButton);
            Assert.IsNotNull(style.Sprite);
            Assert.AreEqual(Image.Type.Sliced, style.ImageType);
            Assert.IsTrue(style.IsSlicedRounded);
            Assert.AreEqual("MacOsPrimaryButton", style.SpriteName);
        }

        [Test]
        public void StyleFor_SecondaryButton_DiffersFromPrimary()
        {
            var primary = MacOsControlKit.StyleFor(MacOsControlKit.Role.PrimaryButton);
            var secondary = MacOsControlKit.StyleFor(MacOsControlKit.Role.SecondaryButton);
            Assert.AreNotEqual(primary.SpriteName, secondary.SpriteName);
            Assert.AreNotEqual(primary.Color, secondary.Color);
        }

        [Test]
        public void StyleFor_TextField_DiffersFromButtons()
        {
            var primary = MacOsControlKit.StyleFor(MacOsControlKit.Role.PrimaryButton);
            var field = MacOsControlKit.StyleFor(MacOsControlKit.Role.TextField);
            Assert.AreEqual("MacOsTextField", field.SpriteName);
            Assert.AreNotEqual(primary.SpriteName, field.SpriteName);
            Assert.IsTrue(field.IsSlicedRounded);
        }

        [Test]
        public void StyleFor_AllRoles_HaveDistinctSurfaces()
        {
            var roles = new[]
            {
                MacOsControlKit.Role.PrimaryButton,
                MacOsControlKit.Role.SecondaryButton,
                MacOsControlKit.Role.TextField,
                MacOsControlKit.Role.Panel,
                MacOsControlKit.Role.Popover,
                MacOsControlKit.Role.MenuRow,
                MacOsControlKit.Role.Checkbox,
                MacOsControlKit.Role.Separator,
                MacOsControlKit.Role.ScrollWell,
                MacOsControlKit.Role.ProgressTrack,
                MacOsControlKit.Role.Segment,
            };
            var names = new System.Collections.Generic.HashSet<string>();
            foreach (var role in roles)
            {
                var style = MacOsControlKit.StyleFor(role);
                Assert.IsNotNull(style.Sprite, role + " needs a sprite");
                Assert.IsTrue(names.Add(style.SpriteName), "duplicate sprite name " + style.SpriteName);
                Assert.IsTrue(style.IsSlicedRounded || style.Sprite.border.y >= 1f, role + " should slice");
            }

            // Backdrop is solid (no sprite).
            var bd = MacOsControlKit.StyleFor(MacOsControlKit.Role.Backdrop);
            Assert.IsNull(bd.Sprite);
            Assert.AreEqual(Image.Type.Simple, bd.ImageType);
            Assert.Greater(bd.Color.a, 0f);
        }

        [Test]
        public void ClassifyButtonColor_SaturatedIsPrimary_GrayIsSecondary()
        {
            Assert.AreEqual(MacOsControlKit.Role.PrimaryButton,
                MacOsControlKit.ClassifyButtonColor(new Color(0.20f, 0.42f, 0.52f, 1f)));
            Assert.AreEqual(MacOsControlKit.Role.PrimaryButton,
                MacOsControlKit.ClassifyButtonColor(new Color(0.18f, 0.46f, 0.30f, 1f)));
            Assert.AreEqual(MacOsControlKit.Role.SecondaryButton,
                MacOsControlKit.ClassifyButtonColor(new Color(0.22f, 0.24f, 0.29f, 1f)));
        }

        [Test]
        public void CreateButton_AppliesSlicedRoundedChrome()
        {
            var btn = MacOsControlKit.CreateButton(_root.transform, "BtnPrimary",
                new Vector2(120f, 34f), MacOsControlKit.PrimaryFill);
            var img = btn.targetGraphic as Image;
            Assert.IsNotNull(img);
            Assert.IsNotNull(img.sprite);
            Assert.AreEqual(Image.Type.Sliced, img.type);
            Assert.AreEqual("MacOsPrimaryButton", img.sprite.name);
            Assert.AreEqual(MacOsControlKit.TextureSize, (int)img.sprite.rect.width);
            Assert.AreEqual(Selectable.Transition.ColorTint, btn.transition);
            Assert.Greater(btn.colors.highlightedColor.r, btn.colors.pressedColor.r);
        }

        [Test]
        public void CreateButton_SecondaryRole_UsesSecondarySprite()
        {
            var btn = MacOsControlKit.CreateButton(_root.transform, "BtnSecondary",
                new Vector2(88f, 34f), MacOsControlKit.SecondaryFill);
            var img = btn.targetGraphic as Image;
            Assert.AreEqual("MacOsSecondaryButton", img.sprite.name);
        }

        [Test]
        public void CreateTextField_AppliesDistinctSlicedChrome()
        {
            var field = MacOsControlKit.CreateTextField(_root.transform, "Field", new Vector2(200f, 32f));
            var img = field.GetComponent<Image>();
            Assert.AreEqual("MacOsTextField", img.sprite.name);
            Assert.AreEqual(Image.Type.Sliced, img.type);
        }

        [Test]
        public void CreatePanel_Popover_Checkbox_MenuRow_Separator()
        {
            var panel = MacOsControlKit.CreatePanel(_root.transform, "P", new Vector2(300f, 200f));
            Assert.AreEqual("MacOsPanel", panel.sprite.name);
            Assert.AreEqual(Image.Type.Sliced, panel.type);

            var pop = MacOsControlKit.CreatePopover(_root.transform, "Pop", new Vector2(180f, 120f));
            Assert.AreEqual("MacOsPopover", pop.sprite.name);

            var box = MacOsControlKit.CreateCheckboxBox(_root.transform, "Chk", new Vector2(22f, 22f), false);
            Assert.AreEqual("MacOsCheckbox", box.sprite.name);
            Assert.AreEqual(MacOsControlKit.CheckboxFill, box.color);

            MacOsControlKit.ApplyCheckbox(box, true);
            Assert.AreEqual(MacOsControlKit.CheckboxCheckedFill, box.color);

            var row = MacOsControlKit.CreateMenuRow(_root.transform, "Row", new Vector2(200f, 28f));
            Assert.AreEqual("MacOsMenuRow", row.sprite.name);

            var sep = MacOsControlKit.CreateSeparator(_root.transform, "Sep", 200f);
            Assert.AreEqual("MacOsSeparator", sep.sprite.name);
        }

        [Test]
        public void ApplySegment_ActiveVsIdle_Differ()
        {
            var go = new GameObject("Seg", typeof(RectTransform));
            go.transform.SetParent(_root.transform, false);
            var img = go.AddComponent<Image>();
            MacOsControlKit.ApplySegment(img, false);
            var idle = img.color;
            MacOsControlKit.ApplySegment(img, true);
            Assert.AreNotEqual(idle, img.color);
            Assert.AreEqual("MacOsSegment", img.sprite.name);
        }

        [Test]
        public void ApplyScrollWell_AndProgressTrack()
        {
            var go = new GameObject("Well", typeof(RectTransform));
            go.transform.SetParent(_root.transform, false);
            var img = go.AddComponent<Image>();
            MacOsControlKit.ApplyScrollWell(img);
            Assert.AreEqual("MacOsScrollWell", img.sprite.name);
            Assert.AreEqual(Image.Type.Sliced, img.type);

            MacOsControlKit.ApplyProgressTrack(img);
            Assert.AreEqual("MacOsProgressTrack", img.sprite.name);
        }

        [Test]
        public void ApplyBackdrop_IsSimpleDim()
        {
            var go = new GameObject("Bd", typeof(RectTransform));
            go.transform.SetParent(_root.transform, false);
            var img = go.AddComponent<Image>();
            MacOsControlKit.ApplyBackdrop(img);
            Assert.IsNull(img.sprite);
            Assert.AreEqual(Image.Type.Simple, img.type);
            Assert.Greater(img.color.a, 0.2f);
        }

        [Test]
        public void StructuralDump_PrimarySecondaryFieldPanel_Differ()
        {
            var primary = MacOsControlKit.CreateButton(_root.transform, "Primary",
                new Vector2(100f, 34f), new Color(0.20f, 0.42f, 0.52f, 1f));
            var secondary = MacOsControlKit.CreateButton(_root.transform, "Secondary",
                new Vector2(100f, 34f), new Color(0.22f, 0.24f, 0.29f, 1f));
            var field = MacOsControlKit.CreateTextField(_root.transform, "Input", new Vector2(180f, 32f));
            var panel = MacOsControlKit.CreatePanel(_root.transform, "Dlg", new Vector2(400f, 300f));

            var pImg = (Image)primary.targetGraphic;
            var sImg = (Image)secondary.targetGraphic;
            var fImg = field.GetComponent<Image>();

            Assert.AreNotEqual(pImg.sprite.name, sImg.sprite.name);
            Assert.AreNotEqual(pImg.sprite.name, fImg.sprite.name);
            Assert.AreNotEqual(fImg.sprite.name, panel.sprite.name);
            Assert.AreNotEqual(pImg.color, fImg.color);
        }

        [Test]
        public void Apply_OnExistingImage_ConfiguresSlicedType()
        {
            var go = new GameObject("Img", typeof(RectTransform));
            go.transform.SetParent(_root.transform, false);
            var img = go.AddComponent<Image>();
            img.sprite = null;
            img.type = Image.Type.Simple;
            var style = MacOsControlKit.ApplyButton(img, new Color(0.20f, 0.42f, 0.52f, 1f));
            Assert.IsTrue(style.IsSlicedRounded);
            Assert.AreEqual(Image.Type.Sliced, img.type);
            Assert.IsNotNull(img.sprite);
        }

        [Test]
        public void ConceptDTheme_MatchesDemoTokens()
        {
            // design/nav-redesign/demo/index.html :root
            Assert.AreEqual(ConceptDTheme.Hex(0x37, 0xc8, 0xc3), ConceptDTheme.Accent);
            Assert.AreEqual(ConceptDTheme.Hex(0x14, 0x18, 0x1b), ConceptDTheme.Bg);
            Assert.AreEqual(ConceptDTheme.Hex(0x1a, 0x1f, 0x23), ConceptDTheme.Bg2);
            Assert.AreEqual(ConceptDTheme.Hex(0x17, 0x1c, 0x20), ConceptDTheme.Panel);
            Assert.AreEqual(ConceptDTheme.Hex(0xff, 0xd9, 0xa0), ConceptDTheme.Warm);
            Assert.AreEqual(ConceptDTheme.Hex(0xe0, 0x6c, 0x60), ConceptDTheme.Danger);
        }

        [Test]
        public void KitFills_UseConceptDTheme()
        {
            Assert.AreEqual(ConceptDTheme.Primary, MacOsControlKit.PrimaryFill);
            Assert.AreEqual(ConceptDTheme.Field, MacOsControlKit.TextFieldFill);
            Assert.AreEqual(ConceptDTheme.Dialog, MacOsControlKit.PanelFill);
            Assert.AreEqual(ConceptDTheme.Accent, MacOsControlKit.SegmentActiveFill);
            Assert.AreEqual(ConceptDTheme.Line, MacOsControlKit.SeparatorFill);
        }
    }
}
