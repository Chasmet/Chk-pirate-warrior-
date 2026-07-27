package fr.chk.piratewarrior;

import static org.junit.Assert.assertEquals;

import org.junit.Test;

public final class SpriteStrip25DTest {
    @Test
    public void buildsExpectedAssetPaths() {
        String folder = "characters25d/island_01/brakor";

        assertEquals(
                "characters25d/island_01/brakor/animations/front/idle.webp",
                SpriteStrip25D.assetPath(
                        folder,
                        SpriteStrip25D.Direction.FRONT,
                        SpriteStrip25D.Animation.IDLE
                )
        );
        assertEquals(
                "characters25d/island_01/brakor/animations/right/ultimate.webp",
                SpriteStrip25D.assetPath(
                        folder,
                        SpriteStrip25D.Direction.RIGHT,
                        SpriteStrip25D.Animation.ULTIMATE
                )
        );
    }

    @Test
    public void animationFrameBudgetsMatchTheTechnicalSpecification() {
        assertEquals(4, SpriteStrip25D.Animation.IDLE.expectedFrames);
        assertEquals(6, SpriteStrip25D.Animation.WALK.expectedFrames);
        assertEquals(8, SpriteStrip25D.Animation.PHASE2.expectedFrames);
        assertEquals(12, SpriteStrip25D.Animation.ULTIMATE.expectedFrames);
        assertEquals(256, SpriteStrip25D.CELL_SIZE);
    }
}
