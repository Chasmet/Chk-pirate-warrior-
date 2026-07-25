package fr.chk.piratewarrior;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

import java.util.HashSet;
import java.util.Set;

public final class Fauna3DCatalogTest {
    @Test
    public void containsEightSpeciesPerIsland() {
        assertEquals(48, Fauna3DCatalog.all().size());

        for (int island = 0; island < 6; island++) {
            assertEquals(8, Fauna3DCatalog.forIsland(island).size());
            assertEquals(2, Fauna3DCatalog.forIslandAndCategory(island, Fauna3DCatalog.Category.AMBIENT).size());
            assertEquals(2, Fauna3DCatalog.forIslandAndCategory(island, Fauna3DCatalog.Category.HOSTILE).size());
            assertEquals(2, Fauna3DCatalog.forIslandAndCategory(island, Fauna3DCatalog.Category.BIRD).size());
            assertEquals(1, Fauna3DCatalog.forIslandAndCategory(island, Fauna3DCatalog.Category.RARE).size());
            assertEquals(1, Fauna3DCatalog.forIslandAndCategory(island, Fauna3DCatalog.Category.MARINE).size());
        }
    }

    @Test
    public void everyModelHasUniqueGlbPath() {
        Set<String> ids = new HashSet<>();
        Set<String> paths = new HashSet<>();

        for (Fauna3DCatalog.Entry entry : Fauna3DCatalog.all()) {
            assertTrue(ids.add(entry.id));
            assertTrue(paths.add(entry.modelAssetPath));
            assertTrue(entry.modelAssetPath.endsWith(".glb"));
            assertTrue(entry.maxAlive >= 1);
        }
    }
}
