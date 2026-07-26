package fr.chk.piratewarrior;

/** État léger partagé entre la carte, la navigation et le rendu des îles étendues. */
public final class WorldSession {
    private static int activeIsland;
    private static boolean initialized;

    private WorldSession() {
    }

    public static int activeIsland(int fallback) {
        if (!initialized) {
            activeIsland = WorldConfig.clampIsland(fallback);
            initialized = true;
        }
        return activeIsland;
    }

    public static void setActiveIsland(int island) {
        activeIsland = WorldConfig.clampIsland(island);
        initialized = true;
    }

    public static int virtualSegment() {
        return Math.min(5, activeIsland);
    }
}
