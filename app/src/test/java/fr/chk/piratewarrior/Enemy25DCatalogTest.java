package fr.chk.piratewarrior;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

import java.util.HashSet;
import java.util.Set;

public final class Enemy25DCatalogTest {
    @Test public void catalogueContainsExpectedDistribution() {
        assertEquals(56, Enemy25DCatalog.all().size());
        int bosses = 0, commanders = 0, subordinates = 0;
        Set<String> ids = new HashSet<>();
        for (Enemy25DCatalog.Entry entry : Enemy25DCatalog.all()) {
            assertTrue("Identifiant dupliqué : " + entry.id, ids.add(entry.id));
            assertTrue(entry.islandIndex >= 0 && entry.islandIndex < WorldConfig.ISLAND_COUNT);
            assertTrue(entry.sheetAssetPath.endsWith("/sheet.webp"));
            switch (entry.rank) {
                case BOSS -> bosses++;
                case COMMANDER -> commanders++;
                case SUBORDINATE -> subordinates++;
            }
        }
        assertEquals(8, bosses);
        assertEquals(24, commanders);
        assertEquals(24, subordinates);
    }

    @Test public void everyIslandHasOneBossAndThreePairs() {
        for (int island = 0; island < Enemy25DCatalog.ISLAND_COUNT; island++) {
            assertNotNull(Enemy25DCatalog.bossForIsland(island));
            assertEquals(3, Enemy25DCatalog.commandersForIsland(island).size());
            assertEquals(3, Enemy25DCatalog.subordinatesForIsland(island).size());
        }
    }

    @Test public void protectedHeroesAreNotEnemyEntries() {
        assertNull(Enemy25DCatalog.byId("cheikh"));
        assertNull(Enemy25DCatalog.byId("yvane"));
        assertNull(Enemy25DCatalog.byId("nelvyn"));
    }

    @Test public void officialIslandOrderIncludesCakeAndSkullIslands() {
        String[] expected = {
                "Port des Naufragés", "Jungle Sauvage", "Royaume des Neiges",
                "Désert des Corsaires", "Île Volcanique", "Forteresse de la Tempête",
                "Île des Gâteaux", "Citadelle du Crâne"
        };
        assertEquals(expected.length, Enemy25DCatalog.ISLAND_NAMES.length);
        for (int i = 0; i < expected.length; i++) {
            assertEquals(expected[i], Enemy25DCatalog.ISLAND_NAMES[i]);
        }
    }

    @Test public void allOfficialRostersAreLocked() {
        assertRoster(0, "brakor", Set.of("tireur_quais", "maitre_croc", "ingenieur_amarres"), Set.of("voleur_agile", "porte_chaine", "guetteur_phare"));
        assertRoster(1, "malkor", Set.of("zaya", "kongo", "silex"), Set.of("ronce", "tika", "mamba"));
        assertRoster(2, "skarn", Set.of("eira", "volkr", "nivor"), Set.of("brume", "harka", "flint"));
        assertRoster(3, "zarok", Set.of("sabir", "razka", "al_varis"), Set.of("chaal", "machoire_desert", "veilleuse_dunes"));
        assertRoster(4, "vulkar", Set.of("cendre", "magma", "pyros"), Set.of("basalte", "scorie", "fumar"));
        assertRoster(5, "tempyr", Set.of("orage", "volt", "cyclone"), Set.of("brisk", "tonnerre", "fulgur"));
        assertRoster(6, "matriarche_sucree", Set.of("prince_mochi", "duc_biscuit", "chevalier_caramel"), Set.of("maitre_bonbon", "gardienne_meringue", "tireur_praline"));
        assertRoster(7, "kaor_crane", Set.of("archonte_aile_noire", "ravageur_cornu", "canon_cendres"), Set.of("roi_des_braises", "oracle_pourpre", "gardien_bestial"));
    }

    @Test public void incompatibleLegacyIdentifiersAreRemoved() {
        Set<String> forbidden = Set.of(
                "capitaine_helios", "roi_boreal", "sultan_dune",
                "seigneur_magma", "reine_mousson", "amiral_foudre",
                "zahrek", "qamar", "sirok", "dune", "khepri", "safra", "rakh"
        );
        for (String id : forbidden) assertNull(Enemy25DCatalog.byId(id));
        for (Enemy25DCatalog.Entry entry : Enemy25DCatalog.all()) {
            assertFalse("Ancien identifiant encore présent : " + entry.id, forbidden.contains(entry.id));
        }
    }

    private static void assertRoster(int island, String bossId,
                                     Set<String> commanderIds,
                                     Set<String> subordinateIds) {
        assertEquals(bossId, Enemy25DCatalog.bossForIsland(island).id);
        Set<String> actualCommanders = new HashSet<>();
        for (Enemy25DCatalog.Entry entry : Enemy25DCatalog.commandersForIsland(island)) {
            actualCommanders.add(entry.id);
        }
        assertEquals(commanderIds, actualCommanders);
        Set<String> actualSubordinates = new HashSet<>();
        for (Enemy25DCatalog.Entry entry : Enemy25DCatalog.subordinatesForIsland(island)) {
            actualSubordinates.add(entry.id);
        }
        assertEquals(subordinateIds, actualSubordinates);
    }
}
