package fr.chk.piratewarrior;

import static org.junit.Assert.assertEquals;

import org.junit.Test;

public final class SpriteStrip25DTest {
    @Test
    public void buildsExpectedAssetPaths() {
        String folder = "characters25d/island_01/capitaine_helios";

        assertEquals(
                "characters25d/island_01/capitaine_helios/animations/front/idle.webp",
                SpriteStrip25D.assetPath(
                        folder,
                        SpriteStrip25D.Direction.FRONT,
                        SpriteStrip25D.Animation.IDLE
                )
        );
        assertEquals(
                "characters25d/island_01/capitaine_helios/animations/right/ultimate.webp",
                SpriteStrip25D.assetPath(
                        folder,
                        SpriteStrip25D.Direction.RIGHT,
                        SpriteStrip25D.Animation.ULTIMATE
                )
        );
    }
}
