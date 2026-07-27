package fr.chk.piratewarrior;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/** Catalogue officiel des personnages ennemis importants en 2.5D, chargés île par île. */
public final class Enemy25DCatalog {
    public enum Rank { BOSS, COMMANDER, SUBORDINATE }

    public static final int ISLAND_COUNT = WorldConfig.ISLAND_COUNT;
    public static final int EXPECTED_BOSSES = ISLAND_COUNT;
    public static final int EXPECTED_COMMANDERS = ISLAND_COUNT * 3;
    public static final int EXPECTED_SUBORDINATES = ISLAND_COUNT * 3;
    public static final int EXPECTED_TOTAL = ISLAND_COUNT * 7;
    public static final String[] ISLAND_NAMES = WorldConfig.ISLAND_NAMES.clone();

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

        Entry(String id, String displayName, int islandIndex, Rank rank, String weapon,
              String ability, String primaryColor, String secondaryColor, String accentColor) {
            this.id = id;
            this.displayName = displayName;
            this.islandIndex = islandIndex;
            this.rank = rank;
            this.weapon = weapon;
            this.ability = ability;
            this.primaryColor = primaryColor;
            this.secondaryColor = secondaryColor;
            this.accentColor = accentColor;
            this.sheetAssetPath = String.format(java.util.Locale.ROOT,
                    "characters25d/island_%02d/%s/sheet.webp", islandIndex + 1, id);
        }

        public boolean isBoss() { return rank == Rank.BOSS; }
    }

    private static Entry e(String id, String name, int island, Rank rank,
                           String weapon, String ability, String p, String s, String a) {
        return new Entry(id, name, island, rank, weapon, ability, p, s, a);
    }

    private static final List<Entry> ENTRIES = List.of(
            e("brakor", "Brakor, Gardien du Port", 0, Rank.BOSS,
                    "énorme ancre-chaîne", "choc d'ancre, traction par chaîne, contrôle de zone et rage",
                    "#2B211D", "#7B2F26", "#B88952"),
            e("tireur_quais", "Tireur des Quais", 0, Rank.COMMANDER,
                    "fusil long", "tirs de précision, recul tactique et couverture",
                    "#2B211D", "#7B2F26", "#B88952"),
            e("maitre_croc", "Maître Croc", 0, Rank.COMMANDER,
                    "sabre courbe et crochet", "duel agressif, attraction et contre-attaque",
                    "#2B211D", "#7B2F26", "#B88952"),
            e("ingenieur_amarres", "Ingénieur des Amarres", 0, Rank.COMMANDER,
                    "outils, chaînes et masse mécanique", "pièges, immobilisation et dispositifs du quai",
                    "#2B211D", "#7B2F26", "#B88952"),
            e("voleur_agile", "Voleur Agile", 0, Rank.SUBORDINATE,
                    "double lame", "esquive, attaque dans le dos et vol rapide",
                    "#2B211D", "#7B2F26", "#B88952"),
            e("porte_chaine", "Porte-Chaîne", 0, Rank.SUBORDINATE,
                    "masse-chaîne", "attaque circulaire, interruption et renversement",
                    "#2B211D", "#7B2F26", "#B88952"),
            e("guetteur_phare", "Guetteur du Phare", 0, Rank.SUBORDINATE,
                    "pistolet et lame courte", "repérage, marquage de cible et tir à distance",
                    "#2B211D", "#7B2F26", "#B88952"),

            e("malkor", "Malkor", 1, Rank.BOSS,
                    "lame lourde végétale", "racines, poison, charge et contrôle de terrain",
                    "#223D2A", "#5D7E3A", "#C2A35A"),
            e("zaya", "Zaya", 1, Rank.COMMANDER,
                    "deux lames courtes", "mobilité, esquive et attaques rapides",
                    "#223D2A", "#5D7E3A", "#C2A35A"),
            e("kongo", "Kongo", 1, Rank.COMMANDER,
                    "massue lourde", "charge, brise-garde et projection",
                    "#223D2A", "#5D7E3A", "#C2A35A"),
            e("silex", "Silex", 1, Rank.COMMANDER,
                    "arc de jungle", "tirs empoisonnés et pièges",
                    "#223D2A", "#5D7E3A", "#C2A35A"),
            e("ronce", "Ronce", 1, Rank.SUBORDINATE,
                    "fouet épineux", "immobilisation et saignement",
                    "#223D2A", "#5D7E3A", "#C2A35A"),
            e("tika", "Tika", 1, Rank.SUBORDINATE,
                    "griffes courtes", "bond, harcèlement et repli",
                    "#223D2A", "#5D7E3A", "#C2A35A"),
            e("mamba", "Mamba", 1, Rank.SUBORDINATE,
                    "lames venimeuses", "poison progressif et attaque furtive",
                    "#223D2A", "#5D7E3A", "#C2A35A"),

            e("skarn", "Skarn, Roi des Glaces", 2, Rank.BOSS,
                    "grande épée de glace", "gel, murs de glace, tempête blanche et phase royale",
                    "#DFF4FF", "#6AAED6", "#263B59"),
            e("eira", "Eira, Dame du Blizzard", 2, Rank.COMMANDER,
                    "lame de blizzard", "rafales gelantes et zones de froid",
                    "#DFF4FF", "#6AAED6", "#263B59"),
            e("volkr", "Volkr, Bouclier du Froid", 2, Rank.COMMANDER,
                    "bouclier et masse", "garde renforcée, charge et contre",
                    "#DFF4FF", "#6AAED6", "#263B59"),
            e("nivor", "Nivor, Arbalétrier des Glaces", 2, Rank.COMMANDER,
                    "arbalète de glace", "salves, ralentissement et tir perforant",
                    "#DFF4FF", "#6AAED6", "#263B59"),
            e("brume", "Brume, l'Ombre Glacée", 2, Rank.SUBORDINATE,
                    "doubles dagues", "furtivité, esquive et frappe arrière",
                    "#DFF4FF", "#6AAED6", "#263B59"),
            e("harka", "Harka, Berserker des Glaces", 2, Rank.SUBORDINATE,
                    "hache lourde", "rage, enchaînement et brise-garde",
                    "#DFF4FF", "#6AAED6", "#263B59"),
            e("flint", "Flint, Ingénieur du Froid", 2, Rank.SUBORDINATE,
                    "outils cryogéniques", "mines de glace et tourelle de ralentissement",
                    "#DFF4FF", "#6AAED6", "#263B59"),

            e("zarok", "Zarok, Khan des Sables", 3, Rank.BOSS,
                    "double cimeterre lourd", "mirages, tempête de sable, frappe circulaire et rage",
                    "#E6B85C", "#A85D2A", "#3F2B23"),
            e("sabir", "Sabir le Dromadaire", 3, Rank.COMMANDER,
                    "mousquet du désert", "tir spécial, recul tactique et salves longues",
                    "#E6B85C", "#A85D2A", "#3F2B23"),
            e("razka", "Razka la Lame de Sable", 3, Rank.COMMANDER,
                    "deux sabres courbes", "dash, combo rapide et lame de sable",
                    "#E6B85C", "#A85D2A", "#3F2B23"),
            e("al_varis", "Al-Varis l'Artificier", 3, Rank.COMMANDER,
                    "lance-grenade et mines", "pièges, mines et explosions de zone",
                    "#E6B85C", "#A85D2A", "#3F2B23"),
            e("chaal", "Chaal le Rapace", 3, Rank.SUBORDINATE,
                    "deux lames courtes", "esquive, attaque bondissante et repli",
                    "#E6B85C", "#A85D2A", "#3F2B23"),
            e("machoire_desert", "Mâchoire du Désert", 3, Rank.SUBORDINATE,
                    "masse lourde", "charge, brise-garde et interruption",
                    "#E6B85C", "#A85D2A", "#3F2B23"),
            e("veilleuse_dunes", "Veilleuse des Dunes", 3, Rank.SUBORDINATE,
                    "lanterne et bâton", "signal lumineux, aveuglement et soutien à distance",
                    "#E6B85C", "#A85D2A", "#3F2B23"),

            e("vulkar", "Vulkar, Seigneur des Flammes", 4, Rank.BOSS,
                    "grande lame volcanique", "lave, explosion, armure en fusion et phase ardente",
                    "#FF7A3D", "#7A1F22", "#2B2020"),
            e("cendre", "Cendre, Lame des Braises", 4, Rank.COMMANDER,
                    "lame des braises", "projection de braises et dash brûlant",
                    "#FF7A3D", "#7A1F22", "#2B2020"),
            e("magma", "Magma, Bouclier de Lave", 4, Rank.COMMANDER,
                    "bouclier de lave", "garde, charge et zone brûlante",
                    "#FF7A3D", "#7A1F22", "#2B2020"),
            e("pyros", "Pyros, Artificier Infernal", 4, Rank.COMMANDER,
                    "artifices incendiaires", "mines, salves et explosions",
                    "#FF7A3D", "#7A1F22", "#2B2020"),
            e("basalte", "Basalte, Gardien des Roches", 4, Rank.SUBORDINATE,
                    "épée de roche", "garde lourde et brise-garde",
                    "#FF7A3D", "#7A1F22", "#2B2020"),
            e("scorie", "Scorie, Faucheuse de Feu", 4, Rank.SUBORDINATE,
                    "faux de feu", "attaque circulaire et brûlure",
                    "#FF7A3D", "#7A1F22", "#2B2020"),
            e("fumar", "Fumar, Alchimiste des Fumées", 4, Rank.SUBORDINATE,
                    "bombes de fumée", "aveuglement, poison et repli",
                    "#FF7A3D", "#7A1F22", "#2B2020"),

            e("tempyr", "Tempyr, Amiral de la Tempête", 5, Rank.BOSS,
                    "lame de la tempête", "éclairs, vagues, téléportation courte et phase orage",
                    "#87C8FF", "#42507A", "#E9F1FF"),
            e("orage", "Orage, Lame du Tonnerre", 5, Rank.COMMANDER,
                    "lame du tonnerre", "dash électrique et étourdissement",
                    "#87C8FF", "#42507A", "#E9F1FF"),
            e("volt", "Volt, Ingénieur du Tonnerre", 5, Rank.COMMANDER,
                    "outils électriques", "pièges, arc électrique et surcharge",
                    "#87C8FF", "#42507A", "#E9F1FF"),
            e("cyclone", "Cyclone, Lance des Vents", 5, Rank.COMMANDER,
                    "lance des vents", "bourrasque, projection et attaque tournoyante",
                    "#87C8FF", "#42507A", "#E9F1FF"),
            e("brisk", "Brisk, Coureur des Courants", 5, Rank.SUBORDINATE,
                    "lames légères", "course rapide et attaques en chaîne",
                    "#87C8FF", "#42507A", "#E9F1FF"),
            e("tonnerre", "Tonnerre, Marteau du Ciel", 5, Rank.SUBORDINATE,
                    "marteau du ciel", "frappe verticale et onde électrique",
                    "#87C8FF", "#42507A", "#E9F1FF"),
            e("fulgur", "Fulgur, Archer des Éclairs", 5, Rank.SUBORDINATE,
                    "arc des éclairs", "salves électriques et zone de foudre",
                    "#87C8FF", "#42507A", "#E9F1FF"),

            e("matriarche_sucree", "Matriarche Sucrée", 6, Rank.BOSS,
                    "sceptre pâtissier et nuages sucrés", "vague de crème, invocation gourmande, contrôle de zone et banquet ultime",
                    "#F7A7C6", "#FFD36E", "#7B3F2A"),
            e("prince_mochi", "Prince Mochi", 6, Rank.COMMANDER,
                    "poings extensibles", "enchaînements rapides, projection et immobilisation élastique",
                    "#F7A7C6", "#FFD36E", "#7B3F2A"),
            e("duc_biscuit", "Duc Biscuit", 6, Rank.COMMANDER,
                    "épée de sucre cristallisé", "garde lourde, contre tranchant et mur de biscuit",
                    "#F7A7C6", "#FFD36E", "#7B3F2A"),
            e("chevalier_caramel", "Chevalier Caramel", 6, Rank.COMMANDER,
                    "grande lame caramélisée", "charge brûlante, garde et zone collante",
                    "#F7A7C6", "#FFD36E", "#7B3F2A"),
            e("maitre_bonbon", "Maître Bonbon", 6, Rank.SUBORDINATE,
                    "canne et projectiles sucrés", "tirs courbes, pièges et ralentissement",
                    "#F7A7C6", "#FFD36E", "#7B3F2A"),
            e("gardienne_meringue", "Gardienne Meringue", 6, Rank.SUBORDINATE,
                    "lame légère et rubans de crème", "esquive aérienne, rafale et soutien",
                    "#F7A7C6", "#FFD36E", "#7B3F2A"),
            e("tireur_praline", "Tireur Praliné", 6, Rank.SUBORDINATE,
                    "mousquet praliné", "salves, recul tactique et éclats de noisette",
                    "#F7A7C6", "#FFD36E", "#7B3F2A"),

            e("kaor_crane", "Kaor, Seigneur du Crâne", 7, Rank.BOSS,
                    "kanabo colossal et chaînes volcaniques", "onde pourpre, souffle draconique, rage du magma et ultime du crâne",
                    "#2B2435", "#6A3A79", "#FF7A2F"),
            e("archonte_aile_noire", "Archonte de l'Aile Noire", 7, Rank.COMMANDER,
                    "lance noire et armure ailée", "piqué blindé, rafale d'acier et contre aérien",
                    "#181B26", "#4A5264", "#F5B24A"),
            e("ravageur_cornu", "Ravageur Cornu", 7, Rank.COMMANDER,
                    "massue incendiaire", "charge bestiale, choc de cornes et traînée de feu",
                    "#2B2435", "#6A3A79", "#FF7A2F"),
            e("canon_cendres", "Canon des Cendres", 7, Rank.COMMANDER,
                    "canon lourd et poings renforcés", "salves explosives, recul brutal et barrage de magma",
                    "#2B2435", "#6A3A79", "#FF7A2F"),
            e("roi_des_braises", "Roi des Braises", 7, Rank.SUBORDINATE,
                    "sabre court et cape royale", "cris de guerre, flammes au sol et soutien agressif",
                    "#D9A42F", "#7A2D4C", "#FF7A2F"),
            e("oracle_pourpre", "Oracle Pourpre", 7, Rank.SUBORDINATE,
                    "bâton rituel", "malédiction, ralentissement et brouillard violet",
                    "#3A274F", "#6A3A79", "#C99AF4"),
            e("gardien_bestial", "Gardien Bestial", 7, Rank.SUBORDINATE,
                    "griffes et chaîne", "bond, saisie et protection du boss",
                    "#4C392C", "#7B5534", "#FF7A2F")
    );

    static { validateOrThrow(); }

    private Enemy25DCatalog() {}

    public static List<Entry> all() { return ENTRIES; }

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
        for (Entry entry : ENTRIES) if (entry.id.equals(id)) return entry;
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
            throw new IllegalStateException("Le catalogue doit contenir exactement " + EXPECTED_TOTAL + " personnages 2.5D.");
        }
        Set<String> ids = new HashSet<>();
        int bosses = 0;
        int commanders = 0;
        int subordinates = 0;
        for (Entry entry : ENTRIES) {
            if (!ids.add(entry.id)) throw new IllegalStateException("Identifiant 2.5D dupliqué : " + entry.id);
            if (FORBIDDEN_LEGACY_IDS.contains(entry.id)) throw new IllegalStateException("Identifiant provisoire interdit : " + entry.id);
            if (entry.islandIndex < 0 || entry.islandIndex >= ISLAND_COUNT) throw new IllegalStateException("Île invalide pour " + entry.id);
            if (!entry.sheetAssetPath.endsWith("/sheet.webp")) throw new IllegalStateException("Chemin de planche invalide pour " + entry.id);
            switch (entry.rank) {
                case BOSS -> bosses++;
                case COMMANDER -> commanders++;
                case SUBORDINATE -> subordinates++;
            }
        }
        if (bosses != EXPECTED_BOSSES || commanders != EXPECTED_COMMANDERS || subordinates != EXPECTED_SUBORDINATES) {
            throw new IllegalStateException("Répartition invalide : boss=" + bosses + ", commandants=" + commanders + ", subordonnés=" + subordinates);
        }
        for (int island = 0; island < ISLAND_COUNT; island++) {
            if (commandersForIsland(island).size() != 3 || subordinatesForIsland(island).size() != 3) {
                throw new IllegalStateException("L'île " + island + " doit avoir 1 boss, 3 commandants et 3 subordonnés.");
            }
            bossForIsland(island);
        }
    }
}
