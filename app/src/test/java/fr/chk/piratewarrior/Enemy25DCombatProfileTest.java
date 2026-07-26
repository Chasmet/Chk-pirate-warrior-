package fr.chk.piratewarrior;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

public final class Enemy25DCombatProfileTest {
    @Test
    public void brakorRemainsHeavyMeleeBoss() {
        Enemy25DCombatProfile profile = Enemy25DCombatProfile.from(
                Enemy25DCatalog.byId("brakor"));

        assertEquals(Enemy25DCombatProfile.Archetype.BOSS, profile.archetype);
        assertFalse(profile.ranged);
        assertTrue(profile.hpMultiplier > 1f);
        assertTrue(profile.radiusMultiplier > 1f);
    }

    @Test
    public void tireurDesQuaisUsesRangedProfile() {
        Enemy25DCombatProfile profile = Enemy25DCombatProfile.from(
                Enemy25DCatalog.byId("tireur_quais"));

        assertEquals(Enemy25DCombatProfile.Archetype.RANGED, profile.archetype);
        assertTrue(profile.ranged);
        assertTrue(profile.preferredDistance >= 200f);
    }

    @Test
    public void voleurAgileUsesAssassinProfile() {
        Enemy25DCombatProfile profile = Enemy25DCombatProfile.from(
                Enemy25DCatalog.byId("voleur_agile"));

        assertEquals(Enemy25DCombatProfile.Archetype.ASSASSIN, profile.archetype);
        assertFalse(profile.ranged);
        assertTrue(profile.speedMultiplier > 1.15f);
    }

    @Test
    public void voltKeepsTechnicalRangedGameplay() {
        Enemy25DCombatProfile profile = Enemy25DCombatProfile.from(
                Enemy25DCatalog.byId("volt"));

        assertEquals(Enemy25DCombatProfile.Archetype.RANGED, profile.archetype);
        assertTrue(profile.ranged);
    }

    @Test
    public void desertCommandersHaveDistinctCombatProfiles() {
        Enemy25DCombatProfile sabir = Enemy25DCombatProfile.from(
                Enemy25DCatalog.byId("sabir"));
        Enemy25DCombatProfile razka = Enemy25DCombatProfile.from(
                Enemy25DCatalog.byId("razka"));
        Enemy25DCombatProfile alVaris = Enemy25DCombatProfile.from(
                Enemy25DCatalog.byId("al_varis"));

        assertEquals(Enemy25DCombatProfile.Archetype.RANGED, sabir.archetype);
        assertTrue(sabir.ranged);
        assertEquals(Enemy25DCombatProfile.Archetype.ASSASSIN, razka.archetype);
        assertTrue(razka.speedMultiplier > 1.15f);
        assertEquals(Enemy25DCombatProfile.Archetype.RANGED, alVaris.archetype);
        assertTrue(alVaris.ranged);
    }

    @Test
    public void desertSubordinatesDoNotShareOneGenericProfile() {
        Enemy25DCombatProfile chaal = Enemy25DCombatProfile.from(
                Enemy25DCatalog.byId("chaal"));
        Enemy25DCombatProfile jaw = Enemy25DCombatProfile.from(
                Enemy25DCatalog.byId("machoire_desert"));
        Enemy25DCombatProfile watcher = Enemy25DCombatProfile.from(
                Enemy25DCatalog.byId("veilleuse_dunes"));

        assertEquals(Enemy25DCombatProfile.Archetype.ASSASSIN, chaal.archetype);
        assertEquals(Enemy25DCombatProfile.Archetype.BRUISER, jaw.archetype);
        assertEquals(Enemy25DCombatProfile.Archetype.CONTROLLER, watcher.archetype);
        assertTrue(chaal.speedMultiplier > jaw.speedMultiplier);
        assertTrue(jaw.hpMultiplier > chaal.hpMultiplier);
    }
}
