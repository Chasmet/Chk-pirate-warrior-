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
 * La V5.5 anime les bitmaps officiels par transformations légères sans modifier leur identité.
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
    private final Paint stroke = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Rect source = new Rect();
    private final RectF localDestination = new RectF();

    private Field screenField;
    private Field runningField;
    private Field selectedHeroField;
    private Field playerXField;
    private Field playerYField;
    private Field playerVXField;
    private Field playerVYField;
    private Field cameraXField;
    private Field cameraInputYField;
    private Field jumpHeightField;
    private Field attackTimeField;
    private Field hurtTimeField;
    private Field auraTimeField;
    private Field animationTimeField;
    private Field defeatedBossesField;
    private boolean reflectionReady;

    private long lastFrameNanos;
    private float previousJumpHeight;
    private float landingTime;
    private float victoryTime;
    private float idleTime;
    private int lastBosses = -1;

    public OfficialHeroOverlay(Context context, PirateGameViewV2 gameView) {
        super(context);
        this.gameView = gameView;
        stroke.setStyle(Paint.Style.STROKE);
        stroke.setStrokeCap(Paint.Cap.ROUND);
        setClickable(false);
        setFocusable(false);
        setWillNotDraw(false);
        loadAssets(context);
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        float dt = frameDelta();
        landingTime = Math.max(0f, landingTime - dt);
        victoryTime = Math.max(0f, victoryTime - dt);

        if (!ensureReflection()) {
            postInvalidateOnAnimation();
            return;
        }
        try {
            Object screen = screenField.get(gameView);
            boolean running = runningField.getBoolean(gameView);
            if (!running || screen == null || !"GAME".equals(screen.toString())) {
                idleTime = 0f;
                previousJumpHeight = 0f;
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
            float playerVY = playerVYField.getFloat(gameView);
            float cameraX = cameraXField.getFloat(gameView);
            float cameraInputY = cameraInputYField.getFloat(gameView);
            float jumpHeight = jumpHeightField.getFloat(gameView);
            float attackTime = attackTimeField.getFloat(gameView);
            float hurtTime = hurtTimeField.getFloat(gameView);
            float auraTime = auraTimeField.getFloat(gameView);
            float animation = animationTimeField.getFloat(gameView);
            int bosses = defeatedBossesField.getInt(gameView);

            if (previousJumpHeight > 1f && jumpHeight <= 0f) landingTime = 0.36f;
            previousJumpHeight = jumpHeight;
            if (lastBosses >= 0 && bosses > lastBosses) victoryTime = 1.55f;
            lastBosses = bosses;

            float movement = GameMath.length(playerVX, playerVY);
            if (movement < 8f && jumpHeight <= 0f && attackTime <= 0f && hurtTime <= 0f) idleTime += dt;
            else idleTime = 0f;

            V55RuntimeState.HeroAnimation mode = V55RuntimeState.HeroAnimation.NONE;
            float modeProgress = 0f;
            V55RuntimeState.Snapshot runtime = V55RuntimeState.heroSnapshot();
            if (runtime.active && runtime.heroIndex == heroIndex) {
                mode = runtime.animation;
                modeProgress = runtime.progress;
            } else if (victoryTime > 0f) {
                mode = V55RuntimeState.HeroAnimation.VICTORY;
                modeProgress = 1f - victoryTime / 1.55f;
            } else if (landingTime > 0f) {
                mode = V55RuntimeState.HeroAnimation.LAND;
                modeProgress = 1f - landingTime / 0.36f;
            } else if (cameraInputY > 0.72f && movement < 12f) {
                mode = V55RuntimeState.HeroAnimation.CROUCH;
                modeProgress = 0.5f + (float) Math.sin(animation * 5f) * 0.5f;
            } else if (idleTime > 6.2f) {
                mode = V55RuntimeState.HeroAnimation.INTERACT;
                modeProgress = (idleTime % 2f) * 0.5f;
            } else if (idleTime > 3.1f) {
                mode = V55RuntimeState.HeroAnimation.OBSERVE;
                modeProgress = ((idleTime - 3.1f) % 2f) * 0.5f;
            }

            float screenX = playerX - cameraX;
            float depth = GameMath.clamp((playerY - getHeight() * 0.30f)
                    / Math.max(1f, getHeight() * 0.62f), 0f, 1f);
            float height = 154f + depth * 55f;
            float width = height * bitmap.getWidth() / Math.max(1f, bitmap.getHeight());
            float bob = movement > 7f ? (float) Math.sin(animation * (movement > 210f ? 14f : 9f)) * 3.2f
                    : (float) Math.sin(animation * 4f) * 1.5f;
            float feetY = playerY - jumpHeight - bob;
            boolean facingRight = Math.abs(playerVX) < 5f || playerVX >= 0f;

            if (auraTime > 0f) drawAura(canvas, heroIndex, screenX, feetY, height, animation);
            drawModeEffectsBehind(canvas, mode, modeProgress, heroIndex, screenX, feetY, height, animation);

            float rotation = attackTime > 0f ? (facingRight ? 7f : -7f) : 0f;
            float scaleX = 1f;
            float scaleY = 1f;
            float offsetX = 0f;
            float offsetY = 0f;

            switch (mode) {
                case LAND -> {
                    float impact = (float) Math.sin(GameMath.clamp(modeProgress, 0f, 1f) * Math.PI);
                    scaleX = 1f + impact * 0.14f;
                    scaleY = 1f - impact * 0.20f;
                    offsetY = impact * 4f;
                }
                case PARRY -> {
                    rotation += (facingRight ? -1f : 1f) * (7f + (float) Math.sin(modeProgress * Math.PI) * 5f);
                    scaleX = 1.04f;
                    scaleY = 1.02f;
                }
                case INTERACT -> {
                    rotation += (float) Math.sin(modeProgress * Math.PI * 2f) * 4f;
                    offsetX = (float) Math.sin(modeProgress * Math.PI * 2f) * 5f;
                }
                case VICTORY -> {
                    float lift = Math.abs((float) Math.sin(modeProgress * Math.PI * 2f));
                    offsetY = -lift * 18f;
                    scaleX = 1.04f + lift * 0.05f;
                    scaleY = 1.04f + lift * 0.05f;
                    rotation += (facingRight ? 1f : -1f) * (float) Math.sin(modeProgress * Math.PI) * 7f;
                }
                case CROUCH -> {
                    scaleX = 1.08f;
                    scaleY = 0.73f;
                }
                case OBSERVE -> {
                    rotation += (float) Math.sin(modeProgress * Math.PI * 2f) * 2.5f;
                    offsetX = (facingRight ? 1f : -1f) * 4f;
                }
                case SPECIAL -> {
                    float surge = (float) Math.sin(modeProgress * Math.PI);
                    scaleX = 1f + surge * 0.10f;
                    scaleY = 1f + surge * 0.07f;
                    rotation += (facingRight ? 1f : -1f) * surge * 10f;
                }
                default -> {
                    // Mouvement normal conservé.
                }
            }

            source.set(0, 0, bitmap.getWidth(), bitmap.getHeight());
            localDestination.set(-width * 0.5f, -height, width * 0.5f, 0f);
            int alpha = hurtTime > 0f && ((int) (animation * 18f) & 1) == 0 ? 135 : 255;

            if (mode == V55RuntimeState.HeroAnimation.SPECIAL) {
                for (int copy = 3; copy >= 1; copy--) {
                    float trail = (facingRight ? -1f : 1f) * copy * 16f;
                    drawHeroBitmap(canvas, bitmap, screenX + offsetX + trail, feetY + offsetY,
                            scaleX, scaleY, rotation, facingRight, 42 + copy * 20);
                }
            }
            drawHeroBitmap(canvas, bitmap, screenX + offsetX, feetY + offsetY,
                    scaleX, scaleY, rotation, facingRight, alpha);
            drawModeEffectsFront(canvas, mode, modeProgress, heroIndex, screenX, feetY, height, animation);
        } catch (ReflectiveOperationException | RuntimeException ignored) {
            // Le fallback Character25D reste visible si le moteur change.
        }
        postInvalidateOnAnimation();
    }

    private void drawHeroBitmap(
            Canvas canvas,
            Bitmap bitmap,
            float x,
            float feetY,
            float scaleX,
            float scaleY,
            float rotation,
            boolean facingRight,
            int alpha
    ) {
        paint.setAlpha(Math.max(0, Math.min(255, alpha)));
        canvas.save();
        canvas.translate(x, feetY);
        canvas.rotate(rotation);
        canvas.scale(facingRight ? scaleX : -scaleX, scaleY);
        canvas.drawBitmap(bitmap, source, localDestination, paint);
        canvas.restore();
        paint.setAlpha(255);
    }

    private void drawAura(Canvas canvas, int hero, float x, float feetY, float height, float animation) {
        int color = HERO_COLORS[hero];
        auraPaint.setColor(Color.argb(58, Color.red(color), Color.green(color), Color.blue(color)));
        canvas.drawCircle(x, feetY - height * 0.48f,
                height * (0.43f + (float) Math.sin(animation * 8f) * 0.025f), auraPaint);
    }

    private void drawModeEffectsBehind(
            Canvas canvas,
            V55RuntimeState.HeroAnimation mode,
            float progress,
            int hero,
            float x,
            float feetY,
            float height,
            float animation
    ) {
        int color = HERO_COLORS[hero];
        if (mode == V55RuntimeState.HeroAnimation.VICTORY) {
            stroke.setColor(Color.argb(155, Color.red(color), Color.green(color), Color.blue(color)));
            stroke.setStrokeWidth(5f);
            float radius = height * (0.35f + Math.abs((float) Math.sin(animation * 6f)) * 0.08f);
            canvas.drawCircle(x, feetY - height * 0.48f, radius, stroke);
        } else if (mode == V55RuntimeState.HeroAnimation.SPECIAL) {
            auraPaint.setColor(Color.argb(48, Color.red(color), Color.green(color), Color.blue(color)));
            canvas.drawCircle(x, feetY - height * 0.50f, height * (0.42f + progress * 0.20f), auraPaint);
        }
    }

    private void drawModeEffectsFront(
            Canvas canvas,
            V55RuntimeState.HeroAnimation mode,
            float progress,
            int hero,
            float x,
            float feetY,
            float height,
            float animation
    ) {
        int color = HERO_COLORS[hero];
        if (mode == V55RuntimeState.HeroAnimation.PARRY) {
            stroke.setColor(Color.argb(215, 220, 245, 255));
            stroke.setStrokeWidth(6f);
            float radius = height * 0.42f;
            canvas.drawArc(new RectF(x - radius, feetY - height * 0.86f,
                    x + radius, feetY - height * 0.10f), -75f, 205f, false, stroke);
        } else if (mode == V55RuntimeState.HeroAnimation.OBSERVE) {
            stroke.setColor(Color.argb(175, Color.red(color), Color.green(color), Color.blue(color)));
            stroke.setStrokeWidth(3f);
            canvas.drawCircle(x + height * 0.22f, feetY - height * 0.83f,
                    9f + (float) Math.sin(animation * 6f) * 2f, stroke);
        } else if (mode == V55RuntimeState.HeroAnimation.INTERACT) {
            paint.setColor(Color.argb(185, 255, 235, 155));
            canvas.drawCircle(x + (float) Math.sin(progress * Math.PI * 2f) * 12f,
                    feetY - height * 0.92f, 5f, paint);
        } else if (mode == V55RuntimeState.HeroAnimation.LAND) {
            stroke.setColor(Color.argb(150, Color.red(color), Color.green(color), Color.blue(color)));
            stroke.setStrokeWidth(4f);
            float radius = 30f + progress * 58f;
            canvas.drawOval(new RectF(x - radius, feetY - 8f, x + radius, feetY + 10f), stroke);
        }
    }

    @Override
    protected void onDetachedFromWindow() {
        for (int index = 0; index < heroes.length; index++) {
            Bitmap bitmap = heroes[index];
            if (bitmap != null && !bitmap.isRecycled()) bitmap.recycle();
            heroes[index] = null;
        }
        super.onDetachedFromWindow();
    }

    private void loadAssets(Context context) {
        for (int index = 0; index < HERO_ASSETS.length; index++) {
            try (InputStream stream = context.getAssets().open(HERO_ASSETS[index])) {
                heroes[index] = BitmapFactory.decodeStream(stream);
            } catch (IOException ignored) {
                heroes[index] = null;
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
            playerVYField = field(type, "playerVY");
            cameraXField = field(type, "cameraX");
            cameraInputYField = field(type, "cameraInputY");
            jumpHeightField = field(type, "jumpHeight");
            attackTimeField = field(type, "attackTime");
            hurtTimeField = field(type, "hurtTime");
            auraTimeField = field(type, "auraTime");
            animationTimeField = field(type, "animationTime");
            defeatedBossesField = field(type, "defeatedBosses");
            reflectionReady = true;
        } catch (ReflectiveOperationException ignored) {
            reflectionReady = false;
        }
        return reflectionReady;
    }

    private float frameDelta() {
        long now = System.nanoTime();
        float result = lastFrameNanos == 0L ? 0f
                : Math.min(0.05f, (now - lastFrameNanos) / 1_000_000_000f);
        lastFrameNanos = now;
        return result;
    }

    private static Field field(Class<?> type, String name) throws NoSuchFieldException {
        Field result = type.getDeclaredField(name);
        result.setAccessible(true);
        return result;
    }
}
