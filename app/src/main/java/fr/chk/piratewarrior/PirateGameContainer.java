package fr.chk.piratewarrior;

import android.content.Context;
import android.widget.FrameLayout;

/**
 * Conserve le moteur V2, les assets officiels et ajoute héros, pouvoirs, carte et navigation
 * sans repartir de zéro.
 */
public final class PirateGameContainer extends FrameLayout {
    private final PirateGameViewV2 gameView;

    public PirateGameContainer(Context context, PirateGameView.VoiceNarrator narrator) {
        super(context);
        gameView = new PirateGameViewV2(context, narrator);
        ExtendedIslandOverlay extendedIslandOverlay = new ExtendedIslandOverlay(context, gameView);
        OfficialHeroOverlay heroOverlay = new OfficialHeroOverlay(context, gameView);
        PirateGameAssetOverlay assetOverlay = new PirateGameAssetOverlay(context, gameView);
        HeroPowerOverlay powerOverlay = new HeroPowerOverlay(context, gameView);
        WorldMapOverlay mapOverlay = new WorldMapOverlay(context, gameView);
        OceanTravelOverlay oceanOverlay = new OceanTravelOverlay(context, gameView);

        addView(gameView, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
        // Recouvre uniquement les îles 7 et 8, puis laisse les héros et ennemis officiels au-dessus.
        addView(extendedIslandOverlay, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
        addView(heroOverlay, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
        addView(assetOverlay, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
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
