package fr.chk.piratewarrior;

/**
 * Petit bus d'état partagé entre les couches V5.5.
 * Il ne possède aucun asset et ne remplace aucun système du moteur.
 */
public final class V55RuntimeState {
    public enum HeroAnimation {
        NONE,
        LAND,
        PARRY,
        INTERACT,
        VICTORY,
        CROUCH,
        OBSERVE,
        SPECIAL
    }

    public static final class Snapshot {
        public final int heroIndex;
        public final HeroAnimation animation;
        public final float progress;
        public final boolean active;

        Snapshot(int heroIndex, HeroAnimation animation, float progress, boolean active) {
            this.heroIndex = heroIndex;
            this.animation = animation;
            this.progress = progress;
            this.active = active;
        }
    }

    private static int heroIndex;
    private static HeroAnimation heroAnimation = HeroAnimation.NONE;
    private static long heroStartNanos;
    private static long heroEndNanos;

    private V55RuntimeState() {}

    public static synchronized void playHeroAnimation(
            int hero,
            HeroAnimation animation,
            float durationSeconds
    ) {
        if (animation == null || animation == HeroAnimation.NONE || durationSeconds <= 0f) return;
        heroIndex = Math.max(0, Math.min(2, hero));
        heroAnimation = animation;
        heroStartNanos = System.nanoTime();
        heroEndNanos = heroStartNanos + (long) (durationSeconds * 1_000_000_000L);
    }

    public static synchronized Snapshot heroSnapshot() {
        long now = System.nanoTime();
        if (heroAnimation == HeroAnimation.NONE || now >= heroEndNanos || heroEndNanos <= heroStartNanos) {
            heroAnimation = HeroAnimation.NONE;
            return new Snapshot(heroIndex, HeroAnimation.NONE, 1f, false);
        }
        float progress = (now - heroStartNanos) / (float) (heroEndNanos - heroStartNanos);
        return new Snapshot(heroIndex, heroAnimation, GameMath.clamp(progress, 0f, 1f), true);
    }

    static synchronized void clearForTests() {
        heroAnimation = HeroAnimation.NONE;
        heroStartNanos = 0L;
        heroEndNanos = 0L;
        heroIndex = 0;
    }
}
