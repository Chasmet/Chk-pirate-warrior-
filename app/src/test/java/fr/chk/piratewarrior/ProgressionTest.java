package fr.chk.piratewarrior;

import org.junit.Test;

import static org.junit.Assert.assertEquals;

public class ProgressionTest {
    @Test
    public void progressionStartsAtLevelOne() {
        assertEquals(1, Progression.levelForXp(0));
        assertEquals(1, Progression.levelForXp(-50));
    }

    @Test
    public void progressionRaisesLevelAtThreshold() {
        assertEquals(2, Progression.levelForXp(120));
        assertEquals(3, Progression.levelForXp(315));
    }
}
