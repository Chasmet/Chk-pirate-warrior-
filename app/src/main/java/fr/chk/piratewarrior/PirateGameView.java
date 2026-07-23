package fr.chk.piratewarrior;

import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.Rect;
import android.graphics.RectF;
import android.graphics.Shader;
import android.media.AudioManager;
import android.media.ToneGenerator;
import android.view.MotionEvent;
import android.view.View;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Locale;
import java.util.Random;

public final class PirateGameView extends View {
    public interface VoiceNarrator {
        void speak(String text);
    }

    private enum Screen { MENU, HEROES, GAME, PAUSE, TRAINING, GAME_OVER, VICTORY }
    private enum Weather { SOLEIL, PLUIE, NEIGE, TEMPETE, CENDRES }

    private static final float WORLD_WIDTH = 10000f;
    private static final int MAX_ENEMIES = 14;
    private static final String[] HERO_NAMES = {"CHEIKH", "YVANE", "NELVYN"};
    private static final String[] HERO_ROLES = {
            "Capitaine puissant", "Éclaireur électrique", "Inventeur tactique"
    };
    private static final int[] HERO_COLORS = {
            Color.rgb(196, 48, 48), Color.rgb(44, 157, 228), Color.rgb(52, 190, 112)
    };
    private static final String[] ZONE_NAMES = {
            "Archipel solaire", "Royaume des neiges", "Désert des corsaires",
            "Île volcanique", "Mer de la tempête"
    };

    private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint stroke = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Path path = new Path();
    private final Random random = new Random(19L);
    private final List<Enemy> enemies = new ArrayList<>();
    private final List<Particle> particles = new ArrayList<>();
    private final List<Pickup> pickups = new ArrayList<>();
    private final SharedPreferences prefs;
    private final VoiceNarrator narrator;
    private final ToneGenerator tones = new ToneGenerator(AudioManager.STREAM_MUSIC, 55);
    private final Bitmap splash;

    private Screen screen = Screen.MENU;
    private Weather weather = Weather.SOLEIL;
    private boolean running = true;
    private boolean voiceEnabled = true;
    private boolean voiceWelcomed;
    private boolean mapVisible;
    private boolean missionAnnounced;
    private long lastFrameNanos;
    private long lastSaveMillis;
    private long lastWeatherChange;
    private long lastSpawnMillis;

    private int width;
    private int height;
    private int selectedHero;
    private int currentZone;
    private int missionKills;
    private int totalBossesDefeated;
    private int level = 1;
    private int xp;
    private int trainingPoints;
    private int coins;
    private int combo;
    private int bestCombo;
    private int attackPointer = -1;
    private int joystickPointer = -1;
    private int activeButtonPointer = -1;

    private float playerX = 560f;
    private float playerY;
    private float playerHp = 100f;
    private float playerMaxHp = 100f;
    private float energy = 100f;
    private float aura = 0f;
    private float auraTime;
    private float attackCooldown;
    private float skillCooldown;
    private float hurtCooldown;
    private float comboTimer;
    private float cameraX;
    private float dayClock = 0.22f;
    private float joystickX;
    private float joystickY;
    private float joystickBaseX;
    private float joystickBaseY;
    private float shake;
    private float flash;

    public PirateGameView(Context context, VoiceNarrator narrator) {
        super(context);
        this.narrator = narrator;
        prefs = context.getSharedPreferences("chk_pirate_save", Context.MODE_PRIVATE);
        splash = BitmapFactory.decodeResource(getResources(), R.drawable.hero_splash);
        stroke.setStyle(Paint.Style.STROKE);
        stroke.setStrokeWidth(3f);
        setFocusable(true);
        setKeepScreenOn(true);
        loadSave();
    }

    public void onVoiceReady() {
        if (!voiceWelcomed && voiceEnabled) {
            voiceWelcomed = true;
            narrator.speak("Bienvenue dans CHK Pirate Warrior. Choisis ton héros et pars à l'aventure.");
        }
    }

    public void pauseGameLoop() {
        running = false;
        saveGame();
    }

    public void resumeGameLoop() {
        running = true;
        lastFrameNanos = 0L;
        postInvalidateOnAnimation();
    }

    @Override
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        width = w;
        height = h;
        joystickBaseX = Math.max(120f, w * 0.11f);
        joystickBaseY = h - Math.max(110f, h * 0.19f);
        playerY = groundY() - 36f;
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        long now = System.nanoTime();
        float dt = lastFrameNanos == 0L ? 0f : Math.min(0.033f, (now - lastFrameNanos) / 1_000_000_000f);
        lastFrameNanos = now;

        if (running && dt > 0f) {
            update(dt);
        }

        switch (screen) {
            case MENU -> drawMenu(canvas);
            case HEROES -> drawHeroSelection(canvas);
            case GAME, PAUSE -> drawGame(canvas);
            case TRAINING -> drawTraining(canvas);
            case GAME_OVER -> drawEndScreen(canvas, false);
            case VICTORY -> drawEndScreen(canvas, true);
        }
        if (screen == Screen.PAUSE) {
            drawPauseOverlay(canvas);
        }
        if (running) {
            postInvalidateOnAnimation();
        }
    }

    private void update(float dt) {
        flash = Math.max(0f, flash - dt * 2.8f);
        shake = Math.max(0f, shake - dt * 22f);
        attackCooldown = Math.max(0f, attackCooldown - dt);
        skillCooldown = Math.max(0f, skillCooldown - dt);
        hurtCooldown = Math.max(0f, hurtCooldown - dt);
        comboTimer = Math.max(0f, comboTimer - dt);
        if (comboTimer <= 0f) combo = 0;

        if (screen != Screen.GAME) return;

        dayClock = (dayClock + dt / 150f) % 1f;
        energy = Math.min(100f, energy + dt * (auraTime > 0f ? 2.5f : 6f));
        if (auraTime > 0f) {
            auraTime -= dt;
            if (auraTime <= 0f && voiceEnabled) narrator.speak("Le déferlement est terminé.");
        }

        float speed = heroSpeed() * (auraTime > 0f ? 1.28f : 1f);
        float magnitude = (float) Math.sqrt(joystickX * joystickX + joystickY * joystickY);
        if (magnitude > 0.08f) {
            float nx = joystickX / Math.max(1f, magnitude);
            float ny = joystickY / Math.max(1f, magnitude);
            playerX = clamp(playerX + nx * speed * dt, 60f, WORLD_WIDTH - 60f);
            playerY = clamp(playerY + ny * speed * 0.62f * dt, groundY() - height * 0.22f, groundY() - 24f);
        }

        int zone = Math.min(4, (int) (playerX / 2000f));
        if (zone != currentZone) {
            currentZone = zone;
            chooseWeatherForZone(true);
            missionKills = 0;
            missionAnnounced = false;
            speak("Nouvelle région. " + ZONE_NAMES[currentZone] + ".");
        }

        cameraX += ((playerX - width * 0.43f) - cameraX) * Math.min(1f, dt * 5f);
        cameraX = clamp(cameraX, 0f, WORLD_WIDTH - width);

        long nowMs = System.currentTimeMillis();
        if (nowMs - lastWeatherChange > 30000L) chooseWeatherForZone(false);
        if (nowMs - lastSpawnMillis > 1200L && enemies.size() < MAX_ENEMIES) {
            spawnEnemy(false);
            lastSpawnMillis = nowMs;
        }

        updateEnemies(dt);
        updateParticles(dt);
        updatePickups(dt);

        if (nowMs - lastSaveMillis > 8000L) saveGame();
        if (!missionAnnounced) {
            missionAnnounced = true;
            speak("Mission. Bats dix ennemis dans " + ZONE_NAMES[currentZone] + ".");
        }
        if (missionKills >= 10 && !hasBossInZone()) {
            spawnEnemy(true);
            missionKills = -999;
            speak("Attention. Un capitaine ennemi approche.");
        }
        if (playerHp <= 0f) {
            screen = Screen.GAME_OVER;
            speak("L'équipage est à terre. Entraîne-toi et reviens plus fort.");
            saveGame();
        }
    }

    private void updateEnemies(float dt) {
        Iterator<Enemy> iterator = enemies.iterator();
        while (iterator.hasNext()) {
            Enemy e = iterator.next();
            e.hitFlash = Math.max(0f, e.hitFlash - dt * 4f);
            e.attackCooldown = Math.max(0f, e.attackCooldown - dt);
            float dx = playerX - e.x;
            float dy = playerY - e.y;
            float distance = (float) Math.sqrt(dx * dx + dy * dy);
            if (distance < 760f && distance > e.attackRange) {
                e.x += dx / Math.max(1f, distance) * e.speed * dt;
                e.y += dy / Math.max(1f, distance) * e.speed * 0.55f * dt;
            }
            if (distance <= e.attackRange && e.attackCooldown <= 0f && hurtCooldown <= 0f) {
                float damage = e.boss ? 15f : 6f + currentZone * 1.2f;
                if (auraTime > 0f) damage *= 0.55f;
                playerHp -= damage;
                hurtCooldown = 0.55f;
                e.attackCooldown = e.boss ? 1.05f : 1.45f;
                combo = 0;
                shake = e.boss ? 18f : 7f;
                flash = 0.35f;
                tones.startTone(ToneGenerator.TONE_PROP_NACK, 80);
                burst(playerX, playerY, Color.rgb(255, 90, 70), 10, 210f);
            }
            if (e.hp <= 0f) {
                iterator.remove();
                int earnedXp = e.boss ? 180 + currentZone * 40 : 18 + currentZone * 5;
                xp += earnedXp;
                coins += e.boss ? 120 : 8;
                aura = Math.min(100f, aura + (e.boss ? 35f : 12f));
                if (e.boss) {
                    totalBossesDefeated++;
                    missionKills = 0;
                    playerHp = Math.min(playerMaxHp, playerHp + 35f);
                    pickups.add(new Pickup(e.x, e.y, true));
                    speak("Capitaine vaincu. La région est libérée.");
                    if (totalBossesDefeated >= 5) screen = Screen.VICTORY;
                } else {
                    missionKills = Math.max(0, missionKills) + 1;
                    if (random.nextFloat() < 0.28f) pickups.add(new Pickup(e.x, e.y, false));
                }
                checkLevelUp();
                burst(e.x, e.y, e.color, e.boss ? 34 : 15, e.boss ? 390f : 240f);
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
            p.vy += 190f * dt;
            if (p.life <= 0f) iterator.remove();
        }
        int target = switch (weather) {
            case PLUIE, TEMPETE -> 90;
            case NEIGE -> 65;
            case CENDRES -> 55;
            default -> 18;
        };
        while (particles.size() < target) {
            Particle p = new Particle();
            p.x = cameraX + random.nextFloat() * width;
            p.y = random.nextFloat() * height * 0.8f;
            p.life = 1.2f + random.nextFloat() * 2f;
            if (weather == Weather.NEIGE) {
                p.color = Color.WHITE;
                p.vx = -25f + random.nextFloat() * 50f;
                p.vy = 35f + random.nextFloat() * 45f;
                p.size = 2f + random.nextFloat() * 5f;
            } else if (weather == Weather.CENDRES) {
                p.color = Color.rgb(90, 78, 72);
                p.vx = -30f + random.nextFloat() * 60f;
                p.vy = 18f + random.nextFloat() * 32f;
                p.size = 2f + random.nextFloat() * 4f;
            } else if (weather == Weather.PLUIE || weather == Weather.TEMPETE) {
                p.color = Color.argb(170, 190, 220, 255);
                p.vx = weather == Weather.TEMPETE ? -270f : -90f;
                p.vy = weather == Weather.TEMPETE ? 690f : 520f;
                p.size = 2f;
            } else {
                p.color = Color.argb(120, 255, 222, 130);
                p.vx = -12f + random.nextFloat() * 24f;
                p.vy = -16f - random.nextFloat() * 22f;
                p.size = 2f + random.nextFloat() * 3f;
            }
            particles.add(p);
        }
    }

    private void updatePickups(float dt) {
        Iterator<Pickup> it = pickups.iterator();
        while (it.hasNext()) {
            Pickup p = it.next();
            p.phase += dt * 3f;
            float dx = playerX - p.x;
            float dy = playerY - p.y;
            if (dx * dx + dy * dy < 85f * 85f) {
                if (p.legendary) {
                    trainingPoints += 3;
                    xp += 100;
                    speak("Trésor légendaire obtenu.");
                } else {
                    coins += 20;
                    playerHp = Math.min(playerMaxHp, playerHp + 10f);
                }
                tones.startTone(ToneGenerator.TONE_PROP_ACK, 100);
                it.remove();
                checkLevelUp();
            }
        }
    }

    private void attack(boolean skill) {
        if (screen != Screen.GAME) return;
        if (skill) {
            if (skillCooldown > 0f || energy < 30f) return;
            skillCooldown = selectedHero == 2 ? 3.4f : 4.2f;
            energy -= 30f;
        } else {
            if (attackCooldown > 0f) return;
            attackCooldown = selectedHero == 1 ? 0.22f : selectedHero == 2 ? 0.34f : 0.46f;
        }

        float radius = skill ? heroSkillRadius() : heroAttackRadius();
        float damage = skill ? heroSkillDamage() : heroAttackDamage();
        if (auraTime > 0f) damage *= 1.65f;
        int hits = 0;
        for (Enemy e : enemies) {
            float dx = e.x - playerX;
            float dy = e.y - playerY;
            float d = (float) Math.sqrt(dx * dx + dy * dy);
            if (d <= radius) {
                float applied = damage;
                if (selectedHero == 2 && skill) applied *= 1f + Math.min(0.6f, enemies.size() * 0.035f);
                e.hp -= applied;
                e.hitFlash = 0.28f;
                float push = skill ? 85f : 30f;
                e.x += dx / Math.max(1f, d) * push;
                e.y += dy / Math.max(1f, d) * push * 0.35f;
                hits++;
                burst(e.x, e.y, HERO_COLORS[selectedHero], skill ? 12 : 5, skill ? 260f : 150f);
            }
        }
        if (hits > 0) {
            combo += hits;
            bestCombo = Math.max(bestCombo, combo);
            comboTimer = 2.4f;
            aura = Math.min(100f, aura + hits * (skill ? 3.5f : 1.7f));
            tones.startTone(skill ? ToneGenerator.TONE_PROP_BEEP2 : ToneGenerator.TONE_PROP_BEEP, skill ? 90 : 45);
            shake = skill ? 10f : 3f;
        }
        if (skill) {
            burst(playerX, playerY, HERO_COLORS[selectedHero], 26, 340f);
        }
    }

    private void activateAura() {
        if (screen != Screen.GAME || aura < 100f || auraTime > 0f) return;
        aura = 0f;
        auraTime = 13f + level * 0.4f;
        flash = 1f;
        shake = 24f;
        String name = switch (selectedHero) {
            case 0 -> "Volonté du Premier Capitaine";
            case 1 -> "Éclair des Sept Vagues";
            default -> "Atelier Suprême Quinet";
        };
        speak(name + ". Déferlement d'énergie.");
        for (Enemy e : enemies) {
            float dx = e.x - playerX;
            float dy = e.y - playerY;
            float d = (float) Math.sqrt(dx * dx + dy * dy);
            if (d < 360f) {
                e.hp -= 34f + level * 5f;
                e.x += dx / Math.max(1f, d) * 150f;
                e.hitFlash = 0.5f;
            }
        }
        burst(playerX, playerY, HERO_COLORS[selectedHero], 70, 520f);
        tones.startTone(ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD, 250);
    }

    private void spawnEnemy(boolean boss) {
        Enemy e = new Enemy();
        e.boss = boss;
        float side = random.nextBoolean() ? -1f : 1f;
        e.x = clamp(playerX + side * (boss ? 520f : 430f + random.nextFloat() * 350f), 80f, WORLD_WIDTH - 80f);
        e.y = clamp(playerY - 45f + random.nextFloat() * 110f, groundY() - height * 0.2f, groundY() - 24f);
        e.type = boss ? 5 : random.nextInt(5);
        e.maxHp = boss ? 360f + currentZone * 110f : 62f + currentZone * 22f + level * 4f;
        e.hp = e.maxHp;
        e.speed = boss ? 82f + currentZone * 6f : 68f + e.type * 7f + currentZone * 4f;
        e.attackRange = boss ? 92f : e.type == 2 ? 190f : 66f;
        e.color = zoneEnemyColor(currentZone, e.type, boss);
        enemies.add(e);
    }

    private void checkLevelUp() {
        int newLevel = Progression.levelForXp(xp);
        if (newLevel > level) {
            level = newLevel;
            playerMaxHp = 100f + (level - 1) * 12f + trainingPoints * 3f;
            playerHp = playerMaxHp;
            flash = 1f;
            speak(HERO_NAMES[selectedHero] + " évolue au niveau " + level + ". Nouvelle puissance maîtrisée.");
            burst(playerX, playerY, Color.rgb(255, 218, 80), 65, 480f);
        }
    }

    private void chooseWeatherForZone(boolean forced) {
        Weather previous = weather;
        weather = switch (currentZone) {
            case 0 -> random.nextFloat() < 0.28f ? Weather.PLUIE : Weather.SOLEIL;
            case 1 -> random.nextFloat() < 0.75f ? Weather.NEIGE : Weather.SOLEIL;
            case 2 -> Weather.SOLEIL;
            case 3 -> random.nextFloat() < 0.72f ? Weather.CENDRES : Weather.SOLEIL;
            default -> random.nextFloat() < 0.72f ? Weather.TEMPETE : Weather.PLUIE;
        };
        lastWeatherChange = System.currentTimeMillis();
        if (forced || previous != weather) {
            String weatherName = weather.name().toLowerCase(Locale.FRANCE).replace('_', ' ');
            speak("La météo change. " + weatherName + ".");
        }
    }

    private void drawMenu(Canvas canvas) {
        paint.setColor(Color.BLACK);
        canvas.drawRect(0, 0, width, height, paint);
        if (splash != null) {
            Rect src = new Rect(0, 0, splash.getWidth(), splash.getHeight());
            RectF dst = coverRect(splash.getWidth(), splash.getHeight(), width, height);
            paint.setAlpha(215);
            canvas.drawBitmap(splash, src, dst, paint);
            paint.setAlpha(255);
        }
        paint.setShader(new LinearGradient(0, 0, 0, height, Color.argb(20, 0, 0, 0), Color.argb(235, 2, 9, 18), Shader.TileMode.CLAMP));
        canvas.drawRect(0, 0, width, height, paint);
        paint.setShader(null);

        text(canvas, "CHK", width * 0.08f, height * 0.2f, height * 0.13f, Color.rgb(244, 198, 73), true);
        text(canvas, "PIRATE WARRIOR", width * 0.08f, height * 0.31f, height * 0.075f, Color.WHITE, true);
        text(canvas, "L'ARCHIPEL DES QUINET", width * 0.083f, height * 0.38f, height * 0.033f, Color.rgb(174, 216, 244), false);

        float bx = width * 0.08f;
        float bw = Math.min(width * 0.33f, 420f);
        float bh = Math.max(54f, height * 0.105f);
        drawButton(canvas, new RectF(bx, height * 0.51f, bx + bw, height * 0.51f + bh), "CONTINUER", Color.rgb(196, 56, 49));
        drawButton(canvas, new RectF(bx, height * 0.64f, bx + bw, height * 0.64f + bh), "CHOISIR LE HÉROS", Color.rgb(31, 112, 161));
        drawButton(canvas, new RectF(bx, height * 0.77f, bx + bw, height * 0.77f + bh), "ENTRAÎNEMENT", Color.rgb(38, 132, 86));

        drawPill(canvas, width - 250f, 28f, 210f, 52f, voiceEnabled ? "VOIX FR : OUI" : "VOIX FR : NON", Color.argb(180, 0, 0, 0));
        text(canvas, "Niveau " + level + "  •  " + coins + " pièces", width - 280f, height - 34f, 23f, Color.WHITE, false);
    }

    private void drawHeroSelection(Canvas canvas) {
        drawOceanBackdrop(canvas, 0);
        text(canvas, "CHOISIS TON HÉROS", width / 2f, height * 0.12f, height * 0.065f, Color.WHITE, true, Paint.Align.CENTER);
        float gap = width * 0.025f;
        float cardW = (width - gap * 4f) / 3f;
        float top = height * 0.2f;
        float bottom = height * 0.84f;
        for (int i = 0; i < 3; i++) {
            float left = gap + i * (cardW + gap);
            RectF card = new RectF(left, top, left + cardW, bottom);
            paint.setColor(Color.argb(i == selectedHero ? 235 : 205, 7, 18, 34));
            canvas.drawRoundRect(card, 26f, 26f, paint);
            stroke.setColor(i == selectedHero ? Color.rgb(246, 204, 79) : Color.argb(120, 255, 255, 255));
            stroke.setStrokeWidth(i == selectedHero ? 6f : 2f);
            canvas.drawRoundRect(card, 26f, 26f, stroke);
            drawHero(canvas, i, card.centerX(), top + card.height() * 0.43f, cardW * 0.42f, 0f, false);
            text(canvas, HERO_NAMES[i], card.centerX(), bottom - 92f, 34f, HERO_COLORS[i], true, Paint.Align.CENTER);
            text(canvas, HERO_ROLES[i], card.centerX(), bottom - 55f, 20f, Color.WHITE, false, Paint.Align.CENTER);
            int heroXp = prefs.getInt("hero_xp_" + i, i == selectedHero ? xp : 0);
            text(canvas, "Puissance " + Progression.levelForXp(heroXp), card.centerX(), bottom - 24f, 18f, Color.rgb(190, 206, 220), false, Paint.Align.CENTER);
        }
        drawButton(canvas, new RectF(width * 0.35f, height * 0.88f, width * 0.65f, height * 0.98f), "JOUER AVEC " + HERO_NAMES[selectedHero], Color.rgb(189, 52, 48));
        drawPill(canvas, 24f, 24f, 130f, 48f, "RETOUR", Color.argb(210, 0, 0, 0));
    }

    private void drawGame(Canvas canvas) {
        canvas.save();
        if (shake > 0f) canvas.translate(-shake / 2f + random.nextFloat() * shake, -shake / 2f + random.nextFloat() * shake);
        drawWorld(canvas);
        drawPickups(canvas);
        for (Enemy e : enemies) drawEnemy(canvas, e);
        drawHero(canvas, selectedHero, playerX - cameraX, playerY, 38f + level * 0.5f, auraTime, true);
        drawWorldParticles(canvas);
        canvas.restore();

        drawHud(canvas);
        drawControls(canvas);
        if (mapVisible) drawMapOverlay(canvas);
        if (flash > 0f) {
            paint.setColor(Color.argb((int) (flash * 120f), 255, 255, 255));
            canvas.drawRect(0, 0, width, height, paint);
        }
    }

    private void drawWorld(Canvas canvas) {
        float dayLight = 0.35f + 0.65f * Math.max(0f, (float) Math.sin(dayClock * Math.PI));
        int skyTop;
        int skyBottom;
        switch (currentZone) {
            case 1 -> { skyTop = mix(Color.rgb(42, 88, 140), Color.rgb(160, 208, 245), dayLight); skyBottom = mix(Color.rgb(80, 120, 160), Color.rgb(220, 240, 252), dayLight); }
            case 2 -> { skyTop = mix(Color.rgb(72, 48, 78), Color.rgb(74, 174, 239), dayLight); skyBottom = mix(Color.rgb(143, 78, 60), Color.rgb(255, 205, 116), dayLight); }
            case 3 -> { skyTop = mix(Color.rgb(24, 19, 34), Color.rgb(88, 70, 88), dayLight); skyBottom = mix(Color.rgb(66, 27, 30), Color.rgb(220, 106, 52), dayLight); }
            case 4 -> { skyTop = Color.rgb(24, 42, 67); skyBottom = Color.rgb(72, 100, 126); }
            default -> { skyTop = mix(Color.rgb(15, 41, 84), Color.rgb(53, 170, 239), dayLight); skyBottom = mix(Color.rgb(45, 85, 120), Color.rgb(190, 235, 250), dayLight); }
        }
        paint.setShader(new LinearGradient(0, 0, 0, groundY(), skyTop, skyBottom, Shader.TileMode.CLAMP));
        canvas.drawRect(0, 0, width, groundY(), paint);
        paint.setShader(null);

        drawSunMoon(canvas);
        drawDistantScenery(canvas);
        drawGround(canvas);
        drawProps(canvas);
    }

    private void drawSunMoon(Canvas canvas) {
        float angle = dayClock * (float) Math.PI * 2f - (float) Math.PI;
        float cx = width * 0.5f + (float) Math.cos(angle) * width * 0.42f;
        float cy = height * 0.5f - (float) Math.sin(angle) * height * 0.42f;
        boolean sun = dayClock > 0.04f && dayClock < 0.52f;
        paint.setColor(sun ? Color.rgb(255, 231, 125) : Color.rgb(225, 234, 247));
        canvas.drawCircle(cx, cy, sun ? 34f : 24f, paint);
        paint.setColor(Color.argb(45, 255, 245, 190));
        canvas.drawCircle(cx, cy, sun ? 58f : 38f, paint);
    }

    private void drawDistantScenery(Canvas canvas) {
        float gy = groundY();
        paint.setColor(zoneMountainColor());
        path.reset();
        path.moveTo(0, gy);
        for (int x = -200; x <= width + 200; x += 230) {
            float world = cameraX + x;
            float peak = gy - 120f - 80f * pseudoNoise(world * 0.0031f + currentZone * 7f);
            path.lineTo(x + 100f, peak);
            path.lineTo(x + 230f, gy);
        }
        path.close();
        canvas.drawPath(path, paint);
        if (currentZone == 0) {
            paint.setColor(Color.rgb(28, 112, 92));
            for (int x = -100; x < width + 100; x += 180) {
                float px = x - (cameraX * 0.18f) % 180f;
                canvas.drawRect(px, gy - 115f, px + 10f, gy - 22f, paint);
                canvas.drawCircle(px + 5f, gy - 125f, 30f, paint);
            }
        }
    }

    private void drawGround(Canvas canvas) {
        int groundColor = switch (currentZone) {
            case 1 -> Color.rgb(226, 239, 247);
            case 2 -> Color.rgb(224, 171, 92);
            case 3 -> Color.rgb(78, 57, 52);
            case 4 -> Color.rgb(52, 73, 82);
            default -> Color.rgb(89, 158, 73);
        };
        paint.setColor(groundColor);
        canvas.drawRect(0, groundY(), width, height, paint);
        if (currentZone == 1) {
            paint.setColor(Color.argb(120, 255, 255, 255));
            for (int i = 0; i < 18; i++) {
                float x = ((i * 157f - cameraX * 0.6f) % (width + 160f)) - 80f;
                canvas.drawOval(new RectF(x, groundY() + 20f + (i % 4) * 35f, x + 90f, groundY() + 38f + (i % 4) * 35f), paint);
            }
        } else if (currentZone == 3) {
            paint.setColor(Color.rgb(235, 78, 35));
            for (int i = 0; i < 7; i++) {
                float x = ((i * 223f - cameraX * 0.9f) % (width + 240f)) - 120f;
                canvas.drawRoundRect(new RectF(x, groundY() + 75f + (i % 2) * 55f, x + 150f, groundY() + 92f + (i % 2) * 55f), 12f, 12f, paint);
            }
        }
    }

    private void drawProps(Canvas canvas) {
        for (int i = 0; i < 12; i++) {
            float wx = currentZone * 2000f + 120f + i * 165f;
            float sx = wx - cameraX;
            if (sx < -100f || sx > width + 100f) continue;
            float py = groundY() - 10f;
            if (currentZone == 0) drawPalm(canvas, sx, py, 0.78f + (i % 3) * 0.1f);
            else if (currentZone == 1) drawPine(canvas, sx, py, 0.75f + (i % 4) * 0.08f);
            else if (currentZone == 2) drawCactus(canvas, sx, py, 0.8f);
            else if (currentZone == 3) drawRock(canvas, sx, py, 0.9f);
            else drawMast(canvas, sx, py, 0.85f);
        }
        float altarX = currentZone * 2000f + 1000f - cameraX;
        if (altarX > -150f && altarX < width + 150f) {
            paint.setColor(Color.rgb(95, 74, 57));
            canvas.drawRoundRect(new RectF(altarX - 70f, groundY() - 58f, altarX + 70f, groundY()), 10f, 10f, paint);
            paint.setColor(HERO_COLORS[selectedHero]);
            canvas.drawCircle(altarX, groundY() - 70f, 18f + (float) Math.sin(System.currentTimeMillis() * 0.004) * 4f, paint);
            text(canvas, "AUTEL D'ENTRAÎNEMENT", altarX, groundY() - 102f, 15f, Color.WHITE, true, Paint.Align.CENTER);
        }
    }

    private void drawHud(Canvas canvas) {
        drawBar(canvas, 24f, 22f, Math.min(350f, width * 0.3f), 24f, playerHp / playerMaxHp, Color.rgb(212, 61, 56), "VIE");
        drawBar(canvas, 24f, 54f, Math.min(350f, width * 0.3f), 16f, energy / 100f, Color.rgb(52, 153, 222), "ÉNERGIE");
        drawBar(canvas, 24f, 78f, Math.min(350f, width * 0.3f), 16f, aura / 100f, HERO_COLORS[selectedHero], "DÉFERLEMENT");
        text(canvas, HERO_NAMES[selectedHero] + "  NIVEAU " + level, 24f, 122f, 24f, Color.WHITE, true);
        text(canvas, "Zone : " + ZONE_NAMES[currentZone], width / 2f, 34f, 21f, Color.WHITE, true, Paint.Align.CENTER);
        text(canvas, "Mission : " + (missionKills < 0 ? "Capitaine ennemi" : Math.max(0, missionKills) + "/10 ennemis"), width / 2f, 60f, 18f, Color.rgb(236, 217, 152), false, Paint.Align.CENTER);
        text(canvas, weatherLabel() + "  •  " + timeLabel(), width / 2f, 84f, 16f, Color.rgb(190, 213, 232), false, Paint.Align.CENTER);
        if (combo > 1) {
            text(canvas, combo + " COUPS", width * 0.72f, height * 0.22f, 38f + Math.min(20f, combo), Color.rgb(255, 216, 74), true, Paint.Align.CENTER);
        }
        drawPill(canvas, width - 180f, 18f, 70f, 48f, "CARTE", Color.argb(185, 0, 0, 0));
        drawPill(canvas, width - 94f, 18f, 70f, 48f, "PAUSE", Color.argb(185, 0, 0, 0));
        text(canvas, coins + " pièces", width - 24f, 92f, 18f, Color.WHITE, true, Paint.Align.RIGHT);
    }

    private void drawControls(Canvas canvas) {
        paint.setStyle(Paint.Style.FILL);
        paint.setColor(Color.argb(70, 255, 255, 255));
        canvas.drawCircle(joystickBaseX, joystickBaseY, 88f, paint);
        stroke.setColor(Color.argb(130, 255, 255, 255));
        stroke.setStrokeWidth(3f);
        canvas.drawCircle(joystickBaseX, joystickBaseY, 88f, stroke);
        paint.setColor(Color.argb(155, 23, 35, 50));
        canvas.drawCircle(joystickBaseX + joystickX * 60f, joystickBaseY + joystickY * 60f, 38f, paint);

        float attackX = width - 95f;
        float attackY = height - 95f;
        drawRoundAction(canvas, attackX, attackY, 58f, Color.rgb(201, 55, 49), "ATTAQUE");
        drawRoundAction(canvas, width - 220f, height - 150f, 49f, Color.rgb(41, 130, 190), skillCooldown > 0f ? String.format(Locale.FRANCE, "%.1f", skillCooldown) : "POUVOIR");
        drawRoundAction(canvas, width - 115f, height - 250f, 49f, aura >= 100f ? HERO_COLORS[selectedHero] : Color.rgb(88, 88, 96), auraTime > 0f ? "AURA" : "DÉFERLER");
    }

    private void drawEnemy(Canvas canvas, Enemy e) {
        float sx = e.x - cameraX;
        if (sx < -120f || sx > width + 120f) return;
        float size = e.boss ? 58f : 34f + e.type * 2f;
        paint.setColor(Color.argb(80, 0, 0, 0));
        canvas.drawOval(new RectF(sx - size, e.y + size * 0.65f, sx + size, e.y + size), paint);
        paint.setColor(e.hitFlash > 0f ? Color.WHITE : e.color);
        canvas.drawRoundRect(new RectF(sx - size * 0.62f, e.y - size * 0.95f, sx + size * 0.62f, e.y + size * 0.65f), size * 0.28f, size * 0.28f, paint);
        paint.setColor(Color.rgb(56, 41, 34));
        canvas.drawCircle(sx, e.y - size * 1.05f, size * 0.45f, paint);
        paint.setColor(Color.WHITE);
        canvas.drawCircle(sx - size * 0.14f, e.y - size * 1.08f, 3f, paint);
        canvas.drawCircle(sx + size * 0.14f, e.y - size * 1.08f, 3f, paint);
        paint.setColor(Color.BLACK);
        canvas.drawCircle(sx - size * 0.14f, e.y - size * 1.08f, 1.5f, paint);
        canvas.drawCircle(sx + size * 0.14f, e.y - size * 1.08f, 1.5f, paint);
        if (e.boss) {
            paint.setColor(Color.argb(80, 255, 60, 50));
            canvas.drawCircle(sx, e.y, size * 1.35f + (float) Math.sin(System.currentTimeMillis() * 0.01) * 6f, paint);
            text(canvas, "CAPITAINE " + (currentZone + 1), sx, e.y - size * 1.85f, 18f, Color.WHITE, true, Paint.Align.CENTER);
        }
        drawBar(canvas, sx - size, e.y - size * 1.65f, size * 2f, 8f, e.hp / e.maxHp, e.boss ? Color.rgb(235, 72, 51) : Color.rgb(222, 114, 61), "");
    }

    private void drawHero(Canvas canvas, int hero, float x, float y, float size, float auraSeconds, boolean movingWorld) {
        if (auraSeconds > 0f) {
            float pulse = 1f + (float) Math.sin(System.currentTimeMillis() * 0.012) * 0.08f;
            paint.setColor(Color.argb(58, Color.red(HERO_COLORS[hero]), Color.green(HERO_COLORS[hero]), Color.blue(HERO_COLORS[hero])));
            canvas.drawCircle(x, y - size * 0.4f, size * 2.1f * pulse, paint);
            stroke.setColor(Color.argb(210, Color.red(HERO_COLORS[hero]), Color.green(HERO_COLORS[hero]), Color.blue(HERO_COLORS[hero])));
            stroke.setStrokeWidth(5f);
            canvas.drawCircle(x, y - size * 0.4f, size * 1.55f * pulse, stroke);
            for (int i = 0; i < 7; i++) {
                double a = System.currentTimeMillis() * 0.004 + i * Math.PI * 2 / 7;
                float ax = x + (float) Math.cos(a) * size * 1.55f;
                float ay = y - size * 0.45f + (float) Math.sin(a) * size * 1.2f;
                paint.setColor(HERO_COLORS[hero]);
                canvas.drawCircle(ax, ay, 4f + i % 3, paint);
            }
        }
        paint.setColor(Color.argb(80, 0, 0, 0));
        canvas.drawOval(new RectF(x - size * 0.8f, y + size * 0.55f, x + size * 0.8f, y + size * 0.88f), paint);

        int skin = hero == 0 ? Color.rgb(113, 71, 48) : Color.rgb(126, 82, 54);
        paint.setColor(HERO_COLORS[hero]);
        canvas.drawRoundRect(new RectF(x - size * 0.52f, y - size * 0.72f, x + size * 0.52f, y + size * 0.45f), size * 0.22f, size * 0.22f, paint);
        paint.setColor(Color.rgb(45, 53, 61));
        canvas.drawRect(x - size * 0.42f, y + size * 0.35f, x - size * 0.08f, y + size * 1.05f, paint);
        canvas.drawRect(x + size * 0.08f, y + size * 0.35f, x + size * 0.42f, y + size * 1.05f, paint);
        paint.setColor(skin);
        canvas.drawCircle(x, y - size * 1.03f, size * 0.42f, paint);
        if (hero == 0) {
            paint.setColor(Color.rgb(37, 29, 26));
            canvas.drawArc(new RectF(x - size * 0.38f, y - size * 1.05f, x + size * 0.38f, y - size * 0.55f), 0, 180, true, paint);
            stroke.setColor(Color.rgb(31, 24, 22));
            stroke.setStrokeWidth(size * 0.1f);
            canvas.drawArc(new RectF(x - size * 0.34f, y - size * 1.08f, x + size * 0.34f, y - size * 0.6f), 10, 160, false, stroke);
        } else if (hero == 1) {
            paint.setColor(Color.rgb(28, 25, 24));
            for (int i = 0; i < 7; i++) {
                float hx = x - size * 0.32f + i * size * 0.105f;
                canvas.drawOval(new RectF(hx - size * 0.12f, y - size * 1.62f + Math.abs(3 - i) * 2f, hx + size * 0.12f, y - size * 1.03f), paint);
            }
        } else {
            paint.setColor(Color.rgb(37, 29, 25));
            canvas.drawArc(new RectF(x - size * 0.43f, y - size * 1.43f, x + size * 0.43f, y - size * 0.85f), 180, 180, true, paint);
        }
        paint.setColor(Color.WHITE);
        canvas.drawCircle(x - size * 0.14f, y - size * 1.07f, size * 0.05f, paint);
        canvas.drawCircle(x + size * 0.14f, y - size * 1.07f, size * 0.05f, paint);
        paint.setColor(Color.BLACK);
        canvas.drawCircle(x - size * 0.14f, y - size * 1.07f, size * 0.024f, paint);
        canvas.drawCircle(x + size * 0.14f, y - size * 1.07f, size * 0.024f, paint);
        if (movingWorld) {
            text(canvas, HERO_NAMES[hero], x, y + size * 1.45f, Math.max(14f, size * 0.35f), Color.WHITE, true, Paint.Align.CENTER);
        }
    }

    private void drawWorldParticles(Canvas canvas) {
        for (Particle p : particles) {
            float sx = p.x - cameraX;
            paint.setColor(p.color);
            if (weather == Weather.PLUIE || weather == Weather.TEMPETE) {
                canvas.drawLine(sx, p.y, sx + p.vx * 0.035f, p.y + p.vy * 0.035f, paint);
            } else {
                canvas.drawCircle(sx, p.y, p.size, paint);
            }
        }
    }

    private void drawPickups(Canvas canvas) {
        for (Pickup p : pickups) {
            float sx = p.x - cameraX;
            float sy = p.y - 20f + (float) Math.sin(p.phase) * 8f;
            paint.setColor(p.legendary ? Color.rgb(255, 210, 63) : Color.rgb(84, 224, 151));
            path.reset();
            path.moveTo(sx, sy - 14f);
            path.lineTo(sx + 13f, sy);
            path.lineTo(sx, sy + 14f);
            path.lineTo(sx - 13f, sy);
            path.close();
            canvas.drawPath(path, paint);
        }
    }

    private void drawTraining(Canvas canvas) {
        drawOceanBackdrop(canvas, selectedHero);
        paint.setColor(Color.argb(220, 3, 12, 23));
        canvas.drawRect(0, 0, width, height, paint);
        text(canvas, "SALLE D'ENTRAÎNEMENT", width / 2f, height * 0.12f, height * 0.065f, Color.rgb(246, 207, 85), true, Paint.Align.CENTER);
        drawHero(canvas, selectedHero, width * 0.22f, height * 0.59f, Math.min(75f, height * 0.12f), 5f, false);
        text(canvas, HERO_NAMES[selectedHero], width * 0.22f, height * 0.83f, 32f, HERO_COLORS[selectedHero], true, Paint.Align.CENTER);
        text(canvas, "Niveau " + level + "  •  Points : " + trainingPoints, width * 0.22f, height * 0.9f, 20f, Color.WHITE, false, Paint.Align.CENTER);

        float x = width * 0.43f;
        float bw = width * 0.45f;
        float bh = height * 0.13f;
        drawButton(canvas, new RectF(x, height * 0.22f, x + bw, height * 0.22f + bh), "FORCE  •  + dégâts et vie", Color.rgb(157, 61, 48));
        drawButton(canvas, new RectF(x, height * 0.4f, x + bw, height * 0.4f + bh), "VITESSE  •  + mobilité", Color.rgb(42, 121, 179));
        drawButton(canvas, new RectF(x, height * 0.58f, x + bw, height * 0.58f + bh), "ÉNERGIE  •  + aura", Color.rgb(47, 143, 93));
        drawButton(canvas, new RectF(x, height * 0.76f, x + bw, height * 0.76f + bh), "CHANGER DE HÉROS", Color.rgb(104, 85, 149));
        drawPill(canvas, 24f, 24f, 130f, 48f, "RETOUR", Color.argb(210, 0, 0, 0));
    }

    private void doTraining(int type) {
        int cost = 45 + trainingPoints * 10;
        if (coins < cost) {
            speak("Il faut " + cost + " pièces pour cet entraînement.");
            return;
        }
        coins -= cost;
        trainingPoints++;
        xp += 35 + trainingPoints * 4;
        playerMaxHp = 100f + (level - 1) * 12f + trainingPoints * 3f;
        playerHp = playerMaxHp;
        String label = switch (type) {
            case 0 -> "Entraînement de force terminé";
            case 1 -> "Entraînement de vitesse terminé";
            default -> "Maîtrise de l'énergie améliorée";
        };
        speak(label + ".");
        tones.startTone(ToneGenerator.TONE_PROP_ACK, 160);
        checkLevelUp();
        saveGame();
    }

    private void drawPauseOverlay(Canvas canvas) {
        paint.setColor(Color.argb(210, 0, 0, 0));
        canvas.drawRect(0, 0, width, height, paint);
        text(canvas, "PAUSE", width / 2f, height * 0.27f, height * 0.1f, Color.WHITE, true, Paint.Align.CENTER);
        drawButton(canvas, new RectF(width * 0.34f, height * 0.39f, width * 0.66f, height * 0.51f), "REPRENDRE", Color.rgb(41, 133, 88));
        drawButton(canvas, new RectF(width * 0.34f, height * 0.56f, width * 0.66f, height * 0.68f), "QUITTER VERS LE MENU", Color.rgb(173, 58, 49));
    }

    private void drawMapOverlay(Canvas canvas) {
        paint.setColor(Color.argb(228, 3, 10, 20));
        canvas.drawRoundRect(new RectF(width * 0.08f, height * 0.12f, width * 0.92f, height * 0.84f), 30f, 30f, paint);
        text(canvas, "CARTE DU MONDE OUVERT", width / 2f, height * 0.2f, 30f, Color.WHITE, true, Paint.Align.CENTER);
        float left = width * 0.14f;
        float right = width * 0.86f;
        float y = height * 0.47f;
        stroke.setColor(Color.rgb(102, 160, 198));
        stroke.setStrokeWidth(7f);
        canvas.drawLine(left, y, right, y, stroke);
        for (int i = 0; i < 5; i++) {
            float x = left + (right - left) * i / 4f;
            paint.setColor(i == currentZone ? Color.rgb(248, 205, 70) : zoneEnemyColor(i, 0, false));
            canvas.drawCircle(x, y, i == currentZone ? 28f : 20f, paint);
            text(canvas, (i + 1) + "", x, y + 7f, 18f, Color.BLACK, true, Paint.Align.CENTER);
            text(canvas, ZONE_NAMES[i], x, y + 68f, 16f, Color.WHITE, false, Paint.Align.CENTER);
            text(canvas, "ALLER", x, y - 55f, 15f, Color.rgb(193, 218, 237), true, Paint.Align.CENTER);
        }
        text(canvas, "Touchez une île pour voyager", width / 2f, height * 0.76f, 20f, Color.rgb(210, 220, 232), false, Paint.Align.CENTER);
    }

    private void drawEndScreen(Canvas canvas, boolean victory) {
        drawOceanBackdrop(canvas, selectedHero);
        paint.setColor(Color.argb(205, 0, 0, 0));
        canvas.drawRect(0, 0, width, height, paint);
        text(canvas, victory ? "LÉGENDES DES MERS" : "ÉQUIPAGE À TERRE", width / 2f, height * 0.26f, height * 0.085f, victory ? Color.rgb(250, 209, 70) : Color.rgb(241, 93, 75), true, Paint.Align.CENTER);
        text(canvas, victory ? "Les cinq régions sont libérées." : "Reprends des forces et retourne au combat.", width / 2f, height * 0.38f, 24f, Color.WHITE, false, Paint.Align.CENTER);
        text(canvas, "Meilleur combo : " + bestCombo + "  •  Pièces : " + coins, width / 2f, height * 0.47f, 22f, Color.rgb(203, 219, 232), false, Paint.Align.CENTER);
        drawButton(canvas, new RectF(width * 0.34f, height * 0.57f, width * 0.66f, height * 0.69f), victory ? "CONTINUER L'EXPLORATION" : "RECOMMENCER", Color.rgb(42, 137, 89));
        drawButton(canvas, new RectF(width * 0.34f, height * 0.74f, width * 0.66f, height * 0.86f), "MENU PRINCIPAL", Color.rgb(53, 91, 137));
    }

    private void drawOceanBackdrop(Canvas canvas, int theme) {
        paint.setShader(new LinearGradient(0, 0, 0, height, Color.rgb(22, 110, 173), Color.rgb(4, 31, 61), Shader.TileMode.CLAMP));
        canvas.drawRect(0, 0, width, height, paint);
        paint.setShader(null);
        for (int i = 0; i < 16; i++) {
            float y = height * 0.55f + i * 17f;
            paint.setColor(Color.argb(40, 255, 255, 255));
            canvas.drawOval(new RectF((i * 97f) % width - 80f, y, (i * 97f) % width + 180f, y + 8f), paint);
        }
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        int action = event.getActionMasked();
        int index = event.getActionIndex();
        int pointerId = event.getPointerId(index);
        float x = event.getX(index);
        float y = event.getY(index);

        if (action == MotionEvent.ACTION_DOWN || action == MotionEvent.ACTION_POINTER_DOWN) {
            handleDown(pointerId, x, y);
        } else if (action == MotionEvent.ACTION_MOVE) {
            for (int i = 0; i < event.getPointerCount(); i++) {
                int id = event.getPointerId(i);
                if (id == joystickPointer) updateJoystick(event.getX(i), event.getY(i));
            }
        } else if (action == MotionEvent.ACTION_UP || action == MotionEvent.ACTION_POINTER_UP || action == MotionEvent.ACTION_CANCEL) {
            if (pointerId == joystickPointer) {
                joystickPointer = -1;
                joystickX = 0f;
                joystickY = 0f;
            }
            if (pointerId == activeButtonPointer) activeButtonPointer = -1;
            if (pointerId == attackPointer) attackPointer = -1;
        }
        return true;
    }

    private void handleDown(int pointerId, float x, float y) {
        switch (screen) {
            case MENU -> handleMenuDown(x, y);
            case HEROES -> handleHeroesDown(x, y);
            case GAME -> handleGameDown(pointerId, x, y);
            case PAUSE -> handlePauseDown(x, y);
            case TRAINING -> handleTrainingDown(x, y);
            case GAME_OVER, VICTORY -> handleEndDown(x, y);
        }
    }

    private void handleMenuDown(float x, float y) {
        float bx = width * 0.08f;
        float bw = Math.min(width * 0.33f, 420f);
        float bh = Math.max(54f, height * 0.105f);
        if (inside(x, y, bx, height * 0.51f, bw, bh)) startGame(false);
        else if (inside(x, y, bx, height * 0.64f, bw, bh)) screen = Screen.HEROES;
        else if (inside(x, y, bx, height * 0.77f, bw, bh)) screen = Screen.TRAINING;
        else if (inside(x, y, width - 250f, 28f, 210f, 52f)) {
            voiceEnabled = !voiceEnabled;
            prefs.edit().putBoolean("voice", voiceEnabled).apply();
            if (voiceEnabled) speak("Voix française activée.");
        }
    }

    private void handleHeroesDown(float x, float y) {
        if (inside(x, y, 24f, 24f, 130f, 48f)) {
            screen = Screen.MENU;
            return;
        }
        float gap = width * 0.025f;
        float cardW = (width - gap * 4f) / 3f;
        for (int i = 0; i < 3; i++) {
            float left = gap + i * (cardW + gap);
            if (x >= left && x <= left + cardW && y >= height * 0.2f && y <= height * 0.84f) {
                saveCurrentHeroProgress();
                selectedHero = i;
                loadHeroProgress();
                speak(HERO_NAMES[i] + ". " + HERO_ROLES[i] + ".");
            }
        }
        if (inside(x, y, width * 0.35f, height * 0.88f, width * 0.3f, height * 0.1f)) startGame(false);
    }

    private void handleGameDown(int pointerId, float x, float y) {
        if (mapVisible) {
            if (y > height * 0.28f && y < height * 0.68f) {
                float left = width * 0.14f;
                float right = width * 0.86f;
                for (int i = 0; i < 5; i++) {
                    float ix = left + (right - left) * i / 4f;
                    if (Math.abs(x - ix) < 60f) {
                        playerX = i * 2000f + 520f;
                        currentZone = i;
                        enemies.clear();
                        pickups.clear();
                        mapVisible = false;
                        chooseWeatherForZone(true);
                        speak("Cap sur " + ZONE_NAMES[i] + ".");
                        return;
                    }
                }
            }
            mapVisible = false;
            return;
        }
        if (inside(x, y, width - 180f, 18f, 70f, 48f)) {
            mapVisible = true;
            return;
        }
        if (inside(x, y, width - 94f, 18f, 70f, 48f)) {
            screen = Screen.PAUSE;
            saveGame();
            return;
        }
        if (distance(x, y, joystickBaseX, joystickBaseY) < 110f && joystickPointer < 0) {
            joystickPointer = pointerId;
            updateJoystick(x, y);
            return;
        }
        if (distance(x, y, width - 95f, height - 95f) < 74f) {
            attackPointer = pointerId;
            attack(false);
            return;
        }
        if (distance(x, y, width - 220f, height - 150f) < 68f) {
            activeButtonPointer = pointerId;
            attack(true);
            return;
        }
        if (distance(x, y, width - 115f, height - 250f) < 68f) {
            activeButtonPointer = pointerId;
            activateAura();
        }
    }

    private void handlePauseDown(float x, float y) {
        if (inside(x, y, width * 0.34f, height * 0.39f, width * 0.32f, height * 0.12f)) screen = Screen.GAME;
        else if (inside(x, y, width * 0.34f, height * 0.56f, width * 0.32f, height * 0.12f)) {
            saveGame();
            screen = Screen.MENU;
        }
    }

    private void handleTrainingDown(float x, float y) {
        if (inside(x, y, 24f, 24f, 130f, 48f)) {
            screen = Screen.MENU;
            return;
        }
        float bx = width * 0.43f;
        float bw = width * 0.45f;
        float bh = height * 0.13f;
        if (inside(x, y, bx, height * 0.22f, bw, bh)) doTraining(0);
        else if (inside(x, y, bx, height * 0.4f, bw, bh)) doTraining(1);
        else if (inside(x, y, bx, height * 0.58f, bw, bh)) doTraining(2);
        else if (inside(x, y, bx, height * 0.76f, bw, bh)) screen = Screen.HEROES;
    }

    private void handleEndDown(float x, float y) {
        if (inside(x, y, width * 0.34f, height * 0.57f, width * 0.32f, height * 0.12f)) {
            playerHp = playerMaxHp;
            aura = 50f;
            enemies.clear();
            missionKills = 0;
            screen = Screen.GAME;
        } else if (inside(x, y, width * 0.34f, height * 0.74f, width * 0.32f, height * 0.12f)) {
            screen = Screen.MENU;
        }
    }

    private void startGame(boolean reset) {
        if (reset) {
            playerX = 560f;
            currentZone = 0;
            missionKills = 0;
            totalBossesDefeated = 0;
        }
        playerHp = Math.max(1f, playerHp);
        playerY = groundY() - 36f;
        enemies.clear();
        pickups.clear();
        screen = Screen.GAME;
        chooseWeatherForZone(true);
        for (int i = 0; i < 5; i++) spawnEnemy(false);
        speak(HERO_NAMES[selectedHero] + " entre dans " + ZONE_NAMES[currentZone] + ".");
    }

    private void updateJoystick(float x, float y) {
        float dx = x - joystickBaseX;
        float dy = y - joystickBaseY;
        float d = (float) Math.sqrt(dx * dx + dy * dy);
        if (d > 70f) {
            dx = dx / d * 70f;
            dy = dy / d * 70f;
        }
        joystickX = dx / 70f;
        joystickY = dy / 70f;
    }

    private void saveCurrentHeroProgress() {
        prefs.edit()
                .putInt("hero_xp_" + selectedHero, xp)
                .putInt("hero_training_" + selectedHero, trainingPoints)
                .putInt("hero_level_" + selectedHero, level)
                .apply();
    }

    private void loadHeroProgress() {
        xp = prefs.getInt("hero_xp_" + selectedHero, 0);
        trainingPoints = prefs.getInt("hero_training_" + selectedHero, 0);
        level = Progression.levelForXp(xp);
        playerMaxHp = 100f + (level - 1) * 12f + trainingPoints * 3f;
        playerHp = playerMaxHp;
        energy = 100f;
        aura = 0f;
    }

    private void saveGame() {
        saveCurrentHeroProgress();
        prefs.edit()
                .putInt("selectedHero", selectedHero)
                .putInt("coins", coins)
                .putInt("bestCombo", bestCombo)
                .putInt("bosses", totalBossesDefeated)
                .putFloat("playerX", playerX)
                .putFloat("playerHp", playerHp)
                .putBoolean("voice", voiceEnabled)
                .apply();
        lastSaveMillis = System.currentTimeMillis();
    }

    private void loadSave() {
        selectedHero = clampInt(prefs.getInt("selectedHero", 0), 0, 2);
        coins = prefs.getInt("coins", 100);
        bestCombo = prefs.getInt("bestCombo", 0);
        totalBossesDefeated = prefs.getInt("bosses", 0);
        playerX = clamp(prefs.getFloat("playerX", 560f), 60f, WORLD_WIDTH - 60f);
        voiceEnabled = prefs.getBoolean("voice", true);
        currentZone = Math.min(4, (int) (playerX / 2000f));
        loadHeroProgress();
        playerHp = clamp(prefs.getFloat("playerHp", playerMaxHp), 1f, playerMaxHp);
        chooseWeatherForZone(false);
    }

    private void speak(String text) {
        if (voiceEnabled && narrator != null) narrator.speak(text);
    }

    private float heroSpeed() {
        float base = selectedHero == 1 ? 280f : selectedHero == 2 ? 235f : 205f;
        return base + level * 4f + trainingPoints * 2f;
    }

    private float heroAttackDamage() {
        float base = selectedHero == 0 ? 24f : selectedHero == 1 ? 15f : 18f;
        return base + level * 3.3f + trainingPoints * 1.5f;
    }

    private float heroSkillDamage() {
        float base = selectedHero == 0 ? 62f : selectedHero == 1 ? 48f : 55f;
        return base + level * 5.5f + trainingPoints * 2.2f;
    }

    private float heroAttackRadius() {
        return selectedHero == 1 ? 120f : selectedHero == 2 ? 145f : 155f;
    }

    private float heroSkillRadius() {
        return selectedHero == 0 ? 255f : selectedHero == 1 ? 290f : 320f;
    }

    private float groundY() {
        return height <= 0 ? 500f : height * 0.72f;
    }

    private boolean hasBossInZone() {
        for (Enemy e : enemies) if (e.boss) return true;
        return false;
    }

    private int zoneEnemyColor(int zone, int type, boolean boss) {
        if (boss) return switch (zone) {
            case 1 -> Color.rgb(95, 150, 210);
            case 2 -> Color.rgb(215, 122, 42);
            case 3 -> Color.rgb(180, 47, 37);
            case 4 -> Color.rgb(84, 82, 128);
            default -> Color.rgb(157, 55, 52);
        };
        int[][] palette = {
                {0xFF724C36, 0xFF9D5B3C, 0xFF586F7C, 0xFF764A73, 0xFF486D54},
                {0xFF5C83A5, 0xFF7DA1BD, 0xFF476D8C, 0xFF9097B7, 0xFF527D76},
                {0xFF9B6238, 0xFFB57A3D, 0xFF7B5848, 0xFFB04D3B, 0xFF86713C},
                {0xFF5B4540, 0xFF803E35, 0xFF634C58, 0xFF8C352F, 0xFF4A4B50},
                {0xFF3F586A, 0xFF5E607B, 0xFF45556B, 0xFF6A4C68, 0xFF3D6B68}
        };
        return palette[zone][type % 5];
    }

    private int zoneMountainColor() {
        return switch (currentZone) {
            case 1 -> Color.rgb(149, 181, 205);
            case 2 -> Color.rgb(165, 112, 74);
            case 3 -> Color.rgb(61, 45, 50);
            case 4 -> Color.rgb(42, 61, 73);
            default -> Color.rgb(51, 108, 91);
        };
    }

    private String weatherLabel() {
        return switch (weather) {
            case SOLEIL -> "Soleil";
            case PLUIE -> "Pluie";
            case NEIGE -> "Neige";
            case TEMPETE -> "Tempête";
            case CENDRES -> "Cendres volcaniques";
        };
    }

    private String timeLabel() {
        if (dayClock < 0.08f || dayClock > 0.82f) return "Nuit";
        if (dayClock < 0.22f) return "Matin";
        if (dayClock < 0.56f) return "Journée";
        return "Soir";
    }

    private void burst(float x, float y, int color, int count, float power) {
        for (int i = 0; i < count && particles.size() < 180; i++) {
            double a = random.nextDouble() * Math.PI * 2;
            float speed = power * (0.25f + random.nextFloat() * 0.75f);
            Particle p = new Particle();
            p.x = x;
            p.y = y;
            p.vx = (float) Math.cos(a) * speed;
            p.vy = (float) Math.sin(a) * speed - 70f;
            p.life = 0.3f + random.nextFloat() * 0.6f;
            p.color = color;
            p.size = 2f + random.nextFloat() * 6f;
            particles.add(p);
        }
    }

    private void drawPalm(Canvas c, float x, float y, float scale) {
        paint.setColor(Color.rgb(102, 66, 38));
        c.drawRect(x - 5f * scale, y - 88f * scale, x + 5f * scale, y, paint);
        paint.setColor(Color.rgb(38, 126, 71));
        for (int i = 0; i < 6; i++) {
            double a = i * Math.PI / 3;
            float ex = x + (float) Math.cos(a) * 42f * scale;
            float ey = y - 90f * scale + (float) Math.sin(a) * 18f * scale;
            c.drawOval(new RectF(Math.min(x, ex) - 9f, Math.min(y - 90f * scale, ey) - 8f, Math.max(x, ex) + 9f, Math.max(y - 90f * scale, ey) + 8f), paint);
        }
    }

    private void drawPine(Canvas c, float x, float y, float scale) {
        paint.setColor(Color.rgb(93, 66, 49));
        c.drawRect(x - 5f, y - 80f * scale, x + 5f, y, paint);
        paint.setColor(Color.rgb(39, 91, 83));
        for (int i = 0; i < 3; i++) {
            float top = y - (125f - i * 35f) * scale;
            path.reset();
            path.moveTo(x, top);
            path.lineTo(x - (42f + i * 7f) * scale, top + 62f * scale);
            path.lineTo(x + (42f + i * 7f) * scale, top + 62f * scale);
            path.close();
            c.drawPath(path, paint);
        }
    }

    private void drawCactus(Canvas c, float x, float y, float scale) {
        paint.setColor(Color.rgb(61, 125, 74));
        c.drawRoundRect(new RectF(x - 9f, y - 92f * scale, x + 9f, y), 8f, 8f, paint);
        c.drawRoundRect(new RectF(x - 34f, y - 64f * scale, x - 8f, y - 48f * scale), 8f, 8f, paint);
        c.drawRoundRect(new RectF(x + 8f, y - 47f * scale, x + 34f, y - 31f * scale), 8f, 8f, paint);
    }

    private void drawRock(Canvas c, float x, float y, float scale) {
        paint.setColor(Color.rgb(61, 54, 55));
        path.reset();
        path.moveTo(x - 45f * scale, y);
        path.lineTo(x - 26f * scale, y - 60f * scale);
        path.lineTo(x + 10f * scale, y - 78f * scale);
        path.lineTo(x + 48f * scale, y - 22f * scale);
        path.lineTo(x + 55f * scale, y);
        path.close();
        c.drawPath(path, paint);
    }

    private void drawMast(Canvas c, float x, float y, float scale) {
        paint.setColor(Color.rgb(93, 65, 47));
        c.drawRect(x - 6f, y - 120f * scale, x + 6f, y, paint);
        paint.setColor(Color.rgb(55, 57, 70));
        path.reset();
        path.moveTo(x + 7f, y - 112f * scale);
        path.lineTo(x + 62f * scale, y - 88f * scale);
        path.lineTo(x + 7f, y - 62f * scale);
        path.close();
        c.drawPath(path, paint);
    }

    private void drawButton(Canvas canvas, RectF r, String label, int color) {
        paint.setColor(Color.argb(225, Color.red(color), Color.green(color), Color.blue(color)));
        canvas.drawRoundRect(r, 18f, 18f, paint);
        stroke.setColor(Color.argb(170, 255, 255, 255));
        stroke.setStrokeWidth(2f);
        canvas.drawRoundRect(r, 18f, 18f, stroke);
        text(canvas, label, r.centerX(), r.centerY() + 8f, Math.min(25f, r.height() * 0.37f), Color.WHITE, true, Paint.Align.CENTER);
    }

    private void drawPill(Canvas canvas, float x, float y, float w, float h, String label, int color) {
        paint.setColor(color);
        canvas.drawRoundRect(new RectF(x, y, x + w, y + h), h / 2f, h / 2f, paint);
        text(canvas, label, x + w / 2f, y + h / 2f + 6f, Math.min(17f, h * 0.36f), Color.WHITE, true, Paint.Align.CENTER);
    }

    private void drawRoundAction(Canvas canvas, float x, float y, float radius, int color, String label) {
        paint.setColor(Color.argb(220, Color.red(color), Color.green(color), Color.blue(color)));
        canvas.drawCircle(x, y, radius, paint);
        stroke.setColor(Color.argb(190, 255, 255, 255));
        stroke.setStrokeWidth(3f);
        canvas.drawCircle(x, y, radius, stroke);
        text(canvas, label, x, y + 5f, Math.min(14f, radius * 0.28f), Color.WHITE, true, Paint.Align.CENTER);
    }

    private void drawBar(Canvas canvas, float x, float y, float w, float h, float value, int color, String label) {
        value = clamp(value, 0f, 1f);
        paint.setColor(Color.argb(175, 0, 0, 0));
        canvas.drawRoundRect(new RectF(x, y, x + w, y + h), h / 2f, h / 2f, paint);
        paint.setColor(color);
        canvas.drawRoundRect(new RectF(x, y, x + w * value, y + h), h / 2f, h / 2f, paint);
        if (!label.isEmpty()) text(canvas, label, x + 7f, y + h - 4f, Math.max(10f, h * 0.62f), Color.WHITE, true);
    }

    private void text(Canvas canvas, String value, float x, float y, float size, int color, boolean bold) {
        text(canvas, value, x, y, size, color, bold, Paint.Align.LEFT);
    }

    private void text(Canvas canvas, String value, float x, float y, float size, int color, boolean bold, Paint.Align align) {
        paint.setShader(null);
        paint.setStyle(Paint.Style.FILL);
        paint.setColor(color);
        paint.setTextSize(size);
        paint.setTextAlign(align);
        paint.setTypeface(bold ? android.graphics.Typeface.DEFAULT_BOLD : android.graphics.Typeface.DEFAULT);
        canvas.drawText(value, x, y, paint);
    }

    private RectF coverRect(int srcW, int srcH, int dstW, int dstH) {
        float srcRatio = srcW / (float) srcH;
        float dstRatio = dstW / (float) dstH;
        if (srcRatio > dstRatio) {
            float newW = dstH * srcRatio;
            return new RectF((dstW - newW) / 2f, 0f, (dstW + newW) / 2f, dstH);
        }
        float newH = dstW / srcRatio;
        return new RectF(0f, (dstH - newH) / 2f, dstW, (dstH + newH) / 2f);
    }

    private float pseudoNoise(float x) {
        return (float) (0.5 + 0.5 * Math.sin(x * 2.17 + Math.sin(x * 0.73) * 1.8));
    }

    private int mix(int a, int b, float t) {
        t = clamp(t, 0f, 1f);
        return Color.rgb(
                (int) (Color.red(a) + (Color.red(b) - Color.red(a)) * t),
                (int) (Color.green(a) + (Color.green(b) - Color.green(a)) * t),
                (int) (Color.blue(a) + (Color.blue(b) - Color.blue(a)) * t)
        );
    }

    private boolean inside(float x, float y, float bx, float by, float bw, float bh) {
        return x >= bx && x <= bx + bw && y >= by && y <= by + bh;
    }

    private float distance(float x1, float y1, float x2, float y2) {
        float dx = x1 - x2;
        float dy = y1 - y2;
        return (float) Math.sqrt(dx * dx + dy * dy);
    }

    private static float clamp(float value, float min, float max) {
        return Math.max(min, Math.min(max, value));
    }

    private static int clampInt(int value, int min, int max) {
        return Math.max(min, Math.min(max, value));
    }

    @Override
    protected void onDetachedFromWindow() {
        saveGame();
        tones.release();
        super.onDetachedFromWindow();
    }

    private static final class Enemy {
        float x;
        float y;
        float hp;
        float maxHp;
        float speed;
        float attackRange;
        float attackCooldown;
        float hitFlash;
        int type;
        int color;
        boolean boss;
    }

    private static final class Particle {
        float x;
        float y;
        float vx;
        float vy;
        float life;
        float size;
        int color;
    }

    private static final class Pickup {
        final float x;
        final float y;
        final boolean legendary;
        float phase;

        Pickup(float x, float y, boolean legendary) {
            this.x = x;
            this.y = y;
            this.legendary = legendary;
        }
    }
}
