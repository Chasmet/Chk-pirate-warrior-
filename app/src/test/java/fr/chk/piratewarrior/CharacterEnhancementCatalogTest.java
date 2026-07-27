package fr.chk.piratewarrior;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;

import org.junit.Test;

public final class CharacterEnhancementCatalogTest {
    @Test
    public void everyOfficialCharacterHasSevenAnimationsAndTwoPowers() {
        assertEquals(Enemy25DCatalog.EXPECTED_TOTAL + 3, CharacterEnhancementCatalog.all().size());
        for (CharacterEnhancementCatalog.Spec spec : CharacterEnhancementCatalog.all()) {
            assertEquals(spec.displayName, 7, spec.animations.size());
            assertEquals(spec.displayName, 2, spec.powers.size());
        }
    }

    @Test
    public void officialHeroesAndBrakorRemainPresent() {
        assertNotNull(CharacterEnhancementCatalog.byId("cheikh"));
        assertNotNull(CharacterEnhancementCatalog.byId("yvane"));
        assertNotNull(CharacterEnhancementCatalog.byId("nelvyn"));
        assertNotNull(CharacterEnhancementCatalog.byId("brakor"));
    }
}
