#include "CHKCharacter.h"

#include "Camera/CameraComponent.h"
#include "Components/CapsuleComponent.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "GameFramework/Controller.h"
#include "GameFramework/SpringArmComponent.h"

ACHKCharacter::ACHKCharacter()
{
    PrimaryActorTick.bCanEverTick = true;

    GetCapsuleComponent()->InitCapsuleSize(42.0f, 96.0f);
    bUseControllerRotationPitch = false;
    bUseControllerRotationYaw = false;
    bUseControllerRotationRoll = false;

    GetCharacterMovement()->bOrientRotationToMovement = true;
    GetCharacterMovement()->RotationRate = FRotator(0.0f, 620.0f, 0.0f);
    GetCharacterMovement()->JumpZVelocity = 560.0f;
    GetCharacterMovement()->AirControl = 0.28f;
    GetCharacterMovement()->MaxWalkSpeed = 740.0f;
    GetCharacterMovement()->BrakingDecelerationWalking = 1500.0f;
    GetCharacterMovement()->GroundFriction = 7.5f;

    CameraBoom = CreateDefaultSubobject<USpringArmComponent>(TEXT("CameraBoom"));
    CameraBoom->SetupAttachment(RootComponent);
    CameraBoom->TargetArmLength = 615.0f;
    CameraBoom->SocketOffset = FVector(48.0f, 0.0f, 82.0f);
    CameraBoom->bUsePawnControlRotation = true;
    CameraBoom->bEnableCameraLag = true;
    CameraBoom->CameraLagSpeed = 13.5f;
    CameraBoom->CameraLagMaxDistance = 85.0f;
    CameraBoom->bDoCollisionTest = true;
    CameraBoom->ProbeSize = 18.0f;

    FollowCamera = CreateDefaultSubobject<UCameraComponent>(TEXT("FollowCamera"));
    FollowCamera->SetupAttachment(CameraBoom, USpringArmComponent::SocketName);
    FollowCamera->bUsePawnControlRotation = false;
    FollowCamera->FieldOfView = 59.0f;
}

void ACHKCharacter::BeginPlay()
{
    Super::BeginPlay();
    Health = MaxHealth;
    Energy = MaxEnergy;

    if (Controller)
    {
        const FRotator Rotation = Controller->GetControlRotation();
        CameraTargetYaw = Rotation.Yaw;
        CameraTargetPitch = FMath::Clamp(Rotation.Pitch, -32.0f, 12.0f);
    }
}

void ACHKCharacter::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    DodgeCooldown = FMath::Max(0.0f, DodgeCooldown - DeltaSeconds);
    Energy = FMath::Min(MaxEnergy, Energy + DeltaSeconds * 7.5f);
}

void ACHKCharacter::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
    Super::SetupPlayerInputComponent(PlayerInputComponent);

    PlayerInputComponent->BindAxis(TEXT("MoveForward"), this, &ACHKCharacter::MoveForward);
    PlayerInputComponent->BindAxis(TEXT("MoveRight"), this, &ACHKCharacter::MoveRight);
    PlayerInputComponent->BindAxis(TEXT("TurnCamera"), this, &ACHKCharacter::TurnCamera);
    PlayerInputComponent->BindAxis(TEXT("LookCamera"), this, &ACHKCharacter::LookCamera);
    PlayerInputComponent->BindAction(TEXT("Attack"), IE_Pressed, this, &ACHKCharacter::Attack);
    PlayerInputComponent->BindAction(TEXT("Skill"), IE_Pressed, this, &ACHKCharacter::Skill);
    PlayerInputComponent->BindAction(TEXT("Dodge"), IE_Pressed, this, &ACHKCharacter::Dodge);
}

void ACHKCharacter::MoveForward(float Value)
{
    if (!Controller || FMath::IsNearlyZero(Value))
    {
        return;
    }

    const FRotator ControlRotation = Controller->GetControlRotation();
    const FRotator YawRotation(0.0f, ControlRotation.Yaw, 0.0f);
    AddMovementInput(FRotationMatrix(YawRotation).GetUnitAxis(EAxis::X), Value);
}

void ACHKCharacter::MoveRight(float Value)
{
    if (!Controller || FMath::IsNearlyZero(Value))
    {
        return;
    }

    const FRotator ControlRotation = Controller->GetControlRotation();
    const FRotator YawRotation(0.0f, ControlRotation.Yaw, 0.0f);
    AddMovementInput(FRotationMatrix(YawRotation).GetUnitAxis(EAxis::Y), Value);
}

void ACHKCharacter::TurnCamera(float Value)
{
    AddControllerYawInput(Value);
}

void ACHKCharacter::LookCamera(float Value)
{
    AddControllerPitchInput(Value);
}

void ACHKCharacter::Attack()
{
    OnAttackRequested();
}

void ACHKCharacter::Skill()
{
    constexpr float SkillCost = 28.0f;
    if (Energy < SkillCost)
    {
        return;
    }

    Energy -= SkillCost;
    OnSkillRequested(HeroId);
}

void ACHKCharacter::Dodge()
{
    if (DodgeCooldown > 0.0f)
    {
        return;
    }

    DodgeCooldown = 0.75f;
    const FVector DodgeDirection = GetLastMovementInputVector().IsNearlyZero()
        ? GetActorForwardVector()
        : GetLastMovementInputVector().GetSafeNormal();
    LaunchCharacter(DodgeDirection * 1180.0f + FVector(0.0f, 0.0f, 85.0f), true, true);
}

void ACHKCharacter::ReceiveDamageCHK(float Amount)
{
    Health = FMath::Clamp(Health - FMath::Max(0.0f, Amount), 0.0f, MaxHealth);
}
