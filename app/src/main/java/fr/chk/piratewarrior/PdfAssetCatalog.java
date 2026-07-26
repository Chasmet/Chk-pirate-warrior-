package fr.chk.piratewarrior;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Catalogue des références visuelles extraites du dossier officiel « asset chk pirate ».
 *
 * Ces entrées servent de fallback visuel lorsque les bandes transparentes finales ne sont pas
 * encore présentes. Les identifiants restent strictement alignés sur Enemy25DCatalog.
 */
public final class PdfAssetCatalog {
    public enum Rank { BOSS, COMMANDER, SUBORDINATE }

    public static final int ISLAND_COUNT = 6;
    public static final String[] ISLAND_NAMES = Enemy25DCatalog.ISLAND_NAMES.clone();

    public static final class Entry {
        public final String id;
        public final String displayName;
        public final int islandIndex;
        public final Rank rank;
        public final int atlasSlot;

        Entry(String id, String displayName, int islandIndex, Rank rank, int atlasSlot) {
            this.id = id;
            this.displayName = displayName;
            this.islandIndex = islandIndex;
            this.rank = rank;
            this.atlasSlot = atlasSlot;
        }

        public boolean isBoss() {
            return rank == Rank.BOSS;
        }
    }

    private static final List<Entry> ENTRIES = List.of(
            new Entry("brakor", "Brakor, Gardien du Port", 0, Rank.BOSS, 0),
            new Entry("tireur_quais", "Tireur des Quais", 0, Rank.COMMANDER, 1),
            new Entry("maitre_croc", "Maître Croc", 0, Rank.COMMANDER, 2),
            new Entry("ingenieur_amarres", "Ingénieur des Amarres", 0, Rank.COMMANDER, 3),
            new Entry("voleur_agile", "Voleur Agile", 0, Rank.SUBORDINATE, 4),
            new Entry("porte_chaine", "Porte-Chaîne", 0, Rank.SUBORDINATE, 5),
            new Entry("guetteur_phare", "Guetteur du Phare", 0, Rank.SUBORDINATE, 6),

            new Entry("malkor", "Malkor", 1, Rank.BOSS, 0),
            new Entry("zaya", "Zaya", 1, Rank.COMMANDER, 1),
            new Entry("kongo", "Kongo", 1, Rank.COMMANDER, 2),
            new Entry("silex", "Silex", 1, Rank.COMMANDER, 3),
            new Entry("ronce", "Ronce", 1, Rank.SUBORDINATE, 4),
            new Entry("tika", "Tika", 1, Rank.SUBORDINATE, 5),
            new Entry("mamba", "Mamba", 1, Rank.SUBORDINATE, 6),

            new Entry("skarn", "Skarn, Roi des Glaces", 2, Rank.BOSS, 0),
            new Entry("eira", "Eira, Dame du Blizzard", 2, Rank.COMMANDER, 1),
            new Entry("volkr", "Volkr, Bouclier du Froid", 2, Rank.COMMANDER, 2),
            new Entry("nivor", "Nivor, Arbalétrier des Glaces", 2, Rank.COMMANDER, 3),
            new Entry("brume", "Brume, l'Ombre Glacée", 2, Rank.SUBORDINATE, 4),
            new Entry("harka", "Harka, Berserker des Glaces", 2, Rank.SUBORDINATE, 5),
            new Entry("flint", "Flint, Ingénieur du Froid", 2, Rank.SUBORDINATE, 6),

            new Entry("zarok", "Zarok, Khan des Sables", 3, Rank.BOSS, 0),
            new Entry("sabir", "Sabir le Dromadaire", 3, Rank.COMMANDER, 1),
            new Entry("razka", "Razka la Lame de Sable", 3, Rank.COMMANDER, 2),
            new Entry("al_varis", "Al-Varis l'Artificier", 3, Rank.COMMANDER, 3),
            new Entry("chaal", "Chaal le Rapace", 3, Rank.SUBORDINATE, 4),
            new Entry("machoire_desert", "Mâchoire du Désert", 3, Rank.SUBORDINATE, 5),
            new Entry("veilleuse_dunes", "Veilleuse des Dunes", 3, Rank.SUBORDINATE, 6),

            new Entry("vulkar", "Vulkar, Seigneur des Flammes", 4, Rank.BOSS, 0),
            new Entry("cendre", "Cendre, Lame des Braises", 4, Rank.COMMANDER, 1),
            new Entry("magma", "Magma, Bouclier de Lave", 4, Rank.COMMANDER, 2),
            new Entry("pyros", "Pyros, Artificier Infernal", 4, Rank.COMMANDER, 3),
            new Entry("basalte", "Basalte, Gardien des Roches", 4, Rank.SUBORDINATE, 4),
            new Entry("scorie", "Scorie, Faucheuse de Feu", 4, Rank.SUBORDINATE, 5),
            new Entry("fumar", "Fumar, Alchimiste des Fumées", 4, Rank.SUBORDINATE, 6),

            new Entry("tempyr", "Tempyr, Amiral de la Tempête", 5, Rank.BOSS, 0),
            new Entry("orage", "Orage, Lame du Tonnerre", 5, Rank.COMMANDER, 1),
            new Entry("volt", "Volt, Ingénieur du Tonnerre", 5, Rank.COMMANDER, 2),
            new Entry("cyclone", "Cyclone, Lance des Vents", 5, Rank.COMMANDER, 3),
            new Entry("brisk", "Brisk, Coureur des Courants", 5, Rank.SUBORDINATE, 4),
            new Entry("tonnerre", "Tonnerre, Marteau du Ciel", 5, Rank.SUBORDINATE, 5),
            new Entry("fulgur", "Fulgur, Archer des Éclairs", 5, Rank.SUBORDINATE, 6)
    );

    private PdfAssetCatalog() {
    }

    public static List<Entry> all() {
        return ENTRIES;
    }

    public static List<Entry> forIsland(int islandIndex) {
        List<Entry> result = new ArrayList<>(7);
        for (Entry entry : ENTRIES) {
            if (entry.islandIndex == islandIndex) result.add(entry);
        }
        return Collections.unmodifiableList(result);
    }

    public static Entry byId(String id) {
        if (id == null) return null;
        for (Entry entry : ENTRIES) {
            if (entry.id.equals(id)) return entry;
        }
        return null;
    }

    public static Entry bossForIsland(int islandIndex) {
        for (Entry entry : ENTRIES) {
            if (entry.islandIndex == islandIndex && entry.rank == Rank.BOSS) return entry;
        }
        throw new IllegalArgumentException("Aucun boss PDF pour l'île " + islandIndex);
    }

    public static String atlasAssetPath(int islandIndex) {
        int safe = Math.max(0, Math.min(ISLAND_COUNT - 1, islandIndex));
        return String.format(java.util.Locale.ROOT,
                "characters25d/pdf_atlas/island_%02d_atlas.webp.b64", safe + 1);
    }
}
