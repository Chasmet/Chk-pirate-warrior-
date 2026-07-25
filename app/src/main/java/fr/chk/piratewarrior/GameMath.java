package fr.chk.piratewarrior;

/** Utilitaires mathématiques sans dépendance Android, partagés par le moteur et les tests. */
public final class GameMath {
    private GameMath() {
    }

    public static float clamp(float value, float min, float max) {
        return Math.max(min, Math.min(max, value));
    }

    public static float length(float x, float z) {
        return (float) Math.sqrt(x * x + z * z);
    }

    public static float distance(float ax, float az, float bx, float bz) {
        return length(ax - bx, az - bz);
    }

    public static float normalizeAngle(float angle) {
        float twoPi = (float) (Math.PI * 2.0);
        angle %= twoPi;
        if (angle > Math.PI) {
            angle -= twoPi;
        } else if (angle < -Math.PI) {
            angle += twoPi;
        }
        return angle;
    }

    public static float lerp(float from, float to, float factor) {
        return from + (to - from) * clamp(factor, 0f, 1f);
    }

    public static boolean circlesOverlap(
            float ax,
            float az,
            float ar,
            float bx,
            float bz,
            float br
    ) {
        float radius = ar + br;
        float dx = ax - bx;
        float dz = az - bz;
        return dx * dx + dz * dz < radius * radius;
    }

    /**
     * Ramène un point dans un disque. Le tableau retourné contient x puis z.
     */
    public static float[] clampToCircle(float x, float z, float cx, float cz, float radius) {
        float dx = x - cx;
        float dz = z - cz;
        float length = length(dx, dz);
        if (length <= radius || length < 0.0001f) {
            return new float[]{x, z};
        }
        float scale = radius / length;
        return new float[]{cx + dx * scale, cz + dz * scale};
    }
}
