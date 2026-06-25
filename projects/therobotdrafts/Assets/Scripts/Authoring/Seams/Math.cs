namespace TheRobotDraft.Authoring.Seams
{
    /// <summary>
    /// A minimal 3-vector. The authoring assembly is engine-free (so the command/rules core unit-tests as
    /// plain C#); the renderer adapter converts between this and <c>UnityEngine.Vector3</c> at the seam.
    /// </summary>
    public readonly struct Float3
    {
        public readonly float X, Y, Z;
        public Float3(float x, float y, float z) { X = x; Y = y; Z = z; }
        public static readonly Float3 Zero = new Float3(0, 0, 0);
        public override string ToString() => $"({X:0.###}, {Y:0.###}, {Z:0.###})";
    }

    /// <summary>A pick ray: origin + (assumed-normalized) direction. Desktop = camera ray; VR = controller ray.</summary>
    public readonly struct Ray3
    {
        public readonly Float3 Origin;
        public readonly Float3 Direction;
        public Ray3(Float3 origin, Float3 direction) { Origin = origin; Direction = direction; }
    }
}
