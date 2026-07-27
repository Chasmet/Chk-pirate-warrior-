package fr.chk.piratewarrior;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

public final class HeroAnimationDynamicsTest {
    @Test
    public void combatStatesKeepPriorityOverMovement() {
        HeroAnimationDynamics.Input input = new HeroAnimationDynamics.Input();
        input.heroIndex = 0;
        input.velocityX = 260f;
        input.sprinting = true;
        input.attackTime = 0.4f;
        input.dodgeTime = 0.2f;
        input.hurtTime = 0.3f;

        assertEquals(HeroAnimationDynamics.Motion.HURT,
                HeroAnimationDynamics.resolveForTests(input, false));

        input.hurtTime = 0f;
        assertEquals(HeroAnimationDynamics.Motion.DODGE,
                HeroAnimationDynamics.resolveForTests(input, false));

        input.dodgeTime = 0f;
        assertEquals(HeroAnimationDynamics.Motion.ATTACK,
                HeroAnimationDynamics.resolveForTests(input, false));
    }

    @Test
    public void jumpLandingAndLocomotionAreResolved() {
        HeroAnimationDynamics.Input input = new HeroAnimationDynamics.Input();
        input.heroIndex = 1;
        input.jumpHeight = 40f;
        input.jumpVelocity = 120f;
        assertEquals(HeroAnimationDynamics.Motion.JUMP_ASCEND,
                HeroAnimationDynamics.resolveForTests(input, false));

        input.jumpVelocity = -120f;
        assertEquals(HeroAnimationDynamics.Motion.JUMP_FALL,
                HeroAnimationDynamics.resolveForTests(input, false));

        input.jumpHeight = 0f;
        assertEquals(HeroAnimationDynamics.Motion.LAND,
                HeroAnimationDynamics.resolveForTests(input, true));

        input.velocityX = 240f;
        input.sprinting = true;
        assertEquals(HeroAnimationDynamics.Motion.RUN,
                HeroAnimationDynamics.resolveForTests(input, false));

        input.sprinting = false;
        input.velocityX = 70f;
        assertEquals(HeroAnimationDynamics.Motion.WALK,
                HeroAnimationDynamics.resolveForTests(input, false));
    }

    @Test
    public void controllerProducesFiniteReusableTransforms() {
        HeroAnimationDynamics.Controller controller = new HeroAnimationDynamics.Controller();
        HeroAnimationDynamics.Input input = new HeroAnimationDynamics.Input();
        input.heroIndex = 2;
        input.velocityX = 230f;
        input.sprinting = true;

        HeroAnimationDynamics.Transform first = controller.update(input, 1f / 60f);
        HeroAnimationDynamics.Transform second = controller.update(input, 1f / 60f);

        assertTrue(first == second);
        assertEquals(HeroAnimationDynamics.Motion.RUN, second.motion);
        assertTrue(Float.isFinite(second.offsetX));
        assertTrue(Float.isFinite(second.offsetY));
        assertTrue(Float.isFinite(second.scaleX));
        assertTrue(Float.isFinite(second.scaleY));
        assertTrue(Float.isFinite(second.rotation));
        assertTrue(second.scaleX > 0f);
        assertTrue(second.scaleY > 0f);
    }

    @Test
    public void forcedAnimationDoesNotChangeHeroIdentity() {
        HeroAnimationDynamics.Controller controller = new HeroAnimationDynamics.Controller();
        HeroAnimationDynamics.Input input = new HeroAnimationDynamics.Input();
        input.heroIndex = 0;
        input.forcedMotion = HeroAnimationDynamics.Motion.PARRY;
        input.externalProgress = 0.5f;

        HeroAnimationDynamics.Transform transform = controller.update(input, 1f / 60f);
        assertEquals(HeroAnimationDynamics.Motion.PARRY, transform.motion);
        assertTrue(transform.effectStrength >= 0f);
        assertTrue(transform.scaleX > 0f);
        assertTrue(transform.scaleY > 0f);
    }
}
