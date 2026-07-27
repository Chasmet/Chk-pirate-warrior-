package fr.chk.piratewarrior;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import org.junit.After;
import org.junit.Test;

public final class V55RuntimeStateTest {
    @After
    public void clear() {
        V55RuntimeState.clearForTests();
    }

    @Test
    public void specialAnimationIsBoundedToOfficialHeroIndexes() {
        V55RuntimeState.playHeroAnimation(99, V55RuntimeState.HeroAnimation.SPECIAL, 1f);
        V55RuntimeState.Snapshot snapshot = V55RuntimeState.heroSnapshot();
        assertTrue(snapshot.active);
        assertEquals(2, snapshot.heroIndex);
        assertEquals(V55RuntimeState.HeroAnimation.SPECIAL, snapshot.animation);
    }

    @Test
    public void invalidAnimationRequestDoesNotStartState() {
        V55RuntimeState.playHeroAnimation(0, V55RuntimeState.HeroAnimation.NONE, 1f);
        assertFalse(V55RuntimeState.heroSnapshot().active);
    }
}
