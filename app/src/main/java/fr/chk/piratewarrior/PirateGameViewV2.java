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
import android.media.AudioManager;
import android.media.ToneGenerator;
import android.view.MotionEvent;
import android.view.View;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.Iterator;
import java.util.List;
import java.util.Locale;
import java.util.Random;

/**
 * Évolution stable du moteur existant. Le rendu reste compatible avec les téléphones modestes,
 * mais les héros sont maintenant de vrais sprites animés 2.5D et la simulation utilise un pas fixe.
 */
public final class PirateGameViewV2 extends View {
    private enum Screen { MENU, HEROES, GAME, PAUSE, GAME_OVER }
    private enum Weather { SOLEIL, PLUIE, NEIGE, TEMPETE, CENDRES, BRUME }

    private static final float FIXED_STEP = 1f / 60f;
    private static final float MAX_FRAME_DELTA = 0.10f;
    private static final int MAX_UPDATES_PER_FRAME = 5;
    private static final float WORLD_WIDTH = 12_000f;
    private static final float ISLAND_WIDTH = 2_000f;
    private static final int MAX_ENEMIES = 18;
    private static final int MAX_PARTICLES = 120;
    private static final float PLAYER_RADIUS = 25f;

    private static final String[] HERO_NAMES = {"CHEIKH", "YVANE", "NELVYN"};
    private static final String[] HERO_ROLES = {
            "Capitaine puissant", "Éclaireur électrique", "Inventeur tactique"
    };
    private static final int[] HERO_COLORS = {
            Color.rgb(196, 48, 48), Color.rgb(44, 157, 228), Color.rgb(52, 190, 112)
    };
    private static final String[] ISLAND_NAMES = {
            "Baie solaire", "Royaume des glaces", "Désert des corsaires",
            "Volcan rouge", "Jungle brumeuse", "Mer de la tempête"
    };

    private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint stroke = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Path path = new Path();
    private final Random random = new Random(0xC4E1A7L);
    private final SharedPreferences prefs;
    private final PirateGameView.VoiceNarrator narrator;
    private final ToneGenerator tones = new ToneGenerator(AudioManager.STREAM_MUSIC, 48);
    private final Character25D[] heroes = {
            new Character25D(0), new Character25D(1), new Character25D(2)
    };
    private final List<Enemy> enemies = new ArrayList<>();
    private final List<Projectile> projectiles = new ArrayList<>();
    private final List<Particle> particles = new ArrayList<>();
    private final List<Obstacle> obstacles = new ArrayList<>();

    private Screen screen = Screen.MENU;
    private Weather weather = Weather.SOLEIL;
    private boolean running = true;
    private boolean released;
    private boolean voiceEnabled = true;
    private boolean facingRight = true;
    private boolean sprinting;

    private int width;
    private int height;
    private int selectedHero;
    private int currentIsland;
    private int level = 1;
    private int xp;
    private int coins;
    private int missionKills;
    private int defeatedBosses;
    private int movePointer = -1;
    private int cameraPointer = -1;
    private int buttonPointer = -1;

    private long lastFrameNanos;
    private long lastSpawnMillis;
    private long lastSaveMillis;
    private long lastWeatherMillis;
    private float accumulator;
    private float animationTime;
    private float playerX = 560f;
    private float playerY;
    private float playerVX;
    private float playerVY;
    private float playerHp = 100f;
    private float playerMaxHp = 100f;
    private float energy = 100f;
    private float aura;
    private float auraTime;
    private float attackTime;
    private float hurtTime;
    private float dodgeTime;
    private float dodgeCooldown;
    private float jumpHeight;
    private float jumpVelocity;
    private float moveX;
    private float moveY;
    private float cameraInputX;
    private float cameraInputY;
    private float cameraX;
    private float cameraLook;
    private float cameraZoom = 1f;
    private float shake;
    private float flash;
    private float comboTimer;
    private int combo;
    private float moveBaseX;
    private float moveBaseY;
    private float cameraBaseX;
    private float cameraBaseY;

    public PirateGameViewV2(Context context, PirateGameView.VoiceNarrator narrator) {
        super(context);
        this.narrator = narrator;
        prefs = context.getSharedPreferences("chk_pirate_save", Context.MODE_PRIVATE);
        stroke.setStyle(Paint.Style.STROKE);
        stroke.setStrokeWidth(3f);
        setFocusable(true);
        setKeepScreenOn(true);
        loadSave();
    }

    public void onVoiceReady() {
        speak("Bienvenue dans CHK Pirate Warrior. Les héros 2.5D sont prêts.");
    }

    public void pauseGameLoop() {
        running = false;
        saveGame();
    }

    public void resumeGameLoop() {
        if (released) return;
        running = true;
        lastFrameNanos = 0L;
        accumulator = 0f;
        postInvalidateOnAnimation();
    }

    @Override
    protected void onDetachedFromWindow() {
        running = false;
        if (!released) {
            released = true;
            tones.release();
            for (Character25D hero : heroes) hero.release();
        }
        super.onDetachedFromWindow();
    }

    @Override
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        width = w;
        height = h;
        moveBaseX = Math.max(112f, width * 0.105f);
        moveBaseY = height - Math.max(105f, height * 0.19f);
        cameraBaseX = width - Math.max(285f, width * 0.22f);
        cameraBaseY = height - Math.max(100f, height * 0.18f);
        if (playerY <= 0f) playerY = playableBottom() - 34f;
        rebuildObstacles();
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        long now = System.nanoTime();
        float frameDelta = lastFrameNanos == 0L ? 0f
                : Math.min(MAX_FRAME_DELTA, (now - lastFrameNanos) / 1_000_000_000f);
        lastFrameNanos = now;

        if (running && frameDelta > 0f) {
            accumulator += frameDelta;
            int updates = 0;
            while (accumulator >= FIXED_STEP && updates < MAX_UPDATES_PER_FRAME) {
                update(FIXED_STEP);
                accumulator -= FIXED_STEP;
                updates++;
            }
            if (updates == MAX_UPDATES_PER_FRAME) accumulator = 0f;
        }

        switch (screen) {
            case MENU -> drawMenu(canvas);
            case HEROES -> drawHeroSelection(canvas);
            case GAME, PAUSE -> drawGame(canvas);
            case GAME_OVER -> drawGameOver(canvas);
        }
        if (screen == Screen.PAUSE) drawPause(canvas);
        if (running && !released) postInvalidateOnAnimation();
    }

    private void update(float dt) {
        animationTime += dt;
        flash = Math.max(0f, flash - dt * 3.2f);
        shake = Math.max(0f, shake - dt * 28f);
        attackTime = Math.max(0f, attackTime - dt);
        hurtTime = Math.max(0f, hurtTime - dt);
        dodgeTime = Math.max(0f, dodgeTime - dt);
        dodgeCooldown = Math.max(0f, dodgeCooldown - dt);
        comboTimer = Math.max(0f, comboTimer - dt);
        if (comboTimer <= 0f) combo = 0;
        if (screen != Screen.GAME) return;

        energy = Math.min(100f, energy + dt * (sprinting ? 3f : 7f));
        auraTime = Math.max(0f, auraTime - dt);
        updatePlayer(dt);
        updateEnemies(dt);
        updateProjectiles(dt);
        updateParticles(dt);

        int island = Math.min(5, Math.max(0, (int) (playerX / ISLAND_WIDTH)));
        if (island != currentIsland) {
            currentIsland = island;
            missionKills = 0;
            enemies.clear();
            projectiles.clear();
            rebuildObstacles();
            chooseWeather(true);
            speak("Nouvelle île. " + ISLAND_NAMES[currentIsland] + ".");
        }

        float targetCamera = playerX - width * (0.48f + cameraLook * 0.10f);
        cameraX += (targetCamera - cameraX) * Math.min(1f, dt * 7.5f);
        cameraX = GameMath.clamp(cameraX, 0f, Math.max(0f, WORLD_WIDTH - width));

        long now = System.currentTimeMillis();
        if (now - lastSpawnMillis > 1150L && enemies.size() < MAX_ENEMIES) {
            spawnEnemy(false);
            lastSpawnMillis = now;
        }
        if (missionKills >= 8 && !hasBoss()) {
            spawnEnemy(true);
            missionKills = -100;
            speak("Le boss de l'île arrive.");
        }
        if (now - lastWeatherMillis > 32_000L) chooseWeather(false);
        if (now - lastSaveMillis > 9_000L) saveGame();
        if (playerHp <= 0f) {
            screen = Screen.GAME_OVER;
            saveGame();
            speak("L'équipage est à terre.");
        }
    }

    private void updatePlayer(float dt) {
        float magnitude = GameMath.length(moveX, moveY);
        float normalizedX = magnitude > 0.08f ? moveX / Math.max(1f, magnitude) : 0f;
        float normalizedY = magnitude > 0.08f ? moveY / Math.max(1f, magnitude) : 0f;
        sprinting = magnitude > 0.82f && energy > 2f;
        float speed = heroSpeed() * (sprinting ? 1.38f : 1f) * (auraTime > 0f ? 1.22f : 1f);
        if (sprinting) energy = Math.max(0f, energy - dt * 5.5f);

        float desiredVX = normalizedX * speed;
        float desiredVY = normalizedY * speed * 0.58f;
        float responsiveness = dodgeTime > 0f ? 22f : 11f;
        playerVX += (desiredVX - playerVX) * Math.min(1f, responsiveness * dt);
        playerVY += (desiredVY - playerVY) * Math.min(1f, responsiveness * dt);

        if (dodgeTime > 0f) {
            float direction = Math.abs(normalizedX) > 0.1f ? Math.signum(normalizedX) : (facingRight ? 1f : -1f);
            playerVX = direction * heroSpeed() * 2.35f;
        }
        if (Math.abs(playerVX) > 8f) facingRight = playerVX > 0f;

        float nextX = GameMath.clamp(playerX + playerVX * dt, 55f, WORLD_WIDTH - 55f);
        float nextY = GameMath.clamp(playerY + playerVY * dt, playableTop(), playableBottom());
        float[] resolved = resolveObstacles(nextX, nextY, PLAYER_RADIUS);
        playerX = resolved[0];
        playerY = resolved[1];

        if (jumpVelocity != 0f || jumpHeight > 0f) {
            jumpVelocity -= 920f * dt;
            jumpHeight += jumpVelocity * dt;
            if (jumpHeight <= 0f) {
                jumpHeight = 0f;
                jumpVelocity = 0f;
            }
        }
        cameraLook += (cameraInputX - cameraLook) * Math.min(1f, dt * 5.5f);
        cameraZoom += ((1f - cameraInputY * 0.12f) - cameraZoom) * Math.min(1f, dt * 4f);
        cameraZoom = GameMath.clamp(cameraZoom, 0.90f, 1.12f);
    }

    private void updateEnemies(float dt) {
        Iterator<Enemy> iterator = enemies.iterator();
        while (iterator.hasNext()) {
            Enemy enemy = iterator.next();
            enemy.cooldown = Math.max(0f, enemy.cooldown - dt);
            enemy.hitTime = Math.max(0f, enemy.hitTime - dt);
            enemy.dodgeTime = Math.max(0f, enemy.dodgeTime - dt);
            enemy.animation += dt;
            float dx = playerX - enemy.x;
            float dy = playerY - enemy.y;
            float distance = GameMath.length(dx, dy);
            float desiredDistance = enemy.ranged ? 205f : enemy.boss ? 78f : 62f;

            if (distance < 800f && enemy.hitTime <= 0f) {
                float direction = distance > 1f ? 1f / distance : 0f;
                if (enemy.ranged && distance < 145f) direction *= -0.8f;
                if (Math.abs(distance - desiredDistance) > 14f) {
                    enemy.vx += (dx * direction * enemy.speed - enemy.vx) * Math.min(1f, dt * 5f);
                    enemy.vy += (dy * direction * enemy.speed * 0.55f - enemy.vy) * Math.min(1f, dt * 5f);
                } else {
                    enemy.vx *= 0.82f;
                    enemy.vy *= 0.82f;
                }
            }

            separateEnemy(enemy, dt);
            float[] resolved = resolveObstacles(
                    GameMath.clamp(enemy.x + enemy.vx * dt, 40f, WORLD_WIDTH - 40f),
                    GameMath.clamp(enemy.y + enemy.vy * dt, playableTop(), playableBottom()),
                    enemy.radius
            );
            enemy.x = resolved[0];
            enemy.y = resolved[1];

            if (distance <= desiredDistance + 24f && enemy.cooldown <= 0f) {
                if (enemy.ranged) {
                    spawnProjectile(enemy, dx, dy, distance);
                    enemy.cooldown = enemy.boss ? 0.75f : 1.55f;
                } else if (dodgeTime <= 0f && hurtTime <= 0f) {
                    hurtPlayer(enemy.boss ? 17f : 6f + currentIsland * 1.1f);
                    enemy.cooldown = enemy.boss ? 0.82f : 1.30f;
                }
            }

            if (enemy.hp <= 0f) {
                iterator.remove();
                xp += enemy.boss ? 260 + currentIsland * 60 : 18 + currentIsland * 5;
                coins += enemy.boss ? 150 : 8;
                aura = Math.min(100f, aura + (enemy.boss ? 38f : 9f));
                if (enemy.boss) {
                    defeatedBosses++;
                    missionKills = 0;
                    playerHp = Math.min(playerMaxHp, playerHp + 35f);
                    speak("Boss vaincu. L'île est libérée.");
                } else {
                    missionKills = Math.max(0, missionKills) + 1;
                }
                checkLevelUp();
                burst(enemy.x, enemy.y, enemy.color, enemy.boss ? 30 : 12);
            }
        }
    }

    private void separateEnemy(Enemy enemy, float dt) {
        for (Enemy other : enemies) {
            if (other == enemy) continue;
            float dx = enemy.x - other.x;
            float dy = enemy.y - other.y;
            float distance = GameMath.length(dx, dy);
            float min = enemy.radius + other.radius + 8f;
            if (distance > 0.01f && distance < min) {
                float push = (min - distance) * 2.5f * dt;
                enemy.x += dx / distance * push;
                enemy.y += dy / distance * push;
            }
        }
    }

    private void updateProjectiles(float dt) {
        Iterator<Projectile> iterator = projectiles.iterator();
        while (iterator.hasNext()) {
            Projectile projectile = iterator.next();
            projectile.life -= dt;
            projectile.x += projectile.vx * dt;
            projectile.y += projectile.vy * dt;
            if (projectile.life <= 0f) {
                iterator.remove();
                continue;
            }
            if (dodgeTime <= 0f && hurtTime <= 0f
                    && GameMath.distance(projectile.x, projectile.y, playerX, playerY) < PLAYER_RADIUS + projectile.radius) {
                hurtPlayer(projectile.damage);
                iterator.remove();
            }
        }
    }

    private void updateParticles(float dt) {
        Iterator<Particle> iterator = particles.iterator();
        while (iterator.hasNext()) {
            Particle p = iterator.next();
            p.life -= dt;
            p.x += p.vx * dt;
            p.y += p.vy * dt;
            p.vy += 105f * dt;
            if (p.life <= 0f) iterator.remove();
        }
        int weatherTarget = weather == Weather.TEMPETE ? 80 : weather == Weather.PLUIE || weather == Weather.NEIGE ? 55 : 15;
        while (particles.size() < Math.min(MAX_PARTICLES, weatherTarget)) {
            Particle p = new Particle();
            p.x = cameraX + random.nextFloat() * width;
            p.y = random.nextFloat() * height * 0.78f;
            p.life = 1.1f + random.nextFloat() * 1.8f;
            p.weather = true;
            if (weather == Weather.NEIGE) {
                p.color = Color.WHITE;
                p.vx = -15f + random.nextFloat() * 30f;
                p.vy = 25f + random.nextFloat() * 35f;
            } else if (weather == Weather.PLUIE || weather == Weather.TEMPETE) {
                p.color = Color.argb(170, 190, 220, 255);
                p.vx = weather == Weather.TEMPETE ? -210f : -70f;
                p.vy = weather == Weather.TEMPETE ? 580f : 430f;
            } else {
                p.color = Color.argb(90, 255, 220, 125);
                p.vx = -10f + random.nextFloat() * 20f;
                p.vy = -18f;
            }
            particles.add(p);
        }
    }

    private void attack(boolean skill) {
        if (screen != Screen.GAME || attackTime > 0f) return;
        if (skill && energy < 32f) return;
        attackTime = skill ? 0.55f : selectedHero == 1 ? 0.25f : 0.36f;
        if (skill) energy -= 32f;
        float radius = skill ? 175f + selectedHero * 14f : 88f + selectedHero * 7f;
        float damage = skill ? 48f + level * 6f : 20f + level * 3.2f;
        if (auraTime > 0f) damage *= 1.55f;
        int hits = 0;
        for (Enemy enemy : enemies) {
            float dx = enemy.x - playerX;
            float dy = enemy.y - playerY;
            float distance = GameMath.length(dx, dy);
            boolean inFront = skill || (facingRight ? dx > -24f : dx < 24f);
            if (distance <= radius + enemy.radius && inFront) {
                enemy.hp -= damage;
                enemy.hitTime = 0.20f;
                float push = skill ? 115f : 48f;
                enemy.x += dx / Math.max(1f, distance) * push;
                enemy.y += dy / Math.max(1f, distance) * push * 0.35f;
                hits++;
                burst(enemy.x, enemy.y, HERO_COLORS[selectedHero], skill ? 10 : 4);
            }
        }
        if (hits > 0) {
            combo += hits;
            comboTimer = 2.2f;
            aura = Math.min(100f, aura + hits * (skill ? 3.2f : 1.6f));
            shake = skill ? 11f : 4f;
            tones.startTone(skill ? ToneGenerator.TONE_PROP_BEEP2 : ToneGenerator.TONE_PROP_BEEP, skill ? 85 : 42);
        }
    }

    private void dodge() {
        if (screen != Screen.GAME || dodgeCooldown > 0f || energy < 12f) return;
        dodgeTime = 0.26f;
        dodgeCooldown = 0.72f;
        energy -= 12f;
        shake = 3f;
    }

    private void jump() {
        if (screen != Screen.GAME || jumpHeight > 0f) return;
        jumpVelocity = 390f;
        jumpHeight = 1f;
    }

    private void activateAura() {
        if (screen != Screen.GAME || aura < 100f || auraTime > 0f) return;
        aura = 0f;
        auraTime = 12f;
        flash = 1f;
        shake = 18f;
        speak("Déferlement de " + HERO_NAMES[selectedHero] + ".");
    }

    private void hurtPlayer(float damage) {
        float applied = auraTime > 0f ? damage * 0.58f : damage;
        playerHp -= applied;
        hurtTime = 0.48f;
        flash = 0.25f;
        shake = Math.min(15f, 4f + damage * 0.5f);
        combo = 0;
        burst(playerX, playerY, Color.rgb(255, 86, 70), 9);
        tones.startTone(ToneGenerator.TONE_PROP_NACK, 70);
    }

    private void spawnEnemy(boolean boss) {
        Enemy enemy = new Enemy();
        enemy.boss = boss;
        enemy.type = boss ? currentIsland + 10 : random.nextInt(5);
        enemy.ranged = !boss && (enemy.type == 2 || enemy.type == 4) || boss && currentIsland % 2 == 1;
        float side = random.nextBoolean() ? -1f : 1f;
        enemy.x = GameMath.clamp(playerX + side * (boss ? 480f : 360f + random.nextFloat() * 330f), 80f, WORLD_WIDTH - 80f);
        enemy.y = playableTop() + random.nextFloat() * Math.max(1f, playableBottom() - playableTop());
        enemy.radius = boss ? 43f : 25f + enemy.type % 3 * 2f;
        enemy.maxHp = boss ? 440f + currentIsland * 120f : 70f + currentIsland * 20f + level * 4f;
        enemy.hp = enemy.maxHp;
        enemy.speed = boss ? 92f + currentIsland * 4f : 75f + random.nextFloat() * 30f;
        enemy.color = islandEnemyColor(currentIsland, enemy.type, boss);
        enemies.add(enemy);
    }

    private void spawnProjectile(Enemy enemy, float dx, float dy, float distance) {
        Projectile projectile = new Projectile();
        projectile.x = enemy.x;
        projectile.y = enemy.y - 18f;
        float inv = 1f / Math.max(1f, distance);
        float speed = enemy.boss ? 360f : 270f;
        projectile.vx = dx * inv * speed;
        projectile.vy = dy * inv * speed;
        projectile.life = 2.6f;
        projectile.radius = enemy.boss ? 11f : 7f;
        projectile.damage = enemy.boss ? 13f : 7f + currentIsland;
        projectile.color = enemy.color;
        projectiles.add(projectile);
    }

    private void rebuildObstacles() {
        obstacles.clear();
        if (width <= 0 || height <= 0) return;
        Random seeded = new Random(7_000L + currentIsland * 977L);
        float start = currentIsland * ISLAND_WIDTH;
        for (int i = 0; i < 13; i++) {
            Obstacle obstacle = new Obstacle();
            obstacle.x = start + 130f + seeded.nextFloat() * (ISLAND_WIDTH - 260f);
            obstacle.y = playableTop() + 18f + seeded.nextFloat() * Math.max(1f, playableBottom() - playableTop() - 36f);
            obstacle.radius = 24f + seeded.nextFloat() * 19f;
            obstacle.type = i % 4;
            if (GameMath.distance(obstacle.x, obstacle.y, playerX, playerY) > 120f) obstacles.add(obstacle);
        }
    }

    private float[] resolveObstacles(float x, float y, float radius) {
        float resolvedX = x;
        float resolvedY = y;
        for (Obstacle obstacle : obstacles) {
            float dx = resolvedX - obstacle.x;
            float dy = resolvedY - obstacle.y;
            float distance = GameMath.length(dx, dy);
            float minimum = radius + obstacle.radius;
            if (distance < minimum) {
                if (distance < 0.01f) {
                    resolvedX += minimum;
                } else {
                    float correction = minimum - distance;
                    resolvedX += dx / distance * correction;
                    resolvedY += dy / distance * correction;
                }
            }
        }
        return new float[]{
                GameMath.clamp(resolvedX, 55f, WORLD_WIDTH - 55f),
                GameMath.clamp(resolvedY, playableTop(), playableBottom())
        };
    }

    private void chooseWeather(boolean forced) {
        Weather previous = weather;
        weather = switch (currentIsland) {
            case 0 -> random.nextFloat() < 0.30f ? Weather.PLUIE : Weather.SOLEIL;
            case 1 -> Weather.NEIGE;
            case 2 -> Weather.SOLEIL;
            case 3 -> Weather.CENDRES;
            case 4 -> random.nextBoolean() ? Weather.BRUME : Weather.PLUIE;
            default -> Weather.TEMPETE;
        };
        lastWeatherMillis = System.currentTimeMillis();
        if (forced || previous != weather) speak("Météo : " + weather.name().toLowerCase(Locale.FRANCE) + ".");
    }

    private void checkLevelUp() {
        int next = Progression.levelForXp(xp);
        if (next > level) {
            level = next;
            playerMaxHp = 100f + (level - 1) * 11f;
            playerHp = playerMaxHp;
            flash = 1f;
            speak(HERO_NAMES[selectedHero] + " atteint le niveau " + level + ".");
        }
    }

    private void drawMenu(Canvas canvas) {
        drawBackdrop(canvas);
        text(canvas, "CHK", width * 0.08f, height * 0.22f, height * 0.14f, Color.rgb(244, 198, 73), true, Paint.Align.LEFT);
        text(canvas, "PIRATE WARRIOR", width * 0.08f, height * 0.34f, height * 0.075f, Color.WHITE, true, Paint.Align.LEFT);
        text(canvas, "HÉROS 2.5D • SIX ÎLES", width * 0.083f, height * 0.41f, height * 0.030f, Color.rgb(177, 219, 246), false, Paint.Align.LEFT);
        float left = width * 0.08f;
        float buttonWidth = Math.min(430f, width * 0.38f);
        float buttonHeight = Math.max(58f, height * 0.105f);
        button(canvas, new RectF(left, height * 0.54f, left + buttonWidth, height * 0.54f + buttonHeight), "CONTINUER", Color.rgb(190, 48, 46));
        button(canvas, new RectF(left, height * 0.68f, left + buttonWidth, height * 0.68f + buttonHeight), "CHOISIR LE HÉROS", Color.rgb(33, 111, 171));
        heroes[selectedHero].draw(canvas, Character25D.Pose.IDLE, animationTime, width * 0.74f, height * 0.88f, height * 0.69f, true, 1f);
        text(canvas, "Niveau " + level + " • " + coins + " pièces", width - 30f, 38f, 21f, Color.WHITE, true, Paint.Align.RIGHT);
    }

    private void drawHeroSelection(Canvas canvas) {
        drawBackdrop(canvas);
        text(canvas, "CHOISIS TON HÉROS", width * 0.5f, height * 0.11f, height * 0.065f, Color.WHITE, true, Paint.Align.CENTER);
        float gap = width * 0.025f;
        float cardWidth = (width - gap * 4f) / 3f;
        for (int i = 0; i < 3; i++) {
            float left = gap + i * (cardWidth + gap);
            RectF card = new RectF(left, height * 0.18f, left + cardWidth, height * 0.84f);
            paint.setColor(Color.argb(i == selectedHero ? 232 : 198, 5, 17, 31));
            canvas.drawRoundRect(card, 24f, 24f, paint);
            stroke.setColor(i == selectedHero ? Color.rgb(246, 204, 79) : Color.argb(90, 255, 255, 255));
            stroke.setStrokeWidth(i == selectedHero ? 5f : 2f);
            canvas.drawRoundRect(card, 24f, 24f, stroke);
            heroes[i].draw(canvas, Character25D.Pose.IDLE, animationTime, card.centerX(), card.bottom - 90f, card.height() * 0.72f, true, 1f);
            text(canvas, HERO_NAMES[i], card.centerX(), card.bottom - 54f, 28f, HERO_COLORS[i], true, Paint.Align.CENTER);
            text(canvas, HERO_ROLES[i], card.centerX(), card.bottom - 25f, 16f, Color.WHITE, false, Paint.Align.CENTER);
        }
        button(canvas, new RectF(width * 0.36f, height * 0.87f, width * 0.64f, height * 0.98f), "JOUER", Color.rgb(184, 50, 47));
    }

    private void drawGame(Canvas canvas) {
        canvas.save();
        if (shake > 0f) canvas.translate(-shake * 0.5f + random.nextFloat() * shake, -shake * 0.5f + random.nextFloat() * shake);
        drawWorld(canvas);
        drawObstacles(canvas);
        drawDepthEntities(canvas);
        drawProjectiles(canvas);
        drawParticles(canvas);
        canvas.restore();
        drawHud(canvas);
        drawControls(canvas);
        if (flash > 0f) {
            paint.setColor(Color.argb((int) (flash * 105f), 255, 255, 255));
            canvas.drawRect(0f, 0f, width, height, paint);
        }
    }

    private void drawWorld(Canvas canvas) {
        int top = switch (currentIsland) {
            case 1 -> Color.rgb(92, 151, 205);
            case 2 -> Color.rgb(180, 111, 51);
            case 3 -> Color.rgb(91, 45, 48);
            case 4 -> Color.rgb(43, 111, 79);
            case 5 -> Color.rgb(35, 57, 92);
            default -> Color.rgb(50, 145, 205);
        };
        int bottom = switch (currentIsland) {
            case 1 -> Color.rgb(223, 241, 251);
            case 2 -> Color.rgb(242, 195, 112);
            case 3 -> Color.rgb(188, 88, 55);
            case 4 -> Color.rgb(130, 182, 122);
            case 5 -> Color.rgb(93, 119, 155);
            default -> Color.rgb(194, 226, 236);
        };
        paint.setShader(new LinearGradient(0f, 0f, 0f, height * 0.58f, top, bottom, Shader.TileMode.CLAMP));
        canvas.drawRect(0f, 0f, width, height * 0.61f, paint);
        paint.setShader(null);
        paint.setColor(currentIsland == 1 ? Color.rgb(218, 232, 235)
                : currentIsland == 2 ? Color.rgb(210, 168, 90)
                : currentIsland == 3 ? Color.rgb(80, 65, 59)
                : currentIsland == 4 ? Color.rgb(72, 125, 67)
                : Color.rgb(107, 156, 86));
        canvas.drawRect(0f, height * 0.47f, width, height, paint);
        paint.setColor(Color.argb(70, 255, 255, 255));
        for (int i = 0; i < 9; i++) {
            float y = height * 0.50f + i * (height * 0.045f);
            canvas.drawLine(0f, y, width, y, paint);
        }
        if (weather == Weather.BRUME) {
            paint.setColor(Color.argb(95, 224, 235, 226));
            canvas.drawRect(0f, height * 0.25f, width, height * 0.78f, paint);
        }
    }

    private void drawObstacles(Canvas canvas) {
        List<Obstacle> sorted = new ArrayList<>(obstacles);
        sorted.sort(Comparator.comparingDouble(o -> o.y));
        for (Obstacle obstacle : sorted) {
            float sx = obstacle.x - cameraX;
            if (sx < -100f || sx > width + 100f) continue;
            float scale = depthScale(obstacle.y);
            float r = obstacle.radius * scale;
            paint.setColor(Color.argb(65, 0, 0, 0));
            canvas.drawOval(new RectF(sx - r, obstacle.y - r * 0.15f, sx + r, obstacle.y + r * 0.25f), paint);
            if (obstacle.type == 0) {
                paint.setColor(Color.rgb(112, 76, 48));
                canvas.drawRect(sx - r * 0.18f, obstacle.y - r * 1.7f, sx + r * 0.18f, obstacle.y, paint);
                paint.setColor(currentIsland == 1 ? Color.rgb(195, 224, 220) : Color.rgb(48, 139, 73));
                canvas.drawCircle(sx, obstacle.y - r * 1.75f, r * 0.9f, paint);
            } else {
                paint.setColor(currentIsland == 3 ? Color.rgb(81, 66, 61) : Color.rgb(104, 112, 110));
                path.reset();
                path.moveTo(sx - r, obstacle.y);
                path.lineTo(sx - r * 0.55f, obstacle.y - r * 1.1f);
                path.lineTo(sx + r * 0.35f, obstacle.y - r * 1.35f);
                path.lineTo(sx + r, obstacle.y);
                path.close();
                canvas.drawPath(path, paint);
            }
        }
    }

    private void drawDepthEntities(Canvas canvas) {
        List<Enemy> sorted = new ArrayList<>(enemies);
        sorted.sort(Comparator.comparingDouble(e -> e.y));
        boolean playerDrawn = false;
        for (Enemy enemy : sorted) {
            if (!playerDrawn && enemy.y > playerY) {
                drawPlayer(canvas);
                playerDrawn = true;
            }
            drawEnemy(canvas, enemy);
        }
        if (!playerDrawn) drawPlayer(canvas);
    }

    private void drawPlayer(Canvas canvas) {
        float sx = playerX - cameraX;
        float heightPx = (118f + level * 0.6f) * depthScale(playerY) * cameraZoom;
        Character25D.Pose pose;
        if (hurtTime > 0f) pose = Character25D.Pose.HURT;
        else if (jumpHeight > 0f) pose = Character25D.Pose.JUMP;
        else if (attackTime > 0f) pose = Character25D.Pose.ATTACK;
        else if (GameMath.length(playerVX, playerVY) > heroSpeed() * 0.85f) pose = Character25D.Pose.RUN;
        else if (GameMath.length(playerVX, playerVY) > 12f) pose = Character25D.Pose.WALK;
        else pose = Character25D.Pose.IDLE;
        if (auraTime > 0f) {
            paint.setColor(Color.argb(55, Color.red(HERO_COLORS[selectedHero]), Color.green(HERO_COLORS[selectedHero]), Color.blue(HERO_COLORS[selectedHero])));
            canvas.drawCircle(sx, playerY - heightPx * 0.45f - jumpHeight, heightPx * 0.62f, paint);
        }
        heroes[selectedHero].draw(canvas, pose, animationTime, sx, playerY - jumpHeight, heightPx, facingRight, dodgeTime > 0f ? 0.72f : 1f);
        text(canvas, HERO_NAMES[selectedHero], sx, playerY + 20f, 14f, Color.WHITE, true, Paint.Align.CENTER);
    }

    private void drawEnemy(Canvas canvas, Enemy enemy) {
        float sx = enemy.x - cameraX;
        if (sx < -120f || sx > width + 120f) return;
        float scale = depthScale(enemy.y);
        float size = (enemy.boss ? 62f : 39f) * scale;
        paint.setColor(Color.argb(65, 0, 0, 0));
        canvas.drawOval(new RectF(sx - size * 0.7f, enemy.y - 4f, sx + size * 0.7f, enemy.y + 9f), paint);
        paint.setColor(enemy.hitTime > 0f ? Color.WHITE : enemy.color);
        canvas.drawRoundRect(new RectF(sx - size * 0.48f, enemy.y - size * 1.45f, sx + size * 0.48f, enemy.y), size * 0.2f, size * 0.2f, paint);
        paint.setColor(Color.rgb(61, 43, 35));
        canvas.drawCircle(sx, enemy.y - size * 1.60f, size * 0.36f, paint);
        paint.setColor(Color.WHITE);
        canvas.drawCircle(sx - size * 0.11f, enemy.y - size * 1.63f, 2.5f, paint);
        canvas.drawCircle(sx + size * 0.11f, enemy.y - size * 1.63f, 2.5f, paint);
        drawBar(canvas, sx - size, enemy.y - size * 2.1f, size * 2f, enemy.boss ? 10f : 6f, enemy.hp / enemy.maxHp, enemy.boss ? Color.rgb(232, 61, 51) : Color.rgb(230, 116, 58));
        if (enemy.boss) text(canvas, "BOSS " + (currentIsland + 1), sx, enemy.y - size * 2.35f, 17f, Color.WHITE, true, Paint.Align.CENTER);
    }

    private void drawProjectiles(Canvas canvas) {
        for (Projectile projectile : projectiles) {
            float sx = projectile.x - cameraX;
            paint.setColor(Color.argb(80, Color.red(projectile.color), Color.green(projectile.color), Color.blue(projectile.color)));
            canvas.drawCircle(sx, projectile.y, projectile.radius * 2.1f, paint);
            paint.setColor(projectile.color);
            canvas.drawCircle(sx, projectile.y, projectile.radius, paint);
        }
    }

    private void drawParticles(Canvas canvas) {
        for (Particle p : particles) {
            float sx = p.x - cameraX;
            paint.setColor(p.color);
            paint.setStrokeWidth(2f);
            if (p.weather && (weather == Weather.PLUIE || weather == Weather.TEMPETE)) {
                canvas.drawLine(sx, p.y, sx + p.vx * 0.03f, p.y + p.vy * 0.03f, paint);
            } else {
                canvas.drawCircle(sx, p.y, p.weather ? 2.5f : 4f, paint);
            }
        }
    }

    private void drawHud(Canvas canvas) {
        drawBar(canvas, 22f, 20f, Math.min(330f, width * 0.29f), 22f, playerHp / playerMaxHp, Color.rgb(208, 55, 50));
        drawBar(canvas, 22f, 51f, Math.min(330f, width * 0.29f), 14f, energy / 100f, Color.rgb(47, 146, 220));
        drawBar(canvas, 22f, 74f, Math.min(330f, width * 0.29f), 14f, aura / 100f, HERO_COLORS[selectedHero]);
        text(canvas, HERO_NAMES[selectedHero] + " NIVEAU " + level, 22f, 115f, 21f, Color.WHITE, true, Paint.Align.LEFT);
        text(canvas, ISLAND_NAMES[currentIsland], width * 0.5f, 31f, 22f, Color.WHITE, true, Paint.Align.CENTER);
        text(canvas, missionKills < 0 ? "Mission : vaincre le boss" : "Mission : " + missionKills + "/8", width * 0.5f, 58f, 17f, Color.rgb(244, 217, 143), false, Paint.Align.CENTER);
        text(canvas, coins + " pièces", width - 20f, 92f, 18f, Color.WHITE, true, Paint.Align.RIGHT);
        if (combo > 1) text(canvas, combo + " COUPS", width * 0.73f, height * 0.24f, 32f, Color.rgb(255, 215, 71), true, Paint.Align.CENTER);
        pill(canvas, new RectF(width - 92f, 15f, width - 18f, 63f), "PAUSE");
    }

    private void drawControls(Canvas canvas) {
        joystick(canvas, moveBaseX, moveBaseY, moveX, moveY, "DÉPLACER");
        joystick(canvas, cameraBaseX, cameraBaseY, cameraInputX, cameraInputY, "CAMÉRA");
        roundAction(canvas, width - 84f, height - 88f, 54f, Color.rgb(197, 52, 47), "ATTAQUE");
        roundAction(canvas, width - 198f, height - 165f, 47f, Color.rgb(37, 124, 188), "POUVOIR");
        roundAction(canvas, width - 92f, height - 228f, 43f, Color.rgb(111, 82, 165), "SAUT");
        roundAction(canvas, width - 292f, height - 73f, 42f, dodgeCooldown <= 0f ? Color.rgb(45, 151, 96) : Color.rgb(82, 88, 91), "ESQUIVE");
        roundAction(canvas, width - 330f, 80f, 39f, aura >= 100f ? HERO_COLORS[selectedHero] : Color.rgb(77, 81, 89), "AURA");
    }

    private void drawPause(Canvas canvas) {
        paint.setColor(Color.argb(215, 0, 0, 0));
        canvas.drawRect(0f, 0f, width, height, paint);
        text(canvas, "PAUSE", width * 0.5f, height * 0.30f, height * 0.10f, Color.WHITE, true, Paint.Align.CENTER);
        button(canvas, new RectF(width * 0.34f, height * 0.42f, width * 0.66f, height * 0.54f), "REPRENDRE", Color.rgb(42, 137, 89));
        button(canvas, new RectF(width * 0.34f, height * 0.60f, width * 0.66f, height * 0.72f), "MENU", Color.rgb(169, 55, 49));
    }

    private void drawGameOver(Canvas canvas) {
        drawBackdrop(canvas);
        paint.setColor(Color.argb(185, 0, 0, 0));
        canvas.drawRect(0f, 0f, width, height, paint);
        text(canvas, "ÉQUIPAGE À TERRE", width * 0.5f, height * 0.30f, height * 0.085f, Color.rgb(239, 83, 68), true, Paint.Align.CENTER);
        text(canvas, "Niveau " + level + " • Boss vaincus " + defeatedBosses, width * 0.5f, height * 0.42f, 23f, Color.WHITE, false, Paint.Align.CENTER);
        button(canvas, new RectF(width * 0.35f, height * 0.56f, width * 0.65f, height * 0.69f), "RECOMMENCER", Color.rgb(43, 137, 89));
        button(canvas, new RectF(width * 0.35f, height * 0.74f, width * 0.65f, height * 0.87f), "MENU", Color.rgb(54, 91, 138));
    }

    private void drawBackdrop(Canvas canvas) {
        paint.setShader(new LinearGradient(0f, 0f, 0f, height, Color.rgb(21, 113, 176), Color.rgb(2, 26, 52), Shader.TileMode.CLAMP));
        canvas.drawRect(0f, 0f, width, height, paint);
        paint.setShader(null);
        paint.setColor(Color.argb(45, 255, 255, 255));
        for (int i = 0; i < 16; i++) {
            float y = height * 0.54f + i * 14f;
            canvas.drawOval(new RectF((i * 91f) % Math.max(1, width) - 100f, y, (i * 91f) % Math.max(1, width) + 180f, y + 7f), paint);
        }
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        int action = event.getActionMasked();
        if (action == MotionEvent.ACTION_DOWN || action == MotionEvent.ACTION_POINTER_DOWN) {
            int index = event.getActionIndex();
            handleDown(event.getPointerId(index), event.getX(index), event.getY(index));
        } else if (action == MotionEvent.ACTION_MOVE) {
            for (int i = 0; i < event.getPointerCount(); i++) {
                int id = event.getPointerId(i);
                if (id == movePointer) updateStick(event.getX(i), event.getY(i), true);
                if (id == cameraPointer) updateStick(event.getX(i), event.getY(i), false);
            }
        } else if (action == MotionEvent.ACTION_UP || action == MotionEvent.ACTION_POINTER_UP) {
            releasePointer(event.getPointerId(event.getActionIndex()));
        } else if (action == MotionEvent.ACTION_CANCEL) {
            movePointer = cameraPointer = buttonPointer = -1;
            moveX = moveY = cameraInputX = cameraInputY = 0f;
        }
        return true;
    }

    private void handleDown(int pointerId, float x, float y) {
        if (screen == Screen.MENU) {
            if (y > height * 0.50f && y < height * 0.66f) startGame();
            else if (y > height * 0.66f && y < height * 0.84f) screen = Screen.HEROES;
            return;
        }
        if (screen == Screen.HEROES) {
            if (y < height * 0.85f) selectedHero = Math.max(0, Math.min(2, (int) (x / Math.max(1f, width / 3f))));
            else startGame();
            return;
        }
        if (screen == Screen.PAUSE) {
            if (y > height * 0.38f && y < height * 0.57f) screen = Screen.GAME;
            else if (y > height * 0.57f && y < height * 0.77f) screen = Screen.MENU;
            return;
        }
        if (screen == Screen.GAME_OVER) {
            if (y > height * 0.52f && y < height * 0.72f) restartGame();
            else if (y > height * 0.72f) screen = Screen.MENU;
            return;
        }
        if (screen != Screen.GAME) return;

        if (x < width * 0.29f && y > height * 0.50f) {
            movePointer = pointerId;
            updateStick(x, y, true);
        } else if (x > width * 0.53f && x < width - 350f && y > height * 0.48f) {
            cameraPointer = pointerId;
            updateStick(x, y, false);
        } else if (insideCircle(x, y, width - 84f, height - 88f, 68f)) {
            buttonPointer = pointerId;
            attack(false);
        } else if (insideCircle(x, y, width - 198f, height - 165f, 61f)) {
            buttonPointer = pointerId;
            attack(true);
        } else if (insideCircle(x, y, width - 92f, height - 228f, 57f)) {
            buttonPointer = pointerId;
            jump();
        } else if (insideCircle(x, y, width - 292f, height - 73f, 57f)) {
            buttonPointer = pointerId;
            dodge();
        } else if (insideCircle(x, y, width - 330f, 80f, 53f)) {
            buttonPointer = pointerId;
            activateAura();
        } else if (x > width - 115f && y < 82f) {
            screen = Screen.PAUSE;
            saveGame();
        }
    }

    private void updateStick(float x, float y, boolean movement) {
        float baseX = movement ? moveBaseX : cameraBaseX;
        float baseY = movement ? moveBaseY : cameraBaseY;
        float dx = x - baseX;
        float dy = y - baseY;
        float length = GameMath.length(dx, dy);
        float max = 74f;
        float scale = length > max ? max / length : 1f;
        float nx = dx * scale / max;
        float ny = dy * scale / max;
        if (movement) {
            moveX = nx;
            moveY = ny;
        } else {
            cameraInputX = nx;
            cameraInputY = ny;
        }
    }

    private void releasePointer(int pointerId) {
        if (pointerId == movePointer) {
            movePointer = -1;
            moveX = moveY = 0f;
        }
        if (pointerId == cameraPointer) {
            cameraPointer = -1;
            cameraInputX = cameraInputY = 0f;
        }
        if (pointerId == buttonPointer) buttonPointer = -1;
    }

    private void startGame() {
        screen = Screen.GAME;
        playerHp = Math.max(1f, playerHp);
        enemies.clear();
        projectiles.clear();
        rebuildObstacles();
        chooseWeather(true);
        speak("Départ avec " + HERO_NAMES[selectedHero] + ".");
    }

    private void restartGame() {
        playerHp = playerMaxHp;
        energy = 100f;
        aura = 0f;
        missionKills = 0;
        enemies.clear();
        projectiles.clear();
        screen = Screen.GAME;
    }

    private void burst(float x, float y, int color, int count) {
        int allowed = Math.min(count, MAX_PARTICLES - particles.size());
        for (int i = 0; i < allowed; i++) {
            Particle p = new Particle();
            double angle = random.nextDouble() * Math.PI * 2.0;
            float speed = 80f + random.nextFloat() * 180f;
            p.x = x;
            p.y = y - 25f;
            p.vx = (float) Math.cos(angle) * speed;
            p.vy = (float) Math.sin(angle) * speed;
            p.life = 0.35f + random.nextFloat() * 0.45f;
            p.color = color;
            particles.add(p);
        }
    }

    private void saveGame() {
        prefs.edit()
                .putInt("selected_hero", selectedHero)
                .putInt("xp", xp)
                .putInt("level", level)
                .putInt("coins", coins)
                .putInt("bosses", defeatedBosses)
                .putFloat("player_x", playerX)
                .putFloat("player_hp", playerHp)
                .apply();
        lastSaveMillis = System.currentTimeMillis();
    }

    private void loadSave() {
        selectedHero = Math.max(0, Math.min(2, prefs.getInt("selected_hero", 0)));
        xp = Math.max(0, prefs.getInt("xp", 0));
        level = Math.max(1, prefs.getInt("level", Progression.levelForXp(xp)));
        coins = Math.max(0, prefs.getInt("coins", 0));
        defeatedBosses = Math.max(0, prefs.getInt("bosses", 0));
        playerX = GameMath.clamp(prefs.getFloat("player_x", 560f), 55f, WORLD_WIDTH - 55f);
        currentIsland = Math.min(5, Math.max(0, (int) (playerX / ISLAND_WIDTH)));
        playerMaxHp = 100f + (level - 1) * 11f;
        playerHp = GameMath.clamp(prefs.getFloat("player_hp", playerMaxHp), 1f, playerMaxHp);
    }

    private boolean hasBoss() {
        for (Enemy enemy : enemies) if (enemy.boss) return true;
        return false;
    }

    private float heroSpeed() {
        return selectedHero == 1 ? 255f : selectedHero == 2 ? 222f : 208f;
    }

    private float playableTop() {
        return height * 0.55f;
    }

    private float playableBottom() {
        return height * 0.85f;
    }

    private float depthScale(float y) {
        float t = (y - playableTop()) / Math.max(1f, playableBottom() - playableTop());
        return 0.76f + GameMath.clamp(t, 0f, 1f) * 0.35f;
    }

    private int islandEnemyColor(int island, int type, boolean boss) {
        int base = switch (island) {
            case 1 -> Color.rgb(92, 166, 205);
            case 2 -> Color.rgb(184, 109, 54);
            case 3 -> Color.rgb(155, 55, 45);
            case 4 -> Color.rgb(59, 141, 82);
            case 5 -> Color.rgb(91, 81, 153);
            default -> Color.rgb(174, 67, 52);
        };
        if (boss) return Color.rgb(Math.min(255, Color.red(base) + 45), Math.max(25, Color.green(base) - 20), Math.max(25, Color.blue(base) - 15));
        int shift = (type % 3) * 18;
        return Color.rgb(Math.min(255, Color.red(base) + shift), Math.min(255, Color.green(base) + shift / 2), Math.min(255, Color.blue(base) + shift / 3));
    }

    private void speak(String message) {
        if (voiceEnabled && narrator != null && message != null && !message.isEmpty()) narrator.speak(message);
    }

    private void joystick(Canvas canvas, float x, float y, float nx, float ny, String label) {
        paint.setColor(Color.argb(55, 255, 255, 255));
        canvas.drawCircle(x, y, 74f, paint);
        stroke.setColor(Color.argb(120, 255, 255, 255));
        canvas.drawCircle(x, y, 74f, stroke);
        paint.setColor(Color.argb(165, 20, 31, 45));
        canvas.drawCircle(x + nx * 52f, y + ny * 52f, 32f, paint);
        text(canvas, label, x, y + 98f, 13f, Color.argb(180, 255, 255, 255), true, Paint.Align.CENTER);
    }

    private void roundAction(Canvas canvas, float x, float y, float radius, int color, String label) {
        paint.setColor(Color.argb(220, Color.red(color), Color.green(color), Color.blue(color)));
        canvas.drawCircle(x, y, radius, paint);
        stroke.setColor(Color.argb(190, 255, 255, 255));
        canvas.drawCircle(x, y, radius, stroke);
        text(canvas, label, x, y + 5f, Math.max(11f, radius * 0.27f), Color.WHITE, true, Paint.Align.CENTER);
    }

    private void button(Canvas canvas, RectF rect, String label, int color) {
        paint.setColor(Color.argb(225, Color.red(color), Color.green(color), Color.blue(color)));
        canvas.drawRoundRect(rect, 19f, 19f, paint);
        stroke.setColor(Color.argb(160, 255, 255, 255));
        canvas.drawRoundRect(rect, 19f, 19f, stroke);
        text(canvas, label, rect.centerX(), rect.centerY() + 8f, Math.min(26f, rect.height() * 0.38f), Color.WHITE, true, Paint.Align.CENTER);
    }

    private void pill(Canvas canvas, RectF rect, String label) {
        paint.setColor(Color.argb(175, 0, 0, 0));
        canvas.drawRoundRect(rect, rect.height() * 0.5f, rect.height() * 0.5f, paint);
        text(canvas, label, rect.centerX(), rect.centerY() + 5f, 14f, Color.WHITE, true, Paint.Align.CENTER);
    }

    private void drawBar(Canvas canvas, float x, float y, float w, float h, float value, int color) {
        paint.setColor(Color.argb(160, 0, 0, 0));
        canvas.drawRoundRect(new RectF(x, y, x + w, y + h), h * 0.5f, h * 0.5f, paint);
        paint.setColor(color);
        canvas.drawRoundRect(new RectF(x + 2f, y + 2f, x + 2f + (w - 4f) * GameMath.clamp(value, 0f, 1f), y + h - 2f), h * 0.4f, h * 0.4f, paint);
    }

    private void text(Canvas canvas, String value, float x, float y, float size, int color, boolean bold, Paint.Align align) {
        paint.setShader(null);
        paint.setStyle(Paint.Style.FILL);
        paint.setColor(color);
        paint.setTextSize(size);
        paint.setTextAlign(align);
        paint.setFakeBoldText(bold);
        canvas.drawText(value, x, y, paint);
        paint.setFakeBoldText(false);
    }

    private static boolean insideCircle(float x, float y, float cx, float cy, float radius) {
        float dx = x - cx;
        float dy = y - cy;
        return dx * dx + dy * dy <= radius * radius;
    }

    private static final class Enemy {
        float x;
        float y;
        float vx;
        float vy;
        float radius;
        float hp;
        float maxHp;
        float speed;
        float cooldown;
        float hitTime;
        float dodgeTime;
        float animation;
        int type;
        int color;
        boolean ranged;
        boolean boss;
    }

    private static final class Projectile {
        float x;
        float y;
        float vx;
        float vy;
        float life;
        float radius;
        float damage;
        int color;
    }

    private static final class Particle {
        float x;
        float y;
        float vx;
        float vy;
        float life;
        int color;
        boolean weather;
    }

    private static final class Obstacle {
        float x;
        float y;
        float radius;
        int type;
    }
}
