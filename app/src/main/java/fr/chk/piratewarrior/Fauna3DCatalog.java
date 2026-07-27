package fr.chk.piratewarrior;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/** Catalogue des animaux et créatures qui restent en 3D. */
public final class Fauna3DCatalog {
    public enum Category { AMBIENT, HOSTILE, BIRD, RARE, MARINE }

    public static final int EXPECTED_TOTAL = 48;

    public static final class Entry {
        public final String id;
        public final String displayName;
        public final int islandIndex;
        public final Category category;
        public final String behavior;
        public final boolean hostile;
        public final int maxAlive;
        public final String modelAssetPath;

        Entry(
                String id,
                String displayName,
                int islandIndex,
                Category category,
                String behavior,
                boolean hostile,
                int maxAlive,
                String modelAssetPath
        ) {
            this.id = id;
            this.displayName = displayName;
            this.islandIndex = islandIndex;
            this.category = category;
            this.behavior = behavior;
            this.hostile = hostile;
            this.maxAlive = maxAlive;
            this.modelAssetPath = modelAssetPath;
        }
    }

    private static final List<Entry> ENTRIES = List.of(
            new Entry("crabe_dore", "Crabe doré", 0, Category.AMBIENT, "fouille le sable", false, 5, "models/fauna/island_01/crabe_dore.glb"),
            new Entry("sanglier_des_plages", "Sanglier des plages", 0, Category.AMBIENT, "cherche de la nourriture", false, 3, "models/fauna/island_01/sanglier_des_plages.glb"),
            new Entry("varan_solaire", "Varan solaire", 0, Category.HOSTILE, "attaque territoriale", true, 3, "models/fauna/island_01/varan_solaire.glb"),
            new Entry("hyene_corsaire", "Hyène corsaire", 0, Category.HOSTILE, "chasse en meute", true, 4, "models/fauna/island_01/hyene_corsaire.glb"),
            new Entry("mouette_azur", "Mouette azur", 0, Category.BIRD, "vole autour des quais", false, 8, "models/fauna/island_01/mouette_azur.glb"),
            new Entry("perroquet_rouge", "Perroquet rouge", 0, Category.BIRD, "se pose dans les palmiers", false, 5, "models/fauna/island_01/perroquet_rouge.glb"),
            new Entry("tortue_geante", "Tortue géante", 0, Category.RARE, "créature rare pacifique", false, 1, "models/fauna/island_01/tortue_geante.glb"),
            new Entry("requin_recif", "Requin du récif", 0, Category.MARINE, "patrouille près des côtes", true, 2, "models/fauna/island_01/requin_recif.glb"),
            new Entry("lievre_blanc", "Lièvre blanc", 1, Category.AMBIENT, "fuit le joueur", false, 4, "models/fauna/island_02/lievre_blanc.glb"),
            new Entry("renne_polaire", "Renne polaire", 1, Category.AMBIENT, "se déplace en petit groupe", false, 3, "models/fauna/island_02/renne_polaire.glb"),
            new Entry("loup_des_glaces", "Loup des glaces", 1, Category.HOSTILE, "chasse en meute", true, 4, "models/fauna/island_02/loup_des_glaces.glb"),
            new Entry("ours_givre", "Ours de givre", 1, Category.HOSTILE, "défend son territoire", true, 2, "models/fauna/island_02/ours_givre.glb"),
            new Entry("chouette_neige", "Chouette des neiges", 1, Category.BIRD, "attaque en piqué si dérangée", false, 4, "models/fauna/island_02/chouette_neige.glb"),
            new Entry("corbeau_polaire", "Corbeau polaire", 1, Category.BIRD, "survole les combats", false, 6, "models/fauna/island_02/corbeau_polaire.glb"),
            new Entry("mammouth_nain", "Mammouth nain", 1, Category.RARE, "rare et très résistant", false, 1, "models/fauna/island_02/mammouth_nain.glb"),
            new Entry("orque_blanche", "Orque blanche", 1, Category.MARINE, "suit le bateau sans attaquer souvent", true, 1, "models/fauna/island_02/orque_blanche.glb"),
            new Entry("fennec", "Fennec", 2, Category.AMBIENT, "fouille les dunes", false, 4, "models/fauna/island_03/fennec.glb"),
            new Entry("dromadaire_sauvage", "Dromadaire sauvage", 2, Category.AMBIENT, "marche entre les oasis", false, 3, "models/fauna/island_03/dromadaire_sauvage.glb"),
            new Entry("scorpion_geant", "Scorpion géant", 2, Category.HOSTILE, "attaque avec poison", true, 3, "models/fauna/island_03/scorpion_geant.glb"),
            new Entry("chacal_sable", "Chacal des sables", 2, Category.HOSTILE, "harcèle en groupe", true, 4, "models/fauna/island_03/chacal_sable.glb"),
            new Entry("vautour_noir", "Vautour noir", 2, Category.BIRD, "tourne au-dessus des blessés", false, 6, "models/fauna/island_03/vautour_noir.glb"),
            new Entry("faucon_dune", "Faucon des dunes", 2, Category.BIRD, "attaque aérienne rapide", true, 3, "models/fauna/island_03/faucon_dune.glb"),
            new Entry("serpent_cristal", "Serpent de cristal", 2, Category.RARE, "embuscade dans le sable", true, 1, "models/fauna/island_03/serpent_cristal.glb"),
            new Entry("raie_des_sables", "Raie des sables", 2, Category.MARINE, "glisse près des hauts-fonds", false, 2, "models/fauna/island_03/raie_des_sables.glb"),
            new Entry("chevre_noire", "Chèvre noire", 3, Category.AMBIENT, "grimpe sur les rochers", false, 3, "models/fauna/island_04/chevre_noire.glb"),
            new Entry("lezard_cendre", "Lézard de cendre", 3, Category.AMBIENT, "se chauffe près de la lave", false, 4, "models/fauna/island_04/lezard_cendre.glb"),
            new Entry("salamandre_lave", "Salamandre de lave", 3, Category.HOSTILE, "projette des braises", true, 3, "models/fauna/island_04/salamandre_lave.glb"),
            new Entry("molosse_magma", "Molosse de magma", 3, Category.HOSTILE, "charge le joueur", true, 3, "models/fauna/island_04/molosse_magma.glb"),
            new Entry("corbeau_cendre", "Corbeau de cendre", 3, Category.BIRD, "vole dans les fumées", false, 6, "models/fauna/island_04/corbeau_cendre.glb"),
            new Entry("rapace_feu", "Rapace de feu", 3, Category.BIRD, "attaque en piqué brûlant", true, 3, "models/fauna/island_04/rapace_feu.glb"),
            new Entry("phenix_mineur", "Phénix mineur", 3, Category.RARE, "renaît une fois", true, 1, "models/fauna/island_04/phenix_mineur.glb"),
            new Entry("anguille_volcanique", "Anguille volcanique", 3, Category.MARINE, "attaque autour des roches chaudes", true, 2, "models/fauna/island_04/anguille_volcanique.glb"),
            new Entry("capybara_jungle", "Capybara de jungle", 4, Category.AMBIENT, "se repose près de l'eau", false, 4, "models/fauna/island_05/capybara_jungle.glb"),
            new Entry("tapir_brume", "Tapir de brume", 4, Category.AMBIENT, "fuit lentement", false, 3, "models/fauna/island_05/tapir_brume.glb"),
            new Entry("jaguar_vert", "Jaguar vert", 4, Category.HOSTILE, "attaque depuis les buissons", true, 2, "models/fauna/island_05/jaguar_vert.glb"),
            new Entry("crocodile_mousse", "Crocodile mousseux", 4, Category.HOSTILE, "embuscade près des rivières", true, 2, "models/fauna/island_05/crocodile_mousse.glb"),
            new Entry("toucan_or", "Toucan d'or", 4, Category.BIRD, "vole entre les arbres", false, 5, "models/fauna/island_05/toucan_or.glb"),
            new Entry("harpie_brume", "Harpie de brume", 4, Category.BIRD, "attaque aérienne territoriale", true, 3, "models/fauna/island_05/harpie_brume.glb"),
            new Entry("gorille_temple", "Gorille du temple", 4, Category.RARE, "protège une zone sacrée", true, 1, "models/fauna/island_05/gorille_temple.glb"),
            new Entry("anaconda_marin", "Anaconda marin", 4, Category.MARINE, "attaque dans les mangroves", true, 1, "models/fauna/island_05/anaconda_marin.glb"),
            new Entry("chevre_falaise", "Chèvre des falaises", 5, Category.AMBIENT, "se déplace sur les hauteurs", false, 3, "models/fauna/island_06/chevre_falaise.glb"),
            new Entry("loutre_tempete", "Loutre de tempête", 5, Category.AMBIENT, "nage autour des quais", false, 4, "models/fauna/island_06/loutre_tempete.glb"),
            new Entry("panthere_electrique", "Panthère électrique", 5, Category.HOSTILE, "dash électrifié", true, 2, "models/fauna/island_06/panthere_electrique.glb"),
            new Entry("crabe_tonnerre", "Crabe tonnerre", 5, Category.HOSTILE, "attaque avec sa carapace", true, 3, "models/fauna/island_06/crabe_tonnerre.glb"),
            new Entry("albatros_gris", "Albatros gris", 5, Category.BIRD, "plane au-dessus de l'océan", false, 6, "models/fauna/island_06/albatros_gris.glb"),
            new Entry("aigle_orage", "Aigle d'orage", 5, Category.BIRD, "attaque en piqué électrique", true, 3, "models/fauna/island_06/aigle_orage.glb"),
            new Entry("cerf_foudre", "Cerf de foudre", 5, Category.RARE, "créature rare très rapide", false, 1, "models/fauna/island_06/cerf_foudre.glb"),
            new Entry("kraken_juvenile", "Kraken juvénile", 5, Category.MARINE, "attaque le bateau à distance", true, 1, "models/fauna/island_06/kraken_juvenile.glb")
    );

    static {
        validateOrThrow();
    }

    private Fauna3DCatalog() {
    }

    public static List<Entry> all() {
        return ENTRIES;
    }

    public static List<Entry> forIsland(int islandIndex) {
        List<Entry> result = new ArrayList<>();
        for (Entry entry : ENTRIES) {
            if (entry.islandIndex == islandIndex) result.add(entry);
        }
        return Collections.unmodifiableList(result);
    }

    public static List<Entry> forIslandAndCategory(int islandIndex, Category category) {
        List<Entry> result = new ArrayList<>();
        for (Entry entry : ENTRIES) {
            if (entry.islandIndex == islandIndex && entry.category == category) result.add(entry);
        }
        return Collections.unmodifiableList(result);
    }

    private static void validateOrThrow() {
        if (ENTRIES.size() != EXPECTED_TOTAL) {
            throw new IllegalStateException("Le catalogue 3D doit contenir 48 espèces ou variantes.");
        }

        Set<String> ids = new HashSet<>();
        for (Entry entry : ENTRIES) {
            if (!ids.add(entry.id)) throw new IllegalStateException("Animal 3D dupliqué : " + entry.id);
            if (entry.islandIndex < 0 || entry.islandIndex >= 6) {
                throw new IllegalStateException("Île invalide pour " + entry.id);
            }
            if (entry.maxAlive < 1) throw new IllegalStateException("Budget invalide pour " + entry.id);
            if (!entry.modelAssetPath.endsWith(".glb")) {
                throw new IllegalStateException("Modèle GLB invalide pour " + entry.id);
            }
        }

        for (int island = 0; island < 6; island++) {
            if (forIsland(island).size() != 8
                    || forIslandAndCategory(island, Category.AMBIENT).size() != 2
                    || forIslandAndCategory(island, Category.HOSTILE).size() != 2
                    || forIslandAndCategory(island, Category.BIRD).size() != 2
                    || forIslandAndCategory(island, Category.RARE).size() != 1
                    || forIslandAndCategory(island, Category.MARINE).size() != 1) {
                throw new IllegalStateException("Répartition 3D invalide pour l'île " + island);
            }
        }
    }
}
