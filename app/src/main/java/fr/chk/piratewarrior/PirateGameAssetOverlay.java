package fr.chk.piratewarrior;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.view.View;

import java.lang.reflect.Field;
import java.util.IdentityHashMap;
import java.util.List;
import java.util.Map;

/**
 * Couche d'intégration non destructive : elle conserve le gameplay V2 et remplace visuellement
 * les élites par les personnages réellement fournis dans le PDF.
 */
public final class PirateGameAssetOverlay extends View {
    private final PirateGameViewV2 gameView;
    private final PdfAtlas25D atlas;
    private final Paint textPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Map<Object, PdfAssetCatalog.Entry> assignments = new IdentityHashMap<>();

    private Field screenField;
    private Field islandField;
    private Field enemiesField;
    private Field cameraField;
    private Field animationField;
    private Field enemyXField;
    private Field enemyYField;
    private Field enemyVxField;
    private Field enemyHpField;
    private Field enemyHitField;
    private Field enemyBossField;
    private boolean reflectionReady;
    private int assignedIsland = -1;
    private int eliteCursor;

    public PirateGameAssetOverlay(Context context, PirateGameViewV2 gameView) {
        super(context);
        this.gameView = gameView;
        atlas = new PdfAtlas25D(context.getAssets());
        textPaint.setTextAlign(Paint.Align.CENTER);
        textPaint.setFakeBoldText(true);
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
            if (island != assignedIsland) {
                assignments.clear();
                eliteCursor = 0;
                assignedIsland = island;
                atlas.prepareIsland(island);
            }

            float cameraX = cameraField.getFloat(gameView);
            float animation = animationField.getFloat(gameView);
            Object value = enemiesField.get(gameView);
            if (!(value instanceof List<?> enemies)) {
                postInvalidateOnAnimation();
                return;
            }
            List<PdfAssetCatalog.Entry> islandEntries = PdfAssetCatalog.forIsland(island);

            int ordinaryIndex = 0;
            for (Object enemy : enemies) {
                boolean boss = enemyBossField.getBoolean(enemy);
                PdfAssetCatalog.Entry entry;
                if (boss) {
                    entry = PdfAssetCatalog.bossForIsland(island);
                } else {
                    entry = assignments.get(enemy);
                    if (entry == null && ordinaryIndex % 3 == 0) {
                        entry = islandEntries.get(1 + eliteCursor % 6);
                        assignments.put(enemy, entry);
                        eliteCursor++;
                    }
                    ordinaryIndex++;
                }
                if (entry == null) continue;

                float worldX = enemyXField.getFloat(enemy);
                float worldY = enemyYField.getFloat(enemy);
                float screenX = worldX - cameraX;
                if (screenX < -180f || screenX > getWidth() + 180f) continue;
                float vx = enemyVxField.getFloat(enemy);
                float hp = enemyHpField.getFloat(enemy);
                float hit = enemyHitField.getFloat(enemy);
                float height = boss ? 190f : entry.rank == PdfAssetCatalog.Rank.COMMANDER ? 145f : 125f;

                if (atlas.draw(canvas, entry, animation, screenX, worldY, height, vx, hit, hp <= 0f)) {
                    textPaint.setColor(boss ? Color.rgb(255, 204, 86) : Color.WHITE);
                    textPaint.setTextSize(boss ? 17f : 13f);
                    canvas.drawText(entry.displayName, screenX, worldY - height - 10f, textPaint);
                }
            }
        } catch (ReflectiveOperationException | RuntimeException ignored) {
            // Le gameplay reste actif même si une future refactorisation change un champ interne.
        }
        postInvalidateOnAnimation();
    }

    @Override
    protected void onDetachedFromWindow() {
        atlas.release();
        assignments.clear();
        super.onDetachedFromWindow();
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
        enemyHpField = field(enemyClass, "hp");
        enemyHitField = field(enemyClass, "hitTime");
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
