package fr.chk.piratewarrior;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Catalogue officiel des personnages ennemis importants en 2.5D.
 *
 * Les trois héros historiques (Cheikh, Yvane et Nelvyn) ne sont pas déclarés ici :
 * ils restent gérés par Character25D et ne doivent jamais être remplacés par ce catalogue.
 */
public final class Enemy25DCatalog {
    public enum Rank { BOSS, COMMANDER, SUBORDINATE }

    public static final int ISLAND_COUNT = 6;
    public static final int EXPECTED_BOSSES = 6;
    public static final int EXPECTED_COMMANDERS = 18;
    public static final int EXPECTED_SUBORDINATES = 18;
    public static final int EXPECTED_TOTAL = 42;

    public static final class Entry {
        public final String id;
        public final String displayName;
        public final int islandIndex;
        public final Rank rank;
        public final String weapon;
        public final String ability;
        public final String primaryColor;
        public final String secondaryColor;
        public final String accentColor;
        public final String sheetAssetPath;

        Entry(
                String id,
                String displayName,
                int islandIndex,
                Rank rank,
                String weapon,
                String ability,
                String primaryColor,
                String secondaryColor,
                String accentColor,
                String sheetAssetPath
        ) {
            this.id = id;
            this.displayName = displayName;
            this.islandIndex = islandIndex;
            this.rank = rank;
            this.weapon = weapon;
            this.ability = ability;
            this.primaryColor = primaryColor;
            this.secondaryColor = secondaryColor;
            this.accentColor = accentColor;
            this.sheetAssetPath = sheetAssetPath;
        }

        public boolean isBoss() {
            return rank == Rank.BOSS;
        }
    }

    private static final List<Entry> ENTRIES = List.of(
            new Entry("capitaine_helios", "Capitaine Hélios", 0, Rank.BOSS, "sabre solaire", "attaque de zone, charge lumineuse, seconde phase ardente", "#F5C451", "#D94A3A", "#2A526B", "characters25d/island_01/capitaine_helios/sheet.webp"),
            new Entry("sirocco", "Sirocco", 0, Rank.COMMANDER, "double sabre", "enchaînements rapides et dash", "#F5C451", "#D94A3A", "#2A526B", "characters25d/island_01/sirocco/sheet.webp"),
            new Entry("braise", "Braise", 0, Rank.SUBORDINATE, "dague courbe", "harcèlement et fumée aveuglante", "#F5C451", "#D94A3A", "#2A526B", "characters25d/island_01/braise/sheet.webp"),
            new Entry("marea", "Maréa", 0, Rank.COMMANDER, "deux pistolets", "tir mobile et ricochets", "#F5C451", "#D94A3A", "#2A526B", "characters25d/island_01/marea/sheet.webp"),
            new Entry("cliquet", "Cliquet", 0, Rank.SUBORDINATE, "carabine courte", "tirs de couverture", "#F5C451", "#D94A3A", "#2A526B", "characters25d/island_01/cliquet/sheet.webp"),
            new Entry("baron_tambour", "Baron Tambour", 0, Rank.COMMANDER, "marteau naval", "ondes de choc", "#F5C451", "#D94A3A", "#2A526B", "characters25d/island_01/baron_tambour/sheet.webp"),
            new Entry("pave", "Pavé", 0, Rank.SUBORDINATE, "bouclier lourd", "blocage et poussée", "#F5C451", "#D94A3A", "#2A526B", "characters25d/island_01/pave/sheet.webp"),
            new Entry("roi_boreal", "Roi Boréal", 1, Rank.BOSS, "grande épée de glace", "gel, murs de glace, tempête blanche", "#DFF4FF", "#6AAED6", "#263B59", "characters25d/island_02/roi_boreal/sheet.webp"),
            new Entry("hastel", "Hastel", 1, Rank.COMMANDER, "lance givrée", "charges perforantes", "#DFF4FF", "#6AAED6", "#263B59", "characters25d/island_02/hastel/sheet.webp"),
            new Entry("givre", "Givre", 1, Rank.SUBORDINATE, "javelots", "ralentissement à distance", "#DFF4FF", "#6AAED6", "#263B59", "characters25d/island_02/givre/sheet.webp"),
            new Entry("sylka", "Sylka", 1, Rank.COMMANDER, "arc polaire", "tirs gelants et pièges", "#DFF4FF", "#6AAED6", "#263B59", "characters25d/island_02/sylka/sheet.webp"),
            new Entry("flocon", "Flocon", 1, Rank.SUBORDINATE, "arbalète", "salves rapides", "#DFF4FF", "#6AAED6", "#263B59", "characters25d/island_02/flocon/sheet.webp"),
            new Entry("brakka", "Brakka", 1, Rank.COMMANDER, "gantelets blindés", "coups lourds et garde", "#DFF4FF", "#6AAED6", "#263B59", "characters25d/island_02/brakka/sheet.webp"),
            new Entry("stal", "Stal", 1, Rank.SUBORDINATE, "masse courte", "brise-garde", "#DFF4FF", "#6AAED6", "#263B59", "characters25d/island_02/stal/sheet.webp"),
            new Entry("sultan_dune", "Sultan des Dunes", 2, Rank.BOSS, "cimeterre royal", "mirages, tempête de sable, attaque souterraine", "#E6B85C", "#A85D2A", "#3F2B23", "characters25d/island_03/sultan_dune/sheet.webp"),
            new Entry("zahir", "Zahir", 2, Rank.COMMANDER, "lames courbes", "téléportations courtes", "#E6B85C", "#A85D2A", "#3F2B23", "characters25d/island_03/zahir/sheet.webp"),
            new Entry("kef", "Kef", 2, Rank.SUBORDINATE, "poignards", "attaques dans le dos", "#E6B85C", "#A85D2A", "#3F2B23", "characters25d/island_03/kef/sheet.webp"),
            new Entry("noura", "Noura", 2, Rank.COMMANDER, "fusil long", "tir embusqué", "#E6B85C", "#A85D2A", "#3F2B23", "characters25d/island_03/noura/sheet.webp"),
            new Entry("mira", "Mira", 2, Rank.SUBORDINATE, "pistolet de précision", "marquage de cible", "#E6B85C", "#A85D2A", "#3F2B23", "characters25d/island_03/mira/sheet.webp"),
            new Entry("grom", "Grom", 2, Rank.COMMANDER, "masse désertique", "frappes au sol", "#E6B85C", "#A85D2A", "#3F2B23", "characters25d/island_03/grom/sheet.webp"),
            new Entry("roc", "Roc", 2, Rank.SUBORDINATE, "massue", "charge frontale", "#E6B85C", "#A85D2A", "#3F2B23", "characters25d/island_03/roc/sheet.webp"),
            new Entry("seigneur_magma", "Seigneur Magma", 3, Rank.BOSS, "hallebarde volcanique", "lave, explosion, armure en fusion", "#FF7A3D", "#7A1F22", "#2B2020", "characters25d/island_04/seigneur_magma/sheet.webp"),
            new Entry("ignara", "Ignara", 3, Rank.COMMANDER, "fouets de lave", "zones brûlantes", "#FF7A3D", "#7A1F22", "#2B2020", "characters25d/island_04/ignara/sheet.webp"),
            new Entry("cendre", "Cendre", 3, Rank.SUBORDINATE, "lame courte", "projection de braises", "#FF7A3D", "#7A1F22", "#2B2020", "characters25d/island_04/cendre/sheet.webp"),
            new Entry("bombax", "Bombax", 3, Rank.COMMANDER, "bombes artisanales", "mines et explosions", "#FF7A3D", "#7A1F22", "#2B2020", "characters25d/island_04/bombax/sheet.webp"),
            new Entry("meche", "Mèche", 3, Rank.SUBORDINATE, "grenades", "harcèlement explosif", "#FF7A3D", "#7A1F22", "#2B2020", "characters25d/island_04/meche/sheet.webp"),
            new Entry("chainor", "Chainor", 3, Rank.COMMANDER, "chaînes brûlantes", "capture et attraction", "#FF7A3D", "#7A1F22", "#2B2020", "characters25d/island_04/chainor/sheet.webp"),
            new Entry("crochet", "Crochet", 3, Rank.SUBORDINATE, "chaîne courte", "interruption", "#FF7A3D", "#7A1F22", "#2B2020", "characters25d/island_04/crochet/sheet.webp"),
            new Entry("reine_mousson", "Reine Mousson", 4, Rank.BOSS, "lame végétale", "brume, racines, poison", "#7CCB78", "#315E3F", "#D0E4BC", "characters25d/island_05/reine_mousson/sheet.webp"),
            new Entry("liane", "Liane", 4, Rank.COMMANDER, "fouet végétal", "immobilisation", "#7CCB78", "#315E3F", "#D0E4BC", "characters25d/island_05/liane/sheet.webp"),
            new Entry("ronce", "Ronce", 4, Rank.SUBORDINATE, "griffes", "saignement", "#7CCB78", "#315E3F", "#D0E4BC", "characters25d/island_05/ronce/sheet.webp"),
            new Entry("totem", "Totem", 4, Rank.COMMANDER, "bâton rituel", "invocations et soins", "#7CCB78", "#315E3F", "#D0E4BC", "characters25d/island_05/totem/sheet.webp"),
            new Entry("masque", "Masque", 4, Rank.SUBORDINATE, "sarbacane", "poison à distance", "#7CCB78", "#315E3F", "#D0E4BC", "characters25d/island_05/masque/sheet.webp"),
            new Entry("koba", "Koba", 4, Rank.COMMANDER, "hache double", "rage et saut", "#7CCB78", "#315E3F", "#D0E4BC", "characters25d/island_05/koba/sheet.webp"),
            new Entry("singe_rouge", "Singe Rouge", 4, Rank.SUBORDINATE, "bâton court", "attaques bondissantes", "#7CCB78", "#315E3F", "#D0E4BC", "characters25d/island_05/singe_rouge/sheet.webp"),
            new Entry("amiral_foudre", "Amiral Foudre", 5, Rank.BOSS, "trident électrique", "éclairs, vagues, phase orage", "#87C8FF", "#42507A", "#E9F1FF", "characters25d/island_06/amiral_foudre/sheet.webp"),
            new Entry("volt", "Volt", 5, Rank.COMMANDER, "épée électrique", "dash et étourdissement", "#87C8FF", "#42507A", "#E9F1FF", "characters25d/island_06/volt/sheet.webp"),
            new Entry("etincelle", "Étincelle", 5, Rank.SUBORDINATE, "deux dagues", "enchaînements rapides", "#87C8FF", "#42507A", "#E9F1FF", "characters25d/island_06/etincelle/sheet.webp"),
            new Entry("zephira", "Zéphira", 5, Rank.COMMANDER, "éventails de vent", "bourrasques et esquive", "#87C8FF", "#42507A", "#E9F1FF", "characters25d/island_06/zephira/sheet.webp"),
            new Entry("rafale", "Rafale", 5, Rank.SUBORDINATE, "lames légères", "tourbillons", "#87C8FF", "#42507A", "#E9F1FF", "characters25d/island_06/rafale/sheet.webp"),
            new Entry("tonnerre", "Tonnerre", 5, Rank.COMMANDER, "canon portatif", "tir de zone", "#87C8FF", "#42507A", "#E9F1FF", "characters25d/island_06/tonnerre/sheet.webp"),
            new Entry("mousse_noir", "Mousse Noir", 5, Rank.SUBORDINATE, "mousquet", "tirs suppressifs", "#87C8FF", "#42507A", "#E9F1FF", "characters25d/island_06/mousse_noir/sheet.webp")
    );

    static {
        validateOrThrow();
    }

    private Enemy25DCatalog() {
    }

    public static List<Entry> all() {
        return ENTRIES;
    }

    public static Entry bossForIsland(int islandIndex) {
        for (Entry entry : ENTRIES) {
            if (entry.islandIndex == islandIndex && entry.rank == Rank.BOSS) {
                return entry;
            }
        }
        throw new IllegalArgumentException("Aucun boss 2.5D pour l'île " + islandIndex);
    }

    public static List<Entry> commandersForIsland(int islandIndex) {
        return filterByIslandAndRank(islandIndex, Rank.COMMANDER);
    }

    public static List<Entry> subordinatesForIsland(int islandIndex) {
        return filterByIslandAndRank(islandIndex, Rank.SUBORDINATE);
    }

    public static Entry byId(String id) {
        if (id == null) return null;
        for (Entry entry : ENTRIES) {
            if (entry.id.equals(id)) return entry;
        }
        return null;
    }

    private static List<Entry> filterByIslandAndRank(int islandIndex, Rank rank) {
        List<Entry> result = new ArrayList<>();
        for (Entry entry : ENTRIES) {
            if (entry.islandIndex == islandIndex && entry.rank == rank) {
                result.add(entry);
            }
        }
        return Collections.unmodifiableList(result);
    }

    private static void validateOrThrow() {
        if (ENTRIES.size() != EXPECTED_TOTAL) {
            throw new IllegalStateException("Le catalogue doit contenir exactement 42 personnages 2.5D.");
        }

        Set<String> ids = new HashSet<>();
        int bosses = 0;
        int commanders = 0;
        int subordinates = 0;

        for (Entry entry : ENTRIES) {
            if (!ids.add(entry.id)) {
                throw new IllegalStateException("Identifiant 2.5D dupliqué : " + entry.id);
            }
            if (entry.islandIndex < 0 || entry.islandIndex >= ISLAND_COUNT) {
                throw new IllegalStateException("Île invalide pour " + entry.id);
            }
            if (entry.sheetAssetPath == null || !entry.sheetAssetPath.endsWith("/sheet.webp")) {
                throw new IllegalStateException("Chemin de planche invalide pour " + entry.id);
            }
            switch (entry.rank) {
                case BOSS -> bosses++;
                case COMMANDER -> commanders++;
                case SUBORDINATE -> subordinates++;
            }
        }

        if (bosses != EXPECTED_BOSSES
                || commanders != EXPECTED_COMMANDERS
                || subordinates != EXPECTED_SUBORDINATES) {
            throw new IllegalStateException(
                    "Répartition invalide : boss=" + bosses
                            + ", commandants=" + commanders
                            + ", subordonnés=" + subordinates
            );
        }

        for (int island = 0; island < ISLAND_COUNT; island++) {
            if (commandersForIsland(island).size() != 3
                    || subordinatesForIsland(island).size() != 3) {
                throw new IllegalStateException("L'île " + island + " doit avoir 1 boss, 3 commandants et 3 subordonnés.");
            }
            bossForIsland(island);
        }
    }
}
