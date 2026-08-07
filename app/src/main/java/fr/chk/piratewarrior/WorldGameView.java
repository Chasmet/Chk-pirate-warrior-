package fr.chk.piratewarrior;

import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RectF;
import android.graphics.Shader;
import android.view.MotionEvent;
import android.view.View;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Locale;
import java.util.Random;

/**
 * V2 gameplay view. The world is deliberately asset-light so the APK remains small and offline,
 * but the systems are separated from the island data and provide a complete 11-island loop.
 */
public final class WorldGameView extends View {
    public interface VoiceNarrator {
        void speak(String text);
    }

    private enum Screen { MENU, HEROES, GAME, MAP, PAUSE, GAME_OVER, VICTORY }
    private enum Mode { FOOT, SHIP }

    private static final String[] HERO_NAMES = {"CHEIKH", "YVANE", "NELVYN"};
    private static final String[] HERO_ROLES = {"Capitaine", "Éclaireur", "Inventeur"};
    private static final int[] HERO_COLORS = {
            Color.rgb(195, 48, 45), Color.rgb(52, 153, 225), Color.rgb(54, 185, 111)
    };

    private static final float ISLAND_RADIUS = 920f;
    private static final float DOCK_X = 0f;
    private static final float DOCK_Z = 760f;
    private static final float WORLD_LIMIT = 1750f;
    private static final int MAX_ENEMIES = 18;

    private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint stroke = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Path path = new Path();
    private final Random random = new Random(54177L);
    private final List<Enemy> enemies = new ArrayList<>();
    private final List<Spark> sparks = new ArrayList<>();
    private final SharedPreferences prefs;
    private final VoiceNarrator narrator;

    private Screen screen = Screen.MENU;
    private Mode mode = Mode.FOOT;
    private int selectedHero;
    private int islandIndex;
    private int unlockedIslands = 1;
    private int defeatedBosses;
    private int kills;
    private int coins = 100;
    private int xp;
    private int level = 1;
    private int combo;
    private int bestCombo;

    private float playerX;
    private float playerZ = 260f;
    private float hp = 100f;
    private float maxHp = 100f;
    private float energy = 100f;
    private float special;
    private float cameraYaw;
    private float cameraPitch = 0.32f;
    private float joystickX;
    private float joystickY;
    private float joystickBaseX;
    private float joystickBaseY;
    private float attackCooldown;
    private float skillCooldown;
    private float hurtCooldown;
    private float comboTimer;
    private float cameraDragLastX;
    private float facingYaw;
    private float boatWake;
    private float flash;
    private float shake;
    private long lastNanos;
    private long lastSpawn;
    private long lastSave;
    private int joystickPointer = -1;
    private int cameraPointer = -1;
    private boolean running = true;
    private boolean bossSpawned;
    private boolean missionComplete;
    private boolean voiceEnabled = true;

    public WorldGameView(Context context, VoiceNarrator narrator) {
        super(context);
        this.narrator = narrator;
        this.prefs = context.getSharedPreferences("chk_pirate_v2_save", Context.MODE_PRIVATE);
        stroke.setStyle(Paint.Style.STROKE);
        setFocusable(true);
        setKeepScreenOn(true);
        load();
    }

    public void onVoiceReady() {
        speak("Bienvenue dans CHK Pirate Warrior. Onze royaumes t'attendent.");
    }

    public void pauseGameLoop() {
        running = false;
        save();
    }

    public void resumeGameLoop() {
        running = true;
        lastNanos = 0L;
        postInvalidateOnAnimation();
    }

    @Override
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        joystickBaseX = Math.max(120f, w * 0.11f);
        joystickBaseY = h - Math.max(105f, h * 0.18f);
    }

    @Override
    protected void onDraw(Canvas canvas) {
        long now = System.nanoTime();
        float dt = lastNanos == 0L ? 0f : Math.min(0.033f, (now - lastNanos) / 1_000_000_000f);
        lastNanos = now;
        if (running && dt > 0f) update(dt);

        switch (screen) {
            case MENU: drawMenu(canvas); break;
            case HEROES: drawHeroes(canvas); break;
            case GAME: drawGame(canvas); break;
            case MAP: drawGame(canvas); drawMap(canvas); break;
            case PAUSE: drawGame(canvas); drawPause(canvas); break;
            case GAME_OVER: drawEnd(canvas, false); break;
            case VICTORY: drawEnd(canvas, true); break;
        }
        if (running) postInvalidateOnAnimation();
    }

    private void update(float dt) {
        attackCooldown = Math.max(0f, attackCooldown - dt);
        skillCooldown = Math.max(0f, skillCooldown - dt);
        hurtCooldown = Math.max(0f, hurtCooldown - dt);
        comboTimer = Math.max(0f, comboTimer - dt);
        flash = Math.max(0f, flash - dt * 2.2f);
        shake = Math.max(0f, shake - dt * 20f);
        if (comboTimer <= 0f) combo = 0;
        if (screen != Screen.GAME) return;

        energy = Math.min(100f, energy + dt * 7f);
        special = Math.min(100f, special + dt * 0.6f);
        boatWake += dt * 8f;

        float mag = (float) Math.sqrt(joystickX * joystickX + joystickY * joystickY);
        if (mag > 0.08f) {
            float forward = -joystickY / Math.max(1f, mag);
            float side = joystickX / Math.max(1f, mag);
            float sin = (float) Math.sin(cameraYaw);
            float cos = (float) Math.cos(cameraYaw);
            float dx = side * cos + forward * sin;
            float dz = forward * cos - side * sin;
            float speed = mode == Mode.SHIP ? 360f : heroSpeed();
            playerX += dx * speed * dt;
            playerZ += dz * speed * dt;
            facingYaw = (float) Math.atan2(dx, dz);
            if (mode == Mode.FOOT) clampToIsland();
            else {
                playerX = clamp(playerX, -WORLD_LIMIT, WORLD_LIMIT);
                playerZ = clamp(playerZ, -WORLD_LIMIT, WORLD_LIMIT);
            }
        }

        if (mode == Mode.FOOT) updateEnemies(dt);
        updateSparks(dt);

        long ms = System.currentTimeMillis();
        if (mode == Mode.FOOT && !missionComplete && ms - lastSpawn > 1300L && enemies.size() < Math.min(MAX_ENEMIES, 7 + islandIndex)) {
            spawnEnemy(false);
            lastSpawn = ms;
        }
        GameWorld.Island island = GameWorld.get(islandIndex);
        if (!bossSpawned && kills >= island.enemyCount) {
            bossSpawned = true;
            spawnEnemy(true);
            speak("Le boss " + island.boss + " arrive.");
        }
        if (ms - lastSave > 7000L) save();
        if (hp <= 0f) {
            screen = Screen.GAME_OVER;
            speak("L'équipage est à terre.");
            save();
        }
    }

    private void clampToIsland() {
        float d = (float) Math.sqrt(playerX * playerX + playerZ * playerZ);
        if (d > ISLAND_RADIUS) {
            playerX = playerX / d * ISLAND_RADIUS;
            playerZ = playerZ / d * ISLAND_RADIUS;
        }
    }

    private void updateEnemies(float dt) {
        Iterator<Enemy> it = enemies.iterator();
        while (it.hasNext()) {
            Enemy e = it.next();
            e.hit = Math.max(0f, e.hit - dt);
            e.cooldown = Math.max(0f, e.cooldown - dt);
            float dx = playerX - e.x;
            float dz = playerZ - e.z;
            float d = (float) Math.sqrt(dx * dx + dz * dz);
            if (d < 620f && d > e.range) {
                e.x += dx / Math.max(1f, d) * e.speed * dt;
                e.z += dz / Math.max(1f, d) * e.speed * dt;
            }
            if (d <= e.range && e.cooldown <= 0f && hurtCooldown <= 0f) {
                hp -= e.boss ? 13f : 5f + islandIndex * 0.7f;
                hurtCooldown = 0.58f;
                e.cooldown = e.boss ? 0.95f : 1.35f;
                shake = e.boss ? 18f : 7f;
                flash = 0.5f;
                combo = 0;
                burst(playerX, playerZ, Color.rgb(255, 91, 65), e.boss ? 18 : 7);
            }
            if (e.hp <= 0f) {
                it.remove();
                if (e.boss) onBossDefeated(e);
                else {
                    kills++;
                    xp += 20 + islandIndex * 5;
                    coins += 7 + islandIndex;
                    special = Math.min(100f, special + 8f);
                }
                checkLevel();
            }
        }
    }

    private void onBossDefeated(Enemy e) {
        defeatedBosses = Math.max(defeatedBosses, islandIndex + 1);
        unlockedIslands = Math.min(GameWorld.ISLAND_COUNT, Math.max(unlockedIslands, islandIndex + 2));
        missionComplete = true;
        xp += 250 + islandIndex * 65;
        coins += 150 + islandIndex * 25;
        hp = maxHp;
        special = 100f;
        burst(e.x, e.z, GameWorld.get(islandIndex).accent, 60);
        speak("Royaume libéré. " + GameWorld.get(islandIndex).displayName() + ".");
        if (islandIndex == GameWorld.ISLAND_COUNT - 1) {
            screen = Screen.VICTORY;
            speak("Le Royaume Troublé est libéré. L'objet rare est retrouvé.");
        }
        save();
    }

    private void attack(boolean skill) {
        if (screen != Screen.GAME || mode != Mode.FOOT) return;
        if (skill) {
            if (skillCooldown > 0f || energy < 28f) return;
            energy -= 28f;
            skillCooldown = 2.8f;
        } else {
            if (attackCooldown > 0f) return;
            attackCooldown = selectedHero == 1 ? 0.26f : 0.38f;
        }
        float radius = skill ? 245f : 120f;
        float damage = (skill ? 46f : 19f) + level * (skill ? 5f : 2.8f);
        int hits = 0;
        for (Enemy e : enemies) {
            float dx = e.x - playerX;
            float dz = e.z - playerZ;
            float d = (float) Math.sqrt(dx * dx + dz * dz);
            if (d < radius) {
                e.hp -= damage;
                e.hit = 0.22f;
                e.x += dx / Math.max(1f, d) * (skill ? 70f : 25f);
                e.z += dz / Math.max(1f, d) * (skill ? 70f : 25f);
                hits++;
                burst(e.x, e.z, HERO_COLORS[selectedHero], skill ? 11 : 4);
            }
        }
        if (hits > 0) {
            combo += hits;
            bestCombo = Math.max(bestCombo, combo);
            comboTimer = 2.3f;
            special = Math.min(100f, special + hits * 3f);
            shake = skill ? 11f : 4f;
        }
    }

    private void unleash() {
        if (screen != Screen.GAME || mode != Mode.FOOT || special < 100f) return;
        special = 0f;
        flash = 1f;
        shake = 26f;
        for (Enemy e : enemies) {
            float d = distance(playerX, playerZ, e.x, e.z);
            if (d < 390f) {
                e.hp -= 70f + level * 6f;
                e.hit = 0.5f;
            }
        }
        burst(playerX, playerZ, HERO_COLORS[selectedHero], 80);
        speak("Déferlement de " + HERO_NAMES[selectedHero] + ".");
    }

    private void toggleBoat() {
        if (screen != Screen.GAME) return;
        if (mode == Mode.FOOT) {
            if (distance(playerX, playerZ, DOCK_X, DOCK_Z) > 220f) {
                speak("Rejoins le ponton pour embarquer.");
                return;
            }
            mode = Mode.SHIP;
            enemies.clear();
            speak("Équipage à bord. Cap sur la mer.");
        } else {
            if (distance(playerX, playerZ, DOCK_X, DOCK_Z) > 250f) {
                speak("Approche le ponton pour débarquer.");
                return;
            }
            mode = Mode.FOOT;
            playerX = DOCK_X;
            playerZ = DOCK_Z - 80f;
            speak("Débarquement.");
        }
    }

    private void travelTo(int target) {
        if (target < 0 || target >= unlockedIslands) return;
        islandIndex = target;
        mode = Mode.SHIP;
        playerX = DOCK_X;
        playerZ = DOCK_Z + 230f;
        kills = 0;
        bossSpawned = false;
        missionComplete = islandIndex < defeatedBosses;
        enemies.clear();
        screen = Screen.GAME;
        GameWorld.Island island = GameWorld.get(islandIndex);
        speak("Arrivée. " + island.displayName() + ". " + island.objective + ".");
        save();
    }

    private void spawnEnemy(boolean boss) {
        Enemy e = new Enemy();
        double a = random.nextDouble() * Math.PI * 2.0;
        float r = boss ? 430f : 300f + random.nextFloat() * 320f;
        e.x = clamp(playerX + (float) Math.sin(a) * r, -780f, 780f);
        e.z = clamp(playerZ + (float) Math.cos(a) * r, -780f, 780f);
        e.boss = boss;
        e.maxHp = boss ? 330f + islandIndex * 95f : 55f + islandIndex * 14f + level * 4f;
        e.hp = e.maxHp;
        e.speed = boss ? 105f : 92f + islandIndex * 2.5f;
        e.range = boss ? 95f : 65f;
        enemies.add(e);
    }

    private void checkLevel() {
        int newLevel = 1 + (int) Math.sqrt(Math.max(0, xp) / 110f);
        if (newLevel > level) {
            level = newLevel;
            maxHp = 100f + (level - 1) * 11f;
            hp = maxHp;
            speak("Niveau " + level + ".");
        }
    }

    private float heroSpeed() {
        float base = selectedHero == 1 ? 285f : selectedHero == 2 ? 250f : 235f;
        return base + level * 3.2f;
    }

    private void drawMenu(Canvas c) {
        drawMenuBackdrop(c);
        float w = getWidth();
        float h = getHeight();
        drawLogo(c, w * 0.13f, h * 0.25f, Math.min(110f, h * 0.18f));
        text(c, "CHK", w * 0.23f, h * 0.21f, h * 0.105f, Color.rgb(248, 204, 74), true, Paint.Align.LEFT);
        text(c, "PIRATE WARRIOR", w * 0.23f, h * 0.31f, h * 0.07f, Color.WHITE, true, Paint.Align.LEFT);
        text(c, "L'ARCHIPEL DES ONZE ROYAUMES", w * 0.23f, h * 0.37f, h * 0.027f, Color.rgb(190, 220, 235), false, Paint.Align.LEFT);

        float bx = w * 0.10f;
        float bw = Math.min(430f, w * 0.34f);
        float bh = Math.max(58f, h * 0.105f);
        button(c, bx, h * 0.51f, bw, bh, "CONTINUER", Color.rgb(190, 48, 43));
        button(c, bx, h * 0.65f, bw, bh, "CHOISIR LE HÉROS", Color.rgb(35, 104, 162));
        button(c, bx, h * 0.79f, bw, bh, "CARTE DU MONDE", Color.rgb(45, 125, 91));
        pill(c, w - 245f, 24f, 215f, 48f, voiceEnabled ? "VOIX FR : OUI" : "VOIX FR : NON");
        text(c, "Progression " + defeatedBosses + "/11  •  Niv. " + level + "  •  " + coins + " pièces",
                w - 28f, h - 28f, 18f, Color.WHITE, true, Paint.Align.RIGHT);
    }

    private void drawMenuBackdrop(Canvas c) {
        float w = getWidth();
        float h = getHeight();
        paint.setShader(new LinearGradient(0, 0, 0, h, Color.rgb(7, 35, 61), Color.rgb(2, 10, 20), Shader.TileMode.CLAMP));
        c.drawRect(0, 0, w, h, paint);
        paint.setShader(null);
        paint.setColor(Color.rgb(15, 90, 130));
        c.drawRect(0, h * 0.55f, w, h, paint);
        for (int i = 0; i < 12; i++) {
            float y = h * 0.58f + i * 18f;
            paint.setColor(Color.argb(35, 255, 255, 255));
            c.drawOval(new RectF((i * 137f) % w - 120f, y, (i * 137f) % w + 220f, y + 8f), paint);
        }
        paint.setColor(Color.argb(150, 0, 0, 0));
        path.reset();
        path.moveTo(w * 0.60f, h * 0.78f);
        path.lineTo(w * 0.80f, h * 0.44f);
        path.lineTo(w * 0.93f, h * 0.78f);
        path.close();
        c.drawPath(path, paint);
    }

    private void drawLogo(Canvas c, float x, float y, float r) {
        paint.setColor(Color.rgb(9, 20, 34));
        c.drawCircle(x, y, r, paint);
        stroke.setStrokeWidth(Math.max(5f, r * 0.07f));
        stroke.setColor(Color.rgb(247, 201, 72));
        c.drawCircle(x, y, r * 0.86f, stroke);
        for (int i = 0; i < 8; i++) {
            double a = i * Math.PI / 4.0;
            float x1 = x + (float) Math.cos(a) * r * 0.50f;
            float y1 = y + (float) Math.sin(a) * r * 0.50f;
            float x2 = x + (float) Math.cos(a) * r * 0.82f;
            float y2 = y + (float) Math.sin(a) * r * 0.82f;
            c.drawLine(x1, y1, x2, y2, stroke);
        }
        paint.setColor(Color.rgb(190, 49, 44));
        c.drawCircle(x, y, r * 0.39f, paint);
        text(c, "CHK", x, y + r * 0.13f, r * 0.34f, Color.WHITE, true, Paint.Align.CENTER);
    }

    private void drawHeroes(Canvas c) {
        drawMenuBackdrop(c);
        float w = getWidth();
        float h = getHeight();
        text(c, "CHOISIS TON HÉROS", w / 2f, h * 0.12f, h * 0.06f, Color.WHITE, true, Paint.Align.CENTER);
        float gap = w * 0.025f;
        float cardW = (w - gap * 4f) / 3f;
        for (int i = 0; i < 3; i++) {
            float left = gap + i * (cardW + gap);
            RectF r = new RectF(left, h * 0.20f, left + cardW, h * 0.80f);
            paint.setColor(Color.argb(i == selectedHero ? 235 : 205, 5, 19, 34));
            c.drawRoundRect(r, 24f, 24f, paint);
            stroke.setColor(i == selectedHero ? Color.rgb(247, 204, 74) : Color.argb(90, 255, 255, 255));
            stroke.setStrokeWidth(i == selectedHero ? 5f : 2f);
            c.drawRoundRect(r, 24f, 24f, stroke);
            drawHero(c, r.centerX(), h * 0.48f, Math.min(82f, h * 0.13f), i, 0f);
            text(c, HERO_NAMES[i], r.centerX(), h * 0.69f, 31f, HERO_COLORS[i], true, Paint.Align.CENTER);
            text(c, HERO_ROLES[i], r.centerX(), h * 0.74f, 18f, Color.WHITE, false, Paint.Align.CENTER);
        }
        button(c, w * 0.35f, h * 0.86f, w * 0.30f, h * 0.10f, "JOUER", Color.rgb(191, 49, 44));
        pill(c, 22f, 20f, 120f, 44f, "RETOUR");
    }

    private void drawGame(Canvas c) {
        c.save();
        if (shake > 0f) c.translate((random.nextFloat() - 0.5f) * shake, (random.nextFloat() - 0.5f) * shake);
        GameWorld.Island island = GameWorld.get(islandIndex);
        drawSky(c, island);
        drawWorld(c, island);
        drawEntities(c);
        drawHud(c, island);
        drawControls(c);
        if (flash > 0f) {
            paint.setColor(Color.argb((int) (flash * 110f), 255, 255, 255));
            c.drawRect(0, 0, getWidth(), getHeight(), paint);
        }
        c.restore();
    }

    private void drawSky(Canvas c, GameWorld.Island island) {
        float h = getHeight();
        paint.setShader(new LinearGradient(0, 0, 0, h * 0.66f, island.skyTop, island.skyBottom, Shader.TileMode.CLAMP));
        c.drawRect(0, 0, getWidth(), h * 0.68f, paint);
        paint.setShader(null);
        paint.setColor(Color.argb(120, 255, 235, 175));
        c.drawCircle(getWidth() * 0.82f, h * 0.18f, h * 0.075f, paint);
        drawWeather(c, island);
    }

    private void drawWeather(Canvas c, GameWorld.Island island) {
        int count;
        switch (island.weather) {
            case SNOW: count = 45; break;
            case RAIN: case STORM: count = 58; break;
            case ASH: count = 38; break;
            case FOG: case GOLDEN_FOG: count = 8; break;
            default: count = 0;
        }
        long t = System.currentTimeMillis();
        for (int i = 0; i < count; i++) {
            float x = (i * 97f + (t * (island.weather == GameWorld.Weather.STORM ? 0.25f : 0.08f))) % (getWidth() + 150f) - 75f;
            float y = (i * 61f + t * 0.15f) % Math.max(1, getHeight());
            if (island.weather == GameWorld.Weather.SNOW) {
                paint.setColor(Color.argb(190, 255, 255, 255));
                c.drawCircle(x, y, 3f + i % 4, paint);
            } else if (island.weather == GameWorld.Weather.RAIN || island.weather == GameWorld.Weather.STORM) {
                paint.setColor(Color.argb(135, 195, 225, 255));
                c.drawLine(x, y, x - 12f, y + 32f, paint);
            } else if (island.weather == GameWorld.Weather.ASH) {
                paint.setColor(Color.argb(155, 70, 62, 58));
                c.drawCircle(x, y, 2f + i % 3, paint);
            }
        }
        if (island.weather == GameWorld.Weather.FOG || island.weather == GameWorld.Weather.GOLDEN_FOG) {
            int col = island.weather == GameWorld.Weather.GOLDEN_FOG ? Color.rgb(214, 175, 96) : Color.rgb(190, 205, 201);
            for (int i = 0; i < 5; i++) {
                paint.setColor(Color.argb(36 + i * 8, Color.red(col), Color.green(col), Color.blue(col)));
                float y = getHeight() * (0.30f + i * 0.11f);
                c.drawOval(new RectF(-120f + i * 80f, y, getWidth() + 180f, y + 95f), paint);
            }
        }
    }

    private void drawWorld(Canvas c, GameWorld.Island island) {
        float w = getWidth();
        float h = getHeight();
        paint.setColor(Color.rgb(17, 105, 148));
        c.drawRect(0, h * 0.62f, w, h, paint);
        paint.setColor(island.ground);
        path.reset();
        path.moveTo(w * 0.10f, h);
        path.quadTo(w * 0.08f, h * 0.62f, w * 0.50f, h * 0.54f);
        path.quadTo(w * 0.92f, h * 0.62f, w * 0.90f, h);
        path.close();
        c.drawPath(path, paint);

        for (int i = 0; i < 26; i++) {
            float ox = proceduralX(i);
            float oz = proceduralZ(i);
            Projected p = project(ox, oz);
            if (!p.visible) continue;
            drawProp(c, p, island, i);
        }
        Projected dock = project(DOCK_X, DOCK_Z);
        if (dock.visible) drawDock(c, dock);
    }

    private float proceduralX(int i) {
        return (float) (Math.sin(i * 9.71 + islandIndex * 3.13) * 720.0);
    }

    private float proceduralZ(int i) {
        return (float) (Math.cos(i * 7.33 + islandIndex * 4.91) * 720.0);
    }

    private Projected project(float worldX, float worldZ) {
        float dx = worldX - playerX;
        float dz = worldZ - playerZ;
        float sin = (float) Math.sin(cameraYaw);
        float cos = (float) Math.cos(cameraYaw);
        float side = dx * cos - dz * sin;
        float depth = dx * sin + dz * cos;
        float perspective = clamp(1.05f - depth / 2100f, 0.48f, 1.55f);
        Projected p = new Projected();
        p.x = getWidth() * 0.5f + side * 0.58f * perspective;
        p.y = getHeight() * (0.62f + cameraPitch * 0.10f) - depth * 0.23f * perspective;
        p.scale = perspective;
        p.depth = depth;
        p.visible = p.x > -160f && p.x < getWidth() + 160f && p.y > getHeight() * 0.34f && p.y < getHeight() + 140f;
        return p;
    }

    private void drawProp(Canvas c, Projected p, GameWorld.Island island, int index) {
        float s = 34f * p.scale;
        switch (island.biome) {
            case TROPICAL: case JUNGLE: case FOOD:
                paint.setColor(Color.rgb(102, 68, 42));
                c.drawRect(p.x - 4f * p.scale, p.y - s * 1.8f, p.x + 4f * p.scale, p.y, paint);
                paint.setColor(island.biome == GameWorld.Biome.FOOD ? Color.rgb(175, 76, 84) : Color.rgb(42, 128, 73));
                c.drawCircle(p.x, p.y - s * 2f, s * 0.62f, paint);
                break;
            case SNOW:
                paint.setColor(Color.rgb(74, 91, 83));
                path.reset(); path.moveTo(p.x, p.y - s * 2.4f); path.lineTo(p.x - s, p.y); path.lineTo(p.x + s, p.y); path.close(); c.drawPath(path, paint);
                paint.setColor(Color.WHITE); c.drawCircle(p.x, p.y - s * 1.9f, s * 0.42f, paint);
                break;
            case VOLCANO:
                paint.setColor(Color.rgb(65, 55, 52));
                c.drawOval(new RectF(p.x - s, p.y - s * 0.7f, p.x + s, p.y), paint);
                paint.setColor(Color.rgb(239, 83, 42)); c.drawCircle(p.x, p.y - s * 0.35f, s * 0.16f, paint);
                break;
            case TECHNO:
                paint.setColor(Color.rgb(43, 52, 72)); c.drawRect(p.x - s * 0.45f, p.y - s * 2.2f, p.x + s * 0.45f, p.y, paint);
                paint.setColor(island.accent); c.drawRect(p.x - s * 0.28f, p.y - s * 1.75f, p.x + s * 0.28f, p.y - s * 1.6f, paint);
                break;
            case MEMORY: case GHOST:
                paint.setColor(Color.argb(175, 95, 91, 84)); c.drawRect(p.x - s * 0.35f, p.y - s * 1.8f, p.x + s * 0.35f, p.y, paint);
                stroke.setColor(island.accent); stroke.setStrokeWidth(2f); c.drawCircle(p.x, p.y - s * 2.1f, s * 0.38f, stroke);
                break;
            default:
                paint.setColor(Color.rgb(117, 89, 61)); c.drawRoundRect(new RectF(p.x - s * 0.7f, p.y - s, p.x + s * 0.7f, p.y), 7f, 7f, paint);
                break;
        }
    }

    private void drawDock(Canvas c, Projected p) {
        float s = 42f * p.scale;
        paint.setColor(Color.rgb(111, 75, 48));
        c.drawRect(p.x - s * 1.2f, p.y - 9f, p.x + s * 1.2f, p.y + 9f, paint);
        text(c, "PONTON", p.x, p.y - 18f, Math.max(12f, 15f * p.scale), Color.WHITE, true, Paint.Align.CENTER);
    }

    private void drawEntities(Canvas c) {
        for (Enemy e : enemies) {
            Projected p = project(e.x, e.z);
            if (p.visible) drawEnemy(c, p, e);
        }
        for (Spark s : sparks) {
            Projected p = project(s.x, s.z);
            if (p.visible) {
                paint.setColor(Color.argb((int) (255f * clamp(s.life, 0f, 1f)), Color.red(s.color), Color.green(s.color), Color.blue(s.color)));
                c.drawCircle(p.x, p.y - s.height, 3f + p.scale * 3f, paint);
            }
        }
        if (mode == Mode.FOOT) drawHero(c, getWidth() * 0.5f, getHeight() * 0.69f, Math.min(62f, getHeight() * 0.105f), selectedHero, facingYaw - cameraYaw);
        else drawShip(c);
    }

    private void drawHero(Canvas c, float x, float y, float size, int hero, float relativeFacing) {
        paint.setColor(Color.argb(65, 0, 0, 0));
        c.drawOval(new RectF(x - size * 0.65f, y + size * 0.72f, x + size * 0.65f, y + size * 0.95f), paint);
        float lean = (float) Math.sin(relativeFacing) * size * 0.17f;
        paint.setColor(HERO_COLORS[hero]);
        c.drawRoundRect(new RectF(x - size * 0.43f + lean, y - size * 0.45f, x + size * 0.43f + lean, y + size * 0.45f), 14f, 14f, paint);
        paint.setColor(Color.rgb(44, 48, 55));
        c.drawRect(x - size * 0.34f, y + size * 0.36f, x - size * 0.06f, y + size * 0.95f, paint);
        c.drawRect(x + size * 0.06f, y + size * 0.36f, x + size * 0.34f, y + size * 0.95f, paint);
        paint.setColor(Color.rgb(126, 83, 57));
        c.drawCircle(x + lean, y - size * 0.76f, size * 0.34f, paint);
        paint.setColor(Color.rgb(30, 25, 24));
        c.drawArc(new RectF(x + lean - size * 0.33f, y - size * 1.02f, x + lean + size * 0.33f, y - size * 0.58f), 180f, 180f, true, paint);
        float eyeShift = clamp((float) Math.sin(relativeFacing), -1f, 1f) * size * 0.10f;
        paint.setColor(Color.WHITE);
        c.drawCircle(x + lean - size * 0.10f + eyeShift, y - size * 0.77f, size * 0.035f, paint);
        c.drawCircle(x + lean + size * 0.10f + eyeShift, y - size * 0.77f, size * 0.035f, paint);
        text(c, HERO_NAMES[hero], x, y + size * 1.23f, 15f, Color.WHITE, true, Paint.Align.CENTER);
    }

    private void drawShip(Canvas c) {
        float x = getWidth() * 0.5f;
        float y = getHeight() * 0.71f;
        float s = Math.min(90f, getHeight() * 0.14f);
        paint.setColor(Color.argb(70, 0, 0, 0));
        c.drawOval(new RectF(x - s * 1.15f, y + s * 0.45f, x + s * 1.15f, y + s * 0.78f), paint);
        paint.setColor(Color.rgb(115, 68, 40));
        path.reset(); path.moveTo(x - s, y); path.lineTo(x - s * 0.68f, y + s * 0.55f); path.lineTo(x + s * 0.68f, y + s * 0.55f); path.lineTo(x + s, y); path.close(); c.drawPath(path, paint);
        paint.setColor(Color.rgb(76, 48, 33)); c.drawRect(x - 5f, y - s * 1.20f, x + 5f, y + s * 0.12f, paint);
        paint.setColor(Color.rgb(232, 224, 196)); path.reset(); path.moveTo(x + 8f, y - s * 1.14f); path.lineTo(x + s * 0.72f, y - s * 0.72f); path.lineTo(x + 8f, y - s * 0.34f); path.close(); c.drawPath(path, paint);
        paint.setColor(HERO_COLORS[selectedHero]); c.drawCircle(x, y - s * 0.08f, 10f, paint);
        paint.setColor(Color.argb(110, 210, 240, 255));
        for (int i = 0; i < 5; i++) {
            float off = (float) Math.sin(boatWake + i) * 8f;
            c.drawOval(new RectF(x - s + i * s * 0.40f + off, y + s * 0.62f + i * 3f, x - s * 0.4f + i * s * 0.40f + off, y + s * 0.69f + i * 3f), paint);
        }
    }

    private void drawEnemy(Canvas c, Projected p, Enemy e) {
        float s = (e.boss ? 58f : 36f) * p.scale;
        paint.setColor(Color.argb(60, 0, 0, 0)); c.drawOval(new RectF(p.x - s, p.y - 3f, p.x + s, p.y + s * 0.35f), paint);
        paint.setColor(e.hit > 0f ? Color.WHITE : (e.boss ? Color.rgb(150, 45, 48) : Color.rgb(78, 65, 58)));
        c.drawRoundRect(new RectF(p.x - s * 0.45f, p.y - s * 1.35f, p.x + s * 0.45f, p.y), 12f, 12f, paint);
        paint.setColor(Color.rgb(111, 76, 55)); c.drawCircle(p.x, p.y - s * 1.62f, s * 0.33f, paint);
        if (e.boss) text(c, GameWorld.get(islandIndex).boss, p.x, p.y - s * 2.1f, 17f, Color.WHITE, true, Paint.Align.CENTER);
        bar(c, p.x - s, p.y - s * 2.02f, s * 2f, 7f, e.hp / e.maxHp, e.boss ? Color.rgb(236, 59, 50) : Color.rgb(219, 109, 62));
    }

    private void drawHud(Canvas c, GameWorld.Island island) {
        float w = getWidth();
        bar(c, 22f, 20f, Math.min(350f, w * 0.29f), 22f, hp / maxHp, Color.rgb(208, 54, 51));
        bar(c, 22f, 49f, Math.min(350f, w * 0.29f), 14f, energy / 100f, Color.rgb(53, 151, 222));
        bar(c, 22f, 70f, Math.min(350f, w * 0.29f), 14f, special / 100f, HERO_COLORS[selectedHero]);
        text(c, HERO_NAMES[selectedHero] + "  NIV. " + level, 22f, 112f, 21f, Color.WHITE, true, Paint.Align.LEFT);
        text(c, island.displayName(), w / 2f, 30f, 21f, Color.WHITE, true, Paint.Align.CENTER);
        String mission = missionComplete ? "ROYAUME LIBÉRÉ" : bossSpawned ? "BOSS : " + island.boss : "Mission : " + kills + "/" + island.enemyCount;
        text(c, mission, w / 2f, 56f, 17f, island.accent, true, Paint.Align.CENTER);
        text(c, mode == Mode.SHIP ? "NAVIGATION" : island.objective, w / 2f, 80f, 15f, Color.rgb(222, 229, 235), false, Paint.Align.CENTER);
        pill(c, w - 180f, 18f, 70f, 44f, "CARTE");
        pill(c, w - 96f, 18f, 72f, 44f, "PAUSE");
        text(c, coins + " pièces", w - 24f, 92f, 17f, Color.WHITE, true, Paint.Align.RIGHT);
        if (combo > 1) text(c, combo + " COMBO", w * 0.74f, getHeight() * 0.24f, 35f, Color.rgb(255, 216, 77), true, Paint.Align.CENTER);
    }

    private void drawControls(Canvas c) {
        paint.setColor(Color.argb(55, 255, 255, 255)); c.drawCircle(joystickBaseX, joystickBaseY, 82f, paint);
        stroke.setColor(Color.argb(115, 255, 255, 255)); stroke.setStrokeWidth(3f); c.drawCircle(joystickBaseX, joystickBaseY, 82f, stroke);
        paint.setColor(Color.argb(170, 20, 31, 45)); c.drawCircle(joystickBaseX + joystickX * 55f, joystickBaseY + joystickY * 55f, 34f, paint);
        float w = getWidth(); float h = getHeight();
        if (mode == Mode.FOOT) {
            action(c, w - 92f, h - 90f, 55f, Color.rgb(194, 49, 46), "ATTAQUE");
            action(c, w - 205f, h - 145f, 47f, Color.rgb(48, 126, 187), skillCooldown > 0f ? String.format(Locale.FRANCE, "%.1f", skillCooldown) : "POUVOIR");
            action(c, w - 110f, h - 232f, 47f, special >= 100f ? HERO_COLORS[selectedHero] : Color.rgb(80, 85, 94), "AURA");
            action(c, w - 320f, h - 83f, 45f, Color.rgb(121, 82, 48), "BATEAU");
        } else {
            action(c, w - 100f, h - 95f, 57f, Color.rgb(39, 124, 170), "CAP");
            action(c, w - 235f, h - 115f, 49f, Color.rgb(121, 82, 48), "DÉBARQ.");
        }
        text(c, "Glisse à droite pour tourner la caméra", w * 0.56f, h - 18f, 13f, Color.argb(170, 255, 255, 255), false, Paint.Align.CENTER);
    }

    private void drawMap(Canvas c) {
        float w = getWidth(); float h = getHeight();
        paint.setColor(Color.argb(228, 2, 11, 22)); c.drawRect(0, 0, w, h, paint);
        text(c, "CARTE DE L'ARCHIPEL", w / 2f, h * 0.11f, h * 0.055f, Color.rgb(247, 204, 75), true, Paint.Align.CENTER);
        text(c, "Sélectionne une île débloquée", w / 2f, h * 0.17f, 17f, Color.WHITE, false, Paint.Align.CENTER);
        for (int i = 0; i < GameWorld.ISLAND_COUNT; i++) {
            Point pos = mapPoint(i, w, h);
            boolean unlocked = i < unlockedIslands;
            boolean cleared = i < defeatedBosses;
            paint.setColor(!unlocked ? Color.rgb(63, 68, 75) : cleared ? Color.rgb(47, 143, 91) : GameWorld.get(i).accent);
            c.drawCircle(pos.x, pos.y, i == islandIndex ? 30f : 23f, paint);
            if (i == islandIndex) { stroke.setColor(Color.WHITE); stroke.setStrokeWidth(4f); c.drawCircle(pos.x, pos.y, 34f, stroke); }
            text(c, String.valueOf(i + 1), pos.x, pos.y + 6f, 17f, Color.WHITE, true, Paint.Align.CENTER);
            text(c, unlocked ? GameWorld.get(i).name : "VERROUILLÉ", pos.x, pos.y + 47f, 13f, unlocked ? Color.WHITE : Color.rgb(135, 142, 149), false, Paint.Align.CENTER);
        }
        pill(c, 22f, 20f, 120f, 44f, "FERMER");
    }

    private Point mapPoint(int i, float w, float h) {
        int row = i / 4;
        int col = i % 4;
        float cols = row == 2 ? 3f : 4f;
        float spacing = w * 0.18f;
        float start = w * 0.22f;
        if (row == 2) start = w * 0.31f;
        return new Point(start + col * spacing, h * (0.31f + row * 0.25f));
    }

    private void drawPause(Canvas c) {
        float w = getWidth(); float h = getHeight();
        paint.setColor(Color.argb(220, 0, 0, 0)); c.drawRect(0, 0, w, h, paint);
        text(c, "PAUSE", w / 2f, h * 0.30f, h * 0.07f, Color.WHITE, true, Paint.Align.CENTER);
        button(c, w * 0.35f, h * 0.40f, w * 0.30f, h * 0.11f, "REPRENDRE", Color.rgb(44, 137, 91));
        button(c, w * 0.35f, h * 0.56f, w * 0.30f, h * 0.11f, "MENU PRINCIPAL", Color.rgb(48, 91, 137));
    }

    private void drawEnd(Canvas c, boolean victory) {
        drawMenuBackdrop(c);
        float w = getWidth(); float h = getHeight();
        text(c, victory ? "AVENTURE TERMINÉE" : "ÉQUIPAGE À TERRE", w / 2f, h * 0.27f, h * 0.07f,
                victory ? Color.rgb(247, 204, 74) : Color.rgb(237, 78, 62), true, Paint.Align.CENTER);
        text(c, victory ? "L'objet rare du Royaume Troublé est à toi." : "Reviens plus fort et reprends l'île.", w / 2f, h * 0.39f, 22f, Color.WHITE, false, Paint.Align.CENTER);
        text(c, "Boss vaincus : " + defeatedBosses + "/11  •  Meilleur combo : " + bestCombo, w / 2f, h * 0.48f, 20f, Color.rgb(205, 220, 232), false, Paint.Align.CENTER);
        button(c, w * 0.35f, h * 0.58f, w * 0.30f, h * 0.11f, victory ? "EXPLORER" : "RECOMMENCER", Color.rgb(45, 138, 91));
        button(c, w * 0.35f, h * 0.74f, w * 0.30f, h * 0.11f, "MENU", Color.rgb(49, 91, 138));
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        int action = event.getActionMasked();
        int index = event.getActionIndex();
        int id = event.getPointerId(index);
        float x = event.getX(index);
        float y = event.getY(index);

        if (action == MotionEvent.ACTION_DOWN || action == MotionEvent.ACTION_POINTER_DOWN) {
            handleDown(id, x, y);
        } else if (action == MotionEvent.ACTION_MOVE) {
            for (int i = 0; i < event.getPointerCount(); i++) {
                int pid = event.getPointerId(i);
                float px = event.getX(i);
                float py = event.getY(i);
                if (pid == joystickPointer) updateJoystick(px, py);
                if (pid == cameraPointer) {
                    float dx = px - cameraDragLastX;
                    cameraYaw -= dx * 0.0085f;
                    cameraDragLastX = px;
                }
            }
        } else if (action == MotionEvent.ACTION_UP || action == MotionEvent.ACTION_POINTER_UP || action == MotionEvent.ACTION_CANCEL) {
            if (id == joystickPointer) { joystickPointer = -1; joystickX = joystickY = 0f; }
            if (id == cameraPointer) cameraPointer = -1;
        }
        return true;
    }

    private void handleDown(int id, float x, float y) {
        float w = getWidth(); float h = getHeight();
        if (screen == Screen.MENU) {
            float bx = w * 0.10f; float bw = Math.min(430f, w * 0.34f); float bh = Math.max(58f, h * 0.105f);
            if (inside(x, y, bx, h * 0.51f, bw, bh)) startGame();
            else if (inside(x, y, bx, h * 0.65f, bw, bh)) screen = Screen.HEROES;
            else if (inside(x, y, bx, h * 0.79f, bw, bh)) screen = Screen.MAP;
            else if (inside(x, y, w - 245f, 24f, 215f, 48f)) { voiceEnabled = !voiceEnabled; save(); }
            return;
        }
        if (screen == Screen.HEROES) {
            if (inside(x, y, 22f, 20f, 120f, 44f)) { screen = Screen.MENU; return; }
            float gap = w * 0.025f; float cardW = (w - gap * 4f) / 3f;
            for (int i = 0; i < 3; i++) {
                float left = gap + i * (cardW + gap);
                if (inside(x, y, left, h * 0.20f, cardW, h * 0.60f)) selectedHero = i;
            }
            if (inside(x, y, w * 0.35f, h * 0.86f, w * 0.30f, h * 0.10f)) startGame();
            return;
        }
        if (screen == Screen.MAP) {
            if (inside(x, y, 22f, 20f, 120f, 44f)) { screen = Screen.GAME; return; }
            for (int i = 0; i < unlockedIslands; i++) {
                Point p = mapPoint(i, w, h);
                if (distance(x, y, p.x, p.y) < 48f) { travelTo(i); return; }
            }
            return;
        }
        if (screen == Screen.PAUSE) {
            if (inside(x, y, w * 0.35f, h * 0.40f, w * 0.30f, h * 0.11f)) screen = Screen.GAME;
            else if (inside(x, y, w * 0.35f, h * 0.56f, w * 0.30f, h * 0.11f)) { save(); screen = Screen.MENU; }
            return;
        }
        if (screen == Screen.GAME_OVER || screen == Screen.VICTORY) {
            if (inside(x, y, w * 0.35f, h * 0.58f, w * 0.30f, h * 0.11f)) { hp = maxHp; screen = Screen.GAME; }
            else if (inside(x, y, w * 0.35f, h * 0.74f, w * 0.30f, h * 0.11f)) screen = Screen.MENU;
            return;
        }
        if (screen != Screen.GAME) return;

        if (inside(x, y, w - 180f, 18f, 70f, 44f)) { screen = Screen.MAP; return; }
        if (inside(x, y, w - 96f, 18f, 72f, 44f)) { screen = Screen.PAUSE; save(); return; }
        if (distance(x, y, joystickBaseX, joystickBaseY) < 105f && joystickPointer < 0) { joystickPointer = id; updateJoystick(x, y); return; }
        if (mode == Mode.FOOT) {
            if (distance(x, y, w - 92f, h - 90f) < 72f) { attack(false); return; }
            if (distance(x, y, w - 205f, h - 145f) < 64f) { attack(true); return; }
            if (distance(x, y, w - 110f, h - 232f) < 64f) { unleash(); return; }
            if (distance(x, y, w - 320f, h - 83f) < 62f) { toggleBoat(); return; }
        } else {
            if (distance(x, y, w - 100f, h - 95f) < 74f) { screen = Screen.MAP; return; }
            if (distance(x, y, w - 235f, h - 115f) < 68f) { toggleBoat(); return; }
        }
        if (x > w * 0.38f && cameraPointer < 0) { cameraPointer = id; cameraDragLastX = x; }
    }

    private void updateJoystick(float x, float y) {
        float dx = x - joystickBaseX; float dy = y - joystickBaseY;
        float d = (float) Math.sqrt(dx * dx + dy * dy);
        if (d > 68f) { dx = dx / d * 68f; dy = dy / d * 68f; }
        joystickX = dx / 68f; joystickY = dy / 68f;
    }

    private void startGame() {
        screen = Screen.GAME;
        if (mode == Mode.FOOT && distance(playerX, playerZ, 0f, 0f) > ISLAND_RADIUS) { playerX = 0f; playerZ = 260f; }
        if (!missionComplete && enemies.isEmpty()) for (int i = 0; i < 5; i++) spawnEnemy(false);
        speak(GameWorld.get(islandIndex).displayName() + ". " + GameWorld.get(islandIndex).objective + ".");
    }

    private void updateSparks(float dt) {
        Iterator<Spark> it = sparks.iterator();
        while (it.hasNext()) {
            Spark s = it.next();
            s.life -= dt;
            s.height += s.vh * dt;
            s.x += s.vx * dt;
            s.z += s.vz * dt;
            if (s.life <= 0f) it.remove();
        }
    }

    private void burst(float x, float z, int color, int count) {
        for (int i = 0; i < count && sparks.size() < 150; i++) {
            double a = random.nextDouble() * Math.PI * 2.0;
            Spark s = new Spark(); s.x = x; s.z = z; s.color = color; s.life = 0.45f + random.nextFloat() * 0.55f;
            float sp = 45f + random.nextFloat() * 110f; s.vx = (float) Math.sin(a) * sp; s.vz = (float) Math.cos(a) * sp; s.vh = 25f + random.nextFloat() * 70f;
            sparks.add(s);
        }
    }

    private void save() {
        prefs.edit()
                .putInt("hero", selectedHero).putInt("island", islandIndex).putInt("unlocked", unlockedIslands)
                .putInt("bosses", defeatedBosses).putInt("coins", coins).putInt("xp", xp).putInt("bestCombo", bestCombo)
                .putFloat("hp", hp).putFloat("x", playerX).putFloat("z", playerZ).putFloat("yaw", cameraYaw)
                .putBoolean("voice", voiceEnabled).apply();
        lastSave = System.currentTimeMillis();
    }

    private void load() {
        selectedHero = clampInt(prefs.getInt("hero", 0), 0, 2);
        islandIndex = clampInt(prefs.getInt("island", 0), 0, GameWorld.ISLAND_COUNT - 1);
        unlockedIslands = clampInt(prefs.getInt("unlocked", 1), 1, GameWorld.ISLAND_COUNT);
        defeatedBosses = clampInt(prefs.getInt("bosses", 0), 0, GameWorld.ISLAND_COUNT);
        coins = prefs.getInt("coins", 100); xp = prefs.getInt("xp", 0); bestCombo = prefs.getInt("bestCombo", 0);
        level = 1 + (int) Math.sqrt(Math.max(0, xp) / 110f); maxHp = 100f + (level - 1) * 11f;
        hp = clamp(prefs.getFloat("hp", maxHp), 1f, maxHp); playerX = prefs.getFloat("x", 0f); playerZ = prefs.getFloat("z", 260f);
        cameraYaw = prefs.getFloat("yaw", 0f); voiceEnabled = prefs.getBoolean("voice", true);
        missionComplete = islandIndex < defeatedBosses;
    }

    private void speak(String text) { if (voiceEnabled && narrator != null) narrator.speak(text); }

    private void button(Canvas c, float x, float y, float w, float h, String label, int color) {
        paint.setColor(Color.argb(230, Color.red(color), Color.green(color), Color.blue(color))); c.drawRoundRect(new RectF(x, y, x + w, y + h), 18f, 18f, paint);
        stroke.setColor(Color.argb(150, 255, 255, 255)); stroke.setStrokeWidth(2f); c.drawRoundRect(new RectF(x, y, x + w, y + h), 18f, 18f, stroke);
        text(c, label, x + w / 2f, y + h / 2f + 7f, Math.min(24f, h * 0.36f), Color.WHITE, true, Paint.Align.CENTER);
    }

    private void pill(Canvas c, float x, float y, float w, float h, String label) {
        paint.setColor(Color.argb(185, 0, 0, 0)); c.drawRoundRect(new RectF(x, y, x + w, y + h), h / 2f, h / 2f, paint);
        text(c, label, x + w / 2f, y + h / 2f + 6f, Math.min(16f, h * 0.35f), Color.WHITE, true, Paint.Align.CENTER);
    }

    private void action(Canvas c, float x, float y, float r, int color, String label) {
        paint.setColor(Color.argb(220, Color.red(color), Color.green(color), Color.blue(color))); c.drawCircle(x, y, r, paint);
        stroke.setColor(Color.argb(180, 255, 255, 255)); stroke.setStrokeWidth(3f); c.drawCircle(x, y, r, stroke);
        text(c, label, x, y + 5f, Math.min(13f, r * 0.27f), Color.WHITE, true, Paint.Align.CENTER);
    }

    private void bar(Canvas c, float x, float y, float w, float h, float value, int color) {
        value = clamp(value, 0f, 1f); paint.setColor(Color.argb(170, 0, 0, 0)); c.drawRoundRect(new RectF(x, y, x + w, y + h), h / 2f, h / 2f, paint);
        paint.setColor(color); c.drawRoundRect(new RectF(x, y, x + w * value, y + h), h / 2f, h / 2f, paint);
    }

    private void text(Canvas c, String value, float x, float y, float size, int color, boolean bold, Paint.Align align) {
        paint.setShader(null); paint.setStyle(Paint.Style.FILL); paint.setTextAlign(align); paint.setTextSize(size); paint.setColor(color);
        paint.setTypeface(bold ? android.graphics.Typeface.DEFAULT_BOLD : android.graphics.Typeface.DEFAULT); c.drawText(value, x, y, paint);
    }

    private boolean inside(float x, float y, float rx, float ry, float rw, float rh) { return x >= rx && x <= rx + rw && y >= ry && y <= ry + rh; }
    private float distance(float x1, float y1, float x2, float y2) { float dx = x2 - x1, dy = y2 - y1; return (float) Math.sqrt(dx * dx + dy * dy); }
    private float clamp(float v, float min, float max) { return Math.max(min, Math.min(max, v)); }
    private int clampInt(int v, int min, int max) { return Math.max(min, Math.min(max, v)); }

    private static final class Enemy { float x, z, hp, maxHp, speed, range, cooldown, hit; boolean boss; }
    private static final class Spark { float x, z, vx, vz, height, vh, life; int color; }
    private static final class Projected { float x, y, scale, depth; boolean visible; }
    private static final class Point { final float x, y; Point(float x, float y) { this.x = x; this.y = y; } }
}
