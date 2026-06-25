using UnityEngine;

namespace TheRobotDraft.Uml3D
{
    /// <summary>
    /// A full 6-DOF camera rig for the 3-D diagram. It owns a perspective <see cref="Camera"/> and recomputes
    /// its transform every <see cref="LateUpdate"/> from a small piece of state — <see cref="Yaw"/>,
    /// <see cref="Pitch"/>, <see cref="Roll"/>, <see cref="Distance"/> — around a focus <see cref="Pivot"/>.
    /// The camera sits on the +Z side of the pivot looking back toward −Z, so by convention it views the nodes'
    /// front (+Z) faces (where the text/content lives) at the default pose.
    /// The integration layer drives it imperatively through <see cref="Uml3DScene"/>: orbit on drag, dolly on
    /// scroll, pan with a modifier, roll with Q/E, free-fly translate with WASD/RF, and <see cref="Frame"/> to
    /// fit the whole diagram in view. Add it to a GameObject (it creates its own child camera in
    /// <see cref="Awake"/> if one isn't supplied) and it is immediately usable.
    /// </summary>
    public sealed class UmlCameraRig : MonoBehaviour
    {
        /// <summary>The perspective camera this rig drives. Created lazily if not assigned.</summary>
        public Camera Cam { get; private set; }

        /// <summary>World-space point the camera orbits and looks at.</summary>
        public Vector3 Pivot = Vector3.zero;

        /// <summary>Orbit angle around the world-up axis, in degrees.</summary>
        public float Yaw = 0f;

        /// <summary>Orbit elevation, in degrees, clamped to (<see cref="MinPitch"/>, <see cref="MaxPitch"/>).</summary>
        public float Pitch = 18f;

        /// <summary>Roll about the view axis, in degrees. Unclamped (wraps freely).</summary>
        public float Roll = 0f;

        /// <summary>Distance from <see cref="Pivot"/> to the camera, clamped to [<see cref="MinDistance"/>, <see cref="MaxDistance"/>].</summary>
        public float Distance = 12f;

        public const float MinPitch = -85f;
        public const float MaxPitch = 85f;
        public const float MinDistance = 1.5f;
        public const float MaxDistance = 400f;

        /// <summary>World units a pan moves the pivot per screen pixel (scaled by distance for a steady feel).</summary>
        private const float PanSpeed = 0.0016f;

        /// <summary>World units a free-fly move shifts the pivot per unit of <see cref="MoveLocal"/> input (scaled
        /// by distance). Callers typically pass Time.deltaTime-scaled deltas, so this reads as units/second/distance.</summary>
        private const float MoveSpeed = 1.6f;

        private void Awake()
        {
            EnsureCamera();
        }

        /// <summary>
        /// Optional explicit setup the scene manager may call after <c>AddComponent</c> — supply an existing
        /// camera (or null to have the rig create one) and seed the starting orbit pose.
        /// </summary>
        public void Init(Camera cam = null, Vector3? pivot = null, float? yaw = null, float? pitch = null,
            float? distance = null, float? roll = null)
        {
            if (cam != null) Cam = cam;
            EnsureCamera();
            if (pivot.HasValue) Pivot = pivot.Value;
            if (yaw.HasValue) Yaw = yaw.Value;
            if (pitch.HasValue) Pitch = pitch.Value;
            if (distance.HasValue) Distance = distance.Value;
            if (roll.HasValue) Roll = roll.Value;
            ApplyTransform();
        }

        private void EnsureCamera()
        {
            if (Cam != null) return;
            // Prefer a Camera already living on this rig's hierarchy; otherwise build one on a child object so
            // the rig GameObject itself stays a plain transform the scene manager can parent under DiagramRoot.
            Cam = GetComponentInChildren<Camera>();
            if (Cam == null)
            {
                var camGo = new GameObject("UmlCamera");
                camGo.transform.SetParent(transform, false);
                Cam = camGo.AddComponent<Camera>();
            }
            Cam.orthographic = false;
            Cam.fieldOfView = 50f;
            Cam.nearClipPlane = 0.05f;
            Cam.farClipPlane = 1000f;
        }

        // --- imperative controls ---

        /// <summary>Rotate the orbit by the given yaw/pitch deltas (degrees); pitch is clamped. Composes with the
        /// current roll because <see cref="ApplyTransform"/> rebuilds the whole orientation from Yaw/Pitch/Roll.</summary>
        public void Orbit(float dYaw, float dPitch)
        {
            Yaw += dYaw;
            Pitch = Mathf.Clamp(Pitch + dPitch, MinPitch, MaxPitch);
        }

        /// <summary>Roll the camera about its own view axis by the given delta (degrees); unclamped (wraps).</summary>
        public void RollBy(float deg)
        {
            Roll += deg;
        }

        /// <summary>
        /// Fly the camera by translating the focus <see cref="Pivot"/> along the camera's own axes:
        /// <paramref name="localDelta"/>.x = right, .y = up, .z = forward (toward what the camera looks at). The
        /// camera follows because it is recomputed from the pivot each <see cref="LateUpdate"/>, so this moves the
        /// whole rig through the scene rather than orbiting a fixed point. Scaled by distance for a steady feel.</summary>
        public void MoveLocal(Vector3 localDelta)
        {
            EnsureCamera();
            float k = MoveSpeed * Distance;
            // Use the camera's actual axes so motion matches the (non-mirrored) view. Forward is the look
            // direction, so a positive localDelta.z flies into the scene.
            Pivot += Cam.transform.right * (localDelta.x * k);
            Pivot += Cam.transform.up * (localDelta.y * k);
            Pivot += Cam.transform.forward * (localDelta.z * k);
        }

        /// <summary>
        /// Move the camera toward (positive) or away from (negative) the pivot. The step scales with the
        /// current distance so zooming feels uniform whether near or far.
        /// </summary>
        public void Dolly(float delta)
        {
            Distance = Mathf.Clamp(Distance - delta * Distance * 0.1f, MinDistance, MaxDistance);
        }

        /// <summary>
        /// Slide the focus pivot in the plane facing the camera by a screen-space delta (right = camera right,
        /// up = camera up). The amount scales with distance so a drag covers a consistent fraction of the view.
        /// </summary>
        public void PanPivot(Vector2 screenDelta)
        {
            Quaternion rot = Orientation();
            Vector3 right = rot * Vector3.right;
            Vector3 up = rot * Vector3.up;
            float k = PanSpeed * Distance;
            Pivot -= right * (screenDelta.x * k);
            Pivot -= up * (screenDelta.y * k);
        }

        /// <summary>Center the pivot on <paramref name="worldBounds"/> and back the camera off to fit it in view.</summary>
        public void Frame(Bounds worldBounds)
        {
            Pivot = worldBounds.center;
            float radius = Mathf.Max(0.5f, worldBounds.extents.magnitude);
            EnsureCamera();
            // Distance that fits the bounding sphere in the smaller of the vertical / horizontal FOV, with margin.
            float vFov = Cam.fieldOfView * Mathf.Deg2Rad;
            float hFov = 2f * Mathf.Atan(Mathf.Tan(vFov * 0.5f) * Mathf.Max(0.0001f, Cam.aspect));
            float fov = Mathf.Min(vFov, hFov);
            float fit = radius / Mathf.Max(0.05f, Mathf.Sin(fov * 0.5f));
            Distance = Mathf.Clamp(fit * 1.15f, MinDistance, MaxDistance);
        }

        // --- queries delegated to the camera ---

        /// <summary>A world-space ray from the rig camera through the given screen point.</summary>
        public Ray ScreenPointToRay(Vector2 screenPos)
        {
            EnsureCamera();
            return Cam.ScreenPointToRay(screenPos);
        }

        /// <summary>Project a world position to screen-space pixels (for placing 2-D overlay menus over a node).</summary>
        public Vector3 WorldToScreen(Vector3 world)
        {
            EnsureCamera();
            return Cam.WorldToScreenPoint(world);
        }

        private void LateUpdate()
        {
            ApplyTransform();
        }

        /// <summary>The rig's full orientation (yaw, pitch, AND roll). The camera transform and every axis-relative
        /// motion (pan / free-fly) derive from this so roll is honored consistently.</summary>
        private Quaternion Orientation() => Quaternion.Euler(Pitch, Yaw, Roll);

        /// <summary>Recompute the camera position/orientation from the current 6-DOF state.</summary>
        private void ApplyTransform()
        {
            if (Cam == null) return;
            Quaternion rot = Orientation();
            // Sit on the +Z side of the pivot so the camera looks back toward −Z — i.e. it faces the nodes' front
            // (+Z) content faces by convention.
            Vector3 pos = Pivot + rot * new Vector3(0f, 0f, Distance);
            // Aim the camera at the pivot with a proper look-rotation (NOT a 180° yaw flip — that mirrors the X
            // axis and renders all text reversed). The rolled up-vector (rot * up) carries pitch/yaw/roll through.
            Vector3 fwd = Pivot - pos;
            if (fwd.sqrMagnitude < 1e-6f) fwd = Vector3.forward;
            Quaternion camRot = Quaternion.LookRotation(fwd.normalized, rot * Vector3.up);
            Cam.transform.SetPositionAndRotation(pos, camRot);
        }
    }
}
