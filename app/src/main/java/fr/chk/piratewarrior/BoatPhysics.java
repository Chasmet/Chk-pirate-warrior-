package fr.chk.piratewarrior;

/**
 * Simulation légère du navire, indépendante du rendu Android.
 * Elle est testable sur la JVM et ne réalise aucune allocation dans update().
 */
public final class BoatPhysics {
    public static final float MAX_FORWARD_SPEED = 420f;
    public static final float MAX_REVERSE_SPEED = -82f;

    private static final float FORWARD_ACCELERATION = 185f;
    private static final float REVERSE_ACCELERATION = 118f;
    private static final float PASSIVE_DRAG = 0.52f;
    private static final float ACTIVE_BRAKE = 295f;
    private static final float BASE_TURN_RATE = 1.34f;

    private float x;
    private float lane;
    private float speed;
    private float heading;
    private float roll;
    private float pitch;
    private float wavePhase;

    public void reset() {
        x = 0f;
        lane = 0f;
        speed = 0f;
        heading = 0f;
        roll = 0f;
        pitch = 0f;
        wavePhase = 0f;
    }

    public void update(float throttle, float steering, float brake, float wind, float dt) {
        if (dt <= 0f) return;
        dt = Math.min(dt, 0.05f);
        throttle = GameMath.clamp(throttle, -1f, 1f);
        steering = GameMath.clamp(steering, -1f, 1f);
        brake = GameMath.clamp(brake, 0f, 1f);
        wind = GameMath.clamp(wind, -1f, 1f);

        if (throttle >= 0f) {
            speed += throttle * FORWARD_ACCELERATION * dt;
        } else {
            speed += throttle * REVERSE_ACCELERATION * dt;
        }

        if (brake > 0f) {
            float braking = ACTIVE_BRAKE * brake * dt;
            if (speed > 0f) speed = Math.max(0f, speed - braking);
            else if (speed < 0f) speed = Math.min(0f, speed + braking);
        } else if (Math.abs(throttle) < 0.04f) {
            speed *= Math.max(0f, 1f - PASSIVE_DRAG * dt);
        }

        speed += wind * 7.5f * dt;
        speed = GameMath.clamp(speed, MAX_REVERSE_SPEED, MAX_FORWARD_SPEED);

        float speedRatio = Math.abs(speed) / MAX_FORWARD_SPEED;
        float direction = speed < -1f ? -1f : 1f;
        heading += steering * BASE_TURN_RATE * (0.20f + speedRatio * 0.80f) * direction * dt;
        heading += wind * (0.035f + speedRatio * 0.025f) * dt;
        heading = GameMath.clamp(heading, -0.72f, 0.72f);

        float forward = Math.max(0f, speed);
        x += forward * (float) Math.cos(heading) * dt;
        lane += speed * (float) Math.sin(heading) * dt * 0.72f;
        lane = GameMath.clamp(lane, -430f, 430f);

        wavePhase += dt * (1.65f + speedRatio * 2.2f);
        float targetRoll = (float) Math.sin(wavePhase) * (0.035f + speedRatio * 0.055f)
                - steering * speedRatio * 0.22f;
        float targetPitch = (float) Math.sin(wavePhase * 0.73f + 0.8f)
                * (0.025f + speedRatio * 0.050f);
        roll += (targetRoll - roll) * Math.min(1f, dt * 4.8f);
        pitch += (targetPitch - pitch) * Math.min(1f, dt * 4.2f);
    }

    /**
     * Applique un choc contre un rocher et renvoie la force normalisée du choc.
     */
    public float collide(float severity) {
        severity = GameMath.clamp(severity, 0f, 1f);
        float impact = Math.min(1f, Math.abs(speed) / MAX_FORWARD_SPEED) * severity;
        speed *= -(0.10f + 0.18f * severity);
        heading *= 0.55f;
        roll += (heading >= 0f ? -1f : 1f) * (0.10f + impact * 0.22f);
        return impact;
    }

    public float getX() {
        return x;
    }

    public float getLane() {
        return lane;
    }

    public float getSpeed() {
        return speed;
    }

    public float getHeading() {
        return heading;
    }

    public float getRoll() {
        return roll;
    }

    public float getPitch() {
        return pitch;
    }
}
