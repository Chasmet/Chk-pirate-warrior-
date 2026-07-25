#include "CHKBoatPawn.h"

#include "CHKCharacter.h"
#include "Camera/CameraComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "GameFramework/SpringArmComponent.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "UObject/ConstructorHelpers.h"

ACHKBoatPawn::ACHKBoatPawn()
{
    PrimaryActorTick.bCanEverTick = true;
    AutoPossessAI = EAutoPossessAI::Disabled;

    static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeMesh(TEXT("/Engine/BasicShapes/Cube.Cube"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> CylinderMesh(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> PlaneMesh(TEXT("/Engine/BasicShapes/Plane.Plane"));

    Hull = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Hull"));
    SetRootComponent(Hull);
    Hull->SetSimulatePhysics(false);
    Hull->SetCollisionProfileName(TEXT("Pawn"));
    Hull->SetRelativeScale3D(FVector(5.8f, 2.15f, 0.78f));
    if (CubeMesh.Succeeded())
    {
        Hull->SetStaticMesh(CubeMesh.Object);
    }

    Deck = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Deck"));
    Deck->SetupAttachment(Hull);
    Deck->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    Deck->SetRelativeLocation(FVector(0.0f, 0.0f, 86.0f));
    Deck->SetRelativeScale3D(FVector(0.92f, 0.92f, 0.18f));
    if (CubeMesh.Succeeded())
    {
        Deck->SetStaticMesh(CubeMesh.Object);
    }

    Mast = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Mast"));
    Mast->SetupAttachment(Hull);
    Mast->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    Mast->SetRelativeLocation(FVector(30.0f, 0.0f, 290.0f));
    Mast->SetRelativeScale3D(FVector(0.06f, 0.06f, 4.7f));
    if (CylinderMesh.Succeeded())
    {
        Mast->SetStaticMesh(CylinderMesh.Object);
    }

    Sail = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Sail"));
    Sail->SetupAttachment(Mast);
    Sail->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    Sail->SetRelativeLocation(FVector(-12.0f, 0.0f, 18.0f));
    Sail->SetRelativeRotation(FRotator(90.0f, 0.0f, 90.0f));
    Sail->SetRelativeScale3D(FVector(3.15f, 2.35f, 1.0f));
    if (PlaneMesh.Succeeded())
    {
        Sail->SetStaticMesh(PlaneMesh.Object);
    }

    Rudder = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Rudder"));
    Rudder->SetupAttachment(Hull);
    Rudder->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    Rudder->SetRelativeLocation(FVector(-330.0f, 0.0f, -12.0f));
    Rudder->SetRelativeScale3D(FVector(0.12f, 0.58f, 0.78f));
    if (CubeMesh.Succeeded())
    {
        Rudder->SetStaticMesh(CubeMesh.Object);
    }

    Helm = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Helm"));
    Helm->SetupAttachment(Hull);
    Helm->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    Helm->SetRelativeLocation(FVector(-175.0f, 0.0f, 165.0f));
    Helm->SetRelativeRotation(FRotator(90.0f, 0.0f, 0.0f));
    Helm->SetRelativeScale3D(FVector(0.38f, 0.38f, 0.10f));
    if (CylinderMesh.Succeeded())
    {
        Helm->SetStaticMesh(CylinderMesh.Object);
    }

    CameraBoom = CreateDefaultSubobject<USpringArmComponent>(TEXT("CameraBoom"));
    CameraBoom->SetupAttachment(Hull);
    CameraBoom->TargetArmLength = 1780.0f;
    CameraBoom->SocketOffset = FVector(165.0f, 0.0f, 330.0f);
    CameraBoom->bUsePawnControlRotation = true;
    CameraBoom->bDoCollisionTest = true;
    CameraBoom->ProbeSize = 34.0f;
    CameraBoom->bEnableCameraLag = true;
    CameraBoom->CameraLagSpeed = 9.5f;
    CameraBoom->CameraLagMaxDistance = 220.0f;

    BoatCamera = CreateDefaultSubobject<UCameraComponent>(TEXT("BoatCamera"));
    BoatCamera->SetupAttachment(CameraBoom, USpringArmComponent::SocketName);
    BoatCamera->bUsePawnControlRotation = false;
    BoatCamera->FieldOfView = 61.0f;
}

void ACHKBoatPawn::BeginPlay()
{
    Super::BeginPlay();
    ApplyBoatMaterials();
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

    Rudder->SetRelativeRotation(FRotator(0.0f, SteeringInput * 32.0f, 0.0f));
    Helm->SetRelativeRotation(FRotator(90.0f, 0.0f, SteeringInput * -48.0f));
    Sail->SetRelativeRotation(FRotator(90.0f, FMath::Sin(WaveTime * 0.72f) * 4.0f + SteeringInput * 5.0f, 90.0f));
    UpdatePilotPresentation(DeltaSeconds);
}

void ACHKBoatPawn::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
    Super::SetupPlayerInputComponent(PlayerInputComponent);

    PlayerInputComponent->BindAxis(TEXT("BoatThrottle"), this, &ACHKBoatPawn::Throttle);
    PlayerInputComponent->BindAxis(TEXT("BoatSteer"), this, &ACHKBoatPawn::Steering);
    PlayerInputComponent->BindAxis(TEXT("TurnCamera"), this, &ACHKBoatPawn::TurnCamera);
    PlayerInputComponent->BindAxis(TEXT("LookCamera"), this, &ACHKBoatPawn::LookCamera);
}

void ACHKBoatPawn::SetPilotCharacter(ACHKCharacter* NewPilot)
{
    PilotCharacter = NewPilot;
    if (!NewPilot)
    {
        return;
    }

    NewPilot->SetActorEnableCollision(false);
    NewPilot->AttachToComponent(Hull, FAttachmentTransformRules::KeepWorldTransform);
    NewPilot->SetActorTransform(GetHelmTransform());
    NewPilot->SetActorHiddenInGame(false);
}

void ACHKBoatPawn::ClearPilotCharacter()
{
    if (PilotCharacter.IsValid())
    {
        PilotCharacter->DetachFromActor(FDetachmentTransformRules::KeepWorldTransform);
        PilotCharacter->SetActorEnableCollision(true);
    }
    PilotCharacter.Reset();
}

FVector ACHKBoatPawn::GetExitLocation() const
{
    return GetActorLocation() + GetActorRightVector() * 540.0f + FVector(0.0f, 0.0f, 210.0f);
}

FTransform ACHKBoatPawn::GetHelmTransform() const
{
    const FVector Location = Helm
        ? Helm->GetComponentLocation() + GetActorUpVector() * 65.0f - GetActorForwardVector() * 35.0f
        : GetActorLocation() + FVector(0.0f, 0.0f, 190.0f);
    return FTransform(GetActorRotation(), Location, FVector(0.72f));
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

void ACHKBoatPawn::UpdatePilotPresentation(float DeltaSeconds)
{
    if (!PilotCharacter.IsValid())
    {
        return;
    }

    const FTransform HelmPose = GetHelmTransform();
    PilotCharacter->SetActorLocation(FMath::VInterpTo(PilotCharacter->GetActorLocation(), HelmPose.GetLocation(), DeltaSeconds, 12.0f));
    PilotCharacter->SetActorRotation(FMath::RInterpTo(PilotCharacter->GetActorRotation(), GetActorRotation(), DeltaSeconds, 10.0f));
}

void ACHKBoatPawn::ApplyBoatMaterials()
{
    if (UMaterialInstanceDynamic* Material = Hull->CreateAndSetMaterialInstanceDynamic(0))
    {
        Material->SetVectorParameterValue(TEXT("Color"), FLinearColor(0.16f, 0.055f, 0.018f, 1.0f));
    }
    if (UMaterialInstanceDynamic* Material = Deck->CreateAndSetMaterialInstanceDynamic(0))
    {
        Material->SetVectorParameterValue(TEXT("Color"), FLinearColor(0.34f, 0.13f, 0.035f, 1.0f));
    }
    if (UMaterialInstanceDynamic* Material = Mast->CreateAndSetMaterialInstanceDynamic(0))
    {
        Material->SetVectorParameterValue(TEXT("Color"), FLinearColor(0.22f, 0.08f, 0.02f, 1.0f));
    }
    if (UMaterialInstanceDynamic* Material = Sail->CreateAndSetMaterialInstanceDynamic(0))
    {
        Material->SetVectorParameterValue(TEXT("Color"), FLinearColor(0.72f, 0.055f, 0.025f, 1.0f));
    }
    if (UMaterialInstanceDynamic* Material = Rudder->CreateAndSetMaterialInstanceDynamic(0))
    {
        Material->SetVectorParameterValue(TEXT("Color"), FLinearColor(0.13f, 0.045f, 0.015f, 1.0f));
    }
    if (UMaterialInstanceDynamic* Material = Helm->CreateAndSetMaterialInstanceDynamic(0))
    {
        Material->SetVectorParameterValue(TEXT("Color"), FLinearColor(0.56f, 0.25f, 0.055f, 1.0f));
    }
}
