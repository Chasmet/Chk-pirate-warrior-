package fr.chk.piratewarrior;

import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Rect;
import android.graphics.RectF;
import android.util.Base64;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;

/** Charge un seul atlas de référence à la fois et anime légèrement ses personnages dans le monde. */
public final class PdfAtlas25D {
    private static final int COLUMNS = 4;
    private static final int ROWS = 2;
    private static final int CAKE_ISLAND_INDEX = 6;
    private static final int CAKE_SOURCE_WIDTH = 1536;
    private static final int CAKE_SOURCE_HEIGHT = 1024;

    /** Rectangles issus directement de la planche de personnages reçue pour l'île 7. */
    private static final int[][] CAKE_SOURCE_RECTS = {
            {380, 60, 1050, 860},
            {80, 320, 420, 865},
            {540, 400, 860, 865},
            {1160, 290, 1515, 870},
            {770, 260, 1020, 760},
            {10, 430, 190, 870},
            {960, 360, 1245, 870}
    };

    private final AssetManager assets;
    private final Paint bitmapPaint = new Paint(Paint.ANTI_ALIAS_FLAG | Paint.FILTER_BITMAP_FLAG);
    private final Paint shadowPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private Bitmap atlas;
    private int loadedIsland = -1;

    public PdfAtlas25D(AssetManager assets) {
        this.assets = assets;
        shadowPaint.setColor(Color.argb(105, 0, 0, 0));
    }

    public boolean prepareIsland(int islandIndex) {
        int safe = Math.max(0, Math.min(PdfAssetCatalog.ISLAND_COUNT - 1, islandIndex));
        if (safe == loadedIsland && atlas != null && !atlas.isRecycled()) return true;
        release();
        try (InputStream input = assets.open(PdfAssetCatalog.atlasAssetPath(safe));
             ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            byte[] buffer = new byte[8192];
            int read;
            while ((read = input.read(buffer)) != -1) output.write(buffer, 0, read);
            byte[] encoded = output.toByteArray();
            byte[] decoded = Base64.decode(encoded, Base64.DEFAULT);
            atlas = BitmapFactory.decodeByteArray(decoded, 0, decoded.length);
            if (atlas == null) return false;
            loadedIsland = safe;
            return true;
        } catch (IOException | IllegalArgumentException ignored) {
            release();
            return false;
        }
    }

    public boolean draw(
            Canvas canvas,
            PdfAssetCatalog.Entry entry,
            float animationSeconds,
            float centerX,
            float feetY,
            float height,
            float horizontalSpeed,
            float hitTime,
            boolean defeated
    ) {
        if (canvas == null || entry == null || atlas == null || atlas.isRecycled()) return false;
        if (entry.islandIndex != loadedIsland) return false;

        Rect source = sourceRect(entry.atlasSlot);
        float bob = defeated ? 0f : (float) Math.sin(animationSeconds * 5.1f + entry.atlasSlot) * 2.8f;
        float movement = Math.min(1f, Math.abs(horizontalSpeed) / 120f);
        float lean = defeated ? 72f : horizontalSpeed * 0.025f;
        float squashX = 1f + movement * 0.045f;
        float squashY = 1f - movement * 0.025f;
        if (hitTime > 0f) {
            squashX *= 1.08f;
            squashY *= 0.94f;
        }

        float width = height * 0.78f;
        if (loadedIsland == CAKE_ISLAND_INDEX) {
            float ratio = source.width() / (float) Math.max(1, source.height());
            width = height * GameMath.clamp(ratio * 0.92f, 0.58f, 1.12f);
        }
        RectF destination = new RectF(-width * 0.5f, -height, width * 0.5f, 0f);

        canvas.save();
        canvas.translate(centerX, feetY + bob);
        canvas.rotate(lean);
        canvas.scale(horizontalSpeed < -4f ? -squashX : squashX, squashY);
        canvas.drawOval(new RectF(-width * 0.42f, -height * 0.055f, width * 0.42f, height * 0.035f), shadowPaint);
        bitmapPaint.setAlpha(defeated ? 145 : 255);
        canvas.drawBitmap(atlas, source, destination, bitmapPaint);
        bitmapPaint.setAlpha(255);
        canvas.restore();
        return true;
    }

    private Rect sourceRect(int atlasSlot) {
        boolean rawCakeBoard = loadedIsland == CAKE_ISLAND_INDEX
                && atlas.getWidth() >= 1000
                && atlas.getHeight() >= 600;
        if (rawCakeBoard && atlasSlot >= 0 && atlasSlot < CAKE_SOURCE_RECTS.length) {
            int[] source = CAKE_SOURCE_RECTS[atlasSlot];
            float scaleX = atlas.getWidth() / (float) CAKE_SOURCE_WIDTH;
            float scaleY = atlas.getHeight() / (float) CAKE_SOURCE_HEIGHT;
            return new Rect(
                    clamp(Math.round(source[0] * scaleX), 0, atlas.getWidth() - 1),
                    clamp(Math.round(source[1] * scaleY), 0, atlas.getHeight() - 1),
                    clamp(Math.round(source[2] * scaleX), 1, atlas.getWidth()),
                    clamp(Math.round(source[3] * scaleY), 1, atlas.getHeight())
            );
        }

        int safeSlot = Math.max(0, Math.min(COLUMNS * ROWS - 1, atlasSlot));
        int cellWidth = atlas.getWidth() / COLUMNS;
        int cellHeight = atlas.getHeight() / ROWS;
        int column = safeSlot % COLUMNS;
        int row = safeSlot / COLUMNS;
        return new Rect(
                column * cellWidth,
                row * cellHeight,
                (column + 1) * cellWidth,
                Math.min(atlas.getHeight(), (row + 1) * cellHeight)
        );
    }

    private static int clamp(int value, int min, int max) {
        return Math.max(min, Math.min(max, value));
    }

    public int loadedIsland() {
        return loadedIsland;
    }

    public void release() {
        if (atlas != null && !atlas.isRecycled()) atlas.recycle();
        atlas = null;
        loadedIsland = -1;
    }
}
