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
    @Test
    public void catalogueContainsExpectedDistribution() {
        assertEquals(42, Enemy25DCatalog.all().size());

        int bosses = 0;
        int commanders = 0;
        int subordinates = 0;
        Set<String> ids = new HashSet<>();

        for (Enemy25DCatalog.Entry entry : Enemy25DCatalog.all()) {
            assertTrue("Identifiant dupliqué : " + entry.id, ids.add(entry.id));
            assertTrue(entry.islandIndex >= 0 && entry.islandIndex < 6);
            assertTrue(entry.sheetAssetPath.endsWith("/sheet.webp"));
            switch (entry.rank) {
                case BOSS -> bosses++;
                case COMMANDER -> commanders++;
                case SUBORDINATE -> subordinates++;
            }
        }

        assertEquals(6, bosses);
        assertEquals(18, commanders);
        assertEquals(18, subordinates);
    }

    @Test
    public void everyIslandHasOneBossAndThreePairs() {
        for (int island = 0; island < 6; island++) {
            assertNotNull(Enemy25DCatalog.bossForIsland(island));
            assertEquals(3, Enemy25DCatalog.commandersForIsland(island).size());
            assertEquals(3, Enemy25DCatalog.subordinatesForIsland(island).size());
        }
    }

    @Test
    public void protectedHeroesAreNotEnemyEntries() {
        assertNull(Enemy25DCatalog.byId("cheikh"));
        assertNull(Enemy25DCatalog.byId("yvane"));
        assertNull(Enemy25DCatalog.byId("nelvyn"));
    }

    @Test
    public void officialIslandOrderIsLocked() {
        assertEquals("Port des Naufragés", Enemy25DCatalog.ISLAND_NAMES[0]);
        assertEquals("Jungle Sauvage", Enemy25DCatalog.ISLAND_NAMES[1]);
        assertEquals("Royaume des Neiges", Enemy25DCatalog.ISLAND_NAMES[2]);
        assertEquals("Désert des Corsaires", Enemy25DCatalog.ISLAND_NAMES[3]);
        assertEquals("Île Volcanique", Enemy25DCatalog.ISLAND_NAMES[4]);
        assertEquals("Forteresse de la Tempête", Enemy25DCatalog.ISLAND_NAMES[5]);
    }

    @Test
    public void portDesNaufragesReferencesAreLocked() {
        assertRoster(0,
                "brakor",
                Set.of("tireur_quais", "maitre_croc", "ingenieur_amarres"),
                Set.of("voleur_agile", "porte_chaine", "guetteur_phare"));
        assertEquals("Brakor, Gardien du Port", Enemy25DCatalog.bossForIsland(0).displayName);
        assertEquals("characters25d/island_01/brakor/sheet.webp",
                Enemy25DCatalog.bossForIsland(0).sheetAssetPath);
    }

    @Test
    public void allOfficialRostersAreLocked() {
        assertRoster(1, "malkor", Set.of("zaya", "kongo", "silex"),
                Set.of("ronce", "tika", "mamba"));
        assertRoster(2, "skarn", Set.of("eira", "volkr", "nivor"),
                Set.of("brume", "harka", "flint"));
        assertRoster(3, "zahrek", Set.of("qamar", "sirok", "dune"),
                Set.of("khepri", "safra", "rakh"));
        assertRoster(4, "vulkar", Set.of("cendre", "magma", "pyros"),
                Set.of("basalte", "scorie", "fumar"));
        assertRoster(5, "tempyr", Set.of("orage", "volt", "cyclone"),
                Set.of("brisk", "tonnerre", "fulgur"));
    }

    @Test
    public void incompatibleLegacyBossesAreRemoved() {
        Set<String> forbidden = Set.of(
                "capitaine_helios", "roi_boreal", "sultan_dune",
                "seigneur_magma", "reine_mousson", "amiral_foudre"
        );
        for (String id : forbidden) assertNull(Enemy25DCatalog.byId(id));
        for (Enemy25DCatalog.Entry entry : Enemy25DCatalog.all()) {
            assertFalse("Ancien identifiant encore présent : " + entry.id,
                    forbidden.contains(entry.id));
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
