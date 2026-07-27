package fr.chk.piratewarrior;

import java.util.Locale;

/**
 * Profil de combat dérivé du rôle, de l'arme et du pouvoir d'un personnage officiel 2.5D.
 *
 * Cette classe ne charge aucun asset et ne dépend pas d'Android. Elle permet d'appliquer des
 * différences de gameplay cohérentes sans dupliquer les règles dans les vues de rendu.
 */
public final class Enemy25DCombatProfile {
    public enum Archetype {
        BOSS,
        BRUISER,
        RANGED,
        ASSASSIN,
        CONTROLLER
    }

    public final Archetype archetype;
    public final boolean ranged;
    public final float hpMultiplier;
    public final float speedMultiplier;
    public final float radiusMultiplier;
    public final float attackCooldownSeconds;
    public final float preferredDistance;

    private Enemy25DCombatProfile(
            Archetype archetype,
            boolean ranged,
            float hpMultiplier,
            float speedMultiplier,
            float radiusMultiplier,
            float attackCooldownSeconds,
            float preferredDistance
    ) {
        this.archetype = archetype;
        this.ranged = ranged;
        this.hpMultiplier = hpMultiplier;
        this.speedMultiplier = speedMultiplier;
        this.radiusMultiplier = radiusMultiplier;
        this.attackCooldownSeconds = attackCooldownSeconds;
        this.preferredDistance = preferredDistance;
    }

    public static Enemy25DCombatProfile from(Enemy25DCatalog.Entry entry) {
        if (entry == null) throw new IllegalArgumentException("Entrée ennemie obligatoire.");

        String description = (entry.weapon + " " + entry.ability).toLowerCase(Locale.ROOT);
        boolean ranged = containsAny(description,
                "fusil", "mousquet", "arc ", "arbal", "pistolet", "tir", "salve", "tourelle",
                "mines", "projectile", "bombe", "artifice", "outils", "lance-grenade");
        boolean assassin = containsAny(description,
                "double lame", "deux lames", "dague", "furtiv", "esquive", "dash",
                "attaque dans le dos", "rapide", "bond");
        boolean controller = containsAny(description,
                "piège", "immobil", "contrôle", "zone", "tempête", "gel", "poison",
                "fumée", "aveug", "racine", "surcharge", "bourrasque", "signal lumineux");
        boolean bruiser = containsAny(description,
                "bouclier", "masse", "ancre", "lourde", "garde", "charge",
                "brise-garde", "projection", "renversement");

        if (entry.rank == Enemy25DCatalog.Rank.BOSS) {
            return new Enemy25DCombatProfile(
                    Archetype.BOSS,
                    ranged,
                    1.20f,
                    ranged ? 0.98f : 1.05f,
                    1.15f,
                    ranged ? 0.82f : 0.74f,
                    ranged ? 225f : 82f
            );
        }

        Archetype archetype;
        if (ranged) archetype = Archetype.RANGED;
        else if (assassin) archetype = Archetype.ASSASSIN;
        else if (controller) archetype = Archetype.CONTROLLER;
        else if (bruiser) archetype = Archetype.BRUISER;
        else archetype = Archetype.BRUISER;

        float rankHp = entry.rank == Enemy25DCatalog.Rank.COMMANDER ? 1.55f : 1.28f;
        float rankRadius = entry.rank == Enemy25DCatalog.Rank.COMMANDER ? 1.10f : 1.02f;
        float rankCooldown = entry.rank == Enemy25DCatalog.Rank.COMMANDER ? 1.02f : 1.18f;

        return switch (archetype) {
            case RANGED -> new Enemy25DCombatProfile(
                    archetype, true, rankHp * 0.92f, 0.96f, rankRadius * 0.94f,
                    rankCooldown + 0.22f, 205f);
            case ASSASSIN -> new Enemy25DCombatProfile(
                    archetype, false, rankHp * 0.88f, 1.24f, rankRadius * 0.92f,
                    Math.max(0.72f, rankCooldown - 0.22f), 58f);
            case CONTROLLER -> new Enemy25DCombatProfile(
                    archetype, false, rankHp, 0.98f, rankRadius,
                    rankCooldown + 0.12f, 92f);
            case BRUISER -> new Enemy25DCombatProfile(
                    archetype, false, rankHp * 1.12f, 0.92f, rankRadius * 1.12f,
                    rankCooldown, 68f);
            case BOSS -> throw new IllegalStateException("Profil boss déjà traité.");
        };
    }

    private static boolean containsAny(String value, String... tokens) {
        for (String token : tokens) {
            if (value.contains(token)) return true;
        }
        return false;
    }
}
