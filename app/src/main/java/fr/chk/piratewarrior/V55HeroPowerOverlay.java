package fr.chk.piratewarrior;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RectF;
import android.view.MotionEvent;
import android.view.View;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;

/**
 * Deux techniques supplémentaires réellement jouables pour chacun des trois héros.
 * La couche conserve le bouton POUVOIR, l'aura et toutes les attaques du moteur existant.
 */
public final class V55HeroPowerOverlay extends View {
    private static final String[][] POWER_NAMES = {
            {"AURA ROYALE", "LAME D'ÉCLIPSE"},
            {"RAFALE STELLAIRE", "BOUCLIER SACRÉ"},
            {"TORNADE ÉCLAIR", "HYPER VITESSE"}
    };
    private static final float[][] POWER_COSTS = {
            {32f, 44f}, {34f, 46f}, {34f, 45f}
    };
    private static final float[][] POWER_COOLDOWNS = {
            {6.5f, 10.5f}, {7.5f, 12f}, {7f, 12f}
    };
    private static final int[] HERO_COLORS = {
            Color.rgb(238, 92, 49), Color.rgb(72, 190, 255), Color.rgb(67, 220, 142)
    };

    private final PirateGameViewV2 gameView;
    private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint stroke = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Path path = new Path();
    private final RectF[] buttons = {new RectF(), new RectF()};
    private final float[][] cooldowns = new float[3][2];
    private final List<EffectTarget> targets = new ArrayList<>();

    private boolean reflectionReady;
    private boolean enemyReflectionReady;
    private Field screenField;
    private Field runningField;
    private Field selectedHeroField;
    private Field playerXField;
    private Field playerYField;
    private Field playerHpField;
    private Field playerMaxHpField;
    private Field playerVXField;
    private Field playerVYField;
    private Field cameraXField;
    private Field energyField;
    private Field auraTimeField;
    private Field facingRightField;
    private Field enemiesField;
    private Field enemyXField;
    private Field enemyYField;
    private Field enemyHpField;
    private Field enemyMaxHpField;
    private Field enemyHitField;
    private Field enemyBossField;

    private long lastFrameNanos;
    private float animationTime;
    private float activeEffectTime;
    private float activeEffectDuration = 1f;
    private int activeHero = -1;
    private int activeSlot = -1;
    private float shieldTime;
    private float hyperSpeedTime;
    private float lastKnownHp = -1f;

    public V55HeroPowerOverlay(Context context, PirateGameViewV2 gameView) {
        super(context);
        this.gameView = gameView;
        stroke.setStyle(Paint.Style.STROKE);
        stroke.setStrokeCap(Paint.Cap.ROUND);
        setClickable(true);
        setFocusable(false);
        setWillNotDraw(false);
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        float dt = frameDelta();
        animationTime += dt;
        for (int hero = 0; hero < cooldowns.length; hero++) {
            for (int slot = 0; slot < cooldowns[hero].length; slot++) {
                cooldowns[hero][slot] = Math.max(0f, cooldowns[hero][slot] - dt);
            }
        }
        activeEffectTime = Math.max(0f, activeEffectTime - dt);
        shieldTime = Math.max(0f, shieldTime - dt);
        hyperSpeedTime = Math.max(0f, hyperSpeedTime - dt);

        if (isGameplayActive()) {
            updatePersistentEffects();
            drawPowerButtons(canvas);
            drawEffects(canvas);
        } else {
            buttons[0].setEmpty();
            buttons[1].setEmpty();
            lastKnownHp = -1f;
        }
        postInvalidateOnAnimation();
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        if (event.getActionMasked() != MotionEvent.ACTION_DOWN || !isGameplayActive()) return false;
        float x = event.getX();
        float y = event.getY();
        for (int slot = 0; slot < buttons.length; slot++) {
            if (!buttons[slot].isEmpty() && buttons[slot].contains(x, y)) {
                castPower(slot);
                return true;
            }
        }
        return false;
    }

    private void drawPowerButtons(Canvas canvas) {
        try {
            int hero = heroIndex();
            float energy = energyField.getFloat(gameView);
            float width = Math.min(230f, Math.max(178f, getWidth() * 0.19f));
            float right = getWidth() - 18f;
            float left = right - width;
            float top = 76f;
            float height = 62f;
            float gap = 9f;

            for (int slot = 0; slot < 2; slot++) {
                buttons[slot].set(left, top + slot * (height + gap), right, top + slot * (height + gap) + height);
                int color = HERO_COLORS[hero];
                boolean ready = cooldowns[hero][slot] <= 0f && energy >= POWER_COSTS[hero][slot];
                int alpha = ready ? 226 : 124;
                paint.setColor(Color.argb(alpha, Color.red(color), Color.green(color), Color.blue(color)));
                canvas.drawRoundRect(buttons[slot], 17f, 17f, paint);
                stroke.setColor(Color.argb(205, 255, 255, 255));
                stroke.setStrokeWidth(2f);
                canvas.drawRoundRect(buttons[slot], 17f, 17f, stroke);

                text(canvas, POWER_NAMES[hero][slot], buttons[slot].centerX(), buttons[slot].top + 24f,
                        12.5f, Color.WHITE, true, Paint.Align.CENTER);
                String state = cooldowns[hero][slot] > 0f
                        ? String.format(Locale.FRANCE, "Recharge %.1fs", cooldowns[hero][slot])
                        : String.format(Locale.FRANCE, "%.0f énergie", POWER_COSTS[hero][slot]);
                text(canvas, state, buttons[slot].centerX(), buttons[slot].bottom - 13f,
                        11.5f, Color.WHITE, false, Paint.Align.CENTER);
            }
        } catch (ReflectiveOperationException ignored) {
            buttons[0].setEmpty();
            buttons[1].setEmpty();
        }
    }

    private void castPower(int slot) {
        if (!isGameplayActive() || slot < 0 || slot > 1) return;
        try {
            int hero = heroIndex();
            float cost = POWER_COSTS[hero][slot];
            float energy = energyField.getFloat(gameView);
            if (cooldowns[hero][slot] > 0f || energy < cost) return;

            float px = playerXField.getFloat(gameView);
            float py = playerYField.getFloat(gameView);
            targets.clear();
            activeHero = hero;
            activeSlot = slot;
            activeEffectDuration = slot == 0 ? 0.95f : 1.20f;
            activeEffectTime = activeEffectDuration;

            if (hero == 0 && slot == 0) castAuraRoyale(px, py);
            else if (hero == 0) castLameEclipse(px, py);
            else if (hero == 1 && slot == 0) castRafaleStellaire(px, py);
            else if (hero == 1) castBouclierSacre();
            else if (slot == 0) castTornadeEclair(px, py);
            else castHyperVitesse();

            energyField.setFloat(gameView, energy - cost);
            cooldowns[hero][slot] = POWER_COOLDOWNS[hero][slot];
            V55RuntimeState.playHeroAnimation(hero,
                    isDefensive(hero, slot) ? V55RuntimeState.HeroAnimation.PARRY
                            : V55RuntimeState.HeroAnimation.SPECIAL,
                    isDefensive(hero, slot) ? 0.85f : 1.05f);
        } catch (ReflectiveOperationException ignored) {
            targets.clear();
        }
    }

    private void castAuraRoyale(float px, float py) throws ReflectiveOperationException {
        if (!prepareEnemyFields()) return;
        for (Object enemy : enemies()) {
            float ex = enemyXField.getFloat(enemy);
            float ey = enemyYField.getFloat(enemy);
            float distance = GameMath.distance(px, py, ex, ey);
            if (distance > 270f) continue;
            applyDamage(enemy, 48f, 0.34f);
            float inv = 1f / Math.max(1f, distance);
            enemyXField.setFloat(enemy, ex + (ex - px) * inv * 155f);
            enemyYField.setFloat(enemy, ey + (ey - py) * inv * 70f);
            targets.add(new EffectTarget(ex, ey));
        }
    }

    private void castLameEclipse(float px, float py) throws ReflectiveOperationException {
        if (!prepareEnemyFields()) return;
        boolean right = facingRightField.getBoolean(gameView);
        for (Object enemy : enemies()) {
            float ex = enemyXField.getFloat(enemy);
            float ey = enemyYField.getFloat(enemy);
            float dx = ex - px;
            float dy = Math.abs(ey - py);
            boolean inDirection = right ? dx >= -20f : dx <= 20f;
            if (!inDirection || Math.abs(dx) > 760f || dy > 115f) continue;
            applyDamage(enemy, 92f, 0.45f);
            enemyXField.setFloat(enemy, ex + (right ? 95f : -95f));
            targets.add(new EffectTarget(ex, ey));
        }
    }

    private void castRafaleStellaire(float px, float py) throws ReflectiveOperationException {
        if (!prepareEnemyFields()) return;
        List<EnemyDistance> candidates = new ArrayList<>();
        for (Object enemy : enemies()) {
            float ex = enemyXField.getFloat(enemy);
            float ey = enemyYField.getFloat(enemy);
            float distance = GameMath.distance(px, py, ex, ey);
            if (distance <= 720f) candidates.add(new EnemyDistance(enemy, distance));
        }
        candidates.sort(Comparator.comparingDouble(item -> item.distance));
        int count = Math.min(6, candidates.size());
        for (int index = 0; index < count; index++) {
            Object enemy = candidates.get(index).enemy;
            applyDamage(enemy, 42f, 0.28f);
            targets.add(new EffectTarget(enemyXField.getFloat(enemy), enemyYField.getFloat(enemy)));
        }
    }

    private void castBouclierSacre() throws IllegalAccessException {
        shieldTime = 6f;
        lastKnownHp = playerHpField.getFloat(gameView);
        activeEffectDuration = 0.75f;
        activeEffectTime = activeEffectDuration;
    }

    private void castTornadeEclair(float px, float py) throws ReflectiveOperationException {
        if (!prepareEnemyFields()) return;
        for (Object enemy : enemies()) {
            float ex = enemyXField.getFloat(enemy);
            float ey = enemyYField.getFloat(enemy);
            float distance = GameMath.distance(px, py, ex, ey);
            if (distance > 320f) continue;
            applyDamage(enemy, 38f, 0.38f);
            float inv = 1f / Math.max(1f, distance);
            enemyXField.setFloat(enemy, ex + (px - ex) * inv * 115f);
            enemyYField.setFloat(enemy, ey + (py - ey) * inv * 85f);
            targets.add(new EffectTarget(ex, ey));
        }
    }

    private void castHyperVitesse() {
        hyperSpeedTime = 6f;
        activeEffectDuration = 0.65f;
        activeEffectTime = activeEffectDuration;
    }

    private void updatePersistentEffects() {
        try {
            float hp = playerHpField.getFloat(gameView);
            float maxHp = Math.max(1f, playerMaxHpField.getFloat(gameView));
            if (shieldTime > 0f && lastKnownHp >= 0f && hp < lastKnownHp) {
                float prevented = (lastKnownHp - hp) * 0.45f;
                hp = Math.min(maxHp, hp + prevented);
                playerHpField.setFloat(gameView, hp);
            }
            lastKnownHp = hp;

            if (hyperSpeedTime > 0f) {
                float aura = auraTimeField.getFloat(gameView);
                auraTimeField.setFloat(gameView, Math.max(aura, 0.14f));
                float vx = playerVXField.getFloat(gameView);
                float vy = playerVYField.getFloat(gameView);
                playerVXField.setFloat(gameView, GameMath.clamp(vx * 1.08f, -470f, 470f));
                playerVYField.setFloat(gameView, GameMath.clamp(vy * 1.06f, -300f, 300f));
            }
        } catch (ReflectiveOperationException ignored) {
            shieldTime = 0f;
            hyperSpeedTime = 0f;
        }
    }

    private void drawEffects(Canvas canvas) {
        try {
            float px = playerXField.getFloat(gameView);
            float py = playerYField.getFloat(gameView);
            float cameraX = cameraXField.getFloat(gameView);
            float sx = px - cameraX;

            if (shieldTime > 0f) {
                float pulse = 1f + (float) Math.sin(animationTime * 8f) * 0.06f;
                paint.setColor(Color.argb(42, 160, 225, 255));
                canvas.drawCircle(sx, py - 70f, 92f * pulse, paint);
                stroke.setColor(Color.argb(205, 205, 242, 255));
                stroke.setStrokeWidth(5f);
                canvas.drawCircle(sx, py - 70f, 92f * pulse, stroke);
            }
            if (hyperSpeedTime > 0f) {
                stroke.setColor(Color.argb(145, 92, 255, 190));
                stroke.setStrokeWidth(5f);
                for (int index = 0; index < 4; index++) {
                    float offset = 28f + index * 19f;
                    canvas.drawLine(sx - offset, py - 105f + index * 15f,
                            sx - offset * 1.8f, py - 105f + index * 15f, stroke);
                }
            }
            if (activeEffectTime <= 0f || activeHero < 0) return;

            float progress = 1f - activeEffectTime / Math.max(0.01f, activeEffectDuration);
            int alpha = (int) (225f * (1f - progress));
            int color = HERO_COLORS[activeHero];
            stroke.setColor(Color.argb(alpha, Color.red(color), Color.green(color), Color.blue(color)));
            stroke.setStrokeWidth(9f - progress * 4f);

            if (activeHero == 0 && activeSlot == 0) {
                float radius = 70f + progress * 235f;
                canvas.drawCircle(sx, py - 35f, radius, stroke);
                canvas.drawCircle(sx, py - 35f, radius * 0.72f, stroke);
            } else if (activeHero == 0) {
                boolean right = facingRightField.getBoolean(gameView);
                float endX = sx + (right ? 720f : -720f) * Math.min(1f, progress * 1.6f);
                path.reset();
                path.moveTo(sx, py - 72f);
                path.quadTo((sx + endX) * 0.5f, py - 195f, endX, py - 70f);
                canvas.drawPath(path, stroke);
            } else if (activeHero == 1 && activeSlot == 0) {
                for (EffectTarget target : targets) {
                    float tx = target.x - cameraX;
                    stroke.setStrokeWidth(4f);
                    canvas.drawLine(sx, py - 115f, tx, target.y - 55f, stroke);
                    paint.setColor(Color.argb(alpha, 220, 245, 255));
                    canvas.drawCircle(tx, target.y - 55f, 10f + progress * 15f, paint);
                }
            } else if (activeHero == 1) {
                canvas.drawCircle(sx, py - 70f, 45f + progress * 70f, stroke);
            } else if (activeSlot == 0) {
                for (int ring = 0; ring < 4; ring++) {
                    float radius = 52f + ring * 38f + progress * 35f;
                    canvas.drawArc(new RectF(sx - radius, py - 70f - radius,
                                    sx + radius, py - 70f + radius),
                            animationTime * 260f + ring * 35f, 245f, false, stroke);
                }
            } else {
                canvas.drawCircle(sx, py - 72f, 55f + progress * 75f, stroke);
            }
        } catch (ReflectiveOperationException ignored) {
            activeEffectTime = 0f;
        }
    }

    private void applyDamage(Object enemy, float damage, float hitTime) throws IllegalAccessException {
        boolean boss = enemyBossField != null && enemyBossField.getBoolean(enemy);
        float applied = boss ? damage * 0.68f : damage;
        enemyHpField.setFloat(enemy, Math.max(0f, enemyHpField.getFloat(enemy) - applied));
        enemyHitField.setFloat(enemy, Math.max(enemyHitField.getFloat(enemy), hitTime));
    }

    private boolean isDefensive(int hero, int slot) {
        return (hero == 1 && slot == 1) || (hero == 2 && slot == 1);
    }

    private int heroIndex() throws IllegalAccessException {
        return Math.max(0, Math.min(2, selectedHeroField.getInt(gameView)));
    }

    @SuppressWarnings("unchecked")
    private List<Object> enemies() throws IllegalAccessException {
        Object value = enemiesField.get(gameView);
        if (value instanceof List<?>) return (List<Object>) value;
        return java.util.Collections.emptyList();
    }

    private boolean prepareEnemyFields() {
        if (!ensureReflection()) return false;
        if (enemyReflectionReady) return true;
        try {
            List<Object> current = enemies();
            if (current.isEmpty()) return false;
            Class<?> type = current.get(0).getClass();
            enemyXField = field(type, "x");
            enemyYField = field(type, "y");
            enemyHpField = field(type, "hp");
            enemyMaxHpField = field(type, "maxHp");
            enemyHitField = field(type, "hitTime");
            enemyBossField = field(type, "boss");
            enemyReflectionReady = true;
            return true;
        } catch (ReflectiveOperationException ignored) {
            return false;
        }
    }

    private boolean isGameplayActive() {
        if (!ensureReflection()) return false;
        try {
            Object screen = screenField.get(gameView);
            return runningField.getBoolean(gameView) && screen != null && "GAME".equals(screen.toString());
        } catch (ReflectiveOperationException ignored) {
            return false;
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
            playerHpField = field(type, "playerHp");
            playerMaxHpField = field(type, "playerMaxHp");
            playerVXField = field(type, "playerVX");
            playerVYField = field(type, "playerVY");
            cameraXField = field(type, "cameraX");
            energyField = field(type, "energy");
            auraTimeField = field(type, "auraTime");
            facingRightField = field(type, "facingRight");
            enemiesField = field(type, "enemies");
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

    private void text(Canvas canvas, String value, float x, float y, float size,
                      int color, boolean bold, Paint.Align align) {
        paint.setStyle(Paint.Style.FILL);
        paint.setColor(color);
        paint.setTextSize(size);
        paint.setTextAlign(align);
        paint.setFakeBoldText(bold);
        canvas.drawText(value, x, y, paint);
        paint.setFakeBoldText(false);
    }

    private static Field field(Class<?> type, String name) throws NoSuchFieldException {
        Field result = type.getDeclaredField(name);
        result.setAccessible(true);
        return result;
    }

    private static final class EffectTarget {
        final float x;
        final float y;

        EffectTarget(float x, float y) {
            this.x = x;
            this.y = y;
        }
    }

    private static final class EnemyDistance {
        final Object enemy;
        final float distance;

        EnemyDistance(Object enemy, float distance) {
            this.enemy = enemy;
            this.distance = distance;
        }
    }
}
