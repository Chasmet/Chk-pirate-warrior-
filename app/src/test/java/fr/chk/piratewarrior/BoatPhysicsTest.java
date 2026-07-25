package fr.chk.piratewarrior;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

public final class BoatPhysicsTest {
    @Test
    public void throttleAcceleratesAndBrakeStopsTheBoat() {
        BoatPhysics boat = new BoatPhysics();
        boat.reset();
        for (int i = 0; i < 120; i++) boat.update(1f, 0f, 0f, 0f, 1f / 60f);
        assertTrue(boat.getSpeed() > 250f);
        float beforeBrake = boat.getSpeed();
        for (int i = 0; i < 90; i++) boat.update(0f, 0f, 1f, 0f, 1f / 60f);
        assertTrue(boat.getSpeed() < beforeBrake);
        assertEquals(0f, boat.getSpeed(), 0.01f);
    }

    @Test
    public void steeringChangesHeadingAndLane() {
        BoatPhysics boat = new BoatPhysics();
        boat.reset();
        for (int i = 0; i < 180; i++) boat.update(1f, 0.65f, 0f, 0f, 1f / 60f);
        assertTrue(boat.getHeading() > 0.15f);
        assertTrue(boat.getLane() > 10f);
        assertTrue(boat.getX() > 100f);
    }

    @Test
    public void speedRemainsInsideSupportedLimits() {
        BoatPhysics boat = new BoatPhysics();
        boat.reset();
        for (int i = 0; i < 2_000; i++) boat.update(1f, 0f, 0f, 1f, 1f / 60f);
        assertTrue(boat.getSpeed() <= BoatPhysics.MAX_FORWARD_SPEED);
        for (int i = 0; i < 2_000; i++) boat.update(-1f, 0f, 0f, -1f, 1f / 60f);
        assertTrue(boat.getSpeed() >= BoatPhysics.MAX_REVERSE_SPEED);
    }

    @Test
    public void collisionReducesAndReversesSpeed() {
        BoatPhysics boat = new BoatPhysics();
        boat.reset();
        for (int i = 0; i < 90; i++) boat.update(1f, 0f, 0f, 0f, 1f / 60f);
        float impact = boat.collide(1f);
        assertTrue(impact > 0f);
        assertTrue(boat.getSpeed() <= 0f);
    }
}
