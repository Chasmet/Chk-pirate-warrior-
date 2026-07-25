package fr.chk.piratewarrior;

import android.content.Context;
import android.content.SharedPreferences;
import android.opengl.GLES20;
import android.opengl.GLSurfaceView;
import android.opengl.Matrix;
import android.os.SystemClock;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;
import java.nio.ShortBuffer;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Random;
import java.util.concurrent.atomic.AtomicBoolean;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

/**
 * Première fondation 3D réelle du jeu. Le rendu utilise OpenGL ES 2.0 afin de rester compatible
 * avec Android 5.0+, sans moteur externe et sans téléportation entre les îles.
 */
public final class PirateRenderer implements GLSurfaceView.Renderer {
    public enum Mode { MENU, HEROES, PLAYING, PAUSED, GAME_OVER }

    public static final class HudState {
        public final Mode mode;
        public final String islandName;
        public final String objective;
        public final String heroName;
        public final float health;
        public final float maxHealth;
        public final float boatSpeed;
        public final int fps;
        public final boolean piloting;
        public final boolean canInteract;

        HudState(
                Mode mode,
                String islandName,
                String objective,
                String heroName,
                float health,
                float maxHealth,
                float boatSpeed,
                int fps,
                boolean piloting,
                boolean canInteract
        ) {
            this.mode = mode;
            this.islandName = islandName;
            this.objective = objective;
            this.heroName = heroName;
            this.health = health;
            this.maxHealth = maxHealth;
            this.boatSpeed = boatSpeed;
            this.fps = fps;
            this.piloting = piloting;
            this.canInteract = canInteract;
        }
    }

    private enum Weather { SUN, RAIN, SNOW, STORM, ASH, MIST }
    private enum EnemyKind { MELEE, RANGED, DODGER }

    private static final String[] HERO_NAMES = {"CHEIKH", "YVANE", "NELVYN"};
    private static final float DEG = 180f / (float) Math.PI;
    private static final float WORLD_HALF_X = 235f;
    private static final float WORLD_HALF_Z = 95f;
    private static final int MAX_PROJECTILES = 32;

    private final Context context;
    private final PirateGameView.VoiceNarrator narrator;
    private final SharedPreferences preferences;
    private final Random random = new Random(24072026L);
    private final List<Enemy> enemies = new ArrayList<>();
    private final List<Projectile> projectiles = new ArrayList<>();
    private final List<Rock> rocks = new ArrayList<>();
    private final List<Tree> trees = new ArrayList<>();
    private final WeatherDrop[] weatherDrops = new WeatherDrop[36];

    private final float[] projection = new float[16];
    private final float[] view = new float[16];
    private final float[] viewProjection = new float[16];
    private final float[] model = new float[16];
    private final float[] mvp = new float[16];
    private final float[] color = new float[4];

    private final AtomicBoolean attackRequested = new AtomicBoolean();
    private final AtomicBoolean jumpRequested = new AtomicBoolean();
    private final AtomicBoolean interactRequested = new AtomicBoolean();

    private volatile Mode mode = Mode.MENU;
    private volatile float moveX;
    private volatile float moveY;
    private volatile HudState hudState = new HudState(
            Mode.MENU, "Île de l'Aube", "Choisir un héros", HERO_NAMES[0],
            100f, 100f, 0f, 0, false, false
    );

    private float pendingCameraYaw;
    private float pendingCameraPitch;
    private int width;
    private int height;
    private long lastFrameNanos;
    private long lastSaveMillis;
    private long fpsWindowStart;
    private int fpsFrames;
    private int fps;
    private float elapsed;

    private int program;
    private int aPosition;
    private int aNormal;
    private int uMvp;
    private int uModel;
    private int uColor;
    private int uCamera;
    private int uFogColor;
    private int uFogDensity;
    private int uTime;
    private int uWave;

    private Mesh cube;
    private Mesh verticalQuad;
    private Mesh flatQuad;
    private Mesh islandCylinder;
    private Mesh waterGrid;
    private Mesh pyramid;

    private final Island[] islands = {
            new Island("Île de l'Aube", -190f, -12f, 22f, 2.1f,
                    0.24f, 0.61f, 0.24f, Weather.SUN),
            new Island("Royaume des Neiges", -112f, 34f, 25f, 2.8f,
                    0.70f, 0.82f, 0.90f, Weather.SNOW),
            new Island("Désert des Corsaires", -34f, -26f, 27f, 2.4f,
                    0.76f, 0.57f, 0.25f, Weather.MIST),
            new Island("Fournaise Rouge", 55f, 31f, 24f, 3.2f,
                    0.39f, 0.16f, 0.11f, Weather.ASH),
            new Island("Atoll de la Tempête", 132f, -30f, 28f, 2.0f,
                    0.17f, 0.46f, 0.32f, Weather.STORM),
            new Island("Citadelle du Kraken", 207f, 21f, 30f, 3.5f,
                    0.30f, 0.27f, 0.42f, Weather.RAIN)
    };

    private int selectedHero;
    private int currentIsland;
    private float playerX;
    private float playerZ;
    private float playerHeight;
    private float playerVerticalVelocity;
    private float playerFacing;
    private float playerHealth = 100f;
    private float playerMaxHealth = 100f;
    private float attackCooldown;
    private float hurtCooldown;

    private float boatX;
    private float boatZ;
    private float boatHeading;
    private float boatSpeed;
    private boolean piloting;

    private float cameraYaw = 0.55f;
    private float cameraPitch = 0.36f;
    private float cameraDistance = 12.5f;
    private float cameraX;
    private float cameraY;
    private float cameraZ;

    public PirateRenderer(Context context, PirateGameView.VoiceNarrator narrator) {
        this.context = context.getApplicationContext();
        this.narrator = narrator;
        this.preferences = context.getSharedPreferences("chk_pirate_3d_save", Context.MODE_PRIVATE);
        buildWorld();
        loadGame();
    }

    public HudState getHudState() {
        return hudState;
    }

    public void setMoveInput(float x, float y) {
        moveX = GameMath.clamp(x, -1f, 1f);
        moveY = GameMath.clamp(y, -1f, 1f);
    }

    public synchronized void addCameraDrag(float dx, float dy) {
        pendingCameraYaw += dx;
        pendingCameraPitch += dy;
    }

    public void requestAttack() {
        attackRequested.set(true);
    }

    public void requestJump() {
        jumpRequested.set(true);
    }

    public void requestInteract() {
        interactRequested.set(true);
    }

    public void showHeroSelection() {
        mode = Mode.HEROES;
        publishHud();
    }

    public void selectHero(int hero) {
        selectedHero = Math.max(0, Math.min(HERO_NAMES.length - 1, hero));
        resetForAdventure(false);
        mode = Mode.PLAYING;
        speak(HERO_NAMES[selectedHero] + " prend la mer. Cap sur la prochaine île.");
        saveGame();
    }

    public void togglePause() {
        if (mode == Mode.PLAYING) {
            mode = Mode.PAUSED;
            setMoveInput(0f, 0f);
            saveGame();
        } else if (mode == Mode.PAUSED) {
            mode = Mode.PLAYING;
        }
        publishHud();
    }

    public void returnToMenu() {
        mode = Mode.MENU;
        setMoveInput(0f, 0f);
        saveGame();
        publishHud();
    }

    public void restartAfterDefeat() {
        resetForAdventure(true);
        mode = Mode.PLAYING;
        publishHud();
    }

    public void pauseEngine() {
        saveGame();
    }

    public void resumeEngine() {
        lastFrameNanos = 0L;
    }

    @Override
    public void onSurfaceCreated(GL10 gl, EGLConfig config) {
        GLES20.glClearColor(0.35f, 0.65f, 0.82f, 1f);
        GLES20.glEnable(GLES20.GL_DEPTH_TEST);
        GLES20.glDepthFunc(GLES20.GL_LEQUAL);
        GLES20.glEnable(GLES20.GL_BLEND);
        GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA);

        program = createProgram(VERTEX_SHADER, FRAGMENT_SHADER);
        aPosition = GLES20.glGetAttribLocation(program, "aPosition");
        aNormal = GLES20.glGetAttribLocation(program, "aNormal");
        uMvp = GLES20.glGetUniformLocation(program, "uMvp");
        uModel = GLES20.glGetUniformLocation(program, "uModel");
        uColor = GLES20.glGetUniformLocation(program, "uColor");
        uCamera = GLES20.glGetUniformLocation(program, "uCamera");
        uFogColor = GLES20.glGetUniformLocation(program, "uFogColor");
        uFogDensity = GLES20.glGetUniformLocation(program, "uFogDensity");
        uTime = GLES20.glGetUniformLocation(program, "uTime");
        uWave = GLES20.glGetUniformLocation(program, "uWave");

        cube = Mesh.cube();
        verticalQuad = Mesh.verticalQuad();
        flatQuad = Mesh.flatQuad();
        islandCylinder = Mesh.cylinder(28);
        waterGrid = Mesh.grid(34);
        pyramid = Mesh.pyramid();

        fpsWindowStart = SystemClock.elapsedRealtime();
    }

    @Override
    public void onSurfaceChanged(GL10 gl, int width, int height) {
        this.width = width;
        this.height = height;
        GLES20.glViewport(0, 0, width, height);
        float aspect = width / (float) Math.max(1, height);
        Matrix.perspectiveM(projection, 0, 52f, aspect, 0.35f, 620f);
    }

    @Override
    public void onDrawFrame(GL10 gl) {
        long now = System.nanoTime();
        float dt = lastFrameNanos == 0L ? 0f
                : Math.min(0.033f, (now - lastFrameNanos) / 1_000_000_000f);
        lastFrameNanos = now;
        elapsed += dt;

        consumeCameraDrag();
        if (mode == Mode.PLAYING && dt > 0f) {
            updateGame(dt);
        }
        updateCamera(dt);
        updateFps();
        publishHud();
        drawWorld();

        long nowMs = SystemClock.elapsedRealtime();
        if (nowMs - lastSaveMillis > 6000L) {
            saveGame();
            lastSaveMillis = nowMs;
        }
    }

    private void updateGame(float dt) {
        attackCooldown = Math.max(0f, attackCooldown - dt);
        hurtCooldown = Math.max(0f, hurtCooldown - dt);

        if (piloting) {
            updateBoat(dt);
        } else {
            updatePlayer(dt);
        }

        if (attackRequested.getAndSet(false)) {
            performAttack();
        }
        if (jumpRequested.getAndSet(false) && !piloting && playerHeight <= 0.001f) {
            playerVerticalVelocity = 7.2f;
        }
        if (interactRequested.getAndSet(false)) {
            toggleBoatControl();
        }

        updateEnemies(dt);
        updateProjectiles(dt);
        updateWeather(dt);

        if (playerHealth <= 0f) {
            playerHealth = 0f;
            mode = Mode.GAME_OVER;
            boatSpeed = 0f;
            setMoveInput(0f, 0f);
            speak("L'équipage est à terre. Reprends l'aventure depuis la dernière île.");
            saveGame();
        }
    }

    private void updatePlayer(float dt) {
        Island island = islands[currentIsland];
        float magnitude = GameMath.length(moveX, moveY);
        if (magnitude > 0.08f) {
            float inputForward = -moveY / Math.max(1f, magnitude);
            float inputRight = moveX / Math.max(1f, magnitude);
            float forwardX = (float) Math.sin(cameraYaw);
            float forwardZ = (float) Math.cos(cameraYaw);
            float rightX = (float) Math.cos(cameraYaw);
            float rightZ = -(float) Math.sin(cameraYaw);
            float dx = forwardX * inputForward + rightX * inputRight;
            float dz = forwardZ * inputForward + rightZ * inputRight;
            float speed = selectedHero == 1 ? 7.1f : selectedHero == 2 ? 5.9f : 6.4f;
            float nextX = playerX + dx * speed * dt;
            float nextZ = playerZ + dz * speed * dt;
            float[] clamped = GameMath.clampToCircle(
                    nextX, nextZ, island.x, island.z, island.radius - 1.35f
            );
            playerX = clamped[0];
            playerZ = clamped[1];
            playerFacing = (float) Math.atan2(dx, dz);
        }

        if (playerHeight > 0f || playerVerticalVelocity > 0f) {
            playerVerticalVelocity -= 18f * dt;
            playerHeight += playerVerticalVelocity * dt;
            if (playerHeight < 0f) {
                playerHeight = 0f;
                playerVerticalVelocity = 0f;
            }
        }
    }

    private void updateBoat(float dt) {
        float throttle = GameMath.clamp(-moveY, -1f, 1f);
        float steering = GameMath.clamp(moveX, -1f, 1f);
        float acceleration = throttle >= 0f ? 8.2f : 5.4f;
        boatSpeed += throttle * acceleration * dt;
        boatSpeed = GameMath.clamp(boatSpeed, -4.5f, 13.5f);
        boatSpeed *= (float) Math.pow(0.965f, dt * 60f);
        if (Math.abs(boatSpeed) < 0.025f) {
            boatSpeed = 0f;
        }

        float turnAuthority = 0.35f + Math.min(1f, Math.abs(boatSpeed) / 5f);
        float direction = boatSpeed < -0.2f ? -1f : 1f;
        boatHeading = GameMath.normalizeAngle(
                boatHeading + steering * direction * turnAuthority * 1.35f * dt
        );

        float nextX = boatX + (float) Math.sin(boatHeading) * boatSpeed * dt;
        float nextZ = boatZ + (float) Math.cos(boatHeading) * boatSpeed * dt;
        nextX = GameMath.clamp(nextX, -WORLD_HALF_X, WORLD_HALF_X);
        nextZ = GameMath.clamp(nextZ, -WORLD_HALF_Z, WORLD_HALF_Z);

        boolean collided = false;
        for (Island island : islands) {
            float dx = nextX - island.x;
            float dz = nextZ - island.z;
            float distance = GameMath.length(dx, dz);
            float minimum = island.radius + 1.55f;
            if (distance < minimum) {
                float inv = 1f / Math.max(0.001f, distance);
                nextX = island.x + dx * inv * minimum;
                nextZ = island.z + dz * inv * minimum;
                collided = true;
            }
        }
        if (collided) {
            boatSpeed *= -0.18f;
        }
        boatX = nextX;
        boatZ = nextZ;
        playerX = boatX;
        playerZ = boatZ;
        playerFacing = boatHeading;
    }

    private void performAttack() {
        if (attackCooldown > 0f || mode != Mode.PLAYING) {
            return;
        }
        if (piloting) {
            attackCooldown = 1.0f;
            if (projectiles.size() < MAX_PROJECTILES) {
                float direction = boatHeading;
                projectiles.add(new Projectile(
                        boatX + (float) Math.sin(direction) * 3.1f,
                        1.45f,
                        boatZ + (float) Math.cos(direction) * 3.1f,
                        (float) Math.sin(direction) * 24f,
                        0.8f,
                        (float) Math.cos(direction) * 24f,
                        true,
                        28f
                ));
            }
            return;
        }

        attackCooldown = selectedHero == 1 ? 0.42f : 0.55f;
        float reach = selectedHero == 2 ? 3.8f : 3.2f;
        float damage = selectedHero == 0 ? 30f : selectedHero == 1 ? 22f : 26f;
        float faceX = (float) Math.sin(playerFacing);
        float faceZ = (float) Math.cos(playerFacing);
        for (Enemy enemy : enemies) {
            if (!enemy.alive || enemy.islandIndex != currentIsland) {
                continue;
            }
            float dx = enemy.x - playerX;
            float dz = enemy.z - playerZ;
            float distance = GameMath.length(dx, dz);
            if (distance > reach + enemy.radius) {
                continue;
            }
            float dot = (dx * faceX + dz * faceZ) / Math.max(0.001f, distance);
            if (dot > -0.15f) {
                float applied = damage;
                if (enemy.specialLevel == 3 && livingCommanders(currentIsland) > 0) {
                    applied *= 0.12f;
                } else if (enemy.specialLevel == 2 && livingNakama(currentIsland, enemy.group) > 0) {
                    applied *= 0.45f;
                }
                enemy.hp -= applied;
                enemy.hitFlash = 0.18f;
                enemy.stun = 0.16f;
            }
        }
    }

    private void toggleBoatControl() {
        if (piloting) {
            Island nearest = nearestIsland(boatX, boatZ);
            float distance = GameMath.distance(boatX, boatZ, nearest.x, nearest.z);
            if (distance <= nearest.radius + 4.8f) {
                float dx = boatX - nearest.x;
                float dz = boatZ - nearest.z;
                float inv = 1f / Math.max(0.001f, GameMath.length(dx, dz));
                playerX = nearest.x + dx * inv * (nearest.radius - 1.7f);
                playerZ = nearest.z + dz * inv * (nearest.radius - 1.7f);
                currentIsland = indexOfIsland(nearest);
                piloting = false;
                boatSpeed *= 0.35f;
                speak("Débarquement sur " + nearest.name + ".");
            }
            return;
        }

        if (GameMath.distance(playerX, playerZ, boatX, boatZ) <= 4.5f) {
            piloting = true;
            playerX = boatX;
            playerZ = boatZ;
            boatHeading = playerFacing;
            speak("À la barre. Navigue réellement jusqu'à la prochaine île.");
        }
    }

    private void updateEnemies(float dt) {
        if (piloting) {
            return;
        }
        Island island = islands[currentIsland];
        for (Enemy enemy : enemies) {
            if (!enemy.alive || enemy.islandIndex != currentIsland) {
                continue;
            }
            if (enemy.hp <= 0f) {
                enemy.alive = false;
                if (enemy.specialLevel == 3) {
                    speak("Boss vaincu. " + island.name + " est libérée.");
                }
                continue;
            }
            enemy.attackCooldown = Math.max(0f, enemy.attackCooldown - dt);
            enemy.hitFlash = Math.max(0f, enemy.hitFlash - dt);
            enemy.stun = Math.max(0f, enemy.stun - dt);
            if (enemy.stun > 0f) {
                continue;
            }

            float dx = playerX - enemy.x;
            float dz = playerZ - enemy.z;
            float distance = GameMath.length(dx, dz);
            if (distance > 24f) {
                continue;
            }
            float nx = dx / Math.max(0.001f, distance);
            float nz = dz / Math.max(0.001f, distance);
            float speed = enemy.speed;

            if (enemy.kind == EnemyKind.RANGED) {
                if (distance < 6.5f) {
                    enemy.x -= nx * speed * dt;
                    enemy.z -= nz * speed * dt;
                } else if (distance > 10f) {
                    enemy.x += nx * speed * dt;
                    enemy.z += nz * speed * dt;
                }
                if (distance < 13f && enemy.attackCooldown <= 0f) {
                    fireEnemyProjectile(enemy, nx, nz);
                    enemy.attackCooldown = enemy.specialLevel > 0 ? 1.05f : 1.65f;
                }
            } else if (enemy.kind == EnemyKind.DODGER) {
                float strafe = (float) Math.sin(elapsed * 2.4f + enemy.phase);
                float desiredX = nx * 0.55f + nz * strafe * 0.85f;
                float desiredZ = nz * 0.55f - nx * strafe * 0.85f;
                if (distance > 3.1f) {
                    enemy.x += desiredX * speed * dt;
                    enemy.z += desiredZ * speed * dt;
                }
                if (distance < 3.4f && enemy.attackCooldown <= 0f) {
                    damagePlayer(enemy.specialLevel > 0 ? 13f : 7f);
                    enemy.attackCooldown = 1.15f;
                }
            } else {
                if (distance > 2.45f) {
                    enemy.x += nx * speed * dt;
                    enemy.z += nz * speed * dt;
                } else if (enemy.attackCooldown <= 0f) {
                    float damage = enemy.specialLevel == 3 ? 18f
                            : enemy.specialLevel == 2 ? 13f
                            : enemy.specialLevel == 1 ? 10f : 7f;
                    damagePlayer(damage);
                    enemy.attackCooldown = enemy.specialLevel > 0 ? 1.05f : 1.4f;
                }
            }

            float[] clamped = GameMath.clampToCircle(
                    enemy.x, enemy.z, island.x, island.z, island.radius - 1.2f
            );
            enemy.x = clamped[0];
            enemy.z = clamped[1];
        }
    }

    private void fireEnemyProjectile(Enemy enemy, float nx, float nz) {
        if (projectiles.size() >= MAX_PROJECTILES) {
            return;
        }
        float speed = enemy.specialLevel > 0 ? 12f : 9f;
        projectiles.add(new Projectile(
                enemy.x,
                islands[enemy.islandIndex].height + 1.4f,
                enemy.z,
                nx * speed,
                0f,
                nz * speed,
                false,
                enemy.specialLevel > 0 ? 11f : 7f
        ));
    }

    private void updateProjectiles(float dt) {
        for (int i = projectiles.size() - 1; i >= 0; i--) {
            Projectile projectile = projectiles.get(i);
            projectile.life -= dt;
            projectile.x += projectile.vx * dt;
            projectile.y += projectile.vy * dt;
            projectile.z += projectile.vz * dt;
            projectile.vy -= 2.8f * dt;

            boolean remove = projectile.life <= 0f;
            if (!remove && projectile.fromPlayer) {
                for (Enemy enemy : enemies) {
                    if (!enemy.alive || enemy.islandIndex != currentIsland) {
                        continue;
                    }
                    if (GameMath.distance(projectile.x, projectile.z, enemy.x, enemy.z)
                            < enemy.radius + 0.55f) {
                        enemy.hp -= projectile.damage;
                        enemy.hitFlash = 0.2f;
                        remove = true;
                        break;
                    }
                }
            } else if (!remove && !projectile.fromPlayer && !piloting) {
                if (GameMath.distance(projectile.x, projectile.z, playerX, playerZ) < 1.15f) {
                    damagePlayer(projectile.damage);
                    remove = true;
                }
            }
            if (remove) {
                projectiles.remove(i);
            }
        }
    }

    private void damagePlayer(float damage) {
        if (hurtCooldown > 0f) {
            return;
        }
        playerHealth -= damage;
        hurtCooldown = 0.55f;
    }

    private void updateWeather(float dt) {
        Weather weather = islands[currentIsland].weather;
        for (WeatherDrop drop : weatherDrops) {
            drop.y -= drop.speed * dt;
            drop.x += drop.wind * dt;
            if (drop.y < 0f) {
                resetDrop(drop, weather);
            }
        }
    }

    private void updateCamera(float dt) {
        float targetX = piloting ? boatX : playerX;
        float targetZ = piloting ? boatZ : playerZ;
        float targetY = piloting ? 1.55f : islands[currentIsland].height + 1.4f + playerHeight;
        float desiredDistance = piloting ? 15.5f : cameraDistance;
        float horizontalDistance = (float) Math.cos(cameraPitch) * desiredDistance;
        float desiredX = targetX - (float) Math.sin(cameraYaw) * horizontalDistance;
        float desiredZ = targetZ - (float) Math.cos(cameraYaw) * horizontalDistance;
        float desiredY = targetY + (float) Math.sin(cameraPitch) * desiredDistance + 1.0f;

        float safeDistance = resolveCameraDistance(targetX, targetZ, desiredX, desiredZ, desiredDistance);
        horizontalDistance = (float) Math.cos(cameraPitch) * safeDistance;
        desiredX = targetX - (float) Math.sin(cameraYaw) * horizontalDistance;
        desiredZ = targetZ - (float) Math.cos(cameraYaw) * horizontalDistance;
        desiredY = targetY + (float) Math.sin(cameraPitch) * safeDistance + 1.0f;

        float smoothing = dt <= 0f ? 1f : Math.min(1f, dt * 12f);
        cameraX = GameMath.lerp(cameraX, desiredX, smoothing);
        cameraY = GameMath.lerp(cameraY, desiredY, smoothing);
        cameraZ = GameMath.lerp(cameraZ, desiredZ, smoothing);
        Matrix.setLookAtM(
                view, 0,
                cameraX, cameraY, cameraZ,
                targetX, targetY, targetZ,
                0f, 1f, 0f
        );
        Matrix.multiplyMM(viewProjection, 0, projection, 0, view, 0);
    }

    private float resolveCameraDistance(
            float targetX,
            float targetZ,
            float desiredX,
            float desiredZ,
            float desiredDistance
    ) {
        float dx = desiredX - targetX;
        float dz = desiredZ - targetZ;
        float segmentLength = GameMath.length(dx, dz);
        if (segmentLength < 0.001f) {
            return desiredDistance;
        }
        float nx = dx / segmentLength;
        float nz = dz / segmentLength;
        float safe = desiredDistance;
        for (Rock rock : rocks) {
            if (rock.islandIndex != currentIsland) {
                continue;
            }
            float tx = rock.x - targetX;
            float tz = rock.z - targetZ;
            float projectionDistance = tx * nx + tz * nz;
            if (projectionDistance <= 1.8f || projectionDistance >= segmentLength) {
                continue;
            }
            float closestX = targetX + nx * projectionDistance;
            float closestZ = targetZ + nz * projectionDistance;
            float perpendicular = GameMath.distance(closestX, closestZ, rock.x, rock.z);
            float collisionRadius = rock.radius + 0.65f;
            if (perpendicular < collisionRadius) {
                safe = Math.min(safe, Math.max(3.2f, projectionDistance - collisionRadius));
            }
        }
        return safe;
    }

    private void drawWorld() {
        Island active = islands[currentIsland];
        float[] fog = fogColor(active.weather);
        GLES20.glClearColor(fog[0], fog[1], fog[2], 1f);
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT | GLES20.GL_DEPTH_BUFFER_BIT);
        GLES20.glUseProgram(program);
        GLES20.glUniform3f(uCamera, cameraX, cameraY, cameraZ);
        GLES20.glUniform3f(uFogColor, fog[0], fog[1], fog[2]);
        GLES20.glUniform1f(uFogDensity, fogDensity(active.weather));
        GLES20.glUniform1f(uTime, elapsed);

        drawWater();
        for (int i = 0; i < islands.length; i++) {
            drawIsland(islands[i], i);
        }
        drawBoat();
        drawEnemies();
        drawProjectiles();
        drawPlayer();
        drawWeather();
    }

    private void drawWater() {
        setIdentity();
        Matrix.translateM(model, 0, 0f, -0.12f, 0f);
        Matrix.scaleM(model, 0, WORLD_HALF_X * 2.35f, 1f, WORLD_HALF_Z * 2.6f);
        setColor(0.05f, 0.36f, 0.58f, 0.94f);
        drawMesh(waterGrid, model, color, 0.42f);
    }

    private void drawIsland(Island island, int islandIndex) {
        setIdentity();
        Matrix.translateM(model, 0, island.x, island.height * 0.5f, island.z);
        Matrix.scaleM(model, 0, island.radius, island.height, island.radius);
        setColor(island.r, island.g, island.b, 1f);
        drawMesh(islandCylinder, model, color, 0f);

        for (Rock rock : rocks) {
            if (rock.islandIndex != islandIndex) {
                continue;
            }
            setIdentity();
            Matrix.translateM(model, 0, rock.x, island.height + rock.radius * 0.55f, rock.z);
            Matrix.rotateM(model, 0, rock.rotation, 0f, 1f, 0f);
            Matrix.scaleM(model, 0, rock.radius, rock.radius * 1.1f, rock.radius * 0.82f);
            setColor(0.28f + islandIndex * 0.025f, 0.28f, 0.30f, 1f);
            drawMesh(cube, model, color, 0f);
        }

        for (Tree tree : trees) {
            if (tree.islandIndex != islandIndex) {
                continue;
            }
            setIdentity();
            Matrix.translateM(model, 0, tree.x, island.height + tree.height * 0.5f, tree.z);
            Matrix.scaleM(model, 0, 0.34f, tree.height, 0.34f);
            setColor(0.30f, 0.17f, 0.08f, 1f);
            drawMesh(cube, model, color, 0f);

            setIdentity();
            Matrix.translateM(model, 0, tree.x, island.height + tree.height + 1.1f, tree.z);
            Matrix.scaleM(model, 0, 1.3f, 2.2f, 1.3f);
            if (island.weather == Weather.SNOW) {
                setColor(0.76f, 0.88f, 0.84f, 1f);
            } else if (island.weather == Weather.ASH) {
                setColor(0.30f, 0.20f, 0.17f, 1f);
            } else {
                setColor(0.08f, 0.43f, 0.16f, 1f);
            }
            drawMesh(pyramid, model, color, 0f);
        }

        drawDock(island, islandIndex);
    }

    private void drawDock(Island island, int islandIndex) {
        float angle = islandIndex % 2 == 0 ? 0.15f : 2.85f;
        float shoreX = island.x + (float) Math.sin(angle) * (island.radius + 2.5f);
        float shoreZ = island.z + (float) Math.cos(angle) * (island.radius + 2.5f);
        setIdentity();
        Matrix.translateM(model, 0, shoreX, 0.55f, shoreZ);
        Matrix.rotateM(model, 0, angle * DEG, 0f, 1f, 0f);
        Matrix.scaleM(model, 0, 2.1f, 0.25f, 7.5f);
        setColor(0.39f, 0.23f, 0.10f, 1f);
        drawMesh(cube, model, color, 0f);
    }

    private void drawBoat() {
        setIdentity();
        Matrix.translateM(model, 0, boatX, 0.55f + waveAt(boatX, boatZ), boatZ);
        Matrix.rotateM(model, 0, boatHeading * DEG, 0f, 1f, 0f);
        Matrix.scaleM(model, 0, 2.1f, 0.65f, 4.5f);
        setColor(0.35f, 0.16f, 0.06f, 1f);
        drawMesh(cube, model, color, 0f);

        setIdentity();
        Matrix.translateM(model, 0, boatX, 2.7f + waveAt(boatX, boatZ), boatZ);
        Matrix.rotateM(model, 0, boatHeading * DEG, 0f, 1f, 0f);
        Matrix.scaleM(model, 0, 0.18f, 4.2f, 0.18f);
        setColor(0.24f, 0.11f, 0.04f, 1f);
        drawMesh(cube, model, color, 0f);

        setIdentity();
        Matrix.translateM(model, 0,
                boatX + (float) Math.sin(boatHeading) * 0.10f,
                3.1f + waveAt(boatX, boatZ),
                boatZ + (float) Math.cos(boatHeading) * 0.10f);
        Matrix.rotateM(model, 0, boatHeading * DEG, 0f, 1f, 0f);
        Matrix.scaleM(model, 0, 2.0f, 2.4f, 1f);
        setColor(0.84f, 0.82f, 0.70f, 0.95f);
        drawMesh(verticalQuad, model, color, 0f);
    }

    private void drawPlayer() {
        float ground = piloting ? 1.25f + waveAt(boatX, boatZ)
                : islands[currentIsland].height + playerHeight;
        float x = piloting
                ? boatX - (float) Math.sin(boatHeading) * 0.35f
                : playerX;
        float z = piloting
                ? boatZ - (float) Math.cos(boatHeading) * 0.35f
                : playerZ;
        drawShadow(x, ground + 0.03f, z, 1.0f);

        float facingCamera = (float) Math.atan2(cameraX - x, cameraZ - z) * DEG;
        float[] heroColor = heroColor(selectedHero);
        setIdentity();
        Matrix.translateM(model, 0, x, ground + 1.05f, z);
        Matrix.rotateM(model, 0, facingCamera, 0f, 1f, 0f);
        Matrix.scaleM(model, 0, 1.05f, 2.05f, 1f);
        setColor(heroColor[0], heroColor[1], heroColor[2], 1f);
        drawMesh(verticalQuad, model, color, 0f);

        setIdentity();
        Matrix.translateM(model, 0, x, ground + 2.42f, z);
        Matrix.rotateM(model, 0, facingCamera, 0f, 1f, 0f);
        Matrix.scaleM(model, 0, 0.72f, 0.72f, 1f);
        setColor(0.58f, 0.36f, 0.23f, 1f);
        drawMesh(verticalQuad, model, color, 0f);
    }

    private void drawEnemies() {
        for (Enemy enemy : enemies) {
            if (!enemy.alive) {
                continue;
            }
            Island island = islands[enemy.islandIndex];
            if (GameMath.distance(enemy.x, enemy.z, cameraX, cameraZ) > 72f) {
                continue;
            }
            float ground = island.height;
            drawShadow(enemy.x, ground + 0.03f, enemy.z, enemy.radius);
            float flashValue = enemy.hitFlash > 0f ? 0.75f : 0f;

            if (enemy.specialLevel > 0) {
                float faceCamera = (float) Math.atan2(cameraX - enemy.x, cameraZ - enemy.z) * DEG;
                float scale = enemy.specialLevel == 3 ? 2.6f
                        : enemy.specialLevel == 2 ? 1.95f : 1.55f;
                setIdentity();
                Matrix.translateM(model, 0, enemy.x, ground + scale * 0.62f, enemy.z);
                Matrix.rotateM(model, 0, faceCamera, 0f, 1f, 0f);
                Matrix.scaleM(model, 0, scale * 0.70f, scale, 1f);
                setColor(
                        Math.min(1f, enemy.r + flashValue),
                        Math.min(1f, enemy.g + flashValue),
                        Math.min(1f, enemy.b + flashValue),
                        1f
                );
                drawMesh(verticalQuad, model, color, 0f);
            } else {
                setIdentity();
                Matrix.translateM(model, 0, enemy.x, ground + 0.9f, enemy.z);
                Matrix.scaleM(model, 0, 0.68f, 1.55f, 0.54f);
                setColor(
                        Math.min(1f, enemy.r + flashValue),
                        Math.min(1f, enemy.g + flashValue),
                        Math.min(1f, enemy.b + flashValue),
                        1f
                );
                drawMesh(cube, model, color, 0f);

                setIdentity();
                Matrix.translateM(model, 0, enemy.x, ground + 2.0f, enemy.z);
                Matrix.scaleM(model, 0, 0.52f, 0.52f, 0.52f);
                setColor(0.52f, 0.30f, 0.19f, 1f);
                drawMesh(cube, model, color, 0f);
            }
        }
    }

    private void drawProjectiles() {
        for (Projectile projectile : projectiles) {
            setIdentity();
            Matrix.translateM(model, 0, projectile.x, projectile.y, projectile.z);
            Matrix.scaleM(model, 0, projectile.fromPlayer ? 0.32f : 0.22f,
                    projectile.fromPlayer ? 0.32f : 0.22f,
                    projectile.fromPlayer ? 0.32f : 0.22f);
            if (projectile.fromPlayer) {
                setColor(1f, 0.62f, 0.12f, 1f);
            } else {
                setColor(0.78f, 0.12f, 0.18f, 1f);
            }
            drawMesh(cube, model, color, 0f);
        }
    }

    private void drawWeather() {
        Weather weather = islands[currentIsland].weather;
        if (weather == Weather.SUN || weather == Weather.MIST) {
            return;
        }
        for (WeatherDrop drop : weatherDrops) {
            float worldX = cameraX + drop.x;
            float worldZ = cameraZ + drop.z;
            setIdentity();
            Matrix.translateM(model, 0, worldX, drop.y + 1f, worldZ);
            if (weather == Weather.SNOW) {
                Matrix.scaleM(model, 0, 0.09f, 0.09f, 0.09f);
                setColor(0.96f, 0.98f, 1f, 0.78f);
            } else if (weather == Weather.ASH) {
                Matrix.scaleM(model, 0, 0.07f, 0.16f, 0.07f);
                setColor(0.22f, 0.18f, 0.17f, 0.72f);
            } else {
                Matrix.scaleM(model, 0, 0.035f, weather == Weather.STORM ? 1.4f : 0.8f, 0.035f);
                setColor(0.72f, 0.86f, 0.98f, 0.62f);
            }
            drawMesh(cube, model, color, 0f);
        }
    }

    private void drawShadow(float x, float y, float z, float radius) {
        GLES20.glDepthMask(false);
        setIdentity();
        Matrix.translateM(model, 0, x, y, z);
        Matrix.scaleM(model, 0, radius, 1f, radius * 0.70f);
        setColor(0f, 0f, 0f, 0.28f);
        drawMesh(flatQuad, model, color, 0f);
        GLES20.glDepthMask(true);
    }

    private void drawMesh(Mesh mesh, float[] modelMatrix, float[] rgba, float wave) {
        Matrix.multiplyMM(mvp, 0, viewProjection, 0, modelMatrix, 0);
        GLES20.glUniformMatrix4fv(uMvp, 1, false, mvp, 0);
        GLES20.glUniformMatrix4fv(uModel, 1, false, modelMatrix, 0);
        GLES20.glUniform4fv(uColor, 1, rgba, 0);
        GLES20.glUniform1f(uWave, wave);

        mesh.vertices.position(0);
        GLES20.glVertexAttribPointer(aPosition, 3, GLES20.GL_FLOAT, false, 24, mesh.vertices);
        GLES20.glEnableVertexAttribArray(aPosition);
        mesh.vertices.position(3);
        GLES20.glVertexAttribPointer(aNormal, 3, GLES20.GL_FLOAT, false, 24, mesh.vertices);
        GLES20.glEnableVertexAttribArray(aNormal);
        mesh.indices.position(0);
        GLES20.glDrawElements(GLES20.GL_TRIANGLES, mesh.indexCount, GLES20.GL_UNSIGNED_SHORT, mesh.indices);
    }

    private synchronized void consumeCameraDrag() {
        cameraYaw = GameMath.normalizeAngle(cameraYaw - pendingCameraYaw * 0.0062f);
        cameraPitch = GameMath.clamp(cameraPitch - pendingCameraPitch * 0.0048f, 0.16f, 0.72f);
        pendingCameraYaw = 0f;
        pendingCameraPitch = 0f;
    }

    private void updateFps() {
        fpsFrames++;
        long now = SystemClock.elapsedRealtime();
        if (now - fpsWindowStart >= 1000L) {
            fps = Math.round(fpsFrames * 1000f / Math.max(1L, now - fpsWindowStart));
            fpsFrames = 0;
            fpsWindowStart = now;
        }
    }

    private void publishHud() {
        Island island = islands[currentIsland];
        int commanders = livingCommanders(currentIsland);
        Enemy boss = bossForIsland(currentIsland);
        String objective;
        if (boss == null || !boss.alive) {
            objective = "Île libérée — rejoins le bateau";
        } else if (commanders > 0) {
            objective = commanders + " commandant" + (commanders > 1 ? "s" : "") + " à vaincre";
        } else {
            objective = "Boss principal : " + Math.max(0, Math.round(boss.hp)) + " PV";
        }
        hudState = new HudState(
                mode,
                island.name,
                objective,
                HERO_NAMES[selectedHero],
                playerHealth,
                playerMaxHealth,
                Math.abs(boatSpeed),
                fps,
                piloting,
                canInteract()
        );
    }

    private boolean canInteract() {
        if (piloting) {
            Island nearest = nearestIsland(boatX, boatZ);
            return GameMath.distance(boatX, boatZ, nearest.x, nearest.z) <= nearest.radius + 4.8f;
        }
        return GameMath.distance(playerX, playerZ, boatX, boatZ) <= 4.5f;
    }

    private void buildWorld() {
        for (int islandIndex = 0; islandIndex < islands.length; islandIndex++) {
            Island island = islands[islandIndex];
            Random islandRandom = new Random(9001L + islandIndex * 771L);
            for (int i = 0; i < 7; i++) {
                float angle = islandRandom.nextFloat() * (float) Math.PI * 2f;
                float radius = 4f + islandRandom.nextFloat() * (island.radius - 8f);
                rocks.add(new Rock(
                        islandIndex,
                        island.x + (float) Math.sin(angle) * radius,
                        island.z + (float) Math.cos(angle) * radius,
                        0.65f + islandRandom.nextFloat() * 1.15f,
                        islandRandom.nextFloat() * 180f
                ));
            }
            for (int i = 0; i < 11; i++) {
                float angle = islandRandom.nextFloat() * (float) Math.PI * 2f;
                float radius = 5f + islandRandom.nextFloat() * (island.radius - 9f);
                trees.add(new Tree(
                        islandIndex,
                        island.x + (float) Math.sin(angle) * radius,
                        island.z + (float) Math.cos(angle) * radius,
                        1.8f + islandRandom.nextFloat() * 1.8f
                ));
            }

            for (int i = 0; i < 7; i++) {
                EnemyKind kind = EnemyKind.values()[i % EnemyKind.values().length];
                enemies.add(createEnemy(islandIndex, i, 0, -1, kind, islandRandom));
            }
            for (int group = 0; group < 3; group++) {
                enemies.add(createEnemy(
                        islandIndex, 20 + group, 2, group,
                        EnemyKind.values()[(group + islandIndex) % 3], islandRandom
                ));
                enemies.add(createEnemy(
                        islandIndex, 30 + group, 1, group,
                        EnemyKind.values()[(group + 1 + islandIndex) % 3], islandRandom
                ));
            }
            enemies.add(createEnemy(
                    islandIndex, 50, 3, -1,
                    EnemyKind.values()[islandIndex % 3], islandRandom
            ));
        }

        for (int i = 0; i < weatherDrops.length; i++) {
            weatherDrops[i] = new WeatherDrop();
            resetDrop(weatherDrops[i], islands[currentIsland].weather);
        }
    }

    private Enemy createEnemy(
            int islandIndex,
            int seed,
            int specialLevel,
            int group,
            EnemyKind kind,
            Random islandRandom
    ) {
        Island island = islands[islandIndex];
        float angle = (seed * 0.91f + islandIndex * 0.63f) % ((float) Math.PI * 2f);
        float distance = specialLevel == 3 ? 3f
                : 7f + islandRandom.nextFloat() * (island.radius - 11f);
        float hp = specialLevel == 3 ? 420f + islandIndex * 95f
                : specialLevel == 2 ? 170f + islandIndex * 35f
                : specialLevel == 1 ? 95f + islandIndex * 20f
                : 54f + islandIndex * 12f;
        float hueR = 0.25f + ((islandIndex * 37 + seed * 13) % 65) / 100f;
        float hueG = 0.12f + ((islandIndex * 19 + seed * 23) % 55) / 100f;
        float hueB = 0.16f + ((islandIndex * 29 + seed * 17) % 60) / 100f;
        return new Enemy(
                islandIndex,
                island.x + (float) Math.sin(angle) * distance,
                island.z + (float) Math.cos(angle) * distance,
                hp,
                specialLevel == 3 ? 2.05f : specialLevel == 2 ? 2.65f : 3.15f,
                specialLevel == 3 ? 1.65f : specialLevel == 2 ? 1.25f : 0.82f,
                kind,
                specialLevel,
                group,
                hueR,
                hueG,
                hueB,
                islandRandom.nextFloat() * 10f
        );
    }

    private void resetDrop(WeatherDrop drop, Weather weather) {
        drop.x = -18f + random.nextFloat() * 36f;
        drop.z = -18f + random.nextFloat() * 36f;
        drop.y = 7f + random.nextFloat() * 18f;
        drop.speed = weather == Weather.SNOW ? 2.2f + random.nextFloat() * 2f
                : weather == Weather.ASH ? 1.2f + random.nextFloat() * 1.5f
                : 11f + random.nextFloat() * 8f;
        drop.wind = weather == Weather.STORM ? -5f + random.nextFloat() * 2f
                : -0.5f + random.nextFloat();
    }

    private void resetForAdventure(boolean afterDefeat) {
        Island island = islands[currentIsland];
        playerX = island.x;
        playerZ = island.z;
        playerHeight = 0f;
        playerVerticalVelocity = 0f;
        playerHealth = playerMaxHealth;
        piloting = false;
        boatSpeed = 0f;
        if (afterDefeat) {
            reviveCurrentIslandEnemies();
        }
    }

    private void reviveCurrentIslandEnemies() {
        for (Enemy enemy : enemies) {
            if (enemy.islandIndex == currentIsland) {
                enemy.alive = true;
                enemy.hp = enemy.maxHp;
                enemy.attackCooldown = 0f;
            }
        }
    }

    private void loadGame() {
        selectedHero = preferences.getInt("hero", 0);
        currentIsland = Math.max(0, Math.min(islands.length - 1, preferences.getInt("island", 0)));
        Island island = islands[currentIsland];
        playerX = preferences.getFloat("player_x", island.x);
        playerZ = preferences.getFloat("player_z", island.z);
        playerHealth = preferences.getFloat("health", playerMaxHealth);
        boatX = preferences.getFloat("boat_x", islands[0].x + islands[0].radius + 3.2f);
        boatZ = preferences.getFloat("boat_z", islands[0].z);
        boatHeading = preferences.getFloat("boat_heading", 1.57f);
        cameraX = playerX;
        cameraY = island.height + 6f;
        cameraZ = playerZ - 10f;
    }

    private void saveGame() {
        preferences.edit()
                .putInt("hero", selectedHero)
                .putInt("island", currentIsland)
                .putFloat("player_x", playerX)
                .putFloat("player_z", playerZ)
                .putFloat("health", playerHealth)
                .putFloat("boat_x", boatX)
                .putFloat("boat_z", boatZ)
                .putFloat("boat_heading", boatHeading)
                .apply();
    }

    private int livingCommanders(int islandIndex) {
        int count = 0;
        for (Enemy enemy : enemies) {
            if (enemy.alive && enemy.islandIndex == islandIndex && enemy.specialLevel == 2) {
                count++;
            }
        }
        return count;
    }

    private int livingNakama(int islandIndex, int group) {
        int count = 0;
        for (Enemy enemy : enemies) {
            if (enemy.alive && enemy.islandIndex == islandIndex
                    && enemy.specialLevel == 1 && enemy.group == group) {
                count++;
            }
        }
        return count;
    }

    private Enemy bossForIsland(int islandIndex) {
        for (Enemy enemy : enemies) {
            if (enemy.islandIndex == islandIndex && enemy.specialLevel == 3) {
                return enemy;
            }
        }
        return null;
    }

    private Island nearestIsland(float x, float z) {
        Island nearest = islands[0];
        float best = Float.MAX_VALUE;
        for (Island island : islands) {
            float distance = GameMath.distance(x, z, island.x, island.z);
            if (distance < best) {
                best = distance;
                nearest = island;
            }
        }
        return nearest;
    }

    private int indexOfIsland(Island target) {
        for (int i = 0; i < islands.length; i++) {
            if (islands[i] == target) {
                return i;
            }
        }
        return 0;
    }

    private float waveAt(float x, float z) {
        return ((float) Math.sin(x * 0.13f + elapsed * 1.5f)
                + (float) Math.cos(z * 0.11f - elapsed * 1.1f)) * 0.08f;
    }

    private float[] heroColor(int hero) {
        return switch (hero) {
            case 1 -> new float[]{0.12f, 0.55f, 0.92f};
            case 2 -> new float[]{0.12f, 0.72f, 0.42f};
            default -> new float[]{0.78f, 0.12f, 0.12f};
        };
    }

    private float[] fogColor(Weather weather) {
        return switch (weather) {
            case SNOW -> new float[]{0.72f, 0.82f, 0.88f};
            case STORM -> new float[]{0.20f, 0.27f, 0.34f};
            case ASH -> new float[]{0.35f, 0.25f, 0.22f};
            case RAIN -> new float[]{0.36f, 0.48f, 0.58f};
            case MIST -> new float[]{0.66f, 0.69f, 0.62f};
            default -> new float[]{0.42f, 0.68f, 0.86f};
        };
    }

    private float fogDensity(Weather weather) {
        return switch (weather) {
            case STORM -> 0.030f;
            case ASH, MIST -> 0.026f;
            case RAIN, SNOW -> 0.020f;
            default -> 0.010f;
        };
    }

    private void speak(String text) {
        if (narrator != null) {
            narrator.speak(text);
        }
    }

    private void setIdentity() {
        Matrix.setIdentityM(model, 0);
    }

    private void setColor(float r, float g, float b, float a) {
        color[0] = r;
        color[1] = g;
        color[2] = b;
        color[3] = a;
    }

    private static int createProgram(String vertexSource, String fragmentSource) {
        int vertex = compileShader(GLES20.GL_VERTEX_SHADER, vertexSource);
        int fragment = compileShader(GLES20.GL_FRAGMENT_SHADER, fragmentSource);
        int program = GLES20.glCreateProgram();
        GLES20.glAttachShader(program, vertex);
        GLES20.glAttachShader(program, fragment);
        GLES20.glLinkProgram(program);
        int[] status = new int[1];
        GLES20.glGetProgramiv(program, GLES20.GL_LINK_STATUS, status, 0);
        if (status[0] == 0) {
            String log = GLES20.glGetProgramInfoLog(program);
            GLES20.glDeleteProgram(program);
            throw new IllegalStateException("Échec liaison shader: " + log);
        }
        GLES20.glDeleteShader(vertex);
        GLES20.glDeleteShader(fragment);
        return program;
    }

    private static int compileShader(int type, String source) {
        int shader = GLES20.glCreateShader(type);
        GLES20.glShaderSource(shader, source);
        GLES20.glCompileShader(shader);
        int[] status = new int[1];
        GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, status, 0);
        if (status[0] == 0) {
            String log = GLES20.glGetShaderInfoLog(shader);
            GLES20.glDeleteShader(shader);
            throw new IllegalStateException("Échec compilation shader: " + log);
        }
        return shader;
    }

    private static final String VERTEX_SHADER =
            "uniform mat4 uMvp;\n" +
            "uniform mat4 uModel;\n" +
            "uniform vec3 uCamera;\n" +
            "uniform float uTime;\n" +
            "uniform float uWave;\n" +
            "attribute vec3 aPosition;\n" +
            "attribute vec3 aNormal;\n" +
            "varying float vLight;\n" +
            "varying float vDistance;\n" +
            "void main() {\n" +
            "  vec3 p = aPosition;\n" +
            "  if (uWave > 0.0) {\n" +
            "    p.y += (sin(p.x * 10.0 + uTime * 1.5) + cos(p.z * 9.0 - uTime * 1.1)) * uWave * 0.055;\n" +
            "  }\n" +
            "  vec4 world = uModel * vec4(p, 1.0);\n" +
            "  vec3 normal = normalize(mat3(uModel) * aNormal);\n" +
            "  vec3 lightDirection = normalize(vec3(-0.35, 0.85, 0.28));\n" +
            "  vLight = 0.34 + max(dot(normal, lightDirection), 0.0) * 0.66;\n" +
            "  vDistance = distance(world.xyz, uCamera);\n" +
            "  gl_Position = uMvp * vec4(p, 1.0);\n" +
            "}\n";

    private static final String FRAGMENT_SHADER =
            "precision mediump float;\n" +
            "uniform vec4 uColor;\n" +
            "uniform vec3 uFogColor;\n" +
            "uniform float uFogDensity;\n" +
            "varying float vLight;\n" +
            "varying float vDistance;\n" +
            "void main() {\n" +
            "  float fog = clamp(exp(-uFogDensity * uFogDensity * vDistance * vDistance), 0.0, 1.0);\n" +
            "  vec3 lit = uColor.rgb * vLight;\n" +
            "  vec3 finalColor = mix(uFogColor, lit, fog);\n" +
            "  gl_FragColor = vec4(finalColor, uColor.a);\n" +
            "}\n";

    private static final class Island {
        final String name;
        final float x;
        final float z;
        final float radius;
        final float height;
        final float r;
        final float g;
        final float b;
        final Weather weather;

        Island(String name, float x, float z, float radius, float height,
               float r, float g, float b, Weather weather) {
            this.name = name;
            this.x = x;
            this.z = z;
            this.radius = radius;
            this.height = height;
            this.r = r;
            this.g = g;
            this.b = b;
            this.weather = weather;
        }
    }

    private static final class Enemy {
        final int islandIndex;
        final float maxHp;
        final float speed;
        final float radius;
        final EnemyKind kind;
        final int specialLevel;
        final int group;
        final float r;
        final float g;
        final float b;
        final float phase;
        float x;
        float z;
        float hp;
        float attackCooldown;
        float hitFlash;
        float stun;
        boolean alive = true;

        Enemy(int islandIndex, float x, float z, float hp, float speed, float radius,
              EnemyKind kind, int specialLevel, int group,
              float r, float g, float b, float phase) {
            this.islandIndex = islandIndex;
            this.x = x;
            this.z = z;
            this.hp = hp;
            this.maxHp = hp;
            this.speed = speed;
            this.radius = radius;
            this.kind = kind;
            this.specialLevel = specialLevel;
            this.group = group;
            this.r = r;
            this.g = g;
            this.b = b;
            this.phase = phase;
        }
    }

    private static final class Projectile {
        float x;
        float y;
        float z;
        final float vx;
        float vy;
        final float vz;
        final boolean fromPlayer;
        final float damage;
        float life = 3.2f;

        Projectile(float x, float y, float z, float vx, float vy, float vz,
                   boolean fromPlayer, float damage) {
            this.x = x;
            this.y = y;
            this.z = z;
            this.vx = vx;
            this.vy = vy;
            this.vz = vz;
            this.fromPlayer = fromPlayer;
            this.damage = damage;
        }
    }

    private static final class Rock {
        final int islandIndex;
        final float x;
        final float z;
        final float radius;
        final float rotation;

        Rock(int islandIndex, float x, float z, float radius, float rotation) {
            this.islandIndex = islandIndex;
            this.x = x;
            this.z = z;
            this.radius = radius;
            this.rotation = rotation;
        }
    }

    private static final class Tree {
        final int islandIndex;
        final float x;
        final float z;
        final float height;

        Tree(int islandIndex, float x, float z, float height) {
            this.islandIndex = islandIndex;
            this.x = x;
            this.z = z;
            this.height = height;
        }
    }

    private static final class WeatherDrop {
        float x;
        float y;
        float z;
        float speed;
        float wind;
    }

    private static final class Mesh {
        final FloatBuffer vertices;
        final ShortBuffer indices;
        final int indexCount;

        Mesh(float[] vertexData, short[] indexData) {
            vertices = ByteBuffer.allocateDirect(vertexData.length * 4)
                    .order(ByteOrder.nativeOrder())
                    .asFloatBuffer();
            vertices.put(vertexData).position(0);
            indices = ByteBuffer.allocateDirect(indexData.length * 2)
                    .order(ByteOrder.nativeOrder())
                    .asShortBuffer();
            indices.put(indexData).position(0);
            indexCount = indexData.length;
        }

        static Mesh cube() {
            float[] v = {
                    -0.5f,-0.5f, 0.5f, 0,0,1,   0.5f,-0.5f, 0.5f, 0,0,1,   0.5f,0.5f,0.5f,0,0,1,   -0.5f,0.5f,0.5f,0,0,1,
                     0.5f,-0.5f,-0.5f, 0,0,-1, -0.5f,-0.5f,-0.5f,0,0,-1, -0.5f,0.5f,-0.5f,0,0,-1, 0.5f,0.5f,-0.5f,0,0,-1,
                    -0.5f,-0.5f,-0.5f,-1,0,0,  -0.5f,-0.5f,0.5f,-1,0,0,  -0.5f,0.5f,0.5f,-1,0,0,  -0.5f,0.5f,-0.5f,-1,0,0,
                     0.5f,-0.5f,0.5f,1,0,0,     0.5f,-0.5f,-0.5f,1,0,0,   0.5f,0.5f,-0.5f,1,0,0,    0.5f,0.5f,0.5f,1,0,0,
                    -0.5f,0.5f,0.5f,0,1,0,      0.5f,0.5f,0.5f,0,1,0,     0.5f,0.5f,-0.5f,0,1,0,   -0.5f,0.5f,-0.5f,0,1,0,
                    -0.5f,-0.5f,-0.5f,0,-1,0,   0.5f,-0.5f,-0.5f,0,-1,0,  0.5f,-0.5f,0.5f,0,-1,0,  -0.5f,-0.5f,0.5f,0,-1,0
            };
            short[] i = {
                    0,1,2, 0,2,3, 4,5,6, 4,6,7, 8,9,10, 8,10,11,
                    12,13,14, 12,14,15, 16,17,18, 16,18,19, 20,21,22, 20,22,23
            };
            return new Mesh(v, i);
        }

        static Mesh verticalQuad() {
            float[] v = {
                    -0.5f,-0.5f,0f, 0,0,1,
                     0.5f,-0.5f,0f, 0,0,1,
                     0.5f, 0.5f,0f, 0,0,1,
                    -0.5f, 0.5f,0f, 0,0,1
            };
            return new Mesh(v, new short[]{0,1,2,0,2,3});
        }

        static Mesh flatQuad() {
            float[] v = {
                    -0.5f,0f,-0.5f, 0,1,0,
                     0.5f,0f,-0.5f, 0,1,0,
                     0.5f,0f, 0.5f, 0,1,0,
                    -0.5f,0f, 0.5f, 0,1,0
            };
            return new Mesh(v, new short[]{0,1,2,0,2,3});
        }

        static Mesh pyramid() {
            float[] v = {
                    -0.5f,0f,0.5f, 0,0.5f,0.8f,  0.5f,0f,0.5f,0,0.5f,0.8f, 0f,1f,0f,0,0.5f,0.8f,
                     0.5f,0f,0.5f, 0.8f,0.5f,0,  0.5f,0f,-0.5f,0.8f,0.5f,0, 0f,1f,0f,0.8f,0.5f,0,
                     0.5f,0f,-0.5f, 0,0.5f,-0.8f, -0.5f,0f,-0.5f,0,0.5f,-0.8f, 0f,1f,0f,0,0.5f,-0.8f,
                    -0.5f,0f,-0.5f,-0.8f,0.5f,0, -0.5f,0f,0.5f,-0.8f,0.5f,0, 0f,1f,0f,-0.8f,0.5f,0
            };
            return new Mesh(v, new short[]{0,1,2,3,4,5,6,7,8,9,10,11});
        }

        static Mesh cylinder(int segments) {
            int vertexCount = segments * 4 + 2;
            float[] v = new float[vertexCount * 6];
            short[] idx = new short[segments * 12];
            int vp = 0;
            for (int s = 0; s < segments; s++) {
                float angle = (float) (Math.PI * 2.0 * s / segments);
                float x = (float) Math.sin(angle);
                float z = (float) Math.cos(angle);
                vp = put(v, vp, x, 0.5f, z, x, 0f, z);
                vp = put(v, vp, x, -0.5f, z, x, 0f, z);
                vp = put(v, vp, x, 0.5f, z, 0f, 1f, 0f);
                vp = put(v, vp, x, -0.5f, z, 0f, -1f, 0f);
            }
            int topCenter = segments * 4;
            int bottomCenter = topCenter + 1;
            vp = put(v, vp, 0f, 0.5f, 0f, 0f, 1f, 0f);
            put(v, vp, 0f, -0.5f, 0f, 0f, -1f, 0f);
            int ip = 0;
            for (int s = 0; s < segments; s++) {
                int next = (s + 1) % segments;
                short a = (short) (s * 4);
                short b = (short) (s * 4 + 1);
                short c = (short) (next * 4);
                short d = (short) (next * 4 + 1);
                idx[ip++] = a; idx[ip++] = b; idx[ip++] = c;
                idx[ip++] = c; idx[ip++] = b; idx[ip++] = d;
                idx[ip++] = (short) topCenter; idx[ip++] = (short) (s * 4 + 2); idx[ip++] = (short) (next * 4 + 2);
                idx[ip++] = (short) bottomCenter; idx[ip++] = (short) (next * 4 + 3); idx[ip++] = (short) (s * 4 + 3);
            }
            return new Mesh(v, idx);
        }

        static Mesh grid(int cells) {
            int side = cells + 1;
            float[] v = new float[side * side * 6];
            short[] idx = new short[cells * cells * 6];
            int vp = 0;
            for (int z = 0; z <= cells; z++) {
                for (int x = 0; x <= cells; x++) {
                    float px = x / (float) cells - 0.5f;
                    float pz = z / (float) cells - 0.5f;
                    vp = put(v, vp, px, 0f, pz, 0f, 1f, 0f);
                }
            }
            int ip = 0;
            for (int z = 0; z < cells; z++) {
                for (int x = 0; x < cells; x++) {
                    short a = (short) (z * side + x);
                    short b = (short) (a + 1);
                    short c = (short) (a + side);
                    short d = (short) (c + 1);
                    idx[ip++] = a; idx[ip++] = c; idx[ip++] = b;
                    idx[ip++] = b; idx[ip++] = c; idx[ip++] = d;
                }
            }
            return new Mesh(v, idx);
        }

        private static int put(float[] data, int index,
                               float x, float y, float z,
                               float nx, float ny, float nz) {
            data[index++] = x;
            data[index++] = y;
            data[index++] = z;
            data[index++] = nx;
            data[index++] = ny;
            data[index++] = nz;
            return index;
        }
    }
}
