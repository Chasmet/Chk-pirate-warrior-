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
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

/** Navigation pilotable avant/arrière sur la route océanique complète des huit îles. */
public final class OceanTravelOverlay extends View {
    private enum Mode { LAND, SAILING, ARRIVAL }

    private static final float ROUTE_DISTANCE = WorldConfig.ROUTE_DISTANCE;
    private final PirateGameViewV2 gameView;
    private final BoatPhysics physics = new BoatPhysics();
    private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint stroke = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Path path = new Path();
    private final RectF forwardButton = new RectF();
    private final RectF backwardButton = new RectF();
    private final RectF dockButton = new RectF();
    private final RectF brakeButton = new RectF();
    private final List<RouteHazard> hazards = new ArrayList<>();
    private final Random random = new Random(0x0CEA84L);

    private Mode mode = Mode.LAND;
    private Character25D pilotSprite;
    private int pilotHero = -1;
    private int departureIsland;
    private int destinationIsland;
    private int direction = 1;
    private int controlPointer = -1;
    private int cameraPointer = -1;
    private float throttle;
    private float steering;
    private float brake;
    private float cameraYaw;
    private float lastCameraX;
    private float routeDistance;
    private float hull = 100f;
    private float wind;
    private float shake;
    private float animationTime;
    private long lastFrameNanos;
    private String transientMessage;
    private float messageTime;

    private boolean reflectionReady;
    private Field screenField;
    private Field islandField;
    private Field playerXField;
    private Field playerYField;
    private Field selectedHeroField;
    private Field enemiesField;
    private Field projectilesField;
    private Method rebuildObstaclesMethod;
    private Method chooseWeatherMethod;

    public OceanTravelOverlay(Context context, PirateGameViewV2 gameView) {
        super(context);
        this.gameView = gameView;
        stroke.setStyle(Paint.Style.STROKE);
        stroke.setStrokeWidth(3f);
        setFocusable(false);
        setClickable(true);
        setWillNotDraw(false);
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        float dt = frameDelta();
        animationTime += dt;
        shake = Math.max(0f, shake - dt * 20f);
        messageTime = Math.max(0f, messageTime - dt);

        if (mode == Mode.LAND) drawLandOverlay(canvas);
        else {
            updateSailing(dt);
            drawSailing(canvas);
        }
        postInvalidateOnAnimation();
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        int action = event.getActionMasked();
        int actionIndex = event.getActionIndex();
        float x = event.getX(actionIndex);
        float y = event.getY(actionIndex);

        if (mode == Mode.LAND) {
            if (action == MotionEvent.ACTION_DOWN && forwardButton.contains(x, y)) {
                startVoyage(1);
                return true;
            }
            if (action == MotionEvent.ACTION_DOWN && backwardButton.contains(x, y)) {
                startVoyage(-1);
                return true;
            }
            return false;
        }

        if (mode == Mode.ARRIVAL && action == MotionEvent.ACTION_DOWN && dockButton.contains(x, y)) {
            finishVoyage();
            return true;
        }

        if (action == MotionEvent.ACTION_DOWN || action == MotionEvent.ACTION_POINTER_DOWN) {
            int pointerId = event.getPointerId(actionIndex);
            if (brakeButton.contains(x, y)) {
                brake = 1f;
                return true;
            }
            if (x < getWidth() * 0.56f && controlPointer == -1) {
                controlPointer = pointerId;
                updateControl(x, y);
            } else if (cameraPointer == -1) {
                cameraPointer = pointerId;
                lastCameraX = x;
            }
            return true;
        }

        if (action == MotionEvent.ACTION_MOVE) {
            for (int i = 0; i < event.getPointerCount(); i++) {
                int pointerId = event.getPointerId(i);
                if (pointerId == controlPointer) updateControl(event.getX(i), event.getY(i));
                else if (pointerId == cameraPointer) {
                    float current = event.getX(i);
                    cameraYaw = GameMath.clamp(cameraYaw
                            + (current - lastCameraX) / Math.max(1f, getWidth()) * 2.4f,
                            -1f, 1f);
                    lastCameraX = current;
                }
            }
            return true;
        }

        if (action == MotionEvent.ACTION_UP || action == MotionEvent.ACTION_POINTER_UP
                || action == MotionEvent.ACTION_CANCEL) {
            int pointerId = event.getPointerId(actionIndex);
            if (pointerId == controlPointer || action == MotionEvent.ACTION_CANCEL) {
                controlPointer = -1;
                throttle = 0f;
                steering = 0f;
            }
            if (pointerId == cameraPointer || action == MotionEvent.ACTION_CANCEL) {
                cameraPointer = -1;
            }
            if (brakeButton.contains(x, y) || action == MotionEvent.ACTION_CANCEL) brake = 0f;
            return true;
        }
        return true;
    }

    @Override
    protected void onDetachedFromWindow() {
        releasePilot();
        super.onDetachedFromWindow();
    }

    private void drawLandOverlay(Canvas canvas) {
        if (!ensureReflection() || !isGameVisible()) {
            forwardButton.setEmpty();
            backwardButton.setEmpty();
            return;
        }
        try {
            int gameIsland = islandField.getInt(gameView);
            int island = WorldSession.activeIsland(gameIsland);
            int hero = selectedHeroField.getInt(gameView);
            float playerX = playerXField.getFloat(gameView);
            int segment = Math.min(5, island);
            float localX = playerX - segment * WorldConfig.ISLAND_WIDTH;

            islandField.setInt(gameView, island);
            drawLocationChip(canvas, island);

            if (WorldConfig.hasNextIsland(island) && localX > WorldConfig.ISLAND_WIDTH - 430f) {
                forwardButton.set(getWidth() - 288f, getHeight() * 0.36f,
                        getWidth() - 24f, getHeight() * 0.48f);
                button(canvas, forwardButton, "EMBARQUER →", Color.rgb(155, 63, 35));
                text(canvas, WorldConfig.ISLAND_NAMES[island + 1], forwardButton.centerX(),
                        forwardButton.bottom + 21f, 13f, Color.WHITE, false, Paint.Align.CENTER);
            } else forwardButton.setEmpty();

            if (island > 0 && localX < 430f) {
                backwardButton.set(24f, getHeight() * 0.36f,
                        288f, getHeight() * 0.48f);
                button(canvas, backwardButton, "← RETOUR MER", Color.rgb(50, 87, 120));
                text(canvas, WorldConfig.ISLAND_NAMES[island - 1], backwardButton.centerX(),
                        backwardButton.bottom + 21f, 13f, Color.WHITE, false, Paint.Align.CENTER);
            } else backwardButton.setEmpty();

            if (messageTime > 0f && transientMessage != null) {
                paint.setColor(Color.argb(225, 25, 8, 8));
                canvas.drawRoundRect(new RectF(getWidth() * 0.25f, getHeight() * 0.72f,
                        getWidth() * 0.75f, getHeight() * 0.81f), 18f, 18f, paint);
                text(canvas, transientMessage, getWidth() * 0.5f, getHeight() * 0.775f,
                        17f, Color.WHITE, true, Paint.Align.CENTER);
            }
        } catch (ReflectiveOperationException ignored) {
            forwardButton.setEmpty();
            backwardButton.setEmpty();
        }
    }

    private void drawLocationChip(Canvas canvas, int island) {
        paint.setColor(Color.argb(205, 5, 15, 26));
        canvas.drawRoundRect(new RectF(getWidth() * 0.30f, 116f,
                getWidth() * 0.70f, 168f), 18f, 18f, paint);
        int color = island == 7 ? Color.rgb(255, 149, 60) : Color.rgb(250, 214, 104);
        text(canvas, WorldConfig.ISLAND_NAMES[island], getWidth() * 0.5f, 148f,
                19f, color, true, Paint.Align.CENTER);
    }

    private boolean isGameVisible() throws IllegalAccessException {
        Object screen = screenField.get(gameView);
        return screen != null && ("GAME".equals(screen.toString()) || "PAUSE".equals(screen.toString()));
    }

    private void startVoyage(int requestedDirection) {
        if (!ensureReflection()) return;
        try {
            departureIsland = WorldSession.activeIsland(islandField.getInt(gameView));
            int candidate = departureIsland + requestedDirection;
            if (candidate < 0 || candidate >= WorldConfig.ISLAND_COUNT) return;
            direction = requestedDirection;
            destinationIsland = candidate;
            ensurePilot(selectedHeroField.getInt(gameView));
            physics.reset();
            routeDistance = 0f;
            hull = 100f;
            throttle = 0f;
            steering = 0f;
            brake = 0f;
            cameraYaw = 0f;
            wind = -0.45f + random.nextFloat() * 0.90f;
            createRouteHazards();
            mode = Mode.SAILING;
            lastFrameNanos = 0L;
            forwardButton.setEmpty();
            backwardButton.setEmpty();
            gameView.pauseGameLoop();
        } catch (ReflectiveOperationException ignored) {
            mode = Mode.LAND;
        }
    }

    private void updateSailing(float dt) {
        if (mode == Mode.ARRIVAL) {
            brake = 1f;
            throttle = 0f;
        }
        physics.update(throttle, steering, brake, wind, dt);
        routeDistance += Math.max(0f, physics.getSpeed()) * dt;

        for (RouteHazard hazard : hazards) {
            if (hazard.hit) continue;
            float longitudinal = hazard.distance - routeDistance;
            float lateral = hazard.lane - physics.getLane();
            if (Math.abs(longitudinal) < 40f && Math.abs(lateral) < hazard.radius + 52f) {
                hazard.hit = true;
                float impact = physics.collide(0.72f + hazard.radius / 180f);
                hull = Math.max(0f, hull - 14f - impact * 32f);
                shake = 18f + impact * 24f;
                transientMessage = hazard.magma ? "Impact avec une roche de magma"
                        : "Collision avec un récif";
                messageTime = 2.2f;
            }
        }

        if (hull <= 0f) {
            abortVoyage();
            return;
        }
        if (routeDistance >= ROUTE_DISTANCE && mode == Mode.SAILING) {
            routeDistance = ROUTE_DISTANCE;
            mode = Mode.ARRIVAL;
            throttle = 0f;
            brake = 1f;
        }
    }

    private void drawSailing(Canvas canvas) {
        boolean magmaRoute = WorldConfig.isMagmaRoute(departureIsland, destinationIsland);
        canvas.save();
        if (shake > 0f) {
            canvas.translate(-shake * 0.5f + random.nextFloat() * shake,
                    -shake * 0.5f + random.nextFloat() * shake);
        }

        int skyTop = magmaRoute ? Color.rgb(45, 20, 25)
                : destinationIsland == 2 ? Color.rgb(48, 76, 111)
                : destinationIsland == 5 ? Color.rgb(27, 34, 64)
                : destinationIsland == 6 ? Color.rgb(135, 88, 170)
                : Color.rgb(52, 139, 196);
        int skyBottom = magmaRoute ? Color.rgb(176, 75, 42) : Color.rgb(181, 218, 230);
        paint.setShader(new LinearGradient(0f, 0f, 0f, getHeight() * 0.58f,
                skyTop, skyBottom, Shader.TileMode.CLAMP));
        canvas.drawRect(0f, 0f, getWidth(), getHeight() * 0.58f, paint);
        paint.setShader(null);

        float horizon = getHeight() * 0.36f;
        paint.setColor(magmaRoute ? Color.rgb(82, 40, 35) : Color.rgb(17, 83, 123));
        canvas.drawRect(0f, horizon, getWidth(), getHeight(), paint);
        drawDestinationIsland(canvas, horizon, magmaRoute);
        drawWaves(canvas, horizon, magmaRoute);
        drawHazards(canvas, horizon);
        drawShip(canvas, getWidth() * 0.52f, getHeight() * 0.77f);
        canvas.restore();

        drawSailingHud(canvas, magmaRoute);
        drawSailingControls(canvas);
    }

    private void drawDestinationIsland(Canvas canvas, float horizon, boolean magmaRoute) {
        float progress = routeDistance / ROUTE_DISTANCE;
        float islandWidth = 90f + progress * getWidth() * 0.55f;
        float islandHeight = 24f + progress * getHeight() * 0.18f;
        float center = getWidth() * (0.54f - cameraYaw * 0.08f);
        paint.setColor(destinationIsland == 6 ? Color.rgb(161, 91, 130)
                : destinationIsland == 7 ? Color.rgb(48, 42, 43)
                : Color.rgb(41, 73, 61));
        path.reset();
        path.moveTo(center - islandWidth * 0.5f, horizon + 4f);
        path.lineTo(center - islandWidth * 0.24f, horizon - islandHeight * 0.55f);
        path.lineTo(center, horizon - islandHeight);
        path.lineTo(center + islandWidth * 0.22f, horizon - islandHeight * 0.42f);
        path.lineTo(center + islandWidth * 0.5f, horizon + 4f);
        path.close();
        canvas.drawPath(path, paint);
        if (destinationIsland == 7 && progress > 0.34f) {
            float r = islandHeight * 0.42f;
            paint.setColor(Color.rgb(105, 97, 89));
            canvas.drawCircle(center, horizon - islandHeight * 0.60f, r, paint);
            paint.setColor(Color.rgb(23, 18, 19));
            canvas.drawCircle(center - r * 0.36f, horizon - islandHeight * 0.67f, r * 0.20f, paint);
            canvas.drawCircle(center + r * 0.36f, horizon - islandHeight * 0.67f, r * 0.20f, paint);
        }
        if (magmaRoute) {
            paint.setColor(Color.argb(190, 255, 105, 22));
            canvas.drawOval(new RectF(center - islandWidth * 0.44f, horizon - 2f,
                    center + islandWidth * 0.44f, horizon + 10f), paint);
        }
    }

    private void drawWaves(Canvas canvas, float horizon, boolean magmaRoute) {
        for (int row = 0; row < 10; row++) {
            float y = horizon + 18f + row * (getHeight() - horizon) / 11f;
            float perspective = row / 9f;
            paint.setColor(magmaRoute
                    ? Color.argb((int) (80 + perspective * 120), 255, 130, 42)
                    : Color.argb((int) (75 + perspective * 100), 184, 225, 239));
            paint.setStrokeWidth(1.5f + perspective * 2.8f);
            for (int x = -80; x < getWidth() + 80; x += 95) {
                float offset = (float) Math.sin(animationTime * (1.8f + perspective)
                        + x * 0.025f + row) * (8f + perspective * 10f);
                canvas.drawLine(x + offset, y, x + 34f + offset, y - 2f, paint);
            }
        }
    }

    private void drawHazards(Canvas canvas, float horizon) {
        for (RouteHazard hazard : hazards) {
            float ahead = hazard.distance - routeDistance;
            if (ahead < -120f || ahead > 1_500f) continue;
            float perspective = 1f - GameMath.clamp(ahead / 1_500f, 0f, 1f);
            float y = horizon + 18f + perspective * perspective * (getHeight() - horizon - 70f);
            float x = getWidth() * 0.5f
                    + (hazard.lane - physics.getLane()) * (0.26f + perspective * 0.92f)
                    - cameraYaw * getWidth() * 0.20f;
            float radius = hazard.radius * (0.22f + perspective * 0.88f);
            paint.setColor(hazard.hit ? Color.rgb(91, 67, 58)
                    : hazard.magma ? Color.rgb(72, 46, 40) : Color.rgb(57, 62, 64));
            path.reset();
            path.moveTo(x - radius, y + radius * 0.25f);
            path.lineTo(x - radius * 0.46f, y - radius * 0.75f);
            path.lineTo(x + radius * 0.12f, y - radius);
            path.lineTo(x + radius, y + radius * 0.25f);
            path.close();
            canvas.drawPath(path, paint);
            if (hazard.magma && !hazard.hit) {
                paint.setColor(Color.rgb(255, 119, 28));
                canvas.drawCircle(x, y - radius * 0.25f, Math.max(3f, radius * 0.15f), paint);
            }
        }
    }

    private void drawShip(Canvas canvas, float centerX, float deckY) {
        float visualHeading = physics.getHeading() - cameraYaw * 0.45f;
        float visualRoll = physics.getRoll() - cameraYaw * 0.08f;
        float scale = 1f + Math.max(0f, physics.getPitch()) * 0.7f;
        canvas.save();
        canvas.rotate((float) Math.toDegrees(visualRoll), centerX, deckY);
        canvas.scale(scale, scale, centerX, deckY);
        canvas.translate((float) Math.sin(visualHeading) * 55f, 0f);

        paint.setColor(Color.argb(100, 0, 0, 0));
        canvas.drawOval(new RectF(centerX - 138f, deckY + 38f, centerX + 138f, deckY + 72f), paint);
        paint.setColor(Color.rgb(78, 46, 28));
        path.reset();
        path.moveTo(centerX - 142f, deckY - 12f);
        path.lineTo(centerX - 103f, deckY + 52f);
        path.lineTo(centerX + 105f, deckY + 52f);
        path.lineTo(centerX + 145f, deckY - 12f);
        path.lineTo(centerX + 92f, deckY + 18f);
        path.lineTo(centerX - 96f, deckY + 18f);
        path.close();
        canvas.drawPath(path, paint);
        paint.setColor(Color.rgb(159, 104, 52));
        canvas.drawRect(centerX - 104f, deckY - 8f, centerX + 105f, deckY + 10f, paint);
        paint.setColor(Color.rgb(89, 56, 34));
        canvas.drawRect(centerX - 6f, deckY - 170f, centerX + 7f, deckY - 4f, paint);
        paint.setColor(Color.rgb(195, 62, 48));
        path.reset();
        path.moveTo(centerX + 8f, deckY - 158f);
        path.lineTo(centerX + 112f, deckY - 125f);
        path.lineTo(centerX + 8f, deckY - 78f);
        path.close();
        canvas.drawPath(path, paint);
        text(canvas, "CHK", centerX + 49f, deckY - 116f, 20f,
                Color.rgb(244, 226, 188), true, Paint.Align.CENTER);
        if (pilotSprite != null) {
            pilotSprite.draw(canvas, Character25D.Pose.PILOT, animationTime,
                    centerX + 22f, deckY - 2f, 92f, direction > 0, 1f);
        }
        drawWheel(canvas, centerX + 20f, deckY - 27f);
        canvas.restore();
    }

    private void drawWheel(Canvas canvas, float x, float y) {
        stroke.setColor(Color.rgb(174, 112, 54));
        stroke.setStrokeWidth(5f);
        canvas.drawCircle(x, y, 20f, stroke);
        for (int i = 0; i < 8; i++) {
            double angle = i * Math.PI / 4.0;
            canvas.drawLine(x, y, x + (float) Math.cos(angle) * 27f,
                    y + (float) Math.sin(angle) * 27f, stroke);
        }
    }

    private void drawSailingHud(Canvas canvas, boolean magmaRoute) {
        paint.setColor(Color.argb(220, 4, 14, 26));
        canvas.drawRoundRect(new RectF(18f, 16f, getWidth() - 18f, 84f), 18f, 18f, paint);
        text(canvas, WorldConfig.ISLAND_NAMES[departureIsland] + "  →  "
                        + WorldConfig.ISLAND_NAMES[destinationIsland],
                getWidth() * 0.5f, 42f, 19f,
                magmaRoute ? Color.rgb(255, 153, 65) : Color.rgb(250, 214, 104),
                true, Paint.Align.CENTER);
        int percent = Math.min(100, Math.round(routeDistance / ROUTE_DISTANCE * 100f));
        text(canvas, "Traversée " + percent + "%  •  Vitesse "
                        + Math.round(Math.max(0f, physics.getSpeed()))
                        + "  •  Coque " + Math.round(hull) + "%",
                getWidth() * 0.5f, 69f, 14f, Color.WHITE, false, Paint.Align.CENTER);
        if (messageTime > 0f && transientMessage != null) {
            text(canvas, transientMessage, getWidth() * 0.5f, 108f, 18f,
                    Color.rgb(255, 124, 92), true, Paint.Align.CENTER);
        }
        if (mode == Mode.ARRIVAL) {
            dockButton.set(getWidth() * 0.35f, getHeight() * 0.84f,
                    getWidth() * 0.65f, getHeight() * 0.96f);
            button(canvas, dockButton, "ACCOSTER", Color.rgb(46, 133, 78));
        } else dockButton.setEmpty();
    }

    private void drawSailingControls(Canvas canvas) {
        float baseX = 125f;
        float baseY = getHeight() - 125f;
        stroke.setColor(Color.argb(175, 255, 255, 255));
        stroke.setStrokeWidth(4f);
        canvas.drawCircle(baseX, baseY, 78f, stroke);
        paint.setColor(Color.argb(115, 255, 255, 255));
        canvas.drawCircle(baseX + steering * 52f, baseY - throttle * 52f, 28f, paint);
        text(canvas, "GAZ / DIRECTION", baseX, baseY + 105f, 12f,
                Color.WHITE, true, Paint.Align.CENTER);
        brakeButton.set(getWidth() - 155f, getHeight() - 182f,
                getWidth() - 35f, getHeight() - 62f);
        paint.setColor(Color.argb(brake > 0f ? 230 : 165, 159, 45, 45));
        canvas.drawCircle(brakeButton.centerX(), brakeButton.centerY(), 58f, paint);
        text(canvas, "FREIN", brakeButton.centerX(), brakeButton.centerY() + 6f,
                17f, Color.WHITE, true, Paint.Align.CENTER);
        text(canvas, "Glisse à droite pour tourner la caméra", getWidth() - 30f,
                getHeight() - 25f, 12f, Color.WHITE, false, Paint.Align.RIGHT);
    }

    private void updateControl(float x, float y) {
        float baseX = 125f;
        float baseY = getHeight() - 125f;
        steering = GameMath.clamp((x - baseX) / 78f, -1f, 1f);
        throttle = GameMath.clamp((baseY - y) / 78f, -1f, 1f);
    }

    private void finishVoyage() {
        if (!ensureReflection()) return;
        try {
            WorldSession.setActiveIsland(destinationIsland);
            int virtualSegment = Math.min(5, destinationIsland);
            float landingX = virtualSegment * WorldConfig.ISLAND_WIDTH
                    + (direction > 0 ? 220f : WorldConfig.ISLAND_WIDTH - 220f);
            playerXField.setFloat(gameView, landingX);
            playerYField.setFloat(gameView, getHeight() * 0.73f);
            clearCombatLists();

            // Les collisions réutilisent le dernier segment physique pour les îles 7 et 8.
            islandField.setInt(gameView, virtualSegment);
            rebuildObstaclesMethod.invoke(gameView);
            islandField.setInt(gameView, destinationIsland);
            chooseWeatherMethod.invoke(gameView, true);

            mode = Mode.LAND;
            releasePilot();
            transientMessage = "Arrivée : " + WorldConfig.ISLAND_NAMES[destinationIsland];
            messageTime = 3f;
            gameView.resumeGameLoop();
        } catch (ReflectiveOperationException | RuntimeException ignored) {
            abortVoyage();
        }
    }

    private void clearCombatLists() throws IllegalAccessException {
        Object enemyValue = enemiesField.get(gameView);
        if (enemyValue instanceof List<?> list) list.clear();
        Object projectileValue = projectilesField.get(gameView);
        if (projectileValue instanceof List<?> list) list.clear();
    }

    private void abortVoyage() {
        mode = Mode.LAND;
        releasePilot();
        transientMessage = "Navire endommagé : retour au dernier port";
        messageTime = 3f;
        gameView.resumeGameLoop();
    }

    private void createRouteHazards() {
        hazards.clear();
        Random seeded = new Random(31_771L + departureIsland * 997L + destinationIsland * 131L);
        boolean magma = WorldConfig.isMagmaRoute(departureIsland, destinationIsland);
        int count = magma ? 17 : 13;
        for (int i = 0; i < count; i++) {
            RouteHazard hazard = new RouteHazard();
            hazard.distance = 470f + i * (magma ? 245f : 305f) + seeded.nextFloat() * 145f;
            hazard.lane = -360f + seeded.nextFloat() * 720f;
            hazard.radius = 28f + seeded.nextFloat() * 42f;
            hazard.magma = magma && (i % 3 != 0);
            hazards.add(hazard);
        }
    }

    private void ensurePilot(int hero) {
        hero = Math.max(0, Math.min(2, hero));
        if (pilotSprite != null && pilotHero == hero) return;
        releasePilot();
        pilotHero = hero;
        pilotSprite = new Character25D(hero);
    }

    private void releasePilot() {
        if (pilotSprite != null) {
            pilotSprite.release();
            pilotSprite = null;
        }
        pilotHero = -1;
    }

    private boolean ensureReflection() {
        if (reflectionReady) return true;
        try {
            Class<?> type = gameView.getClass();
            screenField = field(type, "screen");
            islandField = field(type, "currentIsland");
            playerXField = field(type, "playerX");
            playerYField = field(type, "playerY");
            selectedHeroField = field(type, "selectedHero");
            enemiesField = field(type, "enemies");
            projectilesField = field(type, "projectiles");
            rebuildObstaclesMethod = method(type, "rebuildObstacles");
            chooseWeatherMethod = method(type, "chooseWeather", boolean.class);
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

    private void button(Canvas canvas, RectF rect, String label, int color) {
        paint.setColor(color);
        canvas.drawRoundRect(rect, 20f, 20f, paint);
        stroke.setColor(Color.argb(180, 255, 255, 255));
        stroke.setStrokeWidth(2f);
        canvas.drawRoundRect(rect, 20f, 20f, stroke);
        text(canvas, label, rect.centerX(), rect.centerY() + 7f, 18f,
                Color.WHITE, true, Paint.Align.CENTER);
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

    private static Field field(Class<?> type, String name) throws ReflectiveOperationException {
        Field result = type.getDeclaredField(name);
        result.setAccessible(true);
        return result;
    }

    private static Method method(Class<?> type, String name, Class<?>... args)
            throws ReflectiveOperationException {
        Method result = type.getDeclaredMethod(name, args);
        result.setAccessible(true);
        return result;
    }

    private static final class RouteHazard {
        float distance;
        float lane;
        float radius;
        boolean magma;
        boolean hit;
    }
}
