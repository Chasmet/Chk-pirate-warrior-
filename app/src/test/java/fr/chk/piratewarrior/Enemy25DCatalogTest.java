package fr.chk.piratewarrior;

import static org.junit.Assert.assertEquals;
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
    public void portDesNaufragesReferencesAreLocked() {
        Enemy25DCatalog.Entry boss = Enemy25DCatalog.bossForIsland(0);
        assertEquals("brakor", boss.id);
        assertEquals("Brakor, Gardien du Port", boss.displayName);
        assertEquals("characters25d/island_01/brakor/sheet.webp", boss.sheetAssetPath);

        Set<String> commanders = new HashSet<>();
        for (Enemy25DCatalog.Entry entry : Enemy25DCatalog.commandersForIsland(0)) {
            commanders.add(entry.id);
        }
        assertTrue(commanders.contains("tireur_quais"));
        assertTrue(commanders.contains("maitre_croc"));
        assertTrue(commanders.contains("ingenieur_amarres"));

        Set<String> nakamas = new HashSet<>();
        for (Enemy25DCatalog.Entry entry : Enemy25DCatalog.subordinatesForIsland(0)) {
            nakamas.add(entry.id);
        }
        assertTrue(nakamas.contains("voleur_agile"));
        assertTrue(nakamas.contains("porte_chaine"));
        assertTrue(nakamas.contains("guetteur_phare"));
        assertNull(Enemy25DCatalog.byId("capitaine_helios"));
    }
}
