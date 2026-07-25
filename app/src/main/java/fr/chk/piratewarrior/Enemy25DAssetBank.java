package fr.chk.piratewarrior;

import android.content.res.AssetManager;
import android.util.Log;

import java.util.HashMap;
import java.util.Map;

/**
 * Cache par île des personnages 2.5D ennemis.
 *
 * Le cache ne conserve jamais les 42 personnages en mémoire. Lors d'un changement d'île, toutes
 * les textures précédentes sont libérées avant de préparer le boss, les trois commandants et les
 * trois subordonnés de la nouvelle île. Les fichiers manquants sont signalés sans faire planter le
 * jeu ; le rendu appelant peut alors utiliser Character25D ou un autre fallback léger.
 */
public final class Enemy25DAssetBank {
    private static final String TAG = "Enemy25DAssetBank";

    public static final class LoadReport {
        public final int islandIndex;
        public final int requestedCharacters;
        public final int charactersWithAssets;
        public final int loadedAnimations;

        LoadReport(int islandIndex, int requestedCharacters, int charactersWithAssets,
                   int loadedAnimations) {
            this.islandIndex = islandIndex;
            this.requestedCharacters = requestedCharacters;
            this.charactersWithAssets = charactersWithAssets;
            this.loadedAnimations = loadedAnimations;
        }

        public boolean hasCompleteRoster() {
            return requestedCharacters == 7 && charactersWithAssets == 7;
        }
    }

    private final AssetManager assets;
    private final Map<String, SpriteStrip25D> loaded = new HashMap<>();
    private int loadedIsland = -1;
    private LoadReport lastReport = new LoadReport(-1, 0, 0, 0);

    public Enemy25DAssetBank(AssetManager assets) {
        this.assets = assets;
    }

    public LoadReport prepareIsland(int islandIndex) {
        int safeIsland = Math.max(0, Math.min(Enemy25DCatalog.ISLAND_COUNT - 1, islandIndex));
        if (safeIsland == loadedIsland) return lastReport;

        releaseAll();
        loadedIsland = safeIsland;

        int charactersWithAssets = 0;
        int loadedAnimations = 0;

        int count = prepare(Enemy25DCatalog.bossForIsland(safeIsland), true);
        if (count > 0) charactersWithAssets++;
        loadedAnimations += count;

        for (Enemy25DCatalog.Entry entry : Enemy25DCatalog.commandersForIsland(safeIsland)) {
            count = prepare(entry, false);
            if (count > 0) charactersWithAssets++;
            loadedAnimations += count;
        }
        for (Enemy25DCatalog.Entry entry : Enemy25DCatalog.subordinatesForIsland(safeIsland)) {
            count = prepare(entry, false);
            if (count > 0) charactersWithAssets++;
            loadedAnimations += count;
        }

        lastReport = new LoadReport(safeIsland, 7, charactersWithAssets, loadedAnimations);
        if (!lastReport.hasCompleteRoster()) {
            Log.w(TAG, "Île " + (safeIsland + 1) + " : " + charactersWithAssets
                    + "/7 personnages disposent d'au moins une bande 2.5D. Fallback conservé.");
        } else {
            Log.i(TAG, "Île " + (safeIsland + 1) + " chargée : "
                    + loadedAnimations + " bandes 2.5D.");
        }
        return lastReport;
    }

    public SpriteStrip25D get(String characterId) {
        return loaded.get(characterId);
    }

    public int loadedCount() {
        return loaded.size();
    }

    public int loadedIsland() {
        return loadedIsland;
    }

    public LoadReport lastReport() {
        return lastReport;
    }

    public void releaseAll() {
        for (SpriteStrip25D strip : loaded.values()) strip.release();
        loaded.clear();
        loadedIsland = -1;
        lastReport = new LoadReport(-1, 0, 0, 0);
    }

    private int prepare(Enemy25DCatalog.Entry entry, boolean boss) {
        String folder = entry.sheetAssetPath.substring(
                0,
                entry.sheetAssetPath.length() - "/sheet.webp".length()
        );
        SpriteStrip25D strip = new SpriteStrip25D(folder);

        for (SpriteStrip25D.Direction direction : SpriteStrip25D.Direction.values()) {
            strip.load(assets, direction, SpriteStrip25D.Animation.IDLE);
            strip.load(assets, direction, SpriteStrip25D.Animation.WALK);
            strip.load(assets, direction, SpriteStrip25D.Animation.ATTACK);
            strip.load(assets, direction, SpriteStrip25D.Animation.HURT);
        }

        if (boss) {
            strip.load(assets, SpriteStrip25D.Direction.FRONT, SpriteStrip25D.Animation.INTRO);
            strip.load(assets, SpriteStrip25D.Direction.FRONT, SpriteStrip25D.Animation.RAGE);
            strip.load(assets, SpriteStrip25D.Direction.FRONT, SpriteStrip25D.Animation.PHASE2);
            strip.load(assets, SpriteStrip25D.Direction.FRONT, SpriteStrip25D.Animation.AREA_ATTACK);
            strip.load(assets, SpriteStrip25D.Direction.FRONT, SpriteStrip25D.Animation.ULTIMATE);
        }

        loaded.put(entry.id, strip);
        return strip.loadedAnimationCount();
    }
}
