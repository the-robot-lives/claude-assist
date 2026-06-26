using UnityEngine;

namespace TheRobotDraft.Uml3D
{
    /// <summary>
    /// 3-D mesh for the UML <b>Actor</b> and C4 <b>Person</b> node kinds: a blocky tin-ROBOT — a cuboid head with
    /// antennae, a box torso, segmented (bent) arms, two legs and feet, plus sphere rivets at the joints. It reads
    /// as a chunky 3-D figure rather than a flat stick, fitting the project's "robot" theme.
    ///
    /// The robot occupies the TOP of the bounding box and leaves a band at the bottom for the node's name label
    /// (the node draws that label itself). The mesh is centered on the origin and inscribed (in X/Y) in
    /// [-w/2, w/2] × [-h/2, h/2]; it bulges past ±d/2 in Z so the body has real depth (the node keeps a separate
    /// box collider, so picking is unaffected).
    /// </summary>
    public static class Uml3DShape_Actor
    {
        /// <summary>Build the robot mesh.</summary>
        /// <param name="w">Node width in world units (typical ~0.74).</param>
        /// <param name="h">Node height in world units (typical ~1.16).</param>
        /// <param name="d">Node depth / thickness in world units (typical ~0.18).</param>
        public static Mesh Build(float w, float h, float d)
        {
            var b = new Uml3DMeshBuilder();

            // Body depth — chunkier than the thin slab so the robot looks solid.
            float rz = Mathf.Max(d, Mathf.Min(w, h) * 0.30f);

            // The figure lives in the upper part of the box; the lower band is left empty for the name label.
            float figTop = h * 0.46f;
            float figBot = -h * 0.5f + h * 0.20f;
            float figH = Mathf.Max(0.04f, figTop - figBot);

            float limbT = Mathf.Max(0.02f, w * 0.10f); // arm/leg thickness

            // Local helper: a box limb segment spanning two points (used for the bent arms).
            void Limb(Vector3 p0, Vector3 p1, float thick, float depth)
            {
                Vector3 dir = p1 - p0;
                float len = dir.magnitude;
                if (len < 1e-4f) return;
                Quaternion rot = Quaternion.FromToRotation(Vector3.up, dir / len);
                b.AddOrientedBox((p0 + p1) * 0.5f, new Vector3(thick, len, depth), rot);
            }

            // --- head -------------------------------------------------------------------
            float headW = w * 0.40f, headH = figH * 0.19f, headD = rz;
            float headCY = figTop - headH * 0.5f;
            float headTop = headCY + headH * 0.5f;
            b.AddBox(new Vector3(0f, headCY, 0f), new Vector3(headW, headH, headD));

            // Antennae: two short stalks with ball tips on the head's top corners.
            float antR = Mathf.Max(0.01f, w * 0.018f);
            float antTip = Mathf.Max(0.02f, w * 0.03f);
            for (int s = -1; s <= 1; s += 2)
            {
                Vector3 baseP = new Vector3(s * headW * 0.30f, headTop, 0f);
                Vector3 tipP = new Vector3(s * headW * 0.30f, headTop + figH * 0.06f, 0f);
                b.AddTube(baseP, tipP, antR, 6);
                b.AddSphere(tipP, antTip, 6, 8);
            }

            // --- neck -------------------------------------------------------------------
            float neckH = figH * 0.05f;
            float neckCY = headCY - headH * 0.5f - neckH * 0.5f;
            b.AddBox(new Vector3(0f, neckCY, 0f), new Vector3(w * 0.12f, neckH, rz * 0.6f));

            // --- torso ------------------------------------------------------------------
            float torsoW = w * 0.46f, torsoH = figH * 0.27f;
            float torsoTop = neckCY - neckH * 0.5f;
            float torsoCY = torsoTop - torsoH * 0.5f;
            float torsoBot = torsoCY - torsoH * 0.5f;
            b.AddBox(new Vector3(0f, torsoCY, 0f), new Vector3(torsoW, torsoH, rz));

            // --- arms (segmented, bent at the elbow) ------------------------------------
            float jointR = limbT * 0.62f;
            for (int s = -1; s <= 1; s += 2)
            {
                Vector3 shoulder = new Vector3(s * torsoW * 0.5f, torsoTop - figH * 0.03f, 0f);
                Vector3 elbow = new Vector3(s * (torsoW * 0.5f + w * 0.12f), torsoCY + figH * 0.01f, 0f);
                Vector3 hand = new Vector3(s * (torsoW * 0.5f + w * 0.09f), torsoBot - figH * 0.02f, 0f);
                Limb(shoulder, elbow, limbT * 0.9f, rz * 0.7f);  // upper arm
                Limb(elbow, hand, limbT * 0.8f, rz * 0.6f);      // forearm
                b.AddSphere(shoulder, jointR, 6, 8);
                b.AddSphere(elbow, jointR * 0.9f, 6, 8);
            }

            // --- legs + feet ------------------------------------------------------------
            float legW = w * 0.14f;
            float footH = figH * 0.05f;
            float footY = figBot + footH * 0.5f;
            float legTopY = torsoBot;
            float legBotY = footY + footH * 0.5f;
            float legCY = (legTopY + legBotY) * 0.5f;
            float legHt = Mathf.Max(0.02f, legTopY - legBotY);
            for (int s = -1; s <= 1; s += 2)
            {
                float lx = s * w * 0.12f;
                b.AddBox(new Vector3(lx, legCY, 0f), new Vector3(legW, legHt, rz * 0.8f));
                // Foot: a wider, shallow block nudged forward.
                b.AddBox(new Vector3(lx, footY, rz * 0.12f), new Vector3(w * 0.18f, footH, rz));
            }

            return b.ToMesh("ActorRobot");
        }
    }
}
