package fr.chk.piratewarrior;

import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Rect;
import android.graphics.RectF;
import android.util.Log;

import java.io.IOException;
import java.io.InputStream;
import java.util.EnumMap;
import java.util.Map;

/**
 * Chargeur léger des bandes d'animation 2.5D placées dans app/src/main/assets.
 *
 * Chaque bande est validée avant d'entrer dans le cache. Un fichier absent ou invalide ne fait
 * jamais planter le jeu : l'erreur est journalisée et le moteur peut conserver son fallback.
 */
public final class SpriteStrip25D {
    private static final String TAG = "SpriteStrip25D";

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

    public static final int CELL_SIZE = 256;

    private final String characterFolder;
    private final Map<Direction, Map<Animation, Bitmap>> strips = new EnumMap<>(Direction.class);
    private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG | Paint.FILTER_BITMAP_FLAG);
    private boolean released;
    private int loadedAnimationCount;

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
            if (!isValidStrip(bitmap, animation)) {
                if (bitmap != null && !bitmap.isRecycled()) bitmap.recycle();
                Log.w(TAG, "Bande 2.5D invalide : " + path
                        + " (cellule attendue 256x256, frames=" + animation.expectedFrames + ")");
                return false;
            }
            directionStrips.put(animation, bitmap);
            loadedAnimationCount++;
            return true;
        } catch (IOException exception) {
            Log.w(TAG, "Asset 2.5D manquant : " + path);
            return false;
        } catch (RuntimeException exception) {
            Log.e(TAG, "Échec du décodage 2.5D : " + path, exception);
            return false;
        }
    }

    public boolean isLoaded(Direction direction, Animation animation) {
        if (released || direction == null || animation == null) return false;
        Bitmap bitmap = strips.get(direction).get(animation);
        return bitmap != null && !bitmap.isRecycled();
    }

    public int loadedAnimationCount() {
        return loadedAnimationCount;
    }

    public boolean hasAnyAnimation() {
        return loadedAnimationCount > 0;
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
        if (strip == null || strip.isRecycled()) return false;

        int frameCount = animation.expectedFrames;
        int frame = Math.max(0, (int) (animationSeconds * animation.framesPerSecond)) % frameCount;
        Rect source = new Rect(frame * CELL_SIZE, 0, (frame + 1) * CELL_SIZE, CELL_SIZE);
        float width = height;
        RectF destination = new RectF(centerX - width * 0.5f, feetY - height,
                centerX + width * 0.5f, feetY);
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
        loadedAnimationCount = 0;
    }

    private static boolean isValidStrip(Bitmap bitmap, Animation animation) {
        if (bitmap == null || bitmap.isRecycled()) return false;
        if (bitmap.getHeight() != CELL_SIZE) return false;
        if (bitmap.getWidth() % CELL_SIZE != 0) return false;
        int frames = bitmap.getWidth() / CELL_SIZE;
        return frames == animation.expectedFrames;
    }

    static String assetPath(String characterFolder, Direction direction, Animation animation) {
        return characterFolder + "/animations/" + direction.folder + "/"
                + animation.fileName + ".webp";
    }
}
