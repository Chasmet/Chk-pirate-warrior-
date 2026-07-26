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
    @Test
    public void pdfCatalogContainsSixCompleteIslandGroups() {
        assertEquals(42, PdfAssetCatalog.all().size());
        assertEquals(6, PdfAssetCatalog.ISLAND_NAMES.length);

        for (int island = 0; island < PdfAssetCatalog.ISLAND_COUNT; island++) {
            List<PdfAssetCatalog.Entry> entries = PdfAssetCatalog.forIsland(island);
            assertEquals(7, entries.size());

            int bosses = 0;
            int commanders = 0;
            int subordinates = 0;
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

    @Test
    public void officialBossesMatchTheValidatedRosterBoards() {
        String[] bosses = {"Brakor", "Malkor", "Skarn", "Zarok", "Vulkar", "Tempyr"};
        for (int island = 0; island < bosses.length; island++) {
            assertTrue(PdfAssetCatalog.bossForIsland(island).displayName.contains(bosses[island]));
        }
    }

    @Test
    public void desertAtlasUsesTheFinalValidatedIdentifiers() {
        assertNotNull(PdfAssetCatalog.byId("zarok"));
        assertNotNull(PdfAssetCatalog.byId("sabir"));
        assertNotNull(PdfAssetCatalog.byId("razka"));
        assertNotNull(PdfAssetCatalog.byId("al_varis"));
        assertNotNull(PdfAssetCatalog.byId("chaal"));
        assertNotNull(PdfAssetCatalog.byId("machoire_desert"));
        assertNotNull(PdfAssetCatalog.byId("veilleuse_dunes"));
    }

    @Test
    public void protectedHeroesAreNeverEnemyAssets() {
        for (PdfAssetCatalog.Entry entry : PdfAssetCatalog.all()) {
            String id = entry.id.toLowerCase(java.util.Locale.ROOT);
            assertFalse(id.equals("cheikh"));
            assertFalse(id.equals("yvane"));
            assertFalse(id.equals("nelvyn"));
        }
    }
}
