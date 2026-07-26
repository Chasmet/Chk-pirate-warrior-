package fr.chk.piratewarrior;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

public final class PdfAssetCatalogTest {
    @Test public void pdfCatalogContainsEightCompleteIslandGroups() {
        assertEquals(56, PdfAssetCatalog.all().size());
        assertEquals(8, PdfAssetCatalog.ISLAND_NAMES.length);
        for (int island = 0; island < PdfAssetCatalog.ISLAND_COUNT; island++) {
            List<PdfAssetCatalog.Entry> entries = PdfAssetCatalog.forIsland(island);
            assertEquals(7, entries.size());
            int bosses = 0, commanders = 0, subordinates = 0;
            Set<Integer> slots = new HashSet<>();
            for (PdfAssetCatalog.Entry entry : entries) {
                assertEquals(island, entry.islandIndex);
                assertTrue(entry.atlasSlot >= 0 && entry.atlasSlot <= 6);
                assertTrue("Emplacement d'atlas dupliqué", slots.add(entry.atlasSlot));
                assertNotNull(entry.id);
                assertNotNull(entry.displayName);
                switch (entry.rank) {
                    case BOSS -> bosses++;
                    case COMMANDER -> commanders++;
                    case SUBORDINATE -> subordinates++;
                }
            }
            assertEquals(1, bosses);
            assertEquals(3, commanders);
            assertEquals(3, subordinates);
            assertEquals(7, slots.size());
            assertTrue(PdfAssetCatalog.atlasAssetPath(island).endsWith(".webp.b64"));
        }
    }

    @Test public void officialBossesMatchTheValidatedRosterBoards() {
        String[] bosses = {"Brakor", "Malkor", "Skarn", "Zarok", "Vulkar", "Tempyr", "Matriarche", "Kaor"};
        for (int island = 0; island < bosses.length; island++) {
            assertTrue(PdfAssetCatalog.bossForIsland(island).displayName.contains(bosses[island]));
        }
    }

    @Test public void newIslandAssetsUseDedicatedPaths() {
        assertEquals("characters25d/pdf_atlas/island_07_atlas.webp.b64", PdfAssetCatalog.atlasAssetPath(6));
        assertEquals("characters25d/pdf_atlas/island_08_atlas.webp.b64", PdfAssetCatalog.atlasAssetPath(7));
        assertNotNull(PdfAssetCatalog.byId("matriarche_sucree"));
        assertNotNull(PdfAssetCatalog.byId("kaor_crane"));
        assertNotNull(PdfAssetCatalog.byId("oracle_pourpre"));
    }

    @Test public void protectedHeroesAreNeverEnemyAssets() {
        for (PdfAssetCatalog.Entry entry : PdfAssetCatalog.all()) {
            String id = entry.id.toLowerCase(java.util.Locale.ROOT);
            assertFalse(id.equals("cheikh"));
            assertFalse(id.equals("yvane"));
            assertFalse(id.equals("nelvyn"));
        }
    }
}
