package fr.chk.piratewarrior;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RectF;
import android.graphics.Shader;
import android.view.View;

import java.lang.reflect.Field;
import java.util.Random;

/**
 * Rend les deux nouvelles îles au-dessus du monde historique sans casser les six zones existantes.
 * Les contrôles tactiles restent ceux de PirateGameViewV2 et les héros/ennemis 2.5D sont dessinés
 * par leurs overlays officiels juste après cette couche.
 */
public final class ExtendedIslandOverlay extends View {
    private final PirateGameViewV2 gameView;
    private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint stroke = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Path path = new Path();
    private final Random random = new Random(0x8C4A7EL);
    private Field screenField;
    private Field islandField;
    private Field missionKillsField;
    private Field coinsField;
    private Field selectedHeroField;
    private boolean reflectionReady;
    private float animation;
    private long lastNanos;

    public ExtendedIslandOverlay(Context context, PirateGameViewV2 gameView) {
        super(context);
        this.gameView = gameView;
        stroke.setStyle(Paint.Style.STROKE);
        setClickable(false);
        setFocusable(false);
        setWillNotDraw(false);
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        float dt = frameDelta();
        animation += dt;
        if (!ensureReflection()) return;
        try {
            Object screen = screenField.get(gameView);
            if (screen == null || !("GAME".equals(screen.toString()) || "PAUSE".equals(screen.toString()))) {
                return;
            }
            int fallback = islandField.getInt(gameView);
            int active = WorldSession.activeIsland(fallback);
            if (active < 6) return;

            // Réapplique l'île étendue après la mise à jour du moteur historique, qui reste borné à 6.
            islandField.setInt(gameView, active);
            if (active == 6) drawCakeIsland(canvas);
            else drawSkullMagmaIsland(canvas);
            drawExtendedHud(canvas, active);
            drawControls(canvas);
            postInvalidateOnAnimation();
        } catch (ReflectiveOperationException ignored) {
            // Le moteur historique reste visible si une version incompatible est chargée.
        }
    }

    private void drawCakeIsland(Canvas canvas) {
        paint.setShader(new LinearGradient(0f, 0f, 0f, getHeight(),
                Color.rgb(126, 85, 171), Color.rgb(247, 174, 203), Shader.TileMode.CLAMP));
        canvas.drawRect(0f, 0f, getWidth(), getHeight(), paint);
        paint.setShader(null);

        drawCreamCloud(canvas, getWidth() * 0.16f, getHeight() * 0.18f, 70f);
        drawCreamCloud(canvas, getWidth() * 0.76f, getHeight() * 0.13f, 86f);
        drawCakeCastle(canvas, getWidth() * 0.52f, getHeight() * 0.48f);

        paint.setColor(Color.rgb(222, 164, 105));
        canvas.drawRect(0f, getHeight() * 0.48f, getWidth(), getHeight(), paint);
        paint.setColor(Color.rgb(125, 66, 45));
        for (int i = 0; i < 8; i++) {
            float y = getHeight() * 0.52f + i * getHeight() * 0.052f;
            canvas.drawLine(0f, y, getWidth(), y, paint);
        }
        paint.setColor(Color.argb(155, 255, 213, 231));
        for (int i = 0; i < 22; i++) {
            float x = (i * 97f + animation * 18f) % (getWidth() + 80f) - 40f;
            float y = getHeight() * 0.22f + (i % 7) * 42f;
            canvas.drawCircle(x, y, 4f + i % 3, paint);
        }
    }

    private void drawCreamCloud(Canvas canvas, float x, float y, float size) {
        paint.setColor(Color.argb(220, 255, 238, 245));
        canvas.drawCircle(x - size * 0.45f, y, size * 0.42f, paint);
        canvas.drawCircle(x, y - size * 0.16f, size * 0.58f, paint);
        canvas.drawCircle(x + size * 0.48f, y, size * 0.40f, paint);
    }

    private void drawCakeCastle(Canvas canvas, float x, float groundY) {
        paint.setColor(Color.rgb(116, 61, 48));
        canvas.drawRoundRect(new RectF(x - 180f, groundY - 155f, x + 180f, groundY + 20f), 22f, 22f, paint);
        paint.setColor(Color.rgb(255, 214, 229));
        canvas.drawRoundRect(new RectF(x - 158f, groundY - 185f, x + 158f, groundY - 105f), 28f, 28f, paint);
        paint.setColor(Color.rgb(247, 121, 167));
        canvas.drawRoundRect(new RectF(x - 118f, groundY - 260f, x + 118f, groundY - 176f), 28f, 28f, paint);
        paint.setColor(Color.rgb(255, 225, 142));
        canvas.drawRoundRect(new RectF(x - 75f, groundY - 330f, x + 75f, groundY - 250f), 24f, 24f, paint);
        paint.setColor(Color.rgb(72, 37, 35));
        canvas.drawRoundRect(new RectF(x - 28f, groundY - 65f, x + 28f, groundY + 20f), 15f, 15f, paint);
    }

    private void drawSkullMagmaIsland(Canvas canvas) {
        paint.setShader(new LinearGradient(0f, 0f, 0f, getHeight(),
                Color.rgb(24, 17, 28), Color.rgb(75, 29, 22), Shader.TileMode.CLAMP));
        canvas.drawRect(0f, 0f, getWidth(), getHeight(), paint);
        paint.setShader(null);

        drawSmoke(canvas);
        drawSkullFortress(canvas, getWidth() * 0.52f, getHeight() * 0.49f,
                Math.min(getWidth() * 0.28f, getHeight() * 0.38f));

        paint.setColor(Color.rgb(39, 34, 36));
        canvas.drawRect(0f, getHeight() * 0.47f, getWidth(), getHeight(), paint);
        drawMagmaRivers(canvas);
        drawBasaltPlatforms(canvas);
        drawAsh(canvas);
    }

    private void drawSmoke(Canvas canvas) {
        for (int i = 0; i < 12; i++) {
            float x = (i * 143f + 57f) % Math.max(1f, getWidth());
            float y = getHeight() * 0.19f + (i % 4) * 38f
                    + (float) Math.sin(animation * 0.8f + i) * 10f;
            float r = 36f + (i % 3) * 16f;
            paint.setColor(Color.argb(45, 180, 160, 177));
            canvas.drawCircle(x, y, r, paint);
        }
    }

    private void drawSkullFortress(Canvas canvas, float x, float y, float radius) {
        paint.setColor(Color.rgb(91, 84, 79));
        canvas.drawCircle(x, y - radius * 0.42f, radius, paint);
        path.reset();
        path.moveTo(x - radius * 0.72f, y - radius * 1.0f);
        path.lineTo(x - radius * 1.35f, y - radius * 1.75f);
        path.lineTo(x - radius * 1.02f, y - radius * 0.45f);
        path.close();
        canvas.drawPath(path, paint);
        path.reset();
        path.moveTo(x + radius * 0.72f, y - radius * 1.0f);
        path.lineTo(x + radius * 1.35f, y - radius * 1.75f);
        path.lineTo(x + radius * 1.02f, y - radius * 0.45f);
        path.close();
        canvas.drawPath(path, paint);

        paint.setColor(Color.rgb(22, 18, 20));
        canvas.drawOval(new RectF(x - radius * 0.72f, y - radius * 0.72f,
                x - radius * 0.12f, y - radius * 0.08f), paint);
        canvas.drawOval(new RectF(x + radius * 0.12f, y - radius * 0.72f,
                x + radius * 0.72f, y - radius * 0.08f), paint);
        path.reset();
        path.moveTo(x, y - radius * 0.30f);
        path.lineTo(x - radius * 0.18f, y + radius * 0.08f);
        path.lineTo(x + radius * 0.18f, y + radius * 0.08f);
        path.close();
        canvas.drawPath(path, paint);

        paint.setColor(Color.rgb(18, 15, 16));
        canvas.drawRoundRect(new RectF(x - radius * 0.58f, y + radius * 0.14f,
                x + radius * 0.58f, y + radius * 0.75f), 18f, 18f, paint);
        paint.setColor(Color.rgb(199, 101, 31));
        for (int i = -2; i <= 2; i++) {
            canvas.drawRect(x + i * radius * 0.20f - radius * 0.055f,
                    y + radius * 0.12f, x + i * radius * 0.20f + radius * 0.055f,
                    y + radius * 0.58f, paint);
        }

        paint.setColor(Color.rgb(48, 41, 42));
        canvas.drawRect(x - radius * 0.55f, y - radius * 1.56f,
                x + radius * 0.55f, y - radius * 1.02f, paint);
        paint.setColor(Color.rgb(173, 55, 42));
        canvas.drawRect(x - radius * 0.05f, y - radius * 1.82f,
                x + radius * 0.02f, y - radius * 1.40f, paint);
        path.reset();
        path.moveTo(x + radius * 0.02f, y - radius * 1.80f);
        path.lineTo(x + radius * 0.43f, y - radius * 1.63f);
        path.lineTo(x + radius * 0.02f, y - radius * 1.48f);
        path.close();
        canvas.drawPath(path, paint);

        paint.setColor(Color.argb(200, 255, 105, 22));
        canvas.drawCircle(x - radius * 0.40f, y - radius * 0.40f, radius * 0.10f, paint);
        canvas.drawCircle(x + radius * 0.40f, y - radius * 0.40f, radius * 0.10f, paint);
    }

    private void drawMagmaRivers(Canvas canvas) {
        paint.setShader(new LinearGradient(0f, getHeight() * 0.52f, 0f, getHeight(),
                Color.rgb(255, 143, 25), Color.rgb(137, 28, 15), Shader.TileMode.CLAMP));
        path.reset();
        path.moveTo(0f, getHeight() * 0.64f);
        path.cubicTo(getWidth() * 0.22f, getHeight() * 0.55f,
                getWidth() * 0.32f, getHeight() * 0.84f,
                getWidth() * 0.52f, getHeight() * 0.69f);
        path.cubicTo(getWidth() * 0.68f, getHeight() * 0.58f,
                getWidth() * 0.82f, getHeight() * 0.90f,
                getWidth(), getHeight() * 0.72f);
        path.lineTo(getWidth(), getHeight());
        path.lineTo(0f, getHeight());
        path.close();
        canvas.drawPath(path, paint);
        paint.setShader(null);
        paint.setColor(Color.argb(150, 255, 231, 120));
        for (int i = 0; i < 15; i++) {
            float x = (i * 113f + animation * 35f) % (getWidth() + 50f) - 25f;
            float y = getHeight() * (0.69f + (i % 4) * 0.06f);
            canvas.drawOval(new RectF(x - 18f, y - 3f, x + 18f, y + 4f), paint);
        }
    }

    private void drawBasaltPlatforms(Canvas canvas) {
        paint.setColor(Color.rgb(55, 49, 51));
        for (int i = 0; i < 9; i++) {
            float x = (i + 0.5f) * getWidth() / 9f;
            float y = getHeight() * (0.59f + (i % 3) * 0.08f);
            float w = 74f + (i % 2) * 24f;
            path.reset();
            path.moveTo(x - w, y + 25f);
            path.lineTo(x - w * 0.65f, y - 30f);
            path.lineTo(x + w * 0.45f, y - 38f);
            path.lineTo(x + w, y + 25f);
            path.close();
            canvas.drawPath(path, paint);
        }
    }

    private void drawAsh(Canvas canvas) {
        paint.setColor(Color.argb(145, 205, 193, 190));
        for (int i = 0; i < 42; i++) {
            float x = (i * 83f + animation * (10f + i % 4)) % (getWidth() + 30f) - 15f;
            float y = (i * 47f + animation * (22f + i % 5)) % Math.max(1f, getHeight());
            canvas.drawCircle(x, y, 1.4f + i % 3, paint);
        }
    }

    private void drawExtendedHud(Canvas canvas, int island) throws IllegalAccessException {
        paint.setColor(Color.argb(220, 4, 14, 24));
        canvas.drawRoundRect(new RectF(18f, 15f, getWidth() - 18f, 112f), 18f, 18f, paint);
        text(canvas, WorldConfig.ISLAND_NAMES[island], getWidth() * 0.5f, 43f,
                22f, island == 7 ? Color.rgb(255, 158, 64) : Color.rgb(255, 217, 132), true, Paint.Align.CENTER);
        int missionKills = missionKillsField.getInt(gameView);
        String mission = missionKills < 0 ? "Mission : vaincre le boss"
                : "Mission : " + Math.max(0, missionKills) + "/8";
        text(canvas, mission, getWidth() * 0.5f, 70f, 16f, Color.WHITE, false, Paint.Align.CENTER);
        text(canvas, coinsField.getInt(gameView) + " pièces", getWidth() - 35f, 96f,
                15f, Color.WHITE, true, Paint.Align.RIGHT);
        text(canvas, island == 7 ? "Danger : magma autour de l'île" : "Royaume des délices",
                30f, 96f, 14f, Color.rgb(230, 200, 148), true, Paint.Align.LEFT);
    }

    private void drawControls(Canvas canvas) {
        float moveX = Math.max(112f, getWidth() * 0.105f);
        float moveY = getHeight() - Math.max(105f, getHeight() * 0.19f);
        float cameraX = getWidth() - Math.max(285f, getWidth() * 0.22f);
        float cameraY = getHeight() - Math.max(100f, getHeight() * 0.18f);
        drawJoystick(canvas, moveX, moveY, "DÉPLACER");
        drawJoystick(canvas, cameraX, cameraY, "CAMÉRA");
        drawAction(canvas, getWidth() - 84f, getHeight() - 88f, 54f, Color.rgb(197, 52, 47), "ATTAQUE");
        drawAction(canvas, getWidth() - 198f, getHeight() - 165f, 47f, Color.rgb(37, 124, 188), "POUVOIR");
        drawAction(canvas, getWidth() - 92f, getHeight() - 228f, 43f, Color.rgb(111, 82, 165), "SAUT");
        drawAction(canvas, getWidth() - 292f, getHeight() - 73f, 42f, Color.rgb(45, 151, 96), "ESQUIVE");
    }

    private void drawJoystick(Canvas canvas, float x, float y, String label) {
        paint.setColor(Color.argb(75, 255, 255, 255));
        canvas.drawCircle(x, y, 74f, paint);
        stroke.setColor(Color.argb(150, 255, 255, 255));
        stroke.setStrokeWidth(4f);
        canvas.drawCircle(x, y, 74f, stroke);
        paint.setColor(Color.argb(185, 20, 31, 45));
        canvas.drawCircle(x, y, 31f, paint);
        text(canvas, label, x, y + 98f, 13f, Color.WHITE, true, Paint.Align.CENTER);
    }

    private void drawAction(Canvas canvas, float x, float y, float radius, int color, String label) {
        paint.setColor(Color.argb(220, Color.red(color), Color.green(color), Color.blue(color)));
        canvas.drawCircle(x, y, radius, paint);
        stroke.setColor(Color.argb(190, 255, 255, 255));
        stroke.setStrokeWidth(3f);
        canvas.drawCircle(x, y, radius, stroke);
        text(canvas, label, x, y + 5f, Math.max(11f, radius * 0.27f), Color.WHITE, true, Paint.Align.CENTER);
    }

    private boolean ensureReflection() {
        if (reflectionReady) return true;
        try {
            Class<?> type = gameView.getClass();
            screenField = field(type, "screen");
            islandField = field(type, "currentIsland");
            missionKillsField = field(type, "missionKills");
            coinsField = field(type, "coins");
            selectedHeroField = field(type, "selectedHero");
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

    private float frameDelta() {
        long now = System.nanoTime();
        float dt = lastNanos == 0L ? 0f : Math.min(0.05f, (now - lastNanos) / 1_000_000_000f);
        lastNanos = now;
        return dt;
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
