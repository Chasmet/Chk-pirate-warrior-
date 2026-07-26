package fr.chk.piratewarrior;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Catalogue officiel des 42 personnages ennemis importants en 2.5D.
 *
 * Les noms et l'ordre des îles sont verrouillés à partir des références officielles du projet.
 * Les trois héros Cheikh, Yvane et Nelvyn sont gérés séparément et ne doivent jamais être
 * remplacés par une entrée ennemie.
 */
public final class Enemy25DCatalog {
    public enum Rank { BOSS, COMMANDER, SUBORDINATE }

    public static final int ISLAND_COUNT = 6;
    public static final int EXPECTED_BOSSES = 6;
    public static final int EXPECTED_COMMANDERS = 18;
    public static final int EXPECTED_SUBORDINATES = 18;
    public static final int EXPECTED_TOTAL = 42;

    public static final String[] ISLAND_NAMES = {
            "Port des Naufragés",
            "Jungle Sauvage",
            "Royaume des Neiges",
            "Désert des Corsaires",
            "Île Volcanique",
            "Forteresse de la Tempête"
    };

    private static final Set<String> FORBIDDEN_LEGACY_IDS = Set.of(
            "capitaine_helios", "roi_boreal", "sultan_dune",
            "seigneur_magma", "reine_mousson", "amiral_foudre",
            "zahrek", "qamar", "sirok", "dune", "khepri", "safra", "rakh"
    );

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

        Entry(String id, String displayName, int islandIndex, Rank rank,
              String weapon, String ability, String primaryColor,
              String secondaryColor, String accentColor) {
            this.id = id;
            this.displayName = displayName;
            this.islandIndex = islandIndex;
            this.rank = rank;
            this.weapon = weapon;
            this.ability = ability;
            this.primaryColor = primaryColor;
            this.secondaryColor = secondaryColor;
            this.accentColor = accentColor;
            this.sheetAssetPath = String.format(
                    java.util.Locale.ROOT,
                    "characters25d/island_%02d/%s/sheet.webp",
                    islandIndex + 1,
                    id
            );
        }

        public boolean isBoss() {
            return rank == Rank.BOSS;
        }
    }

    private static Entry entry(String id, String displayName, int islandIndex, Rank rank,
                               String weapon, String ability, String primaryColor,
                               String secondaryColor, String accentColor) {
        return new Entry(id, displayName, islandIndex, rank, weapon, ability,
                primaryColor, secondaryColor, accentColor);
    }

    private static final List<Entry> ENTRIES = List.of(
            // Île 1 — Port des Naufragés.
            entry("brakor", "Brakor, Gardien du Port", 0, Rank.BOSS,
                    "énorme ancre-chaîne", "choc d'ancre, traction par chaîne, contrôle de zone et rage",
                    "#2B211D", "#7B2F26", "#B88952"),
            entry("tireur_quais", "Tireur des Quais", 0, Rank.COMMANDER,
                    "fusil long", "tirs de précision, recul tactique et couverture",
                    "#2B211D", "#7B2F26", "#B88952"),
            entry("maitre_croc", "Maître Croc", 0, Rank.COMMANDER,
                    "sabre courbe et crochet", "duel agressif, attraction et contre-attaque",
                    "#2B211D", "#7B2F26", "#B88952"),
            entry("ingenieur_amarres", "Ingénieur des Amarres", 0, Rank.COMMANDER,
                    "outils, chaînes et masse mécanique", "pièges, immobilisation et dispositifs du quai",
                    "#2B211D", "#7B2F26", "#B88952"),
            entry("voleur_agile", "Voleur Agile", 0, Rank.SUBORDINATE,
                    "double lame", "esquive, attaque dans le dos et vol rapide",
                    "#2B211D", "#7B2F26", "#B88952"),
            entry("porte_chaine", "Porte-Chaîne", 0, Rank.SUBORDINATE,
                    "masse-chaîne", "attaque circulaire, interruption et renversement",
                    "#2B211D", "#7B2F26", "#B88952"),
            entry("guetteur_phare", "Guetteur du Phare", 0, Rank.SUBORDINATE,
                    "pistolet et lame courte", "repérage, marquage de cible et tir à distance",
                    "#2B211D", "#7B2F26", "#B88952"),

            // Île 2 — Jungle Sauvage.
            entry("malkor", "Malkor", 1, Rank.BOSS,
                    "lame lourde végétale", "racines, poison, charge et contrôle de terrain",
                    "#223D2A", "#5D7E3A", "#C2A35A"),
            entry("zaya", "Zaya", 1, Rank.COMMANDER,
                    "deux lames courtes", "mobilité, esquive et attaques rapides",
                    "#223D2A", "#5D7E3A", "#C2A35A"),
            entry("kongo", "Kongo", 1, Rank.COMMANDER,
                    "massue lourde", "charge, brise-garde et projection",
                    "#223D2A", "#5D7E3A", "#C2A35A"),
            entry("silex", "Silex", 1, Rank.COMMANDER,
                    "arc de jungle", "tirs empoisonnés et pièges",
                    "#223D2A", "#5D7E3A", "#C2A35A"),
            entry("ronce", "Ronce", 1, Rank.SUBORDINATE,
                    "fouet épineux", "immobilisation et saignement",
                    "#223D2A", "#5D7E3A", "#C2A35A"),
            entry("tika", "Tika", 1, Rank.SUBORDINATE,
                    "griffes courtes", "bond, harcèlement et repli",
                    "#223D2A", "#5D7E3A", "#C2A35A"),
            entry("mamba", "Mamba", 1, Rank.SUBORDINATE,
                    "lames venimeuses", "poison progressif et attaque furtive",
                    "#223D2A", "#5D7E3A", "#C2A35A"),

            // Île 3 — Royaume des Neiges.
            entry("skarn", "Skarn, Roi des Glaces", 2, Rank.BOSS,
                    "grande épée de glace", "gel, murs de glace, tempête blanche et phase royale",
                    "#DFF4FF", "#6AAED6", "#263B59"),
            entry("eira", "Eira, Dame du Blizzard", 2, Rank.COMMANDER,
                    "lame de blizzard", "rafales gelantes et zones de froid",
                    "#DFF4FF", "#6AAED6", "#263B59"),
            entry("volkr", "Volkr, Bouclier du Froid", 2, Rank.COMMANDER,
                    "bouclier et masse", "garde renforcée, charge et contre",
                    "#DFF4FF", "#6AAED6", "#263B59"),
            entry("nivor", "Nivor, Arbalétrier des Glaces", 2, Rank.COMMANDER,
                    "arbalète de glace", "salves, ralentissement et tir perforant",
                    "#DFF4FF", "#6AAED6", "#263B59"),
            entry("brume", "Brume, l'Ombre Glacée", 2, Rank.SUBORDINATE,
                    "doubles dagues", "furtivité, esquive et frappe arrière",
                    "#DFF4FF", "#6AAED6", "#263B59"),
            entry("harka", "Harka, Berserker des Glaces", 2, Rank.SUBORDINATE,
                    "hache lourde", "rage, enchaînement et brise-garde",
                    "#DFF4FF", "#6AAED6", "#263B59"),
            entry("flint", "Flint, Ingénieur du Froid", 2, Rank.SUBORDINATE,
                    "outils cryogéniques", "mines de glace et tourelle de ralentissement",
                    "#DFF4FF", "#6AAED6", "#263B59"),

            // Île 4 — Désert des Corsaires.
            entry("zarok", "Zarok, Khan des Sables", 3, Rank.BOSS,
                    "double cimeterre lourd", "mirages, tempête de sable, frappe circulaire et rage",
                    "#E6B85C", "#A85D2A", "#3F2B23"),
            entry("sabir", "Sabir le Dromadaire", 3, Rank.COMMANDER,
                    "mousquet du désert", "tir spécial, recul tactique et salves longues",
                    "#E6B85C", "#A85D2A", "#3F2B23"),
            entry("razka", "Razka la Lame de Sable", 3, Rank.COMMANDER,
                    "deux sabres courbes", "dash, combo rapide et lame de sable",
                    "#E6B85C", "#A85D2A", "#3F2B23"),
            entry("al_varis", "Al-Varis l'Artificier", 3, Rank.COMMANDER,
                    "lance-grenade et mines", "pièges, mines et explosions de zone",
                    "#E6B85C", "#A85D2A", "#3F2B23"),
            entry("chaal", "Chaal le Rapace", 3, Rank.SUBORDINATE,
                    "deux lames courtes", "esquive, attaque bondissante et repli",
                    "#E6B85C", "#A85D2A", "#3F2B23"),
            entry("machoire_desert", "Mâchoire du Désert", 3, Rank.SUBORDINATE,
                    "masse lourde", "charge, brise-garde et interruption",
                    "#E6B85C", "#A85D2A", "#3F2B23"),
            entry("veilleuse_dunes", "Veilleuse des Dunes", 3, Rank.SUBORDINATE,
                    "lanterne et bâton", "signal lumineux, aveuglement et soutien à distance",
                    "#E6B85C", "#A85D2A", "#3F2B23"),

            // Île 5 — Île Volcanique.
            entry("vulkar", "Vulkar, Seigneur des Flammes", 4, Rank.BOSS,
                    "grande lame volcanique", "lave, explosion, armure en fusion et phase ardente",
                    "#FF7A3D", "#7A1F22", "#2B2020"),
            entry("cendre", "Cendre, Lame des Braises", 4, Rank.COMMANDER,
                    "lame des braises", "projection de braises et dash brûlant",
                    "#FF7A3D", "#7A1F22", "#2B2020"),
            entry("magma", "Magma, Bouclier de Lave", 4, Rank.COMMANDER,
                    "bouclier de lave", "garde, charge et zone brûlante",
                    "#FF7A3D", "#7A1F22", "#2B2020"),
            entry("pyros", "Pyros, Artificier Infernal", 4, Rank.COMMANDER,
                    "artifices incendiaires", "mines, salves et explosions",
                    "#FF7A3D", "#7A1F22", "#2B2020"),
            entry("basalte", "Basalte, Gardien des Roches", 4, Rank.SUBORDINATE,
                    "épée de roche", "garde lourde et brise-garde",
                    "#FF7A3D", "#7A1F22", "#2B2020"),
            entry("scorie", "Scorie, Faucheuse de Feu", 4, Rank.SUBORDINATE,
                    "faux de feu", "attaque circulaire et brûlure",
                    "#FF7A3D", "#7A1F22", "#2B2020"),
            entry("fumar", "Fumar, Alchimiste des Fumées", 4, Rank.SUBORDINATE,
                    "bombes de fumée", "aveuglement, poison et repli",
                    "#FF7A3D", "#7A1F22", "#2B2020"),

            // Île 6 — Forteresse de la Tempête.
            entry("tempyr", "Tempyr, Amiral de la Tempête", 5, Rank.BOSS,
                    "lame de la tempête", "éclairs, vagues, téléportation courte et phase orage",
                    "#87C8FF", "#42507A", "#E9F1FF"),
            entry("orage", "Orage, Lame du Tonnerre", 5, Rank.COMMANDER,
                    "lame du tonnerre", "dash électrique et étourdissement",
                    "#87C8FF", "#42507A", "#E9F1FF"),
            entry("volt", "Volt, Ingénieur du Tonnerre", 5, Rank.COMMANDER,
                    "outils électriques", "pièges, arc électrique et surcharge",
                    "#87C8FF", "#42507A", "#E9F1FF"),
            entry("cyclone", "Cyclone, Lance des Vents", 5, Rank.COMMANDER,
                    "lance des vents", "bourrasque, projection et attaque tournoyante",
                    "#87C8FF", "#42507A", "#E9F1FF"),
            entry("brisk", "Brisk, Coureur des Courants", 5, Rank.SUBORDINATE,
                    "lames légères", "course rapide et attaques en chaîne",
                    "#87C8FF", "#42507A", "#E9F1FF"),
            entry("tonnerre", "Tonnerre, Marteau du Ciel", 5, Rank.SUBORDINATE,
                    "marteau du ciel", "frappe verticale et onde électrique",
                    "#87C8FF", "#42507A", "#E9F1FF"),
            entry("fulgur", "Fulgur, Archer des Éclairs", 5, Rank.SUBORDINATE,
                    "arc des éclairs", "salves électriques et zone de foudre",
                    "#87C8FF", "#42507A", "#E9F1FF")
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
            if (entry.islandIndex == islandIndex && entry.rank == Rank.BOSS) return entry;
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
            if (entry.islandIndex == islandIndex && entry.rank == rank) result.add(entry);
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
            if (!ids.add(entry.id)) throw new IllegalStateException("Identifiant 2.5D dupliqué : " + entry.id);
            if (FORBIDDEN_LEGACY_IDS.contains(entry.id)) {
                throw new IllegalStateException("Identifiant provisoire interdit : " + entry.id);
            }
            if (entry.islandIndex < 0 || entry.islandIndex >= ISLAND_COUNT) {
                throw new IllegalStateException("Île invalide pour " + entry.id);
            }
            if (!entry.sheetAssetPath.endsWith("/sheet.webp")) {
                throw new IllegalStateException("Chemin de planche invalide pour " + entry.id);
            }
            switch (entry.rank) {
                case BOSS -> bosses++;
                case COMMANDER -> commanders++;
                case SUBORDINATE -> subordinates++;
            }
        }

        if (bosses != EXPECTED_BOSSES || commanders != EXPECTED_COMMANDERS
                || subordinates != EXPECTED_SUBORDINATES) {
            throw new IllegalStateException("Répartition invalide : boss=" + bosses
                    + ", commandants=" + commanders + ", subordonnés=" + subordinates);
        }

        for (int island = 0; island < ISLAND_COUNT; island++) {
            if (commandersForIsland(island).size() != 3 || subordinatesForIsland(island).size() != 3) {
                throw new IllegalStateException("L'île " + island
                        + " doit avoir 1 boss, 3 commandants et 3 subordonnés.");
            }
            bossForIsland(island);
        }
    }
}
