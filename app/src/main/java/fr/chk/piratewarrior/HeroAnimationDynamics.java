package fr.chk.piratewarrior;

/**
 * Contrôleur d'animation procédurale léger pour les trois héros officiels.
 * Il transforme uniquement leurs bitmaps existants : aucune identité visuelle n'est remplacée.
 * Les objets d'entrée et de sortie sont réutilisés afin d'éviter les allocations dans la boucle.
 */
public final class HeroAnimationDynamics {
    public enum Motion {
        IDLE,
        WALK,
        RUN,
        JUMP_ASCEND,
        JUMP_FALL,
        LAND,
        ATTACK,
        DODGE,
        HURT,
        AURA,
        PARRY,
        INTERACT,
        VICTORY,
        CROUCH,
        OBSERVE,
        SPECIAL
    }

    public static final class Input {
        public int heroIndex;
        public float velocityX;
        public float velocityY;
        public float jumpHeight;
        public float jumpVelocity;
        public float attackTime;
        public float dodgeTime;
        public float hurtTime;
        public float auraTime;
        public float externalProgress;
        public Motion forcedMotion;
        public boolean sprinting;
    }

    public static final class Transform {
        public Motion motion = Motion.IDLE;
        public float offsetX;
        public float offsetY;
        public float scaleX = 1f;
        public float scaleY = 1f;
        public float rotation;
        public float trailStrength;
        public float effectStrength;
        public float normalizedTime;

        private void set(Transform other) {
            motion = other.motion;
            offsetX = other.offsetX;
            offsetY = other.offsetY;
            scaleX = other.scaleX;
            scaleY = other.scaleY;
            rotation = other.rotation;
            trailStrength = other.trailStrength;
            effectStrength = other.effectStrength;
            normalizedTime = other.normalizedTime;
        }
    }

    public static final class Controller {
        private static final float TRANSITION_SECONDS = 0.11f;
        private static final float LAND_SECONDS = 0.34f;

        private final Transform current = new Transform();
        private final Transform from = new Transform();
        private final Transform target = new Transform();

        private Motion motion = Motion.IDLE;
        private float stateTime;
        private float transitionTime = TRANSITION_SECONDS;
        private float landingTime;
        private float previousJumpHeight;
        private int heroIndex = -1;

        public void reset(int selectedHero) {
            heroIndex = selectedHero;
            motion = Motion.IDLE;
            stateTime = 0f;
            transitionTime = TRANSITION_SECONDS;
            landingTime = 0f;
            previousJumpHeight = 0f;
            current.motion = Motion.IDLE;
            current.offsetX = current.offsetY = current.rotation = 0f;
            current.scaleX = current.scaleY = 1f;
            current.trailStrength = current.effectStrength = 0f;
            current.normalizedTime = 0f;
            from.set(current);
        }

        public Transform update(Input input, float dt) {
            float safeDt = GameMath.clamp(dt, 0f, 0.05f);
            if (heroIndex != input.heroIndex) reset(input.heroIndex);

            if (previousJumpHeight > 0.5f && input.jumpHeight <= 0.01f) landingTime = LAND_SECONDS;
            previousJumpHeight = Math.max(0f, input.jumpHeight);
            landingTime = Math.max(0f, landingTime - safeDt);

            Motion resolved = resolve(input, landingTime > 0f);
            if (resolved != motion) {
                from.set(current);
                motion = resolved;
                stateTime = 0f;
                transitionTime = 0f;
            } else {
                stateTime += safeDt;
            }
            transitionTime = Math.min(TRANSITION_SECONDS, transitionTime + safeDt);

            float progress = input.forcedMotion != null
                    ? GameMath.clamp(input.externalProgress, 0f, 1f)
                    : stateProgress(input, motion, stateTime, landingTime);
            sample(target, input, motion, stateTime, progress);

            float blend = smoothstep(transitionTime / TRANSITION_SECONDS);
            current.motion = motion;
            current.offsetX = lerp(from.offsetX, target.offsetX, blend);
            current.offsetY = lerp(from.offsetY, target.offsetY, blend);
            current.scaleX = lerp(from.scaleX, target.scaleX, blend);
            current.scaleY = lerp(from.scaleY, target.scaleY, blend);
            current.rotation = lerp(from.rotation, target.rotation, blend);
            current.trailStrength = lerp(from.trailStrength, target.trailStrength, blend);
            current.effectStrength = lerp(from.effectStrength, target.effectStrength, blend);
            current.normalizedTime = progress;
            return current;
        }

        private Motion resolve(Input input, boolean landing) {
            if (input.forcedMotion != null) return input.forcedMotion;
            if (input.hurtTime > 0f) return Motion.HURT;
            if (input.dodgeTime > 0f) return Motion.DODGE;
            if (input.attackTime > 0f) return Motion.ATTACK;
            if (input.jumpHeight > 0.01f) {
                return input.jumpVelocity >= 0f ? Motion.JUMP_ASCEND : Motion.JUMP_FALL;
            }
            if (landing) return Motion.LAND;
            float speed = GameMath.length(input.velocityX, input.velocityY);
            if (input.sprinting || speed > 205f) return Motion.RUN;
            if (speed > 14f) return Motion.WALK;
            if (input.auraTime > 0f) return Motion.AURA;
            return Motion.IDLE;
        }

        private static float stateProgress(Input input, Motion motion, float time, float landing) {
            return switch (motion) {
                case ATTACK -> GameMath.clamp(1f - input.attackTime / 0.55f, 0f, 1f);
                case DODGE -> GameMath.clamp(1f - input.dodgeTime / 0.26f, 0f, 1f);
                case HURT -> GameMath.clamp(1f - input.hurtTime / 0.48f, 0f, 1f);
                case LAND -> GameMath.clamp(1f - landing / LAND_SECONDS, 0f, 1f);
                default -> time;
            };
        }
    }

    private HeroAnimationDynamics() {}

    static Motion resolveForTests(Input input, boolean landing) {
        Controller controller = new Controller();
        controller.landingTime = landing ? 0.2f : 0f;
        return controller.resolve(input, landing);
    }

    private static void sample(
            Transform out,
            Input input,
            Motion motion,
            float time,
            float progress
    ) {
        int hero = Math.max(0, Math.min(2, input.heroIndex));
        float direction = input.velocityX < -4f ? -1f : 1f;
        float frequency = hero == 1 ? 1.16f : hero == 2 ? 1.08f : 0.92f;
        float weight = hero == 0 ? 0.86f : hero == 1 ? 1.08f : 1f;
        float phase = time * frequency;

        out.motion = motion;
        out.offsetX = 0f;
        out.offsetY = 0f;
        out.scaleX = 1f;
        out.scaleY = 1f;
        out.rotation = 0f;
        out.trailStrength = 0f;
        out.effectStrength = 0f;
        out.normalizedTime = progress;

        switch (motion) {
            case IDLE -> {
                float breath = (float) Math.sin(phase * 3.25f);
                out.scaleX = 1f - breath * 0.008f;
                out.scaleY = 1f + breath * 0.012f;
                out.offsetY = -Math.abs(breath) * 1.4f;
                out.rotation = (float) Math.sin(phase * 1.35f) * 0.7f;
            }
            case WALK -> {
                float step = (float) Math.sin(phase * 8.5f);
                out.offsetY = -Math.abs(step) * 3.5f * weight;
                out.offsetX = step * 1.5f;
                out.rotation = step * 2.4f * direction;
                out.scaleY = 1f - Math.abs(step) * 0.018f;
            }
            case RUN -> {
                float step = (float) Math.sin(phase * 12.5f);
                out.offsetY = -Math.abs(step) * 5.4f;
                out.offsetX = step * 2.3f;
                out.rotation = direction * (5.5f + step * 2.2f);
                out.scaleX = 1.025f;
                out.scaleY = 0.985f;
                out.trailStrength = 0.28f + Math.abs(step) * 0.22f;
            }
            case JUMP_ASCEND -> {
                out.offsetY = -4f;
                out.rotation = direction * 4.5f;
                out.scaleX = 0.94f;
                out.scaleY = 1.09f;
                out.effectStrength = 0.35f;
            }
            case JUMP_FALL -> {
                out.rotation = -direction * 2.5f;
                out.scaleX = 1.045f;
                out.scaleY = 0.96f;
                out.effectStrength = 0.22f;
            }
            case LAND -> {
                float impact = (float) Math.sin(GameMath.clamp(progress, 0f, 1f) * Math.PI);
                out.offsetY = impact * 5f;
                out.scaleX = 1f + impact * 0.15f * weight;
                out.scaleY = 1f - impact * 0.22f * weight;
                out.effectStrength = 1f - progress;
            }
            case ATTACK -> {
                float p = GameMath.clamp(progress, 0f, 1f);
                if (p < 0.28f) {
                    float windup = p / 0.28f;
                    out.offsetX = -direction * windup * 7f;
                    out.rotation = -direction * windup * 8f;
                    out.scaleX = 1f - windup * 0.035f;
                } else if (p < 0.64f) {
                    float strike = smoothstep((p - 0.28f) / 0.36f);
                    out.offsetX = direction * (-7f + strike * 23f);
                    out.rotation = direction * (-8f + strike * 24f);
                    out.scaleX = 1f + strike * 0.09f;
                    out.scaleY = 1f - strike * 0.055f;
                    out.trailStrength = strike;
                    out.effectStrength = strike;
                } else {
                    float recover = (p - 0.64f) / 0.36f;
                    out.offsetX = direction * (16f * (1f - recover));
                    out.rotation = direction * (16f * (1f - recover));
                    out.trailStrength = 1f - recover;
                }
            }
            case DODGE -> {
                float p = GameMath.clamp(progress, 0f, 1f);
                float arc = (float) Math.sin(p * Math.PI);
                out.offsetX = direction * arc * (hero == 1 ? 30f : 24f);
                out.offsetY = arc * 5f;
                out.rotation = direction * arc * 13f;
                out.scaleX = 1f + arc * 0.16f;
                out.scaleY = 1f - arc * 0.20f;
                out.trailStrength = arc;
            }
            case HURT -> {
                float shock = 1f - GameMath.clamp(progress, 0f, 1f);
                out.offsetX = -direction * shock * 10f;
                out.rotation = -direction * shock * 12f;
                out.scaleX = 1f + shock * 0.08f;
                out.scaleY = 1f - shock * 0.08f;
                out.effectStrength = shock;
            }
            case AURA -> {
                float pulse = 0.5f + (float) Math.sin(phase * 7f) * 0.5f;
                out.scaleX = 1.015f + pulse * 0.018f;
                out.scaleY = 1.015f + pulse * 0.018f;
                out.offsetY = -pulse * 2f;
                out.effectStrength = 0.55f + pulse * 0.45f;
            }
            case PARRY -> {
                float arc = (float) Math.sin(progress * Math.PI);
                out.rotation = -direction * (7f + arc * 6f);
                out.offsetX = -direction * arc * 5f;
                out.scaleX = 1.035f;
                out.scaleY = 1.02f;
                out.effectStrength = arc;
            }
            case INTERACT -> {
                out.offsetX = (float) Math.sin(progress * Math.PI * 2f) * 5f;
                out.rotation = (float) Math.sin(progress * Math.PI * 2f) * 3.5f;
                out.effectStrength = 0.6f;
            }
            case VICTORY -> {
                float lift = Math.abs((float) Math.sin(progress * Math.PI * 2f));
                out.offsetY = -lift * 18f;
                out.rotation = direction * (float) Math.sin(progress * Math.PI) * 7f;
                out.scaleX = 1.03f + lift * 0.06f;
                out.scaleY = 1.03f + lift * 0.06f;
                out.effectStrength = 1f;
            }
            case CROUCH -> {
                out.scaleX = 1.09f;
                out.scaleY = 0.73f;
                out.offsetY = 4f;
            }
            case OBSERVE -> {
                out.offsetX = direction * 4f;
                out.rotation = (float) Math.sin(progress * Math.PI * 2f) * 2.2f;
                out.effectStrength = 0.7f;
            }
            case SPECIAL -> {
                float surge = (float) Math.sin(progress * Math.PI);
                out.offsetX = direction * surge * 8f;
                out.rotation = direction * surge * 10f;
                out.scaleX = 1f + surge * 0.11f;
                out.scaleY = 1f + surge * 0.075f;
                out.trailStrength = surge;
                out.effectStrength = surge;
            }
        }
    }

    private static float smoothstep(float value) {
        float t = GameMath.clamp(value, 0f, 1f);
        return t * t * (3f - 2f * t);
    }

    private static float lerp(float start, float end, float amount) {
        return start + (end - start) * amount;
    }
}
