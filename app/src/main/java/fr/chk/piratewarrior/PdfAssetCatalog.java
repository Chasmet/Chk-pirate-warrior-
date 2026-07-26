package fr.chk.piratewarrior;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/** Catalogue des atlas de référence utilisés comme fallback 2.5D. */
public final class PdfAssetCatalog {
    public enum Rank { BOSS, COMMANDER, SUBORDINATE }

    public static final int ISLAND_COUNT = Enemy25DCatalog.ISLAND_COUNT;
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

        public boolean isBoss() { return rank == Rank.BOSS; }
    }

    private static Entry e(String id, String name, int island, Rank rank, int slot) {
        return new Entry(id, name, island, rank, slot);
    }

    private static final List<Entry> ENTRIES = List.of(
            e("brakor", "Brakor, Gardien du Port", 0, Rank.BOSS, 0),
            e("tireur_quais", "Tireur des Quais", 0, Rank.COMMANDER, 1),
            e("maitre_croc", "Maître Croc", 0, Rank.COMMANDER, 2),
            e("ingenieur_amarres", "Ingénieur des Amarres", 0, Rank.COMMANDER, 3),
            e("voleur_agile", "Voleur Agile", 0, Rank.SUBORDINATE, 4),
            e("porte_chaine", "Porte-Chaîne", 0, Rank.SUBORDINATE, 5),
            e("guetteur_phare", "Guetteur du Phare", 0, Rank.SUBORDINATE, 6),

            e("malkor", "Malkor", 1, Rank.BOSS, 0),
            e("zaya", "Zaya", 1, Rank.COMMANDER, 1),
            e("kongo", "Kongo", 1, Rank.COMMANDER, 2),
            e("silex", "Silex", 1, Rank.COMMANDER, 3),
            e("ronce", "Ronce", 1, Rank.SUBORDINATE, 4),
            e("tika", "Tika", 1, Rank.SUBORDINATE, 5),
            e("mamba", "Mamba", 1, Rank.SUBORDINATE, 6),

            e("skarn", "Skarn, Roi des Glaces", 2, Rank.BOSS, 0),
            e("eira", "Eira, Dame du Blizzard", 2, Rank.COMMANDER, 1),
            e("volkr", "Volkr, Bouclier du Froid", 2, Rank.COMMANDER, 2),
            e("nivor", "Nivor, Arbalétrier des Glaces", 2, Rank.COMMANDER, 3),
            e("brume", "Brume, l'Ombre Glacée", 2, Rank.SUBORDINATE, 4),
            e("harka", "Harka, Berserker des Glaces", 2, Rank.SUBORDINATE, 5),
            e("flint", "Flint, Ingénieur du Froid", 2, Rank.SUBORDINATE, 6),

            e("zarok", "Zarok, Khan des Sables", 3, Rank.BOSS, 0),
            e("sabir", "Sabir le Dromadaire", 3, Rank.COMMANDER, 1),
            e("razka", "Razka la Lame de Sable", 3, Rank.COMMANDER, 2),
            e("al_varis", "Al-Varis l'Artificier", 3, Rank.COMMANDER, 3),
            e("chaal", "Chaal le Rapace", 3, Rank.SUBORDINATE, 4),
            e("machoire_desert", "Mâchoire du Désert", 3, Rank.SUBORDINATE, 5),
            e("veilleuse_dunes", "Veilleuse des Dunes", 3, Rank.SUBORDINATE, 6),

            e("vulkar", "Vulkar, Seigneur des Flammes", 4, Rank.BOSS, 0),
            e("cendre", "Cendre, Lame des Braises", 4, Rank.COMMANDER, 1),
            e("magma", "Magma, Bouclier de Lave", 4, Rank.COMMANDER, 2),
            e("pyros", "Pyros, Artificier Infernal", 4, Rank.COMMANDER, 3),
            e("basalte", "Basalte, Gardien des Roches", 4, Rank.SUBORDINATE, 4),
            e("scorie", "Scorie, Faucheuse de Feu", 4, Rank.SUBORDINATE, 5),
            e("fumar", "Fumar, Alchimiste des Fumées", 4, Rank.SUBORDINATE, 6),

            e("tempyr", "Tempyr, Amiral de la Tempête", 5, Rank.BOSS, 0),
            e("orage", "Orage, Lame du Tonnerre", 5, Rank.COMMANDER, 1),
            e("volt", "Volt, Ingénieur du Tonnerre", 5, Rank.COMMANDER, 2),
            e("cyclone", "Cyclone, Lance des Vents", 5, Rank.COMMANDER, 3),
            e("brisk", "Brisk, Coureur des Courants", 5, Rank.SUBORDINATE, 4),
            e("tonnerre", "Tonnerre, Marteau du Ciel", 5, Rank.SUBORDINATE, 5),
            e("fulgur", "Fulgur, Archer des Éclairs", 5, Rank.SUBORDINATE, 6),

            e("matriarche_sucree", "Matriarche Sucrée", 6, Rank.BOSS, 0),
            e("prince_mochi", "Prince Mochi", 6, Rank.COMMANDER, 1),
            e("duc_biscuit", "Duc Biscuit", 6, Rank.COMMANDER, 2),
            e("chevalier_caramel", "Chevalier Caramel", 6, Rank.COMMANDER, 3),
            e("maitre_bonbon", "Maître Bonbon", 6, Rank.SUBORDINATE, 4),
            e("gardienne_meringue", "Gardienne Meringue", 6, Rank.SUBORDINATE, 5),
            e("tireur_praline", "Tireur Praliné", 6, Rank.SUBORDINATE, 6),

            e("kaor_crane", "Kaor, Seigneur du Crâne", 7, Rank.BOSS, 0),
            e("archonte_aile_noire", "Archonte de l'Aile Noire", 7, Rank.COMMANDER, 1),
            e("ravageur_cornu", "Ravageur Cornu", 7, Rank.COMMANDER, 2),
            e("canon_cendres", "Canon des Cendres", 7, Rank.COMMANDER, 3),
            e("roi_des_braises", "Roi des Braises", 7, Rank.SUBORDINATE, 4),
            e("oracle_pourpre", "Oracle Pourpre", 7, Rank.SUBORDINATE, 5),
            e("gardien_bestial", "Gardien Bestial", 7, Rank.SUBORDINATE, 6)
    );

    private PdfAssetCatalog() {}

    public static List<Entry> all() { return ENTRIES; }

    public static List<Entry> forIsland(int islandIndex) {
        List<Entry> result = new ArrayList<>(7);
        for (Entry entry : ENTRIES) if (entry.islandIndex == islandIndex) result.add(entry);
        return Collections.unmodifiableList(result);
    }

    public static Entry byId(String id) {
        if (id == null) return null;
        for (Entry entry : ENTRIES) if (entry.id.equals(id)) return entry;
        return null;
    }

    public static Entry bossForIsland(int islandIndex) {
        for (Entry entry : ENTRIES) {
            if (entry.islandIndex == islandIndex && entry.rank == Rank.BOSS) return entry;
        }
        throw new IllegalArgumentException("Aucun boss PDF pour l'île " + islandIndex);
    }

    public static String atlasAssetPath(int islandIndex) {
        int safe = WorldConfig.clampIsland(islandIndex);
        return String.format(java.util.Locale.ROOT,
                "characters25d/pdf_atlas/island_%02d_atlas.webp.b64", safe + 1);
    }
}
