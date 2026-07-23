package fr.chk.piratewarrior;

public final class Progression {
    private Progression() {
    }

    public static int levelForXp(int xp) {
        int safeXp = Math.max(0, xp);
        int level = 1;
        int threshold = 120;
        int consumed = 0;
        while (safeXp >= consumed + threshold && level < 30) {
            consumed += threshold;
            level++;
            threshold = 120 + (level - 1) * 75;
        }
        return level;
    }
}
