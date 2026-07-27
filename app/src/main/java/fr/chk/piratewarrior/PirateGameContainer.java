package fr.chk.piratewarrior;

import android.content.Context;
import android.widget.FrameLayout;

/**
 * Conserve le moteur V2 et superpose les améliorations V5.5 sans repartir de zéro.
 */
public final class PirateGameContainer extends FrameLayout {
    private final PirateGameViewV2 gameView;

    public PirateGameContainer(Context context, PirateGameView.VoiceNarrator narrator) {
        super(context);
        gameView = new PirateGameViewV2(context, narrator);
        ExtendedIslandOverlay extendedIslandOverlay = new ExtendedIslandOverlay(context, gameView);
        OfficialHeroOverlay heroOverlay = new OfficialHeroOverlay(context, gameView);
        PirateGameAssetOverlay assetOverlay = new PirateGameAssetOverlay(context, gameView);
        V55EnemyAbilityOverlay enemyAbilityOverlay = new V55EnemyAbilityOverlay(context, gameView);
        V55HeroPowerOverlay powerOverlay = new V55HeroPowerOverlay(context, gameView);
        WorldMapOverlay mapOverlay = new WorldMapOverlay(context, gameView);
        OceanTravelOverlay oceanOverlay = new OceanTravelOverlay(context, gameView);

        addView(gameView, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
        // Les îles supplémentaires restent sous les personnages officiels.
        addView(extendedIslandOverlay, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
        addView(heroOverlay, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
        addView(assetOverlay, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
        // Les télégraphes ennemis sont visibles au-dessus des sprites, sans masquer les contrôles.
        addView(enemyAbilityOverlay, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
        addView(powerOverlay, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
        addView(mapOverlay, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
        addView(oceanOverlay, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
    }

    public void onVoiceReady() {
        gameView.onVoiceReady();
    }

    public void pauseGameLoop() {
        gameView.pauseGameLoop();
    }

    public void resumeGameLoop() {
        gameView.resumeGameLoop();
    }
}
