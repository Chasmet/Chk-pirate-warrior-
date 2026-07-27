package fr.chk.piratewarrior;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RectF;
import android.graphics.Shader;
import android.view.MotionEvent;
import android.view.View;

import java.lang.reflect.Field;

/** Carte légère de l'archipel : huit îles reliées par une route maritime continue. */
public final class WorldMapOverlay extends View {
    private final PirateGameViewV2 gameView;
    private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint stroke = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Path route = new Path();
    private final RectF mapButton = new RectF();
    private final RectF closeButton = new RectF();
    private boolean open;
    private int selectedIsland;
    private Field screenField;
    private Field islandField;
    private Field defeatedBossesField;
    private boolean reflectionReady;

    public WorldMapOverlay(Context context, PirateGameViewV2 gameView) {
        super(context);
        this.gameView = gameView;
        stroke.setStyle(Paint.Style.STROKE);
        stroke.setStrokeWidth(4f);
        setClickable(true);
        setFocusable(false);
        setWillNotDraw(false);
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        if (!isGameVisible()) return;
        if (!open) {
            drawMapButton(canvas);
            return;
        }
        drawFullMap(canvas);
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        if (event.getActionMasked() != MotionEvent.ACTION_DOWN || !isGameVisible()) return false;
        float x = event.getX();
        float y = event.getY();
        if (!open) {
            if (!mapButton.contains(x, y)) return false;
            open = true;
            selectedIsland = currentIsland();
            invalidate();
            return true;
        }
        if (closeButton.contains(x, y)) {
            open = false;
            invalidate();
            return true;
        }
        for (int i = 0; i < WorldConfig.ISLAND_COUNT; i++) {
            float px = getWidth() * WorldConfig.MAP_X[i];
            float py = getHeight() * WorldConfig.MAP_Y[i];
            if (GameMath.distance(x, y, px, py) <= 44f) {
                selectedIsland = i;
                invalidate();
                return true;
            }
        }
        return true;
    }

    private void drawMapButton(Canvas canvas) {
        mapButton.set(getWidth() - 230f, 15f, getWidth() - 112f, 63f);
        paint.setColor(Color.argb(220, 10, 43, 67));
        canvas.drawRoundRect(mapButton, 16f, 16f, paint);
        stroke.setColor(Color.argb(190, 255, 255, 255));
        stroke.setStrokeWidth(2f);
        canvas.drawRoundRect(mapButton, 16f, 16f, stroke);
        text(canvas, "CARTE", mapButton.centerX(), mapButton.centerY() + 6f, 16f, Color.WHITE, true, Paint.Align.CENTER);
    }

    private void drawFullMap(Canvas canvas) {
        paint.setShader(new LinearGradient(0f, 0f, 0f, getHeight(),
                Color.rgb(5, 40, 68), Color.rgb(7, 85, 116), Shader.TileMode.CLAMP));
        canvas.drawRect(0f, 0f, getWidth(), getHeight(), paint);
        paint.setShader(null);

        drawOcean(canvas);
        drawRoute(canvas);

        int current = currentIsland();
        int unlocked = Math.min(WorldConfig.ISLAND_COUNT - 1,
                Math.max(current, defeatedBosses() + 1));
        for (int i = 0; i < WorldConfig.ISLAND_COUNT; i++) {
            drawIsland(canvas, i, current, unlocked);
        }

        paint.setColor(Color.argb(225, 3, 18, 31));
        canvas.drawRoundRect(new RectF(20f, 14f, getWidth() - 20f, 84f), 18f, 18f, paint);
        text(canvas, "CARTE DU MONDE • 8 ÎLES RELIÉES PAR L'OCÉAN", getWidth() * 0.5f, 43f,
                20f, Color.rgb(250, 214, 104), true, Paint.Align.CENTER);
        text(canvas, "Position : " + WorldConfig.ISLAND_NAMES[current], getWidth() * 0.5f, 69f,
                14f, Color.WHITE, false, Paint.Align.CENTER);

        closeButton.set(getWidth() - 98f, 20f, getWidth() - 30f, 72f);
        paint.setColor(Color.rgb(154, 48, 44));
        canvas.drawRoundRect(closeButton, 14f, 14f, paint);
        text(canvas, "X", closeButton.centerX(), closeButton.centerY() + 7f, 20f,
                Color.WHITE, true, Paint.Align.CENTER);

        float boxTop = getHeight() - 88f;
        paint.setColor(Color.argb(225, 3, 18, 31));
        canvas.drawRoundRect(new RectF(24f, boxTop, getWidth() - 24f, getHeight() - 18f), 18f, 18f, paint);
        String detail = selectedIsland == 7
                ? "Citadelle du Crâne • mer de magma • forteresse volcanique"
                : selectedIsland == 6
                ? "Île des Gâteaux • royaume pâtissier • roster 2.5D dédié"
                : WorldConfig.ISLAND_NAMES[selectedIsland] + " • route maritime pilotable";
        text(canvas, detail, getWidth() * 0.5f, boxTop + 30f, 16f, Color.WHITE, true, Paint.Align.CENTER);
        text(canvas, "Touchez une île pour consulter sa position. Le voyage se fait uniquement en bateau.",
                getWidth() * 0.5f, boxTop + 56f, 13f, Color.rgb(199, 224, 238), false, Paint.Align.CENTER);
    }

    private void drawOcean(Canvas canvas) {
        paint.setColor(Color.argb(38, 210, 239, 249));
        for (int row = 0; row < 9; row++) {
            float y = 105f + row * Math.max(30f, (getHeight() - 210f) / 9f);
            for (int x = -60; x < getWidth() + 60; x += 105) {
                canvas.drawArc(new RectF(x, y, x + 58f, y + 18f), 200f, 140f, false, paint);
            }
        }
    }

    private void drawRoute(Canvas canvas) {
        route.reset();
        for (int i = 0; i < WorldConfig.ISLAND_COUNT; i++) {
            float x = getWidth() * WorldConfig.MAP_X[i];
            float y = getHeight() * WorldConfig.MAP_Y[i];
            if (i == 0) route.moveTo(x, y); else route.lineTo(x, y);
        }
        stroke.setColor(Color.argb(180, 244, 219, 130));
        stroke.setStrokeWidth(7f);
        canvas.drawPath(route, stroke);
        stroke.setColor(Color.argb(220, 9, 49, 73));
        stroke.setStrokeWidth(3f);
        canvas.drawPath(route, stroke);
    }

    private void drawIsland(Canvas canvas, int island, int current, int unlocked) {
        float x = getWidth() * WorldConfig.MAP_X[island];
        float y = getHeight() * WorldConfig.MAP_Y[island];
        boolean locked = island > unlocked;
        boolean selected = island == selectedIsland;
        float radius = selected ? 37f : 31f;

        if (island == 7) {
            paint.setColor(Color.argb(150, 255, 80, 20));
            canvas.drawCircle(x, y, radius + 14f, paint);
        }
        paint.setColor(locked ? Color.rgb(69, 79, 83)
                : island == 6 ? Color.rgb(239, 154, 190)
                : island == 7 ? Color.rgb(64, 52, 48)
                : Color.rgb(73, 142, 79));
        canvas.drawCircle(x, y, radius, paint);
        stroke.setColor(island == current ? Color.WHITE
                : selected ? Color.rgb(250, 214, 104) : Color.argb(180, 20, 25, 29));
        stroke.setStrokeWidth(island == current ? 6f : 3f);
        canvas.drawCircle(x, y, radius, stroke);

        if (island == 6) drawCakeIcon(canvas, x, y);
        else if (island == 7) drawSkullIcon(canvas, x, y);
        else {
            paint.setColor(locked ? Color.DKGRAY : Color.rgb(47, 93, 53));
            canvas.drawOval(new RectF(x - radius * 0.65f, y - 8f, x + radius * 0.65f, y + 13f), paint);
            paint.setColor(Color.rgb(142, 106, 62));
            canvas.drawRect(x - 3f, y - 24f, x + 3f, y + 4f, paint);
            paint.setColor(Color.rgb(47, 124, 67));
            canvas.drawCircle(x, y - 26f, 11f, paint);
        }

        text(canvas, Integer.toString(island + 1), x, y + 6f, 13f, Color.WHITE, true, Paint.Align.CENTER);
        text(canvas, shortName(island), x, y + radius + 19f, 12f, Color.WHITE, true, Paint.Align.CENTER);
    }

    private void drawCakeIcon(Canvas canvas, float x, float y) {
        paint.setColor(Color.rgb(255, 228, 184));
        canvas.drawRoundRect(new RectF(x - 20f, y - 7f, x + 20f, y + 15f), 5f, 5f, paint);
        paint.setColor(Color.rgb(244, 111, 160));
        canvas.drawRoundRect(new RectF(x - 14f, y - 21f, x + 14f, y - 4f), 5f, 5f, paint);
    }

    private void drawSkullIcon(Canvas canvas, float x, float y) {
        paint.setColor(Color.rgb(207, 198, 177));
        canvas.drawCircle(x, y - 5f, 17f, paint);
        paint.setColor(Color.rgb(35, 29, 27));
        canvas.drawCircle(x - 6f, y - 7f, 4f, paint);
        canvas.drawCircle(x + 6f, y - 7f, 4f, paint);
        canvas.drawRect(x - 8f, y + 7f, x + 8f, y + 16f, paint);
    }

    private String shortName(int island) {
        return switch (island) {
            case 0 -> "Port";
            case 1 -> "Jungle";
            case 2 -> "Neiges";
            case 3 -> "Désert";
            case 4 -> "Volcan";
            case 5 -> "Tempête";
            case 6 -> "Gâteaux";
            default -> "Crâne";
        };
    }

    private boolean isGameVisible() {
        if (!ensureReflection()) return false;
        try {
            Object screen = screenField.get(gameView);
            return screen != null && ("GAME".equals(screen.toString()) || "PAUSE".equals(screen.toString()));
        } catch (IllegalAccessException ignored) {
            return false;
        }
    }

    private int currentIsland() {
        if (!ensureReflection()) return 0;
        try {
            return WorldConfig.clampIsland(islandField.getInt(gameView));
        } catch (IllegalAccessException ignored) {
            return 0;
        }
    }

    private int defeatedBosses() {
        if (!ensureReflection()) return 0;
        try {
            return Math.max(0, defeatedBossesField.getInt(gameView));
        } catch (IllegalAccessException ignored) {
            return 0;
        }
    }

    private boolean ensureReflection() {
        if (reflectionReady) return true;
        try {
            Class<?> type = gameView.getClass();
            screenField = field(type, "screen");
            islandField = field(type, "currentIsland");
            defeatedBossesField = field(type, "defeatedBosses");
            reflectionReady = true;
        } catch (ReflectiveOperationException ignored) {
            reflectionReady = false;
        }
        return reflectionReady;
    }

    private static Field field(Class<?> type, String name) throws ReflectiveOperationException {
        Field result = type.getDeclaredField(name);
        result.setAccessible(true);
        return result;
    }

    private void text(Canvas canvas, String value, float x, float y, float size,
                      int color, boolean bold, Paint.Align align) {
        paint.setShader(null);
        paint.setStyle(Paint.Style.FILL);
        paint.setColor(color);
        paint.setTextSize(size);
        paint.setTextAlign(align);
        paint.setFakeBoldText(bold);
        canvas.drawText(value, x, y, paint);
        paint.setFakeBoldText(false);
    }
}
