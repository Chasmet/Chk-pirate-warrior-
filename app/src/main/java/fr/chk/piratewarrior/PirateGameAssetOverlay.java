package fr.chk.piratewarrior;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.RectF;
import android.util.Log;
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
 * Couche d'intégration non destructive des ennemis officiels.
 *
 * Le moteur V2 reste en place. Cette couche attribue exactement le boss, les trois commandants et
 * les trois subordonnés de l'île active aux ennemis importants. Elle utilise en priorité les vraies
 * bandes SpriteStrip25D, puis l'atlas PDF officiel comme fallback. Les autres ennemis restent des
 * ennemis ordinaires et ne chargent aucun personnage 2.5D important supplémentaire.
 */
public final class PirateGameAssetOverlay extends View {
    private static final String TAG = "OfficialEnemyOverlay";
    private static final int IMPORTANT_NON_BOSS_COUNT = 6;

    private static final class Assignment {
        final Enemy25DCatalog.Entry entry;
        final Enemy25DCombatProfile profile;
        boolean statsApplied;

        Assignment(Enemy25DCatalog.Entry entry) {
            this.entry = entry;
            this.profile = Enemy25DCombatProfile.from(entry);
        }
    }

    private final PirateGameViewV2 gameView;
    private final Enemy25DAssetBank assetBank;
    private final PdfAtlas25D pdfAtlas;
    private final Paint textPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint badgePaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Map<Object, Assignment> assignments = new IdentityHashMap<>();
    private final List<Enemy25DCatalog.Entry> eliteRoster = new ArrayList<>(IMPORTANT_NON_BOSS_COUNT);
    private final Set<String> assignedEliteIds = new HashSet<>(IMPORTANT_NON_BOSS_COUNT);
    private final RectF badge = new RectF();

    private Field screenField;
    private Field islandField;
    private Field enemiesField;
    private Field cameraField;
    private Field animationField;
    private Field enemyXField;
    private Field enemyYField;
    private Field enemyVxField;
    private Field enemyVyField;
    private Field enemyHpField;
    private Field enemyMaxHpField;
    private Field enemySpeedField;
    private Field enemyRadiusField;
    private Field enemyCooldownField;
    private Field enemyHitField;
    private Field enemyRangedField;
    private Field enemyBossField;
    private boolean reflectionReady;
    private int assignedIsland = -1;

    public PirateGameAssetOverlay(Context context, PirateGameViewV2 gameView) {
        super(context);
        this.gameView = gameView;
        assetBank = new Enemy25DAssetBank(context.getAssets());
        pdfAtlas = new PdfAtlas25D(context.getAssets());
        textPaint.setTextAlign(Paint.Align.CENTER);
        textPaint.setFakeBoldText(true);
        badgePaint.setStyle(Paint.Style.FILL);
        setClickable(false);
        setFocusable(false);
        setWillNotDraw(false);
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        try {
            if (!ensureReflection()) {
                postInvalidateOnAnimation();
                return;
            }
            Object screen = screenField.get(gameView);
            if (screen == null || !("GAME".equals(screen.toString()) || "PAUSE".equals(screen.toString()))) {
                postInvalidateOnAnimation();
                return;
            }

            int island = islandField.getInt(gameView);
            if (island != assignedIsland) prepareIsland(island);

            Object value = enemiesField.get(gameView);
            if (!(value instanceof List<?> enemies)) {
                postInvalidateOnAnimation();
                return;
            }
            reconcileAssignments(enemies, island);

            float cameraX = cameraField.getFloat(gameView);
            float globalAnimation = animationField.getFloat(gameView);
            for (Object enemy : enemies) {
                Assignment assignment = assignments.get(enemy);
                if (assignment == null) continue;
                applyProfile(enemy, assignment);
                drawAssignedEnemy(canvas, enemy, assignment, cameraX, globalAnimation);
            }
        } catch (ReflectiveOperationException | RuntimeException exception) {
            Log.w(TAG, "Fallback ennemi conservé après une erreur d'intégration 2.5D.", exception);
        }
        postInvalidateOnAnimation();
    }

    @Override
    protected void onDetachedFromWindow() {
        assetBank.releaseAll();
        pdfAtlas.release();
        assignments.clear();
        eliteRoster.clear();
        super.onDetachedFromWindow();
    }

    private void prepareIsland(int island) {
        assignments.clear();
        eliteRoster.clear();
        assignedEliteIds.clear();
        assignedIsland = island;

        eliteRoster.addAll(Enemy25DCatalog.commandersForIsland(island));
        eliteRoster.addAll(Enemy25DCatalog.subordinatesForIsland(island));
        Enemy25DAssetBank.LoadReport report = assetBank.prepareIsland(island);
        pdfAtlas.prepareIsland(island);
        Log.i(TAG, Enemy25DCatalog.ISLAND_NAMES[island] + " : "
                + report.charactersWithAssets + "/7 personnages avec bandes réelles, atlas PDF en secours.");
    }

    private void reconcileAssignments(List<?> enemies, int island) throws IllegalAccessException {
        Iterator<Map.Entry<Object, Assignment>> iterator = assignments.entrySet().iterator();
        while (iterator.hasNext()) {
            Map.Entry<Object, Assignment> item = iterator.next();
            if (!enemies.contains(item.getKey())) iterator.remove();
        }

        assignedEliteIds.clear();
        for (Assignment assignment : assignments.values()) {
            if (assignment.entry.rank != Enemy25DCatalog.Rank.BOSS) {
                assignedEliteIds.add(assignment.entry.id);
            }
        }

        for (Object enemy : enemies) {
            boolean boss = enemyBossField.getBoolean(enemy);
            Assignment current = assignments.get(enemy);
            if (boss) {
                Enemy25DCatalog.Entry bossEntry = Enemy25DCatalog.bossForIsland(island);
                if (current == null || current.entry != bossEntry) {
                    assignments.put(enemy, new Assignment(bossEntry));
                }
                continue;
            }
            if (current != null || assignedEliteIds.size() >= IMPORTANT_NON_BOSS_COUNT) continue;

            Enemy25DCatalog.Entry available = firstAvailableElite();
            if (available != null) {
                assignments.put(enemy, new Assignment(available));
                assignedEliteIds.add(available.id);
            }
        }
    }

    private Enemy25DCatalog.Entry firstAvailableElite() {
        for (Enemy25DCatalog.Entry entry : eliteRoster) {
            if (!assignedEliteIds.contains(entry.id)) return entry;
        }
        return null;
    }

    private void applyProfile(Object enemy, Assignment assignment) throws IllegalAccessException {
        if (assignment.statsApplied) return;

        float oldMaxHp = Math.max(1f, enemyMaxHpField.getFloat(enemy));
        float oldHp = Math.max(0f, enemyHpField.getFloat(enemy));
        float hpRatio = Math.min(1f, oldHp / oldMaxHp);
        float newMaxHp = oldMaxHp * assignment.profile.hpMultiplier;

        enemyMaxHpField.setFloat(enemy, newMaxHp);
        enemyHpField.setFloat(enemy, newMaxHp * hpRatio);
        enemySpeedField.setFloat(enemy,
                enemySpeedField.getFloat(enemy) * assignment.profile.speedMultiplier);
        enemyRadiusField.setFloat(enemy,
                enemyRadiusField.getFloat(enemy) * assignment.profile.radiusMultiplier);
        enemyRangedField.setBoolean(enemy, assignment.profile.ranged);
        assignment.statsApplied = true;
    }

    private void drawAssignedEnemy(
            Canvas canvas,
            Object enemy,
            Assignment assignment,
            float cameraX,
            float globalAnimation
    ) throws IllegalAccessException {
        float worldX = enemyXField.getFloat(enemy);
        float worldY = enemyYField.getFloat(enemy);
        float screenX = worldX - cameraX;
        if (screenX < -220f || screenX > getWidth() + 220f) return;

        float vx = enemyVxField.getFloat(enemy);
        float vy = enemyVyField.getFloat(enemy);
        float hp = enemyHpField.getFloat(enemy);
        float maxHp = Math.max(1f, enemyMaxHpField.getFloat(enemy));
        float hitTime = enemyHitField.getFloat(enemy);
        float cooldown = enemyCooldownField.getFloat(enemy);
        boolean boss = assignment.entry.rank == Enemy25DCatalog.Rank.BOSS;
        float depth = GameMath.clamp(0.80f + worldY / Math.max(1f, getHeight()) * 0.34f, 0.78f, 1.18f);
        float height = (boss ? 192f
                : assignment.entry.rank == Enemy25DCatalog.Rank.COMMANDER ? 148f : 126f) * depth;

        SpriteStrip25D.Direction direction = directionFor(vx, vy);
        SpriteStrip25D.Animation animation = animationFor(
                assignment, hp / maxHp, vx, vy, hitTime, cooldown);
        boolean drawn = drawRealStrip(canvas, assignment.entry, direction, animation,
                globalAnimation, screenX, worldY, height);

        if (!drawn) {
            PdfAssetCatalog.Entry pdfEntry = pdfEntryFor(assignment.entry);
            drawn = pdfEntry != null && pdfAtlas.draw(canvas, pdfEntry, globalAnimation,
                    screenX, worldY, height, vx, hitTime, hp <= 0f);
        }
        if (!drawn) return;

        int rankColor = switch (assignment.entry.rank) {
            case BOSS -> Color.rgb(232, 72, 67);
            case COMMANDER -> Color.rgb(237, 177, 62);
            case SUBORDINATE -> Color.rgb(67, 166, 219);
        };
        String rank = switch (assignment.entry.rank) {
            case BOSS -> "BOSS";
            case COMMANDER -> "COMMANDANT";
            case SUBORDINATE -> "NAKAMA";
        };
        textPaint.setTextSize(boss ? 17f : 13f);
        float labelY = worldY - height - 12f;
        float badgeWidth = textPaint.measureText(rank) + 18f;
        badge.set(screenX - badgeWidth * 0.5f, labelY - 18f,
                screenX + badgeWidth * 0.5f, labelY + 3f);
        badgePaint.setColor(Color.argb(220, Color.red(rankColor), Color.green(rankColor), Color.blue(rankColor)));
        canvas.drawRoundRect(badge, 8f, 8f, badgePaint);
        textPaint.setColor(Color.WHITE);
        canvas.drawText(rank, screenX, labelY - 2f, textPaint);
        textPaint.setTextSize(boss ? 18f : 14f);
        textPaint.setColor(boss ? Color.rgb(255, 220, 128) : Color.WHITE);
        canvas.drawText(assignment.entry.displayName, screenX, labelY - 25f, textPaint);
    }

    private boolean drawRealStrip(
            Canvas canvas,
            Enemy25DCatalog.Entry entry,
            SpriteStrip25D.Direction direction,
            SpriteStrip25D.Animation animation,
            float animationSeconds,
            float centerX,
            float feetY,
            float height
    ) {
        SpriteStrip25D strip = assetBank.get(entry.id);
        if (strip == null || !strip.hasAnyAnimation()) return false;

        if (strip.draw(canvas, direction, animation, animationSeconds,
                centerX, feetY, height, 1f)) return true;
        if (animation == SpriteStrip25D.Animation.DEFEAT
                && strip.draw(canvas, SpriteStrip25D.Direction.FRONT, SpriteStrip25D.Animation.DEFEAT,
                animationSeconds, centerX, feetY, height, 1f)) return true;
        if ((animation == SpriteStrip25D.Animation.POWER
                || animation == SpriteStrip25D.Animation.RAGE
                || animation == SpriteStrip25D.Animation.PHASE2
                || animation == SpriteStrip25D.Animation.AREA_ATTACK
                || animation == SpriteStrip25D.Animation.ULTIMATE)
                && strip.draw(canvas, SpriteStrip25D.Direction.FRONT, animation,
                animationSeconds, centerX, feetY, height, 1f)) return true;
        if (animation != SpriteStrip25D.Animation.ATTACK
                && strip.draw(canvas, direction, SpriteStrip25D.Animation.ATTACK,
                animationSeconds, centerX, feetY, height, 1f)) return true;
        if (animation != SpriteStrip25D.Animation.WALK
                && strip.draw(canvas, direction, SpriteStrip25D.Animation.WALK,
                animationSeconds, centerX, feetY, height, 1f)) return true;
        return strip.draw(canvas, direction, SpriteStrip25D.Animation.IDLE,
                animationSeconds, centerX, feetY, height, 1f);
    }

    private SpriteStrip25D.Animation animationFor(
            Assignment assignment,
            float hpRatio,
            float vx,
            float vy,
            float hitTime,
            float cooldown
    ) {
        if (hpRatio <= 0f) return SpriteStrip25D.Animation.DEFEAT;
        if (hitTime > 0f) return SpriteStrip25D.Animation.HURT;

        boolean attackActive = cooldown > Math.max(0.35f,
                assignment.profile.attackCooldownSeconds * 0.62f);
        if (assignment.entry.rank == Enemy25DCatalog.Rank.BOSS && attackActive) {
            if (hpRatio < 0.30f) return SpriteStrip25D.Animation.ULTIMATE;
            if (hpRatio < 0.52f) return SpriteStrip25D.Animation.AREA_ATTACK;
            return SpriteStrip25D.Animation.ATTACK;
        }
        if (attackActive) {
            return assignment.profile.archetype == Enemy25DCombatProfile.Archetype.CONTROLLER
                    ? SpriteStrip25D.Animation.POWER : SpriteStrip25D.Animation.ATTACK;
        }
        return GameMath.length(vx, vy) > 12f
                ? SpriteStrip25D.Animation.WALK : SpriteStrip25D.Animation.IDLE;
    }

    private static SpriteStrip25D.Direction directionFor(float vx, float vy) {
        if (Math.abs(vx) >= Math.abs(vy) * 0.72f) {
            return vx < 0f ? SpriteStrip25D.Direction.LEFT : SpriteStrip25D.Direction.RIGHT;
        }
        return vy < 0f ? SpriteStrip25D.Direction.BACK : SpriteStrip25D.Direction.FRONT;
    }

    private PdfAssetCatalog.Entry pdfEntryFor(Enemy25DCatalog.Entry official) {
        for (PdfAssetCatalog.Entry entry : PdfAssetCatalog.forIsland(official.islandIndex)) {
            if (entry.id.equals(official.id)) return entry;
        }
        return null;
    }

    private boolean ensureReflection() throws ReflectiveOperationException {
        if (reflectionReady) return true;
        Class<?> gameClass = gameView.getClass();
        screenField = field(gameClass, "screen");
        islandField = field(gameClass, "currentIsland");
        enemiesField = field(gameClass, "enemies");
        cameraField = field(gameClass, "cameraX");
        animationField = field(gameClass, "animationTime");

        Object enemiesValue = enemiesField.get(gameView);
        if (!(enemiesValue instanceof List<?> enemies) || enemies.isEmpty()) return false;
        Class<?> enemyClass = enemies.get(0).getClass();
        enemyXField = field(enemyClass, "x");
        enemyYField = field(enemyClass, "y");
        enemyVxField = field(enemyClass, "vx");
        enemyVyField = field(enemyClass, "vy");
        enemyHpField = field(enemyClass, "hp");
        enemyMaxHpField = field(enemyClass, "maxHp");
        enemySpeedField = field(enemyClass, "speed");
        enemyRadiusField = field(enemyClass, "radius");
        enemyCooldownField = field(enemyClass, "cooldown");
        enemyHitField = field(enemyClass, "hitTime");
        enemyRangedField = field(enemyClass, "ranged");
        enemyBossField = field(enemyClass, "boss");
        reflectionReady = true;
        return true;
    }

    private static Field field(Class<?> type, String name) throws NoSuchFieldException {
        Field result = type.getDeclaredField(name);
        result.setAccessible(true);
        return result;
    }
}
