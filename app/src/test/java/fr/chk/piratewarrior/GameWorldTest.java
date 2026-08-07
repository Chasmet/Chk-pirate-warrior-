package fr.chk.piratewarrior;

import org.junit.Test;

import java.util.HashSet;
import java.util.Set;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

public class GameWorldTest {
    @Test
    public void campaignContainsElevenOrderedIslands() {
        assertEquals(11, GameWorld.ISLAND_COUNT);
        assertEquals(11, GameWorld.all().length);
        for (int i = 0; i < GameWorld.ISLAND_COUNT; i++) {
            assertEquals(i + 1, GameWorld.get(i).id);
            assertNotNull(GameWorld.get(i).name);
            assertFalse(GameWorld.get(i).name.trim().isEmpty());
            assertNotNull(GameWorld.get(i).boss);
            assertTrue(GameWorld.get(i).enemyCount >= 12);
        }
    }

    @Test
    public void everyIslandHasAUniqueName() {
        Set<String> names = new HashSet<>();
        for (GameWorld.Island island : GameWorld.all()) {
            assertTrue(names.add(island.name));
        }
    }

    @Test
    public void finalIslandIsTheMemoryKingdom() {
        GameWorld.Island finalIsland = GameWorld.get(10);
        assertEquals("Royaume Troublé", finalIsland.name);
        assertEquals(GameWorld.Weather.GOLDEN_FOG, finalIsland.weather);
        assertTrue(finalIsland.objective.contains("objet rare"));
    }
}
