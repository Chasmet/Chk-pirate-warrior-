package fr.chk.piratewarrior;

import android.content.Context;
import android.widget.FrameLayout;

/**
 * Conserve le moteur V2, les assets officiels et ajoute les pouvoirs et la navigation sans repartir de zéro.
 */
public final class PirateGameContainer extends FrameLayout {
    private final PirateGameViewV2 gameView;

    public PirateGameContainer(Context context, PirateGameView.VoiceNarrator narrator) {
        super(context);
        gameView = new PirateGameViewV2(context, narrator);
        PirateGameAssetOverlay assetOverlay = new PirateGameAssetOverlay(context, gameView);
        HeroPowerOverlay powerOverlay = new HeroPowerOverlay(context, gameView);
        BoatTravelOverlay boatOverlay = new BoatTravelOverlay(context, gameView);

        addView(gameView, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
        addView(assetOverlay, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
        addView(powerOverlay, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
        addView(boatOverlay, new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
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
