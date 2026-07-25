#include "CHKBoatPawn.h"

#include "Camera/CameraComponent.h"
#include "Components/StaticMeshComponent.h"
#include "GameFramework/SpringArmComponent.h"

ACHKBoatPawn::ACHKBoatPawn()
{
    PrimaryActorTick.bCanEverTick = true;

    Hull = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Hull"));
    SetRootComponent(Hull);
    Hull->SetSimulatePhysics(false);
    Hull->SetCollisionProfileName(TEXT("Pawn"));

    CameraBoom = CreateDefaultSubobject<USpringArmComponent>(TEXT("CameraBoom"));
    CameraBoom->SetupAttachment(Hull);
    CameraBoom->TargetArmLength = 1780.0f;
    CameraBoom->SocketOffset = FVector(165.0f, 0.0f, 330.0f);
    CameraBoom->bUsePawnControlRotation = true;
    CameraBoom->bDoCollisionTest = true;
    CameraBoom->ProbeSize = 34.0f;
    CameraBoom->bEnableCameraLag = true;
    CameraBoom->CameraLagSpeed = 9.5f;

    BoatCamera = CreateDefaultSubobject<UCameraComponent>(TEXT("BoatCamera"));
    BoatCamera->SetupAttachment(CameraBoom, USpringArmComponent::SocketName);
    BoatCamera->bUsePawnControlRotation = false;
    BoatCamera->FieldOfView = 61.0f;
}

void ACHKBoatPawn::BeginPlay()
{
    Super::BeginPlay();
}

void ACHKBoatPawn::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);

    WaveTime += DeltaSeconds;

    const float TargetSpeed = ThrottleInput >= 0.0f
        ? ThrottleInput * MaximumForwardSpeed
        : ThrottleInput * MaximumReverseSpeed;

    const float Response = FMath::IsNearlyZero(ThrottleInput) ? Acceleration * 0.42f : Acceleration;
    CurrentSpeed = FMath::FInterpConstantTo(CurrentSpeed, TargetSpeed, DeltaSeconds, Response);

    const float SpeedRatio = FMath::Clamp(FMath::Abs(CurrentSpeed) / MaximumForwardSpeed, 0.0f, 1.0f);
    const float SteeringGrip = FMath::Lerp(0.35f, 1.0f, SpeedRatio);
    const float ReverseDirection = CurrentSpeed < -10.0f ? -1.0f : 1.0f;
    const float YawDelta = SteeringInput * TurnSpeedDegrees * SteeringGrip * ReverseDirection * DeltaSeconds;

    AddActorLocalRotation(FRotator(0.0f, YawDelta, 0.0f));

    FHitResult Hit;
    AddActorWorldOffset(GetActorForwardVector() * CurrentSpeed * DeltaSeconds, true, &Hit);
    if (Hit.bBlockingHit)
    {
        CurrentSpeed *= 0.22f;
    }

    FVector Position = GetActorLocation();
    const float WaveHeight = FMath::Sin(WaveTime * 1.55f + Position.X * 0.0009f) * 12.0f
        + FMath::Sin(WaveTime * 2.15f + Position.Y * 0.0013f) * 5.0f;
    Position.Z = FMath::FInterpTo(Position.Z, WaterLevel + WaveHeight, DeltaSeconds, 4.8f);
    SetActorLocation(Position, false);

    const float TargetRoll = -SteeringInput * 5.2f * SpeedRatio + FMath::Sin(WaveTime * 1.4f) * 1.8f;
    const float TargetPitch = FMath::Sin(WaveTime * 1.1f + Position.X * 0.0006f) * 1.5f;
    FRotator Rotation = GetActorRotation();
    Rotation.Roll = FMath::FInterpTo(Rotation.Roll, TargetRoll, DeltaSeconds, 3.2f);
    Rotation.Pitch = FMath::FInterpTo(Rotation.Pitch, TargetPitch, DeltaSeconds, 2.8f);
    SetActorRotation(Rotation);
}

void ACHKBoatPawn::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
    Super::SetupPlayerInputComponent(PlayerInputComponent);

    PlayerInputComponent->BindAxis(TEXT("BoatThrottle"), this, &ACHKBoatPawn::Throttle);
    PlayerInputComponent->BindAxis(TEXT("BoatSteer"), this, &ACHKBoatPawn::Steering);
    PlayerInputComponent->BindAxis(TEXT("TurnCamera"), this, &ACHKBoatPawn::TurnCamera);
    PlayerInputComponent->BindAxis(TEXT("LookCamera"), this, &ACHKBoatPawn::LookCamera);
}

void ACHKBoatPawn::Throttle(float Value)
{
    ThrottleInput = FMath::Clamp(Value, -1.0f, 1.0f);
}

void ACHKBoatPawn::Steering(float Value)
{
    SteeringInput = FMath::Clamp(Value, -1.0f, 1.0f);
}

void ACHKBoatPawn::TurnCamera(float Value)
{
    AddControllerYawInput(Value);
}

void ACHKBoatPawn::LookCamera(float Value)
{
    AddControllerPitchInput(Value);
}
