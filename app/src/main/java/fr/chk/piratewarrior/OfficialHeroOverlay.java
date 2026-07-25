package fr.chk.piratewarrior;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Rect;
import android.graphics.RectF;
import android.view.View;

import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Field;

/**
 * Affiche les trois héros validés au-dessus du fallback procédural.
 * Les bitmaps sont chargés une seule fois puis libérés lors du détachement de la vue.
 */
public final class OfficialHeroOverlay extends View {
    private static final String[] HERO_ASSETS = {
            "heroes25d/cheikh/idle_front.webp",
            "heroes25d/yvane/idle_front.webp",
            "heroes25d/nelvyn/idle_front.webp"
    };
    private static final int[] HERO_COLORS = {
            Color.rgb(222, 80, 46), Color.rgb(58, 179, 255), Color.rgb(66, 204, 130)
    };

    private final PirateGameViewV2 gameView;
    private final Bitmap[] heroes = new Bitmap[3];
    private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG | Paint.FILTER_BITMAP_FLAG);
    private final Paint auraPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Rect source = new Rect();
    private final RectF destination = new RectF();

    private Field screenField;
    private Field runningField;
    private Field selectedHeroField;
    private Field playerXField;
    private Field playerYField;
    private Field playerVXField;
    private Field cameraXField;
    private Field jumpHeightField;
    private Field attackTimeField;
    private Field hurtTimeField;
    private Field auraTimeField;
    private Field animationTimeField;
    private boolean reflectionReady;

    public OfficialHeroOverlay(Context context, PirateGameViewV2 gameView) {
        super(context);
        this.gameView = gameView;
        setClickable(false);
        setFocusable(false);
        setWillNotDraw(false);
        loadAssets(context);
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        if (!ensureReflection()) {
            postInvalidateOnAnimation();
            return;
        }
        try {
            Object screen = screenField.get(gameView);
            boolean running = runningField.getBoolean(gameView);
            if (!running || screen == null || !"GAME".equals(screen.toString())) {
                postInvalidateOnAnimation();
                return;
            }

            int heroIndex = Math.max(0, Math.min(2, selectedHeroField.getInt(gameView)));
            Bitmap bitmap = heroes[heroIndex];
            if (bitmap == null || bitmap.isRecycled()) {
                postInvalidateOnAnimation();
                return;
            }

            float playerX = playerXField.getFloat(gameView);
            float playerY = playerYField.getFloat(gameView);
            float playerVX = playerVXField.getFloat(gameView);
            float cameraX = cameraXField.getFloat(gameView);
            float jumpHeight = jumpHeightField.getFloat(gameView);
            float attackTime = attackTimeField.getFloat(gameView);
            float hurtTime = hurtTimeField.getFloat(gameView);
            float auraTime = auraTimeField.getFloat(gameView);
            float animation = animationTimeField.getFloat(gameView);

            float screenX = playerX - cameraX;
            float depth = GameMath.clamp((playerY - getHeight() * 0.30f)
                    / Math.max(1f, getHeight() * 0.62f), 0f, 1f);
            float height = 154f + depth * 55f;
            float width = height * bitmap.getWidth() / Math.max(1f, bitmap.getHeight());
            float bob = Math.abs(playerVX) > 7f ? (float) Math.sin(animation * 10f) * 3.2f
                    : (float) Math.sin(animation * 4f) * 1.5f;
            float feetY = playerY - jumpHeight - bob;
            float lean = attackTime > 0f ? (playerVX < 0f ? -7f : 7f) : 0f;

            if (auraTime > 0f) {
                int color = HERO_COLORS[heroIndex];
                auraPaint.setColor(Color.argb(58, Color.red(color), Color.green(color), Color.blue(color)));
                canvas.drawCircle(screenX, feetY - height * 0.48f,
                        height * (0.43f + (float) Math.sin(animation * 8f) * 0.025f), auraPaint);
            }

            source.set(0, 0, bitmap.getWidth(), bitmap.getHeight());
            destination.set(screenX - width * 0.5f, feetY - height,
                    screenX + width * 0.5f, feetY);
            paint.setAlpha(hurtTime > 0f && ((int) (animation * 18f) & 1) == 0 ? 135 : 255);

            boolean facingRight = Math.abs(playerVX) < 5f || playerVX >= 0f;
            canvas.save();
            canvas.rotate(lean, screenX, feetY);
            if (facingRight) {
                canvas.drawBitmap(bitmap, source, destination, paint);
            } else {
                canvas.scale(-1f, 1f, screenX, feetY);
                canvas.drawBitmap(bitmap, source, destination, paint);
            }
            canvas.restore();
            paint.setAlpha(255);
        } catch (ReflectiveOperationException | RuntimeException ignored) {
            // Le fallback Character25D reste visible si le moteur change.
        }
        postInvalidateOnAnimation();
    }

    @Override
    protected void onDetachedFromWindow() {
        for (int i = 0; i < heroes.length; i++) {
            Bitmap bitmap = heroes[i];
            if (bitmap != null && !bitmap.isRecycled()) bitmap.recycle();
            heroes[i] = null;
        }
        super.onDetachedFromWindow();
    }

    private void loadAssets(Context context) {
        for (int i = 0; i < HERO_ASSETS.length; i++) {
            try (InputStream stream = context.getAssets().open(HERO_ASSETS[i])) {
                heroes[i] = BitmapFactory.decodeStream(stream);
            } catch (IOException ignored) {
                heroes[i] = null;
            }
        }
    }

    private boolean ensureReflection() {
        if (reflectionReady) return true;
        try {
            Class<?> type = gameView.getClass();
            screenField = field(type, "screen");
            runningField = field(type, "running");
            selectedHeroField = field(type, "selectedHero");
            playerXField = field(type, "playerX");
            playerYField = field(type, "playerY");
            playerVXField = field(type, "playerVX");
            cameraXField = field(type, "cameraX");
            jumpHeightField = field(type, "jumpHeight");
            attackTimeField = field(type, "attackTime");
            hurtTimeField = field(type, "hurtTime");
            auraTimeField = field(type, "auraTime");
            animationTimeField = field(type, "animationTime");
            reflectionReady = true;
        } catch (ReflectiveOperationException ignored) {
            reflectionReady = false;
        }
        return reflectionReady;
    }

    private static Field field(Class<?> type, String name) throws NoSuchFieldException {
        Field result = type.getDeclaredField(name);
        result.setAccessible(true);
        return result;
    }
}
