package fr.chk.piratewarrior;

import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
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
    private static final int SKULL_ISLAND_INDEX = 7;
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
        int safe = WorldConfig.clampIsland(islandIndex);
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
            if (atlas == null) return prepareFallback(safe);
            loadedIsland = safe;
            return true;
        } catch (IOException | IllegalArgumentException ignored) {
            return prepareFallback(safe);
        }
    }

    private boolean prepareFallback(int island) {
        release();
        if (island != SKULL_ISLAND_INDEX) return false;
        atlas = createSkullFallbackAtlas();
        loadedIsland = atlas == null ? -1 : island;
        return atlas != null;
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
        if (loadedIsland == CAKE_ISLAND_INDEX || loadedIsland == SKULL_ISLAND_INDEX) {
            float ratio = source.width() / (float) Math.max(1, source.height());
            width = height * GameMath.clamp(ratio * 0.92f, 0.58f, 1.12f);
        }
        RectF destination = new RectF(-width * 0.5f, -height, width * 0.5f, 0f);

        canvas.save();
        canvas.translate(centerX, feetY + bob);
        canvas.rotate(lean);
        canvas.scale(horizontalSpeed < -4f ? -squashX : squashX, squashY);
        canvas.drawOval(new RectF(-width * 0.42f, -height * 0.055f,
                width * 0.42f, height * 0.035f), shadowPaint);
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

    /**
     * Fallback de sécurité : reprend les silhouettes, cornes, ailes et palettes de la planche reçue.
     * Il est remplacé automatiquement dès que l'atlas WEBP officiel est présent dans les assets.
     */
    private Bitmap createSkullFallbackAtlas() {
        final int cell = 256;
        Bitmap result = Bitmap.createBitmap(cell * COLUMNS, cell * ROWS, Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(result);
        Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        Path path = new Path();
        for (int slot = 0; slot < 7; slot++) {
            float ox = (slot % COLUMNS) * cell;
            float oy = (slot / COLUMNS) * cell;
            drawSkullCharacter(canvas, paint, path, slot, ox, oy, cell);
        }
        return result;
    }

    private void drawSkullCharacter(Canvas canvas, Paint paint, Path path,
                                    int slot, float ox, float oy, float cell) {
        float cx = ox + cell * 0.5f;
        float feet = oy + cell * 0.94f;
        float scale = slot == 0 ? 1.16f : slot == 1 ? 1.03f : 0.92f;
        int main = switch (slot) {
            case 0 -> Color.rgb(68, 43, 82);
            case 1 -> Color.rgb(20, 24, 35);
            case 2, 6 -> Color.rgb(78, 54, 38);
            case 3 -> Color.rgb(48, 52, 60);
            case 4 -> Color.rgb(205, 145, 38);
            case 5 -> Color.rgb(67, 39, 91);
            default -> Color.rgb(55, 43, 47);
        };
        int accent = slot == 5 ? Color.rgb(183, 132, 225) : Color.rgb(255, 119, 35);

        paint.setColor(Color.argb(90, 0, 0, 0));
        canvas.drawOval(new RectF(cx - 55f * scale, feet - 8f,
                cx + 55f * scale, feet + 8f), paint);

        if (slot == 1) {
            paint.setColor(Color.rgb(19, 22, 31));
            path.reset();
            path.moveTo(cx - 25f, feet - 135f);
            path.lineTo(cx - 90f, feet - 40f);
            path.lineTo(cx - 34f, feet - 55f);
            path.close();
            canvas.drawPath(path, paint);
            path.reset();
            path.moveTo(cx + 25f, feet - 135f);
            path.lineTo(cx + 90f, feet - 40f);
            path.lineTo(cx + 34f, feet - 55f);
            path.close();
            canvas.drawPath(path, paint);
        }

        paint.setColor(main);
        canvas.drawRoundRect(new RectF(cx - 45f * scale, feet - 145f * scale,
                cx + 45f * scale, feet - 35f), 22f, 22f, paint);
        paint.setColor(Color.rgb(198, 146, 112));
        canvas.drawCircle(cx, feet - 166f * scale, 31f * scale, paint);

        paint.setColor(Color.rgb(224, 216, 198));
        paint.setStrokeWidth(10f);
        paint.setStyle(Paint.Style.STROKE);
        RectF leftHorn = new RectF(cx - 65f * scale, feet - 210f * scale,
                cx - 8f, feet - 150f * scale);
        RectF rightHorn = new RectF(cx + 8f, feet - 210f * scale,
                cx + 65f * scale, feet - 150f * scale);
        canvas.drawArc(leftHorn, 175f, 165f, false, paint);
        canvas.drawArc(rightHorn, 200f, 165f, false, paint);
        paint.setStyle(Paint.Style.FILL);

        paint.setColor(Color.rgb(34, 27, 29));
        canvas.drawCircle(cx - 10f, feet - 170f * scale, 4f, paint);
        canvas.drawCircle(cx + 10f, feet - 170f * scale, 4f, paint);

        if (slot == 0 || slot == 2) {
            paint.setColor(Color.rgb(65, 46, 37));
            canvas.save();
            canvas.rotate(-34f, cx, feet - 105f);
            canvas.drawRoundRect(new RectF(cx - 10f, feet - 220f,
                    cx + 10f, feet - 15f), 8f, 8f, paint);
            canvas.restore();
        } else if (slot == 3) {
            paint.setColor(Color.rgb(34, 37, 43));
            canvas.drawRoundRect(new RectF(cx + 24f, feet - 126f,
                    cx + 78f, feet - 96f), 10f, 10f, paint);
            paint.setColor(accent);
            canvas.drawCircle(cx + 76f, feet - 111f, 9f, paint);
        } else if (slot == 5) {
            paint.setColor(accent);
            paint.setStrokeWidth(7f);
            canvas.drawLine(cx - 45f, feet - 40f, cx + 43f, feet - 195f, paint);
        }

        paint.setColor(Color.argb(180, Color.red(accent), Color.green(accent), Color.blue(accent)));
        canvas.drawCircle(cx, feet - 112f, slot == 0 ? 15f : 9f, paint);
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
