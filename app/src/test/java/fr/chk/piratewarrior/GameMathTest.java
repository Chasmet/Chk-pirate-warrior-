package fr.chk.piratewarrior;

import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

public final class GameMathTest {
    @Test
    public void clampRespecteLesBornes() {
        assertEquals(0f, GameMath.clamp(-2f, 0f, 10f), 0.0001f);
        assertEquals(5f, GameMath.clamp(5f, 0f, 10f), 0.0001f);
        assertEquals(10f, GameMath.clamp(15f, 0f, 10f), 0.0001f);
    }

    @Test
    public void collisionsCirculairesSontStables() {
        assertTrue(GameMath.circlesOverlap(0f, 0f, 10f, 15f, 0f, 6f));
        assertFalse(GameMath.circlesOverlap(0f, 0f, 10f, 30f, 0f, 6f));
    }

    @Test
    public void pointEstRameneDansLeRayon() {
        assertArrayEquals(new float[]{10f, 0f}, GameMath.clampToCircle(20f, 0f, 0f, 0f, 10f), 0.0001f);
        assertArrayEquals(new float[]{3f, 4f}, GameMath.clampToCircle(3f, 4f, 0f, 0f, 10f), 0.0001f);
    }
}
