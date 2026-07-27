package fr.chk.piratewarrior;

import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.Rect;
import android.graphics.RectF;

/**
 * Personnage 2.5D composé de véritables frames bitmap transparentes.
 * Les frames sont générées une seule fois au chargement, puis réutilisées sans allocation
 * dans la boucle de rendu. Cela conserve l'aspect sprite demandé tout en restant léger sur Android.
 */
public final class Character25D {
    public enum Pose {
        IDLE(4, 4.5f),
        WALK(6, 9f),
        RUN(6, 13f),
        ATTACK(5, 15f),
        JUMP(3, 8f),
        PILOT(4, 6f),
        HURT(3, 10f);

        final int frameCount;
        final float framesPerSecond;

        Pose(int frameCount, float framesPerSecond) {
            this.frameCount = frameCount;
            this.framesPerSecond = framesPerSecond;
        }
    }

    private static final int FRAME_WIDTH = 128;
    private static final int FRAME_HEIGHT = 192;
    private static final int FOOT_Y = 171;

    private final int heroIndex;
    private final Bitmap[][] frames = new Bitmap[Pose.values().length][];
    private final Paint drawPaint = new Paint(Paint.ANTI_ALIAS_FLAG | Paint.FILTER_BITMAP_FLAG);
    private final Rect source = new Rect(0, 0, FRAME_WIDTH, FRAME_HEIGHT);
    private boolean released;

    public Character25D(int heroIndex) {
        this.heroIndex = Math.max(0, Math.min(2, heroIndex));
        for (Pose pose : Pose.values()) {
            Bitmap[] poseFrames = new Bitmap[pose.frameCount];
            for (int frame = 0; frame < poseFrames.length; frame++) {
                poseFrames[frame] = createFrame(pose, frame, poseFrames.length);
            }
            frames[pose.ordinal()] = poseFrames;
        }
    }

    public void draw(
            Canvas canvas,
            Pose pose,
            float animationSeconds,
            float centerX,
            float feetY,
            float height,
            boolean facingRight,
            float alpha
    ) {
        if (released || canvas == null || height <= 1f) return;
        Bitmap[] poseFrames = frames[pose.ordinal()];
        int frame = Math.max(0, (int) (animationSeconds * pose.framesPerSecond)) % poseFrames.length;
        Bitmap bitmap = poseFrames[frame];
        float width = height * FRAME_WIDTH / FRAME_HEIGHT;
        RectF destination = new RectF(centerX - width * 0.5f, feetY - height, centerX + width * 0.5f, feetY);
        drawPaint.setAlpha((int) (GameMath.clamp(alpha, 0f, 1f) * 255f));

        if (facingRight) {
            canvas.drawBitmap(bitmap, source, destination, drawPaint);
        } else {
            canvas.save();
            canvas.scale(-1f, 1f, centerX, feetY);
            canvas.drawBitmap(bitmap, source, destination, drawPaint);
            canvas.restore();
        }
        drawPaint.setAlpha(255);
    }

    public void release() {
        if (released) return;
        released = true;
        for (Bitmap[] poseFrames : frames) {
            if (poseFrames == null) continue;
            for (Bitmap bitmap : poseFrames) {
                if (bitmap != null && !bitmap.isRecycled()) bitmap.recycle();
            }
        }
    }

    private Bitmap createFrame(Pose pose, int frame, int count) {
        Bitmap bitmap = Bitmap.createBitmap(FRAME_WIDTH, FRAME_HEIGHT, Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap);
        Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        Path path = new Path();

        float phase = (float) (frame * Math.PI * 2.0 / Math.max(1, count));
        float bob = pose == Pose.IDLE ? (float) Math.sin(phase) * 1.8f : 0f;
        float stride = 0f;
        float armSwing = 0f;
        float lean = 0f;
        float jump = 0f;

        if (pose == Pose.WALK) {
            stride = (float) Math.sin(phase) * 8f;
            armSwing = -stride * 0.75f;
            bob = Math.abs((float) Math.sin(phase)) * -2f;
        } else if (pose == Pose.RUN) {
            stride = (float) Math.sin(phase) * 13f;
            armSwing = -stride * 0.9f;
            lean = 5f;
            bob = Math.abs((float) Math.sin(phase)) * -4f;
        } else if (pose == Pose.ATTACK) {
            float attack = frame / (float) Math.max(1, count - 1);
            armSwing = attack < 0.5f ? -18f + attack * 70f : 24f - (attack - 0.5f) * 30f;
            lean = attack * 8f;
        } else if (pose == Pose.JUMP) {
            jump = frame == 1 ? 10f : 4f;
            stride = frame == 1 ? 8f : 3f;
            armSwing = -8f;
        } else if (pose == Pose.PILOT) {
            bob = (float) Math.sin(phase) * 1.3f;
            armSwing = 8f;
        } else if (pose == Pose.HURT) {
            lean = -7f + frame * 2f;
            armSwing = 13f;
        }

        float footY = FOOT_Y - jump + bob;
        float hipY = footY - 50f;
        float chestY = hipY - 42f;
        float headY = chestY - 37f;
        float centerX = 62f + lean;

        int skin = heroIndex == 0 ? Color.rgb(112, 69, 45)
                : heroIndex == 1 ? Color.rgb(128, 82, 52)
                : Color.rgb(121, 77, 50);
        int skinLight = lighten(skin, 0.2f);
        int coat = heroIndex == 0 ? Color.rgb(163, 38, 39)
                : heroIndex == 1 ? Color.rgb(30, 126, 204)
                : Color.rgb(38, 159, 91);
        int coatDark = darken(coat, 0.34f);
        int trouser = heroIndex == 1 ? Color.rgb(35, 42, 58) : Color.rgb(39, 45, 49);

        drawGroundShadow(canvas, paint, centerX, FOOT_Y + 2f, pose == Pose.JUMP ? 17f : 27f, pose == Pose.JUMP ? 22 : 52);

        float leftFootX = centerX - 13f + stride;
        float rightFootX = centerX + 13f - stride;
        drawLeg(canvas, paint, centerX - 11f, hipY + 5f, leftFootX, footY, trouser, pose == Pose.JUMP);
        drawLeg(canvas, paint, centerX + 11f, hipY + 5f, rightFootX, footY, darken(trouser, 0.1f), pose == Pose.JUMP);

        paint.setStyle(Paint.Style.FILL);
        paint.setColor(coatDark);
        canvas.drawRoundRect(new RectF(centerX - 29f, chestY - 4f, centerX + 30f, hipY + 13f), 17f, 17f, paint);
        paint.setColor(coat);
        canvas.drawRoundRect(new RectF(centerX - 24f, chestY - 6f, centerX + 23f, hipY + 8f), 15f, 15f, paint);
        paint.setColor(lighten(coat, 0.25f));
        canvas.drawRoundRect(new RectF(centerX - 18f, chestY - 1f, centerX - 10f, hipY - 3f), 4f, 4f, paint);

        if (heroIndex == 0) {
            paint.setColor(Color.rgb(235, 197, 86));
            paint.setStrokeWidth(3f);
            canvas.drawLine(centerX - 17f, chestY + 8f, centerX + 15f, hipY - 2f, paint);
        } else if (heroIndex == 1) {
            paint.setColor(Color.rgb(215, 239, 255));
            canvas.drawRect(centerX - 4f, chestY, centerX + 4f, hipY + 6f, paint);
        } else {
            paint.setColor(Color.rgb(232, 191, 68));
            canvas.drawCircle(centerX, chestY + 14f, 6f, paint);
        }

        float leftHandX = centerX - 35f - armSwing * 0.45f;
        float leftHandY = chestY + 35f + Math.abs(armSwing) * 0.15f;
        float rightHandX = centerX + 35f + armSwing;
        float rightHandY = chestY + 33f - Math.min(16f, armSwing * 0.28f);
        if (pose == Pose.PILOT) {
            leftHandX = centerX - 18f;
            rightHandX = centerX + 18f;
            leftHandY = rightHandY = chestY + 31f;
        }

        drawArm(canvas, paint, centerX - 22f, chestY + 14f, leftHandX, leftHandY, coatDark, skin);
        drawArm(canvas, paint, centerX + 22f, chestY + 14f, rightHandX, rightHandY, coat, skin);
        drawHeroWeapon(canvas, paint, path, pose, rightHandX, rightHandY, armSwing);

        paint.setColor(darken(skin, 0.18f));
        canvas.drawCircle(centerX + 2f, headY + 2f, 22f, paint);
        paint.setColor(skin);
        canvas.drawCircle(centerX, headY, 21f, paint);
        paint.setColor(skinLight);
        canvas.drawOval(new RectF(centerX - 12f, headY - 13f, centerX - 4f, headY + 9f), paint);

        drawHairAndIdentity(canvas, paint, path, centerX, headY);
        drawFace(canvas, paint, centerX, headY, pose == Pose.HURT);

        if (pose == Pose.HURT) {
            paint.setColor(Color.argb(90, 255, 255, 255));
            canvas.drawCircle(centerX, chestY + 22f, 48f, paint);
        }
        return bitmap;
    }

    private void drawLeg(Canvas canvas, Paint paint, float hipX, float hipY, float footX, float footY, int color, boolean tucked) {
        paint.setColor(color);
        paint.setStrokeCap(Paint.Cap.ROUND);
        paint.setStrokeWidth(15f);
        float kneeX = (hipX + footX) * 0.5f + (tucked ? 6f : 0f);
        float kneeY = (hipY + footY) * 0.5f - (tucked ? 8f : 0f);
        canvas.drawLine(hipX, hipY, kneeX, kneeY, paint);
        canvas.drawLine(kneeX, kneeY, footX, footY - 5f, paint);
        paint.setColor(Color.rgb(42, 31, 27));
        paint.setStrokeWidth(10f);
        canvas.drawLine(footX - 2f, footY - 3f, footX + 10f, footY - 3f, paint);
    }

    private void drawArm(Canvas canvas, Paint paint, float shoulderX, float shoulderY, float handX, float handY, int sleeve, int skin) {
        paint.setStrokeCap(Paint.Cap.ROUND);
        paint.setColor(darken(sleeve, 0.15f));
        paint.setStrokeWidth(16f);
        float elbowX = (shoulderX + handX) * 0.5f;
        float elbowY = (shoulderY + handY) * 0.5f + 5f;
        canvas.drawLine(shoulderX, shoulderY, elbowX, elbowY, paint);
        paint.setColor(sleeve);
        paint.setStrokeWidth(13f);
        canvas.drawLine(elbowX, elbowY, handX, handY, paint);
        paint.setColor(skin);
        canvas.drawCircle(handX, handY, 7f, paint);
    }

    private void drawHeroWeapon(Canvas canvas, Paint paint, Path path, Pose pose, float handX, float handY, float swing) {
        if (heroIndex == 0) {
            float blade = pose == Pose.ATTACK ? 48f : 36f;
            paint.setColor(Color.rgb(214, 225, 229));
            paint.setStrokeWidth(5f);
            canvas.drawLine(handX, handY, handX + blade, handY - 20f - swing * 0.25f, paint);
            paint.setColor(Color.rgb(236, 192, 70));
            paint.setStrokeWidth(7f);
            canvas.drawLine(handX - 5f, handY + 2f, handX + 6f, handY - 3f, paint);
        } else if (heroIndex == 1) {
            paint.setColor(Color.argb(210, 130, 220, 255));
            paint.setStrokeWidth(4f);
            path.reset();
            path.moveTo(handX, handY);
            path.lineTo(handX + 14f, handY - 11f);
            path.lineTo(handX + 9f, handY - 25f);
            path.lineTo(handX + 27f, handY - 37f);
            canvas.drawPath(path, paint);
        } else {
            paint.setColor(Color.rgb(184, 193, 199));
            paint.setStrokeWidth(6f);
            canvas.drawLine(handX, handY, handX + 28f, handY - 26f, paint);
            paint.setStyle(Paint.Style.STROKE);
            canvas.drawCircle(handX + 32f, handY - 30f, 9f, paint);
            paint.setStyle(Paint.Style.FILL);
        }
    }

    private void drawHairAndIdentity(Canvas canvas, Paint paint, Path path, float x, float y) {
        if (heroIndex == 0) {
            paint.setColor(Color.rgb(29, 23, 21));
            canvas.drawArc(new RectF(x - 22f, y - 27f, x + 22f, y + 2f), 180f, 180f, true, paint);
            canvas.drawRoundRect(new RectF(x - 18f, y + 8f, x + 18f, y + 27f), 9f, 9f, paint);
            paint.setColor(Color.rgb(196, 45, 43));
            canvas.drawRect(x - 29f, y - 18f, x + 29f, y - 12f, paint);
            paint.setColor(Color.rgb(233, 194, 72));
            canvas.drawCircle(x, y - 15f, 4f, paint);
        } else if (heroIndex == 1) {
            paint.setColor(Color.rgb(25, 22, 21));
            for (int i = 0; i < 7; i++) {
                float ox = -19f + i * 6.3f;
                canvas.drawOval(new RectF(x + ox - 4f, y - 33f - Math.abs(3 - i) * 2f, x + ox + 5f, y - 7f), paint);
            }
            paint.setColor(Color.rgb(48, 154, 228));
            canvas.drawRect(x - 23f, y - 15f, x + 23f, y - 10f, paint);
        } else {
            paint.setColor(Color.rgb(32, 25, 22));
            canvas.drawArc(new RectF(x - 24f, y - 29f, x + 24f, y + 3f), 180f, 180f, true, paint);
            paint.setColor(Color.rgb(221, 184, 62));
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(4f);
            canvas.drawCircle(x - 9f, y - 4f, 8f, paint);
            canvas.drawCircle(x + 9f, y - 4f, 8f, paint);
            canvas.drawLine(x - 1f, y - 4f, x + 1f, y - 4f, paint);
            paint.setStyle(Paint.Style.FILL);
        }
    }

    private void drawFace(Canvas canvas, Paint paint, float x, float y, boolean hurt) {
        paint.setColor(Color.WHITE);
        canvas.drawOval(new RectF(x - 13f, y - 8f, x - 4f, y + 1f), paint);
        canvas.drawOval(new RectF(x + 4f, y - 8f, x + 13f, y + 1f), paint);
        paint.setColor(Color.rgb(20, 19, 18));
        canvas.drawCircle(x - 8f, y - 3f, 2.5f, paint);
        canvas.drawCircle(x + 8f, y - 3f, 2.5f, paint);
        paint.setStrokeWidth(2f);
        if (hurt) {
            canvas.drawLine(x - 6f, y + 10f, x + 7f, y + 7f, paint);
        } else {
            canvas.drawArc(new RectF(x - 8f, y + 4f, x + 8f, y + 14f), 12f, 156f, false, paint);
        }
    }

    private static void drawGroundShadow(Canvas canvas, Paint paint, float x, float y, float radius, int alpha) {
        paint.setColor(Color.argb(alpha, 0, 0, 0));
        canvas.drawOval(new RectF(x - radius, y - 6f, x + radius, y + 6f), paint);
    }

    private static int darken(int color, float amount) {
        float factor = 1f - GameMath.clamp(amount, 0f, 1f);
        return Color.rgb((int) (Color.red(color) * factor), (int) (Color.green(color) * factor), (int) (Color.blue(color) * factor));
    }

    private static int lighten(int color, float amount) {
        float a = GameMath.clamp(amount, 0f, 1f);
        return Color.rgb(
                (int) (Color.red(color) + (255 - Color.red(color)) * a),
                (int) (Color.green(color) + (255 - Color.green(color)) * a),
                (int) (Color.blue(color) + (255 - Color.blue(color)) * a)
        );
    }
}
