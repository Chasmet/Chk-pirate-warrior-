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

/** Charge un seul atlas PDF à la fois et anime légèrement ses personnages dans le monde. */
public final class PdfAtlas25D {
    private static final int COLUMNS = 4;
    private static final int ROWS = 2;

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

        int cellWidth = atlas.getWidth() / COLUMNS;
        int cellHeight = atlas.getHeight() / ROWS;
        int column = entry.atlasSlot % COLUMNS;
        int row = entry.atlasSlot / COLUMNS;
        Rect source = new Rect(
                column * cellWidth,
                row * cellHeight,
                (column + 1) * cellWidth,
                Math.min(atlas.getHeight(), (row + 1) * cellHeight)
        );

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

    public int loadedIsland() {
        return loadedIsland;
    }

    public void release() {
        if (atlas != null && !atlas.isRecycled()) atlas.recycle();
        atlas = null;
        loadedIsland = -1;
    }
}
