package fr.chk.piratewarrior;

/**
 * Configuration commune du monde ouvert. Toutes les îles restent reliées par des routes océaniques
 * pilotables ; une seule île et son roster 2.5D sont actifs à la fois.
 */
public final class WorldConfig {
    public static final int ISLAND_COUNT = 8;
    public static final float ISLAND_WIDTH = 2_000f;
    public static final float WORLD_WIDTH = ISLAND_COUNT * ISLAND_WIDTH;
    public static final float ROUTE_DISTANCE = 4_800f;

    public static final String[] ISLAND_NAMES = {
            "Port des Naufragés",
            "Jungle Sauvage",
            "Royaume des Neiges",
            "Désert des Corsaires",
            "Île Volcanique",
            "Forteresse de la Tempête",
            "Île des Gâteaux",
            "Citadelle du Crâne"
    };

    /** Positions normalisées utilisées par la carte de l'archipel. */
    public static final float[] MAP_X = {0.10f, 0.28f, 0.48f, 0.70f, 0.86f, 0.68f, 0.42f, 0.16f};
    public static final float[] MAP_Y = {0.68f, 0.45f, 0.70f, 0.50f, 0.27f, 0.15f, 0.20f, 0.31f};

    private WorldConfig() {
    }

    public static int clampIsland(int island) {
        return Math.max(0, Math.min(ISLAND_COUNT - 1, island));
    }

    public static boolean hasNextIsland(int island) {
        return island >= 0 && island < ISLAND_COUNT - 1;
    }

    public static boolean isCakeIsland(int island) {
        return island == 6;
    }

    public static boolean isSkullMagmaIsland(int island) {
        return island == 7;
    }

    public static boolean isMagmaRoute(int departureIsland, int destinationIsland) {
        return departureIsland == 7 || destinationIsland == 7;
    }
}
