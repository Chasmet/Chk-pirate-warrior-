package fr.chk.piratewarrior;

import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Rect;
import android.graphics.RectF;

import java.io.IOException;
import java.io.InputStream;
import java.util.EnumMap;
import java.util.Map;

/**
 * Chargeur léger des bandes d'animation 2.5D placées dans app/src/main/assets.
 *
 * La planche sheet.webp reste la fiche de référence artistique. Le moteur charge des bandes
 * séparées afin de ne conserver en mémoire que les animations réellement utilisées.
 */
public final class SpriteStrip25D {
    public enum Direction {
        FRONT("front"), BACK("back"), LEFT("left"), RIGHT("right");

        final String folder;

        Direction(String folder) {
            this.folder = folder;
        }
    }

    public enum Animation {
        IDLE("idle", 4, 4.5f),
        WALK("walk", 6, 9f),
        RUN("run", 6, 13f),
        ATTACK("attack", 6, 15f),
        POWER("power", 8, 12f),
        SPECIAL("special", 8, 12f),
        DODGE("dodge", 5, 15f),
        HURT("hurt", 4, 11f),
        KNOCKBACK("knockback", 5, 9f),
        DEFEAT("defeat", 8, 8f),
        INTRO("intro", 8, 7f),
        RAGE("rage", 8, 10f),
        PHASE2("phase2", 8, 9f),
        AREA_ATTACK("area_attack", 8, 12f),
        ULTIMATE("ultimate", 12, 13f);

        final String fileName;
        final int expectedFrames;
        final float framesPerSecond;

        Animation(String fileName, int expectedFrames, float framesPerSecond) {
            this.fileName = fileName;
            this.expectedFrames = expectedFrames;
            this.framesPerSecond = framesPerSecond;
        }
    }

    private static final int CELL_SIZE = 256;

    private final String characterFolder;
    private final Map<Direction, Map<Animation, Bitmap>> strips = new EnumMap<>(Direction.class);
    private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG | Paint.FILTER_BITMAP_FLAG);
    private boolean released;

    public SpriteStrip25D(String characterFolder) {
        this.characterFolder = characterFolder;
        for (Direction direction : Direction.values()) {
            strips.put(direction, new EnumMap<>(Animation.class));
        }
    }

    public boolean load(AssetManager assets, Direction direction, Animation animation) {
        if (released || assets == null || direction == null || animation == null) return false;
        Map<Animation, Bitmap> directionStrips = strips.get(direction);
        if (directionStrips.containsKey(animation)) return true;

        String path = assetPath(characterFolder, direction, animation);
        try (InputStream input = assets.open(path)) {
            Bitmap bitmap = BitmapFactory.decodeStream(input);
            if (bitmap == null || bitmap.getHeight() < CELL_SIZE || bitmap.getWidth() < CELL_SIZE) {
                return false;
            }
            directionStrips.put(animation, bitmap);
            return true;
        } catch (IOException ignored) {
            return false;
        }
    }

    public boolean draw(
            Canvas canvas,
            Direction direction,
            Animation animation,
            float animationSeconds,
            float centerX,
            float feetY,
            float height,
            float alpha
    ) {
        if (released || canvas == null || direction == null || animation == null) return false;
        Bitmap strip = strips.get(direction).get(animation);
        if (strip == null) return false;

        int availableFrames = Math.max(1, strip.getWidth() / CELL_SIZE);
        int frameCount = Math.min(animation.expectedFrames, availableFrames);
        int frame = Math.max(0, (int) (animationSeconds * animation.framesPerSecond)) % frameCount;
        Rect source = new Rect(frame * CELL_SIZE, 0, (frame + 1) * CELL_SIZE, CELL_SIZE);
        float width = height;
        RectF destination = new RectF(centerX - width * 0.5f, feetY - height, centerX + width * 0.5f, feetY);
        paint.setAlpha((int) (GameMath.clamp(alpha, 0f, 1f) * 255f));
        canvas.drawBitmap(strip, source, destination, paint);
        paint.setAlpha(255);
        return true;
    }

    public void release() {
        if (released) return;
        released = true;
        for (Map<Animation, Bitmap> directionStrips : strips.values()) {
            for (Bitmap bitmap : directionStrips.values()) {
                if (bitmap != null && !bitmap.isRecycled()) bitmap.recycle();
            }
            directionStrips.clear();
        }
    }

    static String assetPath(String characterFolder, Direction direction, Animation animation) {
        return characterFolder + "/animations/" + direction.folder + "/" + animation.fileName + ".webp";
    }
}
