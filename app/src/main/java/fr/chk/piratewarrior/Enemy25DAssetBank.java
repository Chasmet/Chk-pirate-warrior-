package fr.chk.piratewarrior;

import android.content.res.AssetManager;

import java.util.HashMap;
import java.util.Map;

/**
 * Cache par île des personnages 2.5D ennemis.
 *
 * Le cache ne conserve jamais les 42 personnages en mémoire en même temps. Lors d'un changement
 * d'île, toutes les textures précédentes sont libérées avant de préparer le nouveau groupe.
 */
public final class Enemy25DAssetBank {
    private final AssetManager assets;
    private final Map<String, SpriteStrip25D> loaded = new HashMap<>();
    private int loadedIsland = -1;

    public Enemy25DAssetBank(AssetManager assets) {
        this.assets = assets;
    }

    public void prepareIsland(int islandIndex) {
        int safeIsland = Math.max(0, Math.min(Enemy25DCatalog.ISLAND_COUNT - 1, islandIndex));
        if (safeIsland == loadedIsland) return;

        releaseAll();
        loadedIsland = safeIsland;

        prepare(Enemy25DCatalog.bossForIsland(safeIsland), true);
        for (Enemy25DCatalog.Entry entry : Enemy25DCatalog.commandersForIsland(safeIsland)) {
            prepare(entry, false);
        }
        for (Enemy25DCatalog.Entry entry : Enemy25DCatalog.subordinatesForIsland(safeIsland)) {
            prepare(entry, false);
        }
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

    public void releaseAll() {
        for (SpriteStrip25D strip : loaded.values()) {
            strip.release();
        }
        loaded.clear();
        loadedIsland = -1;
    }

    private void prepare(Enemy25DCatalog.Entry entry, boolean boss) {
        String folder = entry.sheetAssetPath.substring(0, entry.sheetAssetPath.length() - "/sheet.webp".length());
        SpriteStrip25D strip = new SpriteStrip25D(folder);

        for (SpriteStrip25D.Direction direction : SpriteStrip25D.Direction.values()) {
            strip.load(assets, direction, SpriteStrip25D.Animation.IDLE);
            strip.load(assets, direction, SpriteStrip25D.Animation.WALK);
            strip.load(assets, direction, SpriteStrip25D.Animation.ATTACK);
            strip.load(assets, direction, SpriteStrip25D.Animation.HURT);
        }

        if (boss) {
            strip.load(assets, SpriteStrip25D.Direction.FRONT, SpriteStrip25D.Animation.INTRO);
            strip.load(assets, SpriteStrip25D.Direction.FRONT, SpriteStrip25D.Animation.PHASE2);
            strip.load(assets, SpriteStrip25D.Direction.FRONT, SpriteStrip25D.Animation.ULTIMATE);
        }

        loaded.put(entry.id, strip);
    }
}
