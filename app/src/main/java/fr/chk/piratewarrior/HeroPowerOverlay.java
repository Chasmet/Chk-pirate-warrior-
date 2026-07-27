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

/** Pouvoirs distincts de Cheikh, Yvane et Nelvyn, ajoutés au moteur existant. */
public final class HeroPowerOverlay extends View {
    private static final String[] POWER_NAMES = {
            "TOURBILLON DU CAPITAINE", "LAME FOUDROYANTE", "ARSENAL CHK"
    };
    private static final int[] POWER_COLORS = {
            Color.rgb(235, 91, 51), Color.rgb(55, 173, 255), Color.rgb(70, 208, 135)
    };

    private final PirateGameViewV2 gameView;
    private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint stroke = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Path path = new Path();
    private final RectF powerButton = new RectF();
    private final List<EffectTarget> effectTargets = new ArrayList<>();

    private boolean reflectionReady;
    private boolean enemyReflectionReady;
    private Field screenField;
    private Field runningField;
    private Field selectedHeroField;
    private Field playerXField;
    private Field playerYField;
    private Field cameraXField;
    private Field energyField;
    private Field enemiesField;
    private Field enemyXField;
    private Field enemyYField;
    private Field enemyHpField;
    private Field enemyHitField;

    private float cooldown;
    private float powerTime;
    private float animationTime;
    private float turretTime;
    private float turretShotCooldown;
    private float turretX;
    private float turretY;
    private float shotX;
    private float shotY;
    private float shotTime;
    private long lastFrameNanos;

    public HeroPowerOverlay(Context context, PirateGameViewV2 gameView) {
        super(context);
        this.gameView = gameView;
        stroke.setStyle(Paint.Style.STROKE);
        setClickable(true);
        setFocusable(false);
        setWillNotDraw(false);
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        float dt = frameDelta();
        animationTime += dt;
        cooldown = Math.max(0f, cooldown - dt);
        powerTime = Math.max(0f, powerTime - dt);
        shotTime = Math.max(0f, shotTime - dt);
        updateTurret(dt);

        if (isGameplayActive()) {
            drawPowerButton(canvas);
            drawPowerEffects(canvas);
        } else {
            powerButton.setEmpty();
        }
        postInvalidateOnAnimation();
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        if (event.getActionMasked() == MotionEvent.ACTION_DOWN
                && !powerButton.isEmpty()
                && powerButton.contains(event.getX(), event.getY())) {
            castPower();
            return true;
        }
        return false;
    }

    private void drawPowerButton(Canvas canvas) {
        try {
            int hero = Math.max(0, Math.min(2, selectedHeroField.getInt(gameView)));
            float energy = energyField.getFloat(gameView);
            powerButton.set(getWidth() - 238f, 90f, getWidth() - 22f, 164f);
            int color = POWER_COLORS[hero];
            int alpha = energy >= 35f && cooldown <= 0f ? 224 : 120;
            paint.setColor(Color.argb(alpha, Color.red(color), Color.green(color), Color.blue(color)));
            canvas.drawRoundRect(powerButton, 18f, 18f, paint);
            stroke.setColor(Color.argb(210, 255, 255, 255));
            stroke.setStrokeWidth(2f);
            canvas.drawRoundRect(powerButton, 18f, 18f, stroke);

            paint.setColor(Color.argb(150, 0, 0, 0));
            canvas.drawRoundRect(new RectF(powerButton.left + 10f, powerButton.bottom - 14f,
                    powerButton.right - 10f, powerButton.bottom - 7f), 5f, 5f, paint);
            paint.setColor(Color.WHITE);
            float progress = cooldown > 0f ? 1f - cooldown / 4.5f : Math.min(1f, energy / 35f);
            canvas.drawRoundRect(new RectF(powerButton.left + 10f, powerButton.bottom - 14f,
                    powerButton.left + 10f + (powerButton.width() - 20f) * progress,
                    powerButton.bottom - 7f), 5f, 5f, paint);

            text(canvas, POWER_NAMES[hero], powerButton.centerX(), powerButton.top + 27f,
                    14f, Color.WHITE, true, Paint.Align.CENTER);
            String state = cooldown > 0f ? String.format(java.util.Locale.FRANCE, "Recharge %.1fs", cooldown)
                    : energy >= 35f ? "35 énergie" : "Énergie insuffisante";
            text(canvas, state, powerButton.centerX(), powerButton.top + 51f,
                    12f, Color.WHITE, false, Paint.Align.CENTER);
        } catch (ReflectiveOperationException ignored) {
            powerButton.setEmpty();
        }
    }

    private void castPower() {
        if (!isGameplayActive() || cooldown > 0f || !prepareEnemyFields()) return;
        try {
            float energy = energyField.getFloat(gameView);
            if (energy < 35f) return;
            int hero = Math.max(0, Math.min(2, selectedHeroField.getInt(gameView)));
            float px = playerXField.getFloat(gameView);
            float py = playerYField.getFloat(gameView);
            effectTargets.clear();

            if (hero == 0) {
                castCheikh(px, py);
            } else if (hero == 1) {
                castYvane(px, py);
            } else {
                turretX = px + 54f;
                turretY = py - 5f;
                turretTime = 10f;
                turretShotCooldown = 0f;
            }
            energyField.setFloat(gameView, energy - 35f);
            cooldown = 4.5f;
            powerTime = 0.78f;
        } catch (ReflectiveOperationException ignored) {
            effectTargets.clear();
        }
    }

    private void castCheikh(float px, float py) throws IllegalAccessException {
        for (Object enemy : enemies()) {
            float ex = enemyXField.getFloat(enemy);
            float ey = enemyYField.getFloat(enemy);
            float distance = GameMath.distance(px, py, ex, ey);
            if (distance <= 235f) {
                applyDamage(enemy, 72f, 0.28f);
                float dx = ex - px;
                float dy = ey - py;
                float inv = 1f / Math.max(1f, distance);
                enemyXField.setFloat(enemy, ex + dx * inv * 125f);
                enemyYField.setFloat(enemy, ey + dy * inv * 52f);
                effectTargets.add(new EffectTarget(ex, ey));
            }
        }
    }

    private void castYvane(float px, float py) throws IllegalAccessException {
        List<Object> candidates = new ArrayList<>(enemies());
        candidates.sort(Comparator.comparingDouble(enemy -> {
            try {
                return GameMath.distance(px, py, enemyXField.getFloat(enemy), enemyYField.getFloat(enemy));
            } catch (IllegalAccessException ignored) {
                return Float.MAX_VALUE;
            }
        }));
        int hits = 0;
        for (Object enemy : candidates) {
            float ex = enemyXField.getFloat(enemy);
            float ey = enemyYField.getFloat(enemy);
            if (GameMath.distance(px, py, ex, ey) > 620f) continue;
            applyDamage(enemy, 54f, 0.34f);
            effectTargets.add(new EffectTarget(ex, ey));
            hits++;
            if (hits >= 5) break;
        }
    }

    private void updateTurret(float dt) {
        if (turretTime <= 0f || !isGameplayActive() || !prepareEnemyFields()) return;
        turretTime = Math.max(0f, turretTime - dt);
        turretShotCooldown = Math.max(0f, turretShotCooldown - dt);
        if (turretShotCooldown > 0f) return;
        try {
            Object nearest = null;
            float nearestDistance = Float.MAX_VALUE;
            for (Object enemy : enemies()) {
                float ex = enemyXField.getFloat(enemy);
                float ey = enemyYField.getFloat(enemy);
                float distance = GameMath.distance(turretX, turretY, ex, ey);
                if (distance < nearestDistance && distance <= 650f) {
                    nearestDistance = distance;
                    nearest = enemy;
                }
            }
            if (nearest != null) {
                applyDamage(nearest, 22f, 0.14f);
                shotX = enemyXField.getFloat(nearest);
                shotY = enemyYField.getFloat(nearest);
                shotTime = 0.18f;
                turretShotCooldown = 0.56f;
            }
        } catch (ReflectiveOperationException ignored) {
            turretTime = 0f;
        }
    }

    private void drawPowerEffects(Canvas canvas) {
        try {
            int hero = Math.max(0, Math.min(2, selectedHeroField.getInt(gameView)));
            float px = playerXField.getFloat(gameView);
            float py = playerYField.getFloat(gameView);
            float cameraX = cameraXField.getFloat(gameView);
            float sx = px - cameraX;

            if (powerTime > 0f && hero == 0) {
                float progress = 1f - powerTime / 0.78f;
                stroke.setColor(Color.argb((int) (220f * (1f - progress)), 255, 113, 47));
                stroke.setStrokeWidth(12f - progress * 6f);
                canvas.drawArc(new RectF(sx - 125f - progress * 80f, py - 125f - progress * 80f,
                        sx + 125f + progress * 80f, py + 125f + progress * 80f),
                        animationTime * 380f, 285f, false, stroke);
            } else if (powerTime > 0f && hero == 1) {
                float previousX = sx;
                float previousY = py;
                stroke.setColor(Color.argb((int) (230f * powerTime / 0.78f), 82, 198, 255));
                stroke.setStrokeWidth(6f);
                for (EffectTarget target : effectTargets) {
                    float tx = target.x - cameraX;
                    float ty = target.y;
                    drawLightning(canvas, previousX, previousY, tx, ty);
                    previousX = tx;
                    previousY = ty;
                }
            }

            if (turretTime > 0f) {
                float tx = turretX - cameraX;
                drawTurret(canvas, tx, turretY);
                if (shotTime > 0f) {
                    stroke.setColor(Color.argb((int) (255f * shotTime / 0.18f), 65, 227, 170));
                    stroke.setStrokeWidth(5f);
                    canvas.drawLine(tx, turretY - 35f, shotX - cameraX, shotY - 18f, stroke);
                }
            }
        } catch (ReflectiveOperationException ignored) {
            effectTargets.clear();
        }
    }

    private void drawLightning(Canvas canvas, float x1, float y1, float x2, float y2) {
        path.reset();
        path.moveTo(x1, y1);
        for (int i = 1; i < 6; i++) {
            float t = i / 6f;
            float x = x1 + (x2 - x1) * t;
            float y = y1 + (y2 - y1) * t + (float) Math.sin(animationTime * 31f + i * 2.2f) * 14f;
            path.lineTo(x, y);
        }
        path.lineTo(x2, y2);
        canvas.drawPath(path, stroke);
    }

    private void drawTurret(Canvas canvas, float x, float y) {
        paint.setColor(Color.argb(175, 0, 0, 0));
        canvas.drawOval(new RectF(x - 34f, y - 3f, x + 34f, y + 15f), paint);
        paint.setColor(Color.rgb(47, 65, 66));
        canvas.drawRoundRect(new RectF(x - 25f, y - 47f, x + 25f, y), 9f, 9f, paint);
        paint.setColor(Color.rgb(66, 213, 158));
        canvas.drawCircle(x, y - 31f, 9f + (float) Math.sin(animationTime * 8f) * 2f, paint);
        stroke.setColor(Color.rgb(132, 255, 211));
        stroke.setStrokeWidth(3f);
        canvas.drawCircle(x, y - 31f, 17f, stroke);
    }

    private void applyDamage(Object enemy, float damage, float hitTime) throws IllegalAccessException {
        enemyHpField.setFloat(enemy, enemyHpField.getFloat(enemy) - damage);
        enemyHitField.setFloat(enemy, hitTime);
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
            List<Object> enemies = enemies();
            if (enemies.isEmpty()) return false;
            Class<?> type = enemies.get(0).getClass();
            enemyXField = field(type, "x");
            enemyYField = field(type, "y");
            enemyHpField = field(type, "hp");
            enemyHitField = field(type, "hitTime");
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
            cameraXField = field(type, "cameraX");
            energyField = field(type, "energy");
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
}
