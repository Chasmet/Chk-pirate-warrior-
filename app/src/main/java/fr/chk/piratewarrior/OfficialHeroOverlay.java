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
 * Affiche et anime les trois héros officiels au-dessus du fallback Character25D.
 * Les transformations restent légères et conservent strictement les visuels fournis.
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
    private final Paint bitmapPaint = new Paint(Paint.ANTI_ALIAS_FLAG | Paint.FILTER_BITMAP_FLAG);
    private final Paint effectPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint strokePaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Rect source = new Rect();
    private final RectF localDestination = new RectF();
    private final RectF effectRect = new RectF();
    private final HeroAnimationDynamics.Input animationInput = new HeroAnimationDynamics.Input();
    private final HeroAnimationDynamics.Controller animationController = new HeroAnimationDynamics.Controller();

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
    private Field jumpVelocityField;
    private Field attackTimeField;
    private Field dodgeTimeField;
    private Field hurtTimeField;
    private Field auraTimeField;
    private Field sprintingField;
    private Field animationTimeField;
    private Field defeatedBossesField;
    private boolean reflectionReady;

    private long lastFrameNanos;
    private float idleTime;
    private float victoryTime;
    private int lastBosses = -1;
    private int lastHeroIndex = -1;
    private boolean facingRight = true;

    public OfficialHeroOverlay(Context context, PirateGameViewV2 gameView) {
        super(context);
        this.gameView = gameView;
        strokePaint.setStyle(Paint.Style.STROKE);
        strokePaint.setStrokeCap(Paint.Cap.ROUND);
        setClickable(false);
        setFocusable(false);
        setWillNotDraw(false);
        loadAssets(context);
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        float dt = frameDelta();
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
                postInvalidateOnAnimation();
                return;
            }

            int heroIndex = Math.max(0, Math.min(2, selectedHeroField.getInt(gameView)));
            Bitmap bitmap = heroes[heroIndex];
            if (bitmap == null || bitmap.isRecycled()) {
                postInvalidateOnAnimation();
                return;
            }

            if (heroIndex != lastHeroIndex) {
                animationController.reset(heroIndex);
                lastHeroIndex = heroIndex;
            }

            float playerX = playerXField.getFloat(gameView);
            float playerY = playerYField.getFloat(gameView);
            float playerVX = playerVXField.getFloat(gameView);
            float playerVY = playerVYField.getFloat(gameView);
            float cameraX = cameraXField.getFloat(gameView);
            float cameraInputY = cameraInputYField.getFloat(gameView);
            float jumpHeight = jumpHeightField.getFloat(gameView);
            float jumpVelocity = jumpVelocityField.getFloat(gameView);
            float attackTime = attackTimeField.getFloat(gameView);
            float dodgeTime = dodgeTimeField.getFloat(gameView);
            float hurtTime = hurtTimeField.getFloat(gameView);
            float auraTime = auraTimeField.getFloat(gameView);
            boolean sprinting = sprintingField.getBoolean(gameView);
            float globalAnimation = animationTimeField.getFloat(gameView);
            int defeatedBosses = defeatedBossesField.getInt(gameView);

            if (lastBosses >= 0 && defeatedBosses > lastBosses) victoryTime = 1.65f;
            lastBosses = defeatedBosses;

            float movement = GameMath.length(playerVX, playerVY);
            if (movement < 8f && jumpHeight <= 0f && attackTime <= 0f
                    && dodgeTime <= 0f && hurtTime <= 0f) {
                idleTime += dt;
            } else {
                idleTime = 0f;
            }

            if (Math.abs(playerVX) > 4f) facingRight = playerVX > 0f;

            V55RuntimeState.Snapshot runtime = V55RuntimeState.heroSnapshot();
            animationInput.heroIndex = heroIndex;
            animationInput.velocityX = playerVX;
            animationInput.velocityY = playerVY;
            animationInput.jumpHeight = jumpHeight;
            animationInput.jumpVelocity = jumpVelocity;
            animationInput.attackTime = attackTime;
            animationInput.dodgeTime = dodgeTime;
            animationInput.hurtTime = hurtTime;
            animationInput.auraTime = auraTime;
            animationInput.sprinting = sprinting;
            animationInput.forcedMotion = null;
            animationInput.externalProgress = 0f;

            if (runtime.active && runtime.heroIndex == heroIndex) {
                animationInput.forcedMotion = mapRuntimeMotion(runtime.animation);
                animationInput.externalProgress = runtime.progress;
            } else if (victoryTime > 0f) {
                animationInput.forcedMotion = HeroAnimationDynamics.Motion.VICTORY;
                animationInput.externalProgress = 1f - victoryTime / 1.65f;
            } else if (cameraInputY > 0.72f && movement < 12f) {
                animationInput.forcedMotion = HeroAnimationDynamics.Motion.CROUCH;
                animationInput.externalProgress = 0.5f + (float) Math.sin(globalAnimation * 5f) * 0.5f;
            } else if (idleTime > 6.2f) {
                animationInput.forcedMotion = HeroAnimationDynamics.Motion.INTERACT;
                animationInput.externalProgress = (idleTime % 2f) * 0.5f;
            } else if (idleTime > 3.1f) {
                animationInput.forcedMotion = HeroAnimationDynamics.Motion.OBSERVE;
                animationInput.externalProgress = ((idleTime - 3.1f) % 2f) * 0.5f;
            }

            HeroAnimationDynamics.Transform transform = animationController.update(animationInput, dt);

            float screenX = playerX - cameraX;
            float depth = GameMath.clamp((playerY - getHeight() * 0.30f)
                    / Math.max(1f, getHeight() * 0.62f), 0f, 1f);
            float heroHeight = 154f + depth * 55f;
            float heroWidth = heroHeight * bitmap.getWidth() / Math.max(1f, bitmap.getHeight());
            float feetY = playerY - jumpHeight + transform.offsetY;

            source.set(0, 0, bitmap.getWidth(), bitmap.getHeight());
            localDestination.set(-heroWidth * 0.5f, -heroHeight, heroWidth * 0.5f, 0f);

            drawGroundContact(canvas, transform, heroIndex, screenX, playerY, heroHeight);
            if (auraTime > 0f || transform.motion == HeroAnimationDynamics.Motion.AURA) {
                drawAura(canvas, heroIndex, screenX, feetY, heroHeight, globalAnimation,
                        Math.max(0.45f, transform.effectStrength));
            }
            drawBehindEffects(canvas, transform, heroIndex, screenX, feetY, heroHeight, globalAnimation);

            int mainAlpha = hurtTime > 0f && ((int) (globalAnimation * 18f) & 1) == 0 ? 135 : 255;
            if (transform.trailStrength > 0.08f) {
                drawAfterImages(canvas, bitmap, transform, screenX, feetY, facingRight);
            }

            drawHeroBitmap(canvas, bitmap,
                    screenX + transform.offsetX,
                    feetY,
                    transform.scaleX,
                    transform.scaleY,
                    transform.rotation,
                    facingRight,
                    mainAlpha);

            drawFrontEffects(canvas, transform, heroIndex, screenX, feetY, heroHeight, globalAnimation);
        } catch (ReflectiveOperationException | RuntimeException ignored) {
            // Character25D reste visible si une donnée du moteur évolue ou si un asset manque.
        }

        postInvalidateOnAnimation();
    }

    private static HeroAnimationDynamics.Motion mapRuntimeMotion(V55RuntimeState.HeroAnimation animation) {
        return switch (animation) {
            case LAND -> HeroAnimationDynamics.Motion.LAND;
            case PARRY -> HeroAnimationDynamics.Motion.PARRY;
            case INTERACT -> HeroAnimationDynamics.Motion.INTERACT;
            case VICTORY -> HeroAnimationDynamics.Motion.VICTORY;
            case CROUCH -> HeroAnimationDynamics.Motion.CROUCH;
            case OBSERVE -> HeroAnimationDynamics.Motion.OBSERVE;
            case SPECIAL -> HeroAnimationDynamics.Motion.SPECIAL;
            case NONE -> null;
        };
    }

    private void drawAfterImages(
            Canvas canvas,
            Bitmap bitmap,
            HeroAnimationDynamics.Transform transform,
            float x,
            float feetY,
            boolean right
    ) {
        float direction = right ? -1f : 1f;
        int copies = transform.trailStrength > 0.72f ? 3 : 2;
        for (int copy = copies; copy >= 1; copy--) {
            float distance = copy * (10f + transform.trailStrength * 11f);
            int alpha = (int) (transform.trailStrength * (72f - copy * 10f));
            drawHeroBitmap(canvas, bitmap,
                    x + transform.offsetX + direction * distance,
                    feetY,
                    transform.scaleX,
                    transform.scaleY,
                    transform.rotation,
                    right,
                    alpha);
        }
    }

    private void drawHeroBitmap(
            Canvas canvas,
            Bitmap bitmap,
            float x,
            float feetY,
            float scaleX,
            float scaleY,
            float rotation,
            boolean right,
            int alpha
    ) {
        bitmapPaint.setAlpha(Math.max(0, Math.min(255, alpha)));
        canvas.save();
        canvas.translate(x, feetY);
        canvas.rotate(rotation);
        canvas.scale(right ? scaleX : -scaleX, scaleY);
        canvas.drawBitmap(bitmap, source, localDestination, bitmapPaint);
        canvas.restore();
        bitmapPaint.setAlpha(255);
    }

    private void drawGroundContact(
            Canvas canvas,
            HeroAnimationDynamics.Transform transform,
            int hero,
            float x,
            float feetY,
            float height
    ) {
        if (transform.motion != HeroAnimationDynamics.Motion.LAND) return;
        int color = HERO_COLORS[hero];
        float radius = 28f + transform.effectStrength * 62f;
        strokePaint.setStrokeWidth(4f);
        strokePaint.setColor(Color.argb((int) (165f * transform.effectStrength),
                Color.red(color), Color.green(color), Color.blue(color)));
        effectRect.set(x - radius, feetY - 8f, x + radius, feetY + 11f);
        canvas.drawOval(effectRect, strokePaint);
    }

    private void drawAura(
            Canvas canvas,
            int hero,
            float x,
            float feetY,
            float height,
            float animation,
            float strength
    ) {
        int color = HERO_COLORS[hero];
        float pulse = 0.5f + (float) Math.sin(animation * 8f) * 0.5f;
        effectPaint.setColor(Color.argb((int) (35f + strength * 55f),
                Color.red(color), Color.green(color), Color.blue(color)));
        canvas.drawCircle(x, feetY - height * 0.48f,
                height * (0.40f + pulse * 0.055f + strength * 0.03f), effectPaint);
        strokePaint.setStrokeWidth(3f + strength * 2f);
        strokePaint.setColor(Color.argb((int) (75f + strength * 105f),
                Color.red(color), Color.green(color), Color.blue(color)));
        canvas.drawCircle(x, feetY - height * 0.48f,
                height * (0.45f + pulse * 0.035f), strokePaint);
    }

    private void drawBehindEffects(
            Canvas canvas,
            HeroAnimationDynamics.Transform transform,
            int hero,
            float x,
            float feetY,
            float height,
            float animation
    ) {
        int color = HERO_COLORS[hero];
        if (transform.motion == HeroAnimationDynamics.Motion.SPECIAL
                || transform.motion == HeroAnimationDynamics.Motion.VICTORY) {
            float pulse = 0.5f + (float) Math.sin(animation * 7f) * 0.5f;
            effectPaint.setColor(Color.argb((int) (35f + 45f * transform.effectStrength),
                    Color.red(color), Color.green(color), Color.blue(color)));
            canvas.drawCircle(x, feetY - height * 0.50f,
                    height * (0.38f + pulse * 0.06f + transform.effectStrength * 0.12f), effectPaint);
        }
    }

    private void drawFrontEffects(
            Canvas canvas,
            HeroAnimationDynamics.Transform transform,
            int hero,
            float x,
            float feetY,
            float height,
            float animation
    ) {
        int color = HERO_COLORS[hero];
        if (transform.motion == HeroAnimationDynamics.Motion.PARRY) {
            strokePaint.setStrokeWidth(5f + transform.effectStrength * 3f);
            strokePaint.setColor(Color.argb((int) (125f + 110f * transform.effectStrength),
                    220, 245, 255));
            float radius = height * 0.42f;
            effectRect.set(x - radius, feetY - height * 0.86f,
                    x + radius, feetY - height * 0.10f);
            canvas.drawArc(effectRect, -75f, 205f, false, strokePaint);
        } else if (transform.motion == HeroAnimationDynamics.Motion.OBSERVE) {
            strokePaint.setStrokeWidth(3f);
            strokePaint.setColor(Color.argb(175, Color.red(color), Color.green(color), Color.blue(color)));
            canvas.drawCircle(x + height * 0.22f, feetY - height * 0.83f,
                    9f + (float) Math.sin(animation * 6f) * 2f, strokePaint);
        } else if (transform.motion == HeroAnimationDynamics.Motion.INTERACT) {
            effectPaint.setColor(Color.argb(190, 255, 235, 155));
            canvas.drawCircle(x + (float) Math.sin(transform.normalizedTime * Math.PI * 2f) * 12f,
                    feetY - height * 0.92f, 5f, effectPaint);
        } else if (transform.motion == HeroAnimationDynamics.Motion.ATTACK
                && transform.effectStrength > 0.10f) {
            strokePaint.setStrokeWidth(4f + transform.effectStrength * 4f);
            strokePaint.setColor(Color.argb((int) (190f * transform.effectStrength),
                    Color.red(color), Color.green(color), Color.blue(color)));
            float reach = 34f + height * 0.36f * transform.effectStrength;
            float start = facingRight ? -55f : 235f;
            effectRect.set(x - reach, feetY - height * 0.74f,
                    x + reach, feetY - height * 0.12f);
            canvas.drawArc(effectRect, start, facingRight ? 125f : -125f, false, strokePaint);
        } else if (transform.motion == HeroAnimationDynamics.Motion.HURT) {
            effectPaint.setColor(Color.argb((int) (85f * transform.effectStrength), 255, 255, 255));
            canvas.drawCircle(x, feetY - height * 0.48f,
                    height * 0.38f, effectPaint);
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
            jumpVelocityField = field(type, "jumpVelocity");
            attackTimeField = field(type, "attackTime");
            dodgeTimeField = field(type, "dodgeTime");
            hurtTimeField = field(type, "hurtTime");
            auraTimeField = field(type, "auraTime");
            sprintingField = field(type, "sprinting");
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
