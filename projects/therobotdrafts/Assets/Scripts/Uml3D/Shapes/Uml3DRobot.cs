using System.Collections.Generic;
using UnityEngine;

namespace TheRobotDraft.Uml3D
{
    /// <summary>
    /// The result of building a robot: its root GameObject plus the per-part fill renderers and the colors they were
    /// built with, so the owning node can re-tint / highlight the individual parts (depth gray, selection lift).
    /// </summary>
    public readonly struct RobotHandle
    {
        public readonly GameObject Root;
        public readonly IReadOnlyList<Renderer> Parts;
        public readonly IReadOnlyList<Color> BaseColors;
        public RobotHandle(GameObject root, IReadOnlyList<Renderer> parts, IReadOnlyList<Color> baseColors)
        {
            Root = root; Parts = parts; BaseColors = baseColors;
        }
    }

    /// <summary>
    /// Builds the <b>Actor</b> / <b>Person</b> node as a cute, FLAT mechanical ROBOT — a paper-doll figure with the
    /// humanoid part layout (head, neck, torso, two arms, two legs, feet) but a boxy robotic look: square-ish metal
    /// rectangles, thin segmented limbs, an antenna, a glowing screen face and a chest panel. It's authored as a
    /// 2-D <see cref="Uml3DVector"/> picture (rectangles at different rotations) and then volumetrized (extruded a
    /// little) so the parts read as thin slabs with edge borders. Each part is its own fill, so the eyes / mouth /
    /// panel are real colored elements (not holes) and the body carries several shades.
    ///
    /// Portrait proportions (the node uses a tall footprint for actors). Built centered on the parent's origin
    /// (+Z faces the camera, +Y up); the lower band of the box is left clear for the node's name label.
    /// </summary>
    public static class Uml3DRobot
    {
        /// <summary>
        /// Build the robot under <paramref name="parent"/>; returns a <see cref="RobotHandle"/> with its root
        /// GameObject (destroy to rebuild) plus the per-part fill renderers + base colors for re-tinting.
        /// </summary>
        public static RobotHandle Build(Transform parent, float w, float h, float d, Color fill)
        {
            var root = new GameObject("Robot");
            root.transform.SetParent(parent, false);

            float dep = Mathf.Max(0.04f, d * 0.8f); // flat: thin extrusion for every part
            float front = dep * 0.5f;               // torso/head front plane — face & panel sit here

            float figTop = h * 0.48f;
            float figBot = -h * 0.5f + h * 0.14f;
            float figH = Mathf.Max(0.04f, figTop - figBot);

            // Shade palette + glowing accents.
            Color torsoC = fill;
            Color headC = Color.Lerp(fill, Color.black, 0.08f);
            Color arm = Color.Lerp(fill, Color.black, 0.20f);
            Color leg = Color.Lerp(fill, Color.black, 0.34f);
            Color foot = Color.Lerp(fill, Color.black, 0.50f);
            Color metal = Color.Lerp(fill, Color.black, 0.30f);
            Color panel = Color.Lerp(fill, Color.white, 0.10f);
            Color stroke = Color.Lerp(fill, Color.black, 0.64f);
            Color eye = new Color(0.55f, 0.93f, 1f, 1f);
            Color pupil = new Color(0.06f, 0.09f, 0.13f, 1f);
            Color mouth = new Color(0.10f, 0.12f, 0.16f, 1f);
            Color blush = new Color(1f, 0.62f, 0.62f, 1f);

            var v = new Uml3DVector();

            // --- landmarks (portrait, top → bottom) ------------------------------------
            float headH = figH * 0.18f, headW = w * 0.40f;
            float headCY = figTop - headH * 0.5f;
            float headTop = headCY + headH * 0.5f, headBot = headCY - headH * 0.5f;

            float neckH = figH * 0.05f, neckW = w * 0.12f;
            float neckCY = headBot - neckH * 0.5f;

            float torsoH = figH * 0.30f, torsoW = w * 0.44f;
            float torsoTop = neckCY - neckH * 0.5f;
            float torsoCY = torsoTop - torsoH * 0.5f;
            float torsoBot = torsoCY - torsoH * 0.5f;

            float footH = figH * 0.045f, footY = figBot + footH * 0.5f;

            // --- antenna (stalk + glowing bulb) ----------------------------------------
            float aR = Mathf.Max(0.02f, headW * 0.10f);
            v.Rect("AntStalk", 0f, headTop + figH * 0.035f, w * 0.025f, figH * 0.075f, 0f, dep * 0.6f, metal, stroke);
            v.Ellipse("AntBulb", 0f, headTop + figH * 0.085f, aR, aR, 0f, dep * 0.8f, eye, stroke, emissive: true);

            // --- arms: thin segmented metal off each shoulder --------------------------
            float armT = w * 0.075f;
            for (int s = -1; s <= 1; s += 2)
            {
                Vector2 shoulder = new(s * torsoW * 0.46f, torsoTop - torsoH * 0.05f);
                Vector2 elbow = new(s * (torsoW * 0.5f + w * 0.14f), torsoCY + torsoH * 0.06f);
                Vector2 hand = new(s * (torsoW * 0.5f + w * 0.11f), torsoBot - torsoH * 0.02f);
                Limb(v, "UpperArm", shoulder, elbow, armT, 0f, dep, arm, stroke, armT * 0.25f);
                Limb(v, "ForeArm", elbow, hand, armT * 0.92f, 0f, dep, arm, stroke, armT * 0.25f);
                v.Ellipse("Shoulder", shoulder.x, shoulder.y, armT * 0.62f, armT * 0.62f, dep * 0.1f, dep, metal, stroke);
                v.Rect("Hand", hand.x, hand.y, armT * 1.5f, armT * 1.1f, dep * 0.1f, dep, metal, stroke);
            }

            // --- legs: thin segmented, splayed slightly, with boxy feet ----------------
            float legT = w * 0.11f;
            for (int s = -1; s <= 1; s += 2)
            {
                Vector2 hip = new(s * w * 0.11f, torsoBot + torsoH * 0.02f);
                Vector2 knee = new(s * w * 0.14f, (torsoBot + footY) * 0.5f);
                Vector2 ankle = new(s * w * 0.15f, footY + footH * 0.5f);
                Limb(v, "Thigh", hip, knee, legT, 0f, dep, leg, stroke, legT * 0.2f);
                Limb(v, "Shin", knee, ankle, legT * 0.92f, 0f, dep, leg, stroke, legT * 0.2f);
                v.Rect("Foot", s * w * 0.16f, footY, w * 0.16f, footH, dep * 0.15f, dep, foot, stroke);
            }

            // --- neck, torso (drawn after limbs so the body overlaps the joints) -------
            v.Rect("Neck", 0f, neckCY, neckW, neckH, 0f, dep * 0.9f, metal, stroke);
            v.RoundRect("Torso", 0f, torsoCY, torsoW, torsoH, w * 0.04f, 0f, dep, torsoC, stroke);
            // Chest panel + two indicator lights — robotic detail.
            v.RoundRect("Panel", 0f, torsoCY + torsoH * 0.05f, torsoW * 0.5f, torsoH * 0.42f, torsoW * 0.04f, front, dep * 0.4f, panel, stroke);
            v.Ellipse("Led1", -torsoW * 0.12f, torsoCY + torsoH * 0.12f, w * 0.022f, w * 0.022f, front + dep * 0.2f, dep * 0.3f, eye, stroke, emissive: true);
            v.Ellipse("Led2", torsoW * 0.12f, torsoCY + torsoH * 0.12f, w * 0.022f, w * 0.022f, front + dep * 0.2f, dep * 0.3f, blush, stroke);

            // --- head + screen face ----------------------------------------------------
            v.RoundRect("Head", 0f, headCY, headW, headH, Mathf.Min(headW, headH) * 0.16f, 0f, dep, headC, stroke);
            float eyeY = headCY + headH * 0.06f, eyeX = headW * 0.22f;
            float eyeW = headW * 0.30f, eyeH = headH * 0.42f;
            v.RoundRect("EyeL", -eyeX, eyeY, eyeW, eyeH, eyeH * 0.35f, front, dep * 0.5f, eye, stroke, emissive: true);
            v.RoundRect("EyeR", eyeX, eyeY, eyeW, eyeH, eyeH * 0.35f, front, dep * 0.5f, eye, stroke, emissive: true);
            v.Rect("PupilL", -eyeX + eyeW * 0.16f, eyeY, eyeW * 0.34f, eyeH * 0.5f, front + dep * 0.18f, dep * 0.3f, pupil, pupil);
            v.Rect("PupilR", eyeX + eyeW * 0.16f, eyeY, eyeW * 0.34f, eyeH * 0.5f, front + dep * 0.18f, dep * 0.3f, pupil, pupil);
            v.Ellipse("BlushL", -headW * 0.32f, eyeY - eyeH * 0.7f, headW * 0.09f, headH * 0.07f, front, dep * 0.4f, blush, stroke);
            v.Ellipse("BlushR", headW * 0.32f, eyeY - eyeH * 0.7f, headW * 0.09f, headH * 0.07f, front, dep * 0.4f, blush, stroke);
            // Smile grille: a center bar with two up-stepped ends.
            float my = headCY - headH * 0.28f, bw = headW * 0.15f, bh = headH * 0.08f;
            v.RoundRect("Mouth", 0f, my, bw * 1.4f, bh, bh * 0.4f, front, dep * 0.4f, mouth, stroke);
            v.RoundRect("MouthL", -headW * 0.16f, my + bh, bw, bh, bh * 0.4f, front, dep * 0.4f, mouth, stroke);
            v.RoundRect("MouthR", headW * 0.16f, my + bh, bw, bh, bh * 0.4f, front, dep * 0.4f, mouth, stroke);

            v.Volumetrize(root.transform);
            return new RobotHandle(root, v.Parts, v.PartBaseColors);
        }

        /// <summary>A limb = a rounded rectangle of the given thickness spanning a→b, rotated to match its direction.</summary>
        private static void Limb(Uml3DVector v, string name, Vector2 a, Vector2 b, float thick, float z, float depth,
            Color fill, Color stroke, float radius)
        {
            Vector2 mid = (a + b) * 0.5f;
            Vector2 dir = b - a;
            float len = dir.magnitude;
            if (len < 1e-4f) return;
            float rot = Mathf.Atan2(dir.y, dir.x) * Mathf.Rad2Deg - 90f; // rect long axis is +Y
            v.RoundRect(name, mid.x, mid.y, thick, len + thick * 0.4f, radius, z, depth, fill, stroke, rot);
        }
    }
}
