package fr.chk.piratewarrior;

import android.graphics.Color;

import java.util.Locale;

/** Immutable world definition used by the game engine and UI. */
public final class GameWorld {
    public static final int ISLAND_COUNT = 11;

    public enum Biome {
        TROPICAL, FOOD, DESERT, JUNGLE, SNOW, VOLCANO, SKY, TECHNO, GHOST, ANCIENT, MEMORY
    }

    public enum Weather {
        CLEAR, RAIN, STORM, SNOW, ASH, FOG, GOLDEN_FOG
    }

    public static final class Island {
        public final int id;
        public final String name;
        public final String subtitle;
        public final String boss;
        public final String objective;
        public final Biome biome;
        public final Weather weather;
        public final int skyTop;
        public final int skyBottom;
        public final int ground;
        public final int accent;
        public final int enemyCount;

        Island(int id, String name, String subtitle, String boss, String objective,
               Biome biome, Weather weather, int skyTop, int skyBottom,
               int ground, int accent, int enemyCount) {
            this.id = id;
            this.name = name;
            this.subtitle = subtitle;
            this.boss = boss;
            this.objective = objective;
            this.biome = biome;
            this.weather = weather;
            this.skyTop = skyTop;
            this.skyBottom = skyBottom;
            this.ground = ground;
            this.accent = accent;
            this.enemyCount = enemyCount;
        }

        public String displayName() {
            return String.format(Locale.FRANCE, "ÎLE %d — %s", id, name);
        }
    }

    private static final Island[] ISLANDS = new Island[] {
            new Island(1, "Royaume des Palmes", "Port solaire et jungle côtière", "Amiral Koro",
                    "Libérer le port et vaincre l'amiral", Biome.TROPICAL, Weather.CLEAR,
                    Color.rgb(65, 174, 232), Color.rgb(198, 230, 244), Color.rgb(82, 145, 76), Color.rgb(247, 198, 74), 12),
            new Island(2, "Royaume des Roches", "Falaises, grottes et canyons marins", "Général Basalte",
                    "Trouver trois sceaux dans les falaises", Biome.ANCIENT, Weather.RAIN,
                    Color.rgb(88, 133, 166), Color.rgb(178, 194, 199), Color.rgb(105, 98, 82), Color.rgb(205, 151, 84), 14),
            new Island(3, "Royaume de Nourriture", "Village gourmand et cultures géantes", "Chef Gourmand",
                    "Protéger les habitants et récupérer les réserves", Biome.FOOD, Weather.CLEAR,
                    Color.rgb(105, 195, 232), Color.rgb(247, 218, 171), Color.rgb(120, 167, 75), Color.rgb(242, 111, 83), 14),
            new Island(4, "Jungle Interdite", "Ruines mangées par une forêt immense", "Reine Croc",
                    "Traverser la jungle et sauver les explorateurs", Biome.JUNGLE, Weather.RAIN,
                    Color.rgb(48, 120, 104), Color.rgb(118, 168, 113), Color.rgb(49, 96, 52), Color.rgb(215, 187, 72), 16),
            new Island(5, "Royaume des Glaces", "Montagnes gelées et villages enneigés", "Commandant Boréal",
                    "Réactiver les trois brasiers du royaume", Biome.SNOW, Weather.SNOW,
                    Color.rgb(112, 157, 199), Color.rgb(222, 237, 244), Color.rgb(205, 225, 230), Color.rgb(87, 182, 232), 16),
            new Island(6, "Terres du Volcan", "Lave, cendres et forteresse noire", "Seigneur Magma",
                    "Fermer les bouches de lave et atteindre la forteresse", Biome.VOLCANO, Weather.ASH,
                    Color.rgb(83, 49, 50), Color.rgb(218, 94, 53), Color.rgb(61, 51, 48), Color.rgb(244, 91, 48), 18),
            new Island(7, "Archipel du Ciel", "Îlots suspendus au-dessus des nuages", "Gardien Zéphyr",
                    "Rallumer les balises célestes", Biome.SKY, Weather.CLEAR,
                    Color.rgb(74, 154, 229), Color.rgb(224, 240, 250), Color.rgb(142, 177, 164), Color.rgb(245, 220, 108), 18),
            new Island(8, "Cité Néon", "Métropole futuriste alimentée par un cœur d'énergie", "Prototype Zéro",
                    "Désactiver les relais ennemis", Biome.TECHNO, Weather.STORM,
                    Color.rgb(24, 34, 71), Color.rgb(71, 40, 96), Color.rgb(47, 55, 70), Color.rgb(64, 224, 220), 20),
            new Island(9, "Mer des Spectres", "Brume, épaves et village fantôme", "Capitaine Sans-Nom",
                    "Retrouver les lanternes des marins disparus", Biome.GHOST, Weather.FOG,
                    Color.rgb(41, 61, 70), Color.rgb(105, 119, 115), Color.rgb(62, 77, 68), Color.rgb(142, 220, 185), 20),
            new Island(10, "Empire Ancien", "Palais, temples et armée impériale", "Empereur d'Obsidienne",
                    "Ouvrir la porte impériale et vaincre l'empereur", Biome.ANCIENT, Weather.CLEAR,
                    Color.rgb(128, 91, 70), Color.rgb(233, 188, 124), Color.rgb(130, 103, 72), Color.rgb(242, 196, 88), 22),
            new Island(11, "Royaume Troublé", "Souvenirs oubliés derrière une brume dorée", "Le Gardien du Souvenir",
                    "Retrouver l'objet rare et libérer les souvenirs", Biome.MEMORY, Weather.GOLDEN_FOG,
                    Color.rgb(94, 75, 65), Color.rgb(199, 165, 94), Color.rgb(89, 79, 68), Color.rgb(255, 212, 94), 24)
    };

    private GameWorld() {
    }

    public static Island get(int index) {
        return ISLANDS[Math.max(0, Math.min(ISLAND_COUNT - 1, index))];
    }

    public static Island[] all() {
        return ISLANDS.clone();
    }
}
