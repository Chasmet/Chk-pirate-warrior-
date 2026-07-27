package fr.chk.piratewarrior;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.RectF;
import android.view.View;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.IdentityHashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Active deux techniques pour chaque ennemi important réellement affecté à l'île courante.
 * Les attaques dangereuses sont télégraphiées et restent esquivables.
 */
public final class V55EnemyAbilityOverlay extends View {
    private static final int IMPORTANT_NON_BOSS_COUNT = 6;

    private static final class AbilityState {
        final Enemy25DCatalog.Entry entry;
        final Enemy25DCombatProfile profile;
        float cooldown;
        float telegraph;
        float active;
        float originalSpeed;
        int slot = -1;
        boolean transformed;

        AbilityState(Enemy25DCatalog.Entry entry) {
            this.entry = entry;
            this.profile = Enemy25DCombatProfile.from(entry);
            this.cooldown = 2.8f + Math.abs(entry.id.hashCode() % 28) * 0.10f;
        }
    }

    private final PirateGameViewV2 gameView;
    private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint stroke = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Map<Object, AbilityState> states = new IdentityHashMap<>();
    private final List<Enemy25DCatalog.Entry> eliteRoster = new ArrayList<>(IMPORTANT_NON_BOSS_COUNT);
    private final Set<String> assignedEliteIds = new HashSet<>(IMPORTANT_NON_BOSS_COUNT);

    private Field screenField;
    private Field runningField;
    private Field islandField;
    private Field enemiesField;
    private Field cameraField;
    private Field playerXField;
    private Field playerYField;
    private Field playerHpField;
    private Field playerMaxHpField;
    private Field hurtTimeField;
    private Field dodgeTimeField;
    private Field enemyXField;
    private Field enemyYField;
    private Field enemyHpField;
    private Field enemyMaxHpField;
    private Field enemySpeedField;
    private Field enemyCooldownField;
    private Field enemyHitField;
    private Field enemyBossField;
    private boolean reflectionReady;
    private int assignedIsland = -1;
    private long lastFrameNanos;
    private float animationTime;

    public V55EnemyAbilityOverlay(Context context, PirateGameViewV2 gameView) {
        super(context);
        this.gameView = gameView;
        stroke.setStyle(Paint.Style.STROKE);
        stroke.setStrokeCap(Paint.Cap.ROUND);
        paint.setTextAlign(Paint.Align.CENTER);
        setClickable(false);
        setFocusable(false);
        setWillNotDraw(false);
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        float dt = frameDelta();
        animationTime += dt;
        try {
            if (!ensureReflection() || !isGameplayActive()) {
                postInvalidateOnAnimation();
                return;
            }
            int island = islandField.getInt(gameView);
            if (island != assignedIsland) prepareIsland(island);
            List<Object> enemies = enemies();
            reconcile(enemies, island);

            float cameraX = cameraField.getFloat(gameView);
            for (Object enemy : enemies) {
                AbilityState state = states.get(enemy);
                if (state == null) continue;
                updateState(enemy, state, dt, enemies);
                drawState(canvas, enemy, state, cameraX);
            }
        } catch (ReflectiveOperationException | RuntimeException ignored) {
            // Le moteur et les attaques ordinaires restent fonctionnels en cas de fallback.
        }
        postInvalidateOnAnimation();
    }

    private void prepareIsland(int island) {
        restoreAllSpeeds();
        states.clear();
        eliteRoster.clear();
        assignedEliteIds.clear();
        assignedIsland = island;
        if (island < 0 || island >= Enemy25DCatalog.ISLAND_COUNT) return;
        eliteRoster.addAll(Enemy25DCatalog.commandersForIsland(island));
        eliteRoster.addAll(Enemy25DCatalog.subordinatesForIsland(island));
    }

    private void reconcile(List<Object> enemies, int island) throws IllegalAccessException {
        Iterator<Map.Entry<Object, AbilityState>> iterator = states.entrySet().iterator();
        while (iterator.hasNext()) {
            Map.Entry<Object, AbilityState> item = iterator.next();
            if (!enemies.contains(item.getKey())) {
                restoreSpeed(item.getKey(), item.getValue());
                iterator.remove();
            }
        }

        assignedEliteIds.clear();
        for (AbilityState state : states.values()) {
            if (state.entry.rank != Enemy25DCatalog.Rank.BOSS) assignedEliteIds.add(state.entry.id);
        }

        if (island < 0 || island >= Enemy25DCatalog.ISLAND_COUNT) return;
        for (Object enemy : enemies) {
            boolean boss = enemyBossField.getBoolean(enemy);
            AbilityState current = states.get(enemy);
            if (boss) {
                Enemy25DCatalog.Entry entry = Enemy25DCatalog.bossForIsland(island);
                if (current == null || current.entry != entry) states.put(enemy, new AbilityState(entry));
                continue;
            }
            if (current != null || assignedEliteIds.size() >= IMPORTANT_NON_BOSS_COUNT) continue;
            Enemy25DCatalog.Entry entry = firstAvailableElite();
            if (entry != null) {
                states.put(enemy, new AbilityState(entry));
                assignedEliteIds.add(entry.id);
            }
        }
    }

    private Enemy25DCatalog.Entry firstAvailableElite() {
        for (Enemy25DCatalog.Entry entry : eliteRoster) {
            if (!assignedEliteIds.contains(entry.id)) return entry;
        }
        return null;
    }

    private void updateState(
            Object enemy,
            AbilityState state,
            float dt,
            List<Object> enemies
    ) throws ReflectiveOperationException {
        float hp = enemyHpField.getFloat(enemy);
        if (hp <= 0f) {
            restoreSpeed(enemy, state);
            return;
        }

        state.cooldown = Math.max(0f, state.cooldown - dt);
        state.active = Math.max(0f, state.active - dt);
        if (state.transformed && state.active <= 0f) restoreSpeed(enemy, state);

        if (state.telegraph > 0f) {
            state.telegraph -= dt;
            if (state.telegraph <= 0f) resolveAbility(enemy, state, enemies);
            return;
        }

        float distance = distanceToPlayer(enemy);
        if (state.cooldown <= 0f && distance <= 720f) beginAbility(enemy, state);
    }

    private void beginAbility(Object enemy, AbilityState state) throws IllegalAccessException {
        state.slot = (state.slot + 1) % 2;
        state.telegraph = switch (state.entry.rank) {
            case BOSS -> 1.10f;
            case COMMANDER -> 0.82f;
            case SUBORDINATE -> 0.64f;
        };
        state.cooldown = switch (state.entry.rank) {
            case BOSS -> 7.2f;
            case COMMANDER -> 8.8f;
            case SUBORDINATE -> 10.2f;
        } + Math.abs(state.entry.id.hashCode() % 13) * 0.08f;
        float current = enemyCooldownField.getFloat(enemy);
        enemyCooldownField.setFloat(enemy, Math.max(current, state.telegraph + 0.75f));
    }

    private void resolveAbility(
            Object enemy,
            AbilityState state,
            List<Object> enemies
    ) throws ReflectiveOperationException {
        float distance = distanceToPlayer(enemy);
        int island = Math.max(0, state.entry.islandIndex);

        if (state.entry.rank == Enemy25DCatalog.Rank.BOSS) {
            if (state.slot == 0) {
                state.active = 0.85f;
                if (distance <= 305f) damagePlayer(15f + island * 1.8f);
            } else {
                state.active = 5f;
                if (!state.transformed) {
                    state.originalSpeed = enemySpeedField.getFloat(enemy);
                    enemySpeedField.setFloat(enemy, state.originalSpeed * 1.20f);
                    state.transformed = true;
                }
                float maxHp = Math.max(1f, enemyMaxHpField.getFloat(enemy));
                float hp = enemyHpField.getFloat(enemy);
                enemyHpField.setFloat(enemy, Math.min(maxHp, hp + maxHp * 0.06f));
            }
            return;
        }

        if (state.entry.rank == Enemy25DCatalog.Rank.COMMANDER) {
            if (state.slot == 0) {
                state.active = 0.70f;
                if (state.profile.ranged) {
                    if (distance <= 650f) damagePlayer(8f + island * 1.1f);
                } else {
                    dashTowardPlayer(enemy, 105f);
                    if (distance <= 205f) damagePlayer(10f + island * 1.2f);
                }
            } else {
                state.active = 0.95f;
                Object boss = findBoss(enemies);
                if (boss != null) {
                    healEnemy(boss, 0.025f);
                    if (distance <= 335f) damagePlayer(12f + island * 1.25f);
                } else if (distance <= 230f) {
                    damagePlayer(8f + island);
                }
            }
            return;
        }

        if (state.slot == 0) {
            state.active = 0.75f;
            healEnemy(enemy, 0.10f);
            Object boss = findBoss(enemies);
            if (boss != null && distanceBetween(enemy, boss) <= 360f) healEnemy(boss, 0.018f);
        } else {
            state.active = 0.60f;
            dashTowardPlayer(enemy, 70f);
            if (distance <= 225f) damagePlayer(6f + island * 0.9f);
        }
    }

    private void drawState(
            Canvas canvas,
            Object enemy,
            AbilityState state,
            float cameraX
    ) throws IllegalAccessException {
        if (state.telegraph <= 0f && state.active <= 0f) return;
        float x = enemyXField.getFloat(enemy) - cameraX;
        float y = enemyYField.getFloat(enemy);
        if (x < -180f || x > getWidth() + 180f) return;

        int color = colorFor(state.entry);
        if (state.telegraph > 0f) {
            float pulse = 1f + (float) Math.sin(animationTime * 12f) * 0.08f;
            float radius = switch (state.entry.rank) {
                case BOSS -> 145f;
                case COMMANDER -> 92f;
                case SUBORDINATE -> 66f;
            } * pulse;
            paint.setColor(Color.argb(38, Color.red(color), Color.green(color), Color.blue(color)));
            canvas.drawCircle(x, y - 24f, radius, paint);
            stroke.setColor(Color.argb(225, Color.red(color), Color.green(color), Color.blue(color)));
            stroke.setStrokeWidth(state.entry.rank == Enemy25DCatalog.Rank.BOSS ? 7f : 4f);
            canvas.drawCircle(x, y - 24f, radius, stroke);

            if (state.profile.ranged || state.slot == 1) {
                float px = playerXField.getFloat(gameView) - cameraX;
                float py = playerYField.getFloat(gameView);
                stroke.setStrokeWidth(3f);
                canvas.drawLine(x, y - 55f, px, py - 55f, stroke);
            }
            drawAbilityName(canvas, state, x, y - radius - 14f, color);
        }

        if (state.active > 0f) {
            float progress = Math.min(1f, state.active / 5f);
            stroke.setColor(Color.argb(185, Color.red(color), Color.green(color), Color.blue(color)));
            stroke.setStrokeWidth(state.entry.rank == Enemy25DCatalog.Rank.BOSS ? 8f : 5f);
            float radius = 48f + (float) Math.sin(animationTime * 10f) * 9f;
            canvas.drawArc(new RectF(x - radius, y - 90f - radius, x + radius, y - 90f + radius),
                    animationTime * 210f, 285f, false, stroke);
            if (state.transformed) {
                paint.setColor(Color.argb((int) (45f + progress * 45f),
                        Color.red(color), Color.green(color), Color.blue(color)));
                canvas.drawCircle(x, y - 85f, 92f, paint);
            }
        }
    }

    private void drawAbilityName(Canvas canvas, AbilityState state, float x, float y, int color) {
        CharacterEnhancementCatalog.Spec spec = CharacterEnhancementCatalog.byId(state.entry.id);
        String name = spec == null || state.slot < 0 || state.slot >= spec.powers.size()
                ? "TECHNIQUE SPÉCIALE" : spec.powers.get(state.slot);
        if (name.length() > 34) name = name.substring(0, 31) + "…";
        paint.setTextSize(state.entry.rank == Enemy25DCatalog.Rank.BOSS ? 14f : 11f);
        paint.setFakeBoldText(true);
        paint.setTextAlign(Paint.Align.CENTER);
        paint.setColor(Color.argb(225, 0, 0, 0));
        float width = paint.measureText(name) + 18f;
        canvas.drawRoundRect(new RectF(x - width * 0.5f, y - 17f, x + width * 0.5f, y + 5f), 8f, 8f, paint);
        paint.setColor(color);
        canvas.drawText(name, x, y, paint);
        paint.setFakeBoldText(false);
    }

    private void damagePlayer(float damage) throws IllegalAccessException {
        if (dodgeTimeField.getFloat(gameView) > 0f) return;
        float hp = playerHpField.getFloat(gameView);
        if (hp <= 0f) return;
        playerHpField.setFloat(gameView, Math.max(0f, hp - damage));
        hurtTimeField.setFloat(gameView, Math.max(hurtTimeField.getFloat(gameView), 0.42f));
    }

    private void healEnemy(Object enemy, float ratio) throws IllegalAccessException {
        float maxHp = Math.max(1f, enemyMaxHpField.getFloat(enemy));
        float hp = enemyHpField.getFloat(enemy);
        enemyHpField.setFloat(enemy, Math.min(maxHp, hp + maxHp * ratio));
    }

    private void dashTowardPlayer(Object enemy, float distance) throws IllegalAccessException {
        float ex = enemyXField.getFloat(enemy);
        float ey = enemyYField.getFloat(enemy);
        float px = playerXField.getFloat(gameView);
        float py = playerYField.getFloat(gameView);
        float length = GameMath.distance(ex, ey, px, py);
        float inv = 1f / Math.max(1f, length);
        enemyXField.setFloat(enemy, ex + (px - ex) * inv * distance);
        enemyYField.setFloat(enemy, ey + (py - ey) * inv * distance * 0.55f);
    }

    private float distanceToPlayer(Object enemy) throws IllegalAccessException {
        return GameMath.distance(enemyXField.getFloat(enemy), enemyYField.getFloat(enemy),
                playerXField.getFloat(gameView), playerYField.getFloat(gameView));
    }

    private float distanceBetween(Object first, Object second) throws IllegalAccessException {
        return GameMath.distance(enemyXField.getFloat(first), enemyYField.getFloat(first),
                enemyXField.getFloat(second), enemyYField.getFloat(second));
    }

    private Object findBoss(List<Object> enemies) throws IllegalAccessException {
        for (Object enemy : enemies) {
            if (enemyBossField.getBoolean(enemy) && enemyHpField.getFloat(enemy) > 0f) return enemy;
        }
        return null;
    }

    private int colorFor(Enemy25DCatalog.Entry entry) {
        try {
            return Color.parseColor(entry.accentColor);
        } catch (IllegalArgumentException ignored) {
            return Color.rgb(235, 175, 72);
        }
    }

    private void restoreAllSpeeds() {
        for (Map.Entry<Object, AbilityState> item : states.entrySet()) restoreSpeed(item.getKey(), item.getValue());
    }

    private void restoreSpeed(Object enemy, AbilityState state) {
        if (!state.transformed || enemySpeedField == null) return;
        try {
            enemySpeedField.setFloat(enemy, state.originalSpeed);
        } catch (IllegalAccessException ignored) {
            // L'objet peut déjà avoir été libéré par le moteur.
        }
        state.transformed = false;
        state.active = 0f;
    }

    @SuppressWarnings("unchecked")
    private List<Object> enemies() throws IllegalAccessException {
        Object value = enemiesField.get(gameView);
        if (value instanceof List<?>) return (List<Object>) value;
        return java.util.Collections.emptyList();
    }

    private boolean isGameplayActive() throws IllegalAccessException {
        Object screen = screenField.get(gameView);
        return runningField.getBoolean(gameView) && screen != null && "GAME".equals(screen.toString());
    }

    private boolean ensureReflection() {
        if (reflectionReady) return true;
        try {
            Class<?> gameClass = gameView.getClass();
            screenField = field(gameClass, "screen");
            runningField = field(gameClass, "running");
            islandField = field(gameClass, "currentIsland");
            enemiesField = field(gameClass, "enemies");
            cameraField = field(gameClass, "cameraX");
            playerXField = field(gameClass, "playerX");
            playerYField = field(gameClass, "playerY");
            playerHpField = field(gameClass, "playerHp");
            playerMaxHpField = field(gameClass, "playerMaxHp");
            hurtTimeField = field(gameClass, "hurtTime");
            dodgeTimeField = field(gameClass, "dodgeTime");

            List<Object> current = enemies();
            if (current.isEmpty()) return false;
            Class<?> enemyClass = current.get(0).getClass();
            enemyXField = field(enemyClass, "x");
            enemyYField = field(enemyClass, "y");
            enemyHpField = field(enemyClass, "hp");
            enemyMaxHpField = field(enemyClass, "maxHp");
            enemySpeedField = field(enemyClass, "speed");
            enemyCooldownField = field(enemyClass, "cooldown");
            enemyHitField = field(enemyClass, "hitTime");
            enemyBossField = field(enemyClass, "boss");
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
