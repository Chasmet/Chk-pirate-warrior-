#include "CHKCharacter.h"

#include "CHKEnemyCharacter.h"
#include "Camera/CameraComponent.h"
#include "Components/CapsuleComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "EngineUtils.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "GameFramework/Controller.h"
#include "GameFramework/SpringArmComponent.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "UObject/ConstructorHelpers.h"

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

    static ConstructorHelpers::FObjectFinder<UStaticMesh> CylinderMesh(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> SphereMesh(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeMesh(TEXT("/Engine/BasicShapes/Cube.Cube"));

    BodyVisual = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("BodyVisual"));
    BodyVisual->SetupAttachment(GetCapsuleComponent());
    BodyVisual->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    BodyVisual->SetRelativeLocation(FVector(0.0f, 0.0f, -4.0f));
    BodyVisual->SetRelativeScale3D(FVector(0.62f, 0.50f, 1.52f));
    if (CylinderMesh.Succeeded())
    {
        BodyVisual->SetStaticMesh(CylinderMesh.Object);
    }

    HeadVisual = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("HeadVisual"));
    HeadVisual->SetupAttachment(GetCapsuleComponent());
    HeadVisual->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    HeadVisual->SetRelativeLocation(FVector(0.0f, 0.0f, 87.0f));
    HeadVisual->SetRelativeScale3D(FVector(0.43f));
    if (SphereMesh.Succeeded())
    {
        HeadVisual->SetStaticMesh(SphereMesh.Object);
    }

    WeaponVisual = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("WeaponVisual"));
    WeaponVisual->SetupAttachment(GetCapsuleComponent());
    WeaponVisual->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    WeaponVisual->SetRelativeLocation(FVector(34.0f, 24.0f, 25.0f));
    WeaponVisual->SetRelativeRotation(FRotator(0.0f, 0.0f, 22.0f));
    WeaponVisual->SetRelativeScale3D(FVector(0.08f, 0.12f, 1.08f));
    if (CubeMesh.Succeeded())
    {
        WeaponVisual->SetStaticMesh(CubeMesh.Object);
    }

    GetMesh()->SetVisibility(false, true);
}

void ACHKCharacter::BeginPlay()
{
    Super::BeginPlay();
    UpdateHeroProfile(true);
}

void ACHKCharacter::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);

    DodgeCooldown = FMath::Max(0.0f, DodgeCooldown - DeltaSeconds);
    AttackCooldown = FMath::Max(0.0f, AttackCooldown - DeltaSeconds);
    SkillCooldown = FMath::Max(0.0f, SkillCooldown - DeltaSeconds);
    DamageInvulnerability = FMath::Max(0.0f, DamageInvulnerability - DeltaSeconds);
    Energy = FMath::Min(MaxEnergy, Energy + DeltaSeconds * (HeroId == ECHKHeroId::Nelvyn ? 10.0f : 7.5f));
}

void ACHKCharacter::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
    Super::SetupPlayerInputComponent(PlayerInputComponent);

    PlayerInputComponent->BindAxis(TEXT("MoveForward"), this, &ACHKCharacter::MoveForward);
    PlayerInputComponent->BindAxis(TEXT("MoveRight"), this, &ACHKCharacter::MoveRight);
    PlayerInputComponent->BindAxis(TEXT("TurnCamera"), this, &ACHKCharacter::TurnCamera);
    PlayerInputComponent->BindAxis(TEXT("LookCamera"), this, &ACHKCharacter::LookCamera);
    PlayerInputComponent->BindAction(TEXT("Attack"), IE_Pressed, this, &ACHKCharacter::RequestAttack);
    PlayerInputComponent->BindAction(TEXT("Skill"), IE_Pressed, this, &ACHKCharacter::RequestSkill);
    PlayerInputComponent->BindAction(TEXT("Dodge"), IE_Pressed, this, &ACHKCharacter::RequestDodge);
    PlayerInputComponent->BindAction(TEXT("SwitchHero"), IE_Pressed, this, &ACHKCharacter::SwitchHero);
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

void ACHKCharacter::RequestAttack()
{
    if (AttackCooldown > 0.0f)
    {
        return;
    }

    AttackCooldown = HeroId == ECHKHeroId::Yvane ? 0.34f : 0.48f;
    const float Damage = HeroId == ECHKHeroId::Cheikh ? 42.0f : HeroId == ECHKHeroId::Yvane ? 29.0f : 34.0f;
    const float Radius = HeroId == ECHKHeroId::Yvane ? 780.0f : 290.0f;
    const float MinimumDot = HeroId == ECHKHeroId::Yvane ? 0.35f : -0.05f;
    DamageEnemiesInArc(Damage + static_cast<float>(Level - 1) * 3.5f, Radius, MinimumDot, 470.0f);
    OnAttackRequested();
}

void ACHKCharacter::RequestSkill()
{
    constexpr float SkillCost = 28.0f;
    if (Energy < SkillCost || SkillCooldown > 0.0f)
    {
        return;
    }

    Energy -= SkillCost;
    SkillCooldown = 2.8f;

    if (HeroId == ECHKHeroId::Cheikh)
    {
        DamageEnemiesInArc(105.0f + Level * 6.0f, 620.0f, -0.35f, 1150.0f);
        DamageEnemiesInRadius(48.0f + Level * 3.0f, 380.0f, 680.0f);
    }
    else if (HeroId == ECHKHeroId::Yvane)
    {
        int32 HitCount = 0;
        for (TActorIterator<ACHKEnemyCharacter> It(GetWorld()); It && HitCount < 7; ++It)
        {
            ACHKEnemyCharacter* Enemy = *It;
            if (Enemy && Enemy->IsAlive() && FVector::Dist2D(GetActorLocation(), Enemy->GetActorLocation()) <= 1350.0f)
            {
                Enemy->ReceiveDamageCHK(72.0f + Level * 5.0f, Enemy->GetActorLocation() - GetActorLocation());
                ++HitCount;
            }
        }
    }
    else
    {
        DamageEnemiesInRadius(96.0f + Level * 6.0f, 920.0f, 1320.0f);
    }

    OnSkillRequested(HeroId);
}

void ACHKCharacter::RequestDodge()
{
    if (DodgeCooldown > 0.0f)
    {
        return;
    }

    DodgeCooldown = HeroId == ECHKHeroId::Yvane ? 0.48f : 0.72f;
    DamageInvulnerability = 0.42f;
    const FVector DodgeDirection = GetLastMovementInputVector().IsNearlyZero()
        ? GetActorForwardVector()
        : GetLastMovementInputVector().GetSafeNormal();
    const float DodgePower = HeroId == ECHKHeroId::Yvane ? 1480.0f : HeroId == ECHKHeroId::Nelvyn ? 1280.0f : 1180.0f;
    LaunchCharacter(DodgeDirection * DodgePower + FVector(0.0f, 0.0f, 85.0f), true, true);
}

void ACHKCharacter::ReceiveDamageCHK(float Amount)
{
    if (DamageInvulnerability > 0.0f || Amount <= 0.0f)
    {
        return;
    }

    DamageInvulnerability = 0.28f;
    Health = FMath::Clamp(Health - Amount, 0.0f, MaxHealth);
    if (Health <= 0.0f)
    {
        Health = MaxHealth;
        SetActorLocation(FVector(0.0f, 0.0f, 420.0f), false, nullptr, ETeleportType::TeleportPhysics);
    }
}

void ACHKCharacter::SwitchHero()
{
    const int32 Next = (static_cast<int32>(HeroId) + 1) % 3;
    HeroId = static_cast<ECHKHeroId>(Next);
    UpdateHeroProfile(false);
    OnHeroChanged(HeroId);
}

void ACHKCharacter::AddRewards(int32 ExperienceReward, int32 CoinReward)
{
    Experience += FMath::Max(0, ExperienceReward);
    Coins += FMath::Max(0, CoinReward);
    RecalculateLevel();
}

void ACHKCharacter::ApplySavedProgress(ECHKHeroId SavedHero, int32 SavedLevel, int32 SavedExperience, int32 SavedCoins)
{
    HeroId = SavedHero;
    Level = FMath::Clamp(SavedLevel, 1, 50);
    Experience = FMath::Max(0, SavedExperience);
    Coins = FMath::Max(0, SavedCoins);
    UpdateHeroProfile(true);
}

FString ACHKCharacter::GetHeroDisplayName() const
{
    switch (HeroId)
    {
        case ECHKHeroId::Yvane: return TEXT("YVANE");
        case ECHKHeroId::Nelvyn: return TEXT("NELVYN");
        default: return TEXT("CHEIKH");
    }
}

FString ACHKCharacter::GetSkillDisplayName() const
{
    switch (HeroId)
    {
        case ECHKHeroId::Yvane: return TEXT("ÉCLAIR SERPENTINE");
        case ECHKHeroId::Nelvyn: return TEXT("BOULE DU BIG BANG");
        default: return TEXT("ÉPÉE INFERNALE DU CERBÈRE");
    }
}

float ACHKCharacter::GetHealthRatio() const
{
    return Health / FMath::Max(MaxHealth, 1.0f);
}

float ACHKCharacter::GetEnergyRatio() const
{
    return Energy / FMath::Max(MaxEnergy, 1.0f);
}

void ACHKCharacter::UpdateHeroProfile(bool bRestoreHealth)
{
    const float PreviousRatio = Health / FMath::Max(MaxHealth, 1.0f);

    if (HeroId == ECHKHeroId::Cheikh)
    {
        MaxHealth = 165.0f + (Level - 1) * 13.0f;
        GetCharacterMovement()->MaxWalkSpeed = 740.0f;
        GetCapsuleComponent()->SetCapsuleSize(46.0f, 102.0f);
        BodyVisual->SetRelativeScale3D(FVector(0.66f, 0.54f, 1.62f));
        HeadVisual->SetRelativeLocation(FVector(0.0f, 0.0f, 94.0f));
        HeadVisual->SetRelativeScale3D(FVector(0.45f));
        WeaponVisual->SetRelativeScale3D(FVector(0.08f, 0.12f, 1.18f));
    }
    else if (HeroId == ECHKHeroId::Yvane)
    {
        MaxHealth = 118.0f + (Level - 1) * 10.0f;
        GetCharacterMovement()->MaxWalkSpeed = 1020.0f;
        GetCapsuleComponent()->SetCapsuleSize(39.0f, 86.0f);
        BodyVisual->SetRelativeScale3D(FVector(0.50f, 0.42f, 1.30f));
        HeadVisual->SetRelativeLocation(FVector(0.0f, 0.0f, 74.0f));
        HeadVisual->SetRelativeScale3D(FVector(0.39f));
        WeaponVisual->SetRelativeScale3D(FVector(0.08f, 0.52f, 0.08f));
    }
    else
    {
        MaxHealth = 126.0f + (Level - 1) * 11.0f;
        GetCharacterMovement()->MaxWalkSpeed = 870.0f;
        GetCapsuleComponent()->SetCapsuleSize(38.0f, 76.0f);
        BodyVisual->SetRelativeScale3D(FVector(0.47f, 0.40f, 1.14f));
        HeadVisual->SetRelativeLocation(FVector(0.0f, 0.0f, 65.0f));
        HeadVisual->SetRelativeScale3D(FVector(0.38f));
        WeaponVisual->SetRelativeScale3D(FVector(0.28f));
    }

    Health = bRestoreHealth ? MaxHealth : FMath::Clamp(MaxHealth * PreviousRatio, 1.0f, MaxHealth);
    Energy = FMath::Clamp(Energy, 0.0f, MaxEnergy);
    UpdateVisualIdentity();
}

void ACHKCharacter::UpdateVisualIdentity()
{
    const FLinearColor HeroColor = HeroId == ECHKHeroId::Cheikh
        ? FLinearColor(0.58f, 0.08f, 0.035f, 1.0f)
        : HeroId == ECHKHeroId::Yvane
            ? FLinearColor(0.025f, 0.32f, 0.82f, 1.0f)
            : FLinearColor(0.42f, 0.16f, 0.72f, 1.0f);
    const FLinearColor AccentColor = HeroId == ECHKHeroId::Cheikh
        ? FLinearColor(1.0f, 0.38f, 0.03f, 1.0f)
        : HeroId == ECHKHeroId::Yvane
            ? FLinearColor(0.18f, 0.78f, 1.0f, 1.0f)
            : FLinearColor(0.95f, 0.74f, 0.18f, 1.0f);

    if (UMaterialInstanceDynamic* Material = BodyVisual->CreateAndSetMaterialInstanceDynamic(0))
    {
        Material->SetVectorParameterValue(TEXT("Color"), HeroColor);
    }
    if (UMaterialInstanceDynamic* Material = HeadVisual->CreateAndSetMaterialInstanceDynamic(0))
    {
        Material->SetVectorParameterValue(TEXT("Color"), FLinearColor(0.47f, 0.25f, 0.14f, 1.0f));
    }
    if (UMaterialInstanceDynamic* Material = WeaponVisual->CreateAndSetMaterialInstanceDynamic(0))
    {
        Material->SetVectorParameterValue(TEXT("Color"), AccentColor);
    }
}

int32 ACHKCharacter::DamageEnemiesInArc(float Damage, float Radius, float MinimumDot, float PushStrength)
{
    int32 Hits = 0;
    const FVector Forward = GetActorForwardVector();
    for (TActorIterator<ACHKEnemyCharacter> It(GetWorld()); It; ++It)
    {
        ACHKEnemyCharacter* Enemy = *It;
        if (!Enemy || !Enemy->IsAlive())
        {
            continue;
        }

        FVector Offset = Enemy->GetActorLocation() - GetActorLocation();
        Offset.Z = 0.0f;
        const float Distance = Offset.Size();
        if (Distance <= Radius && !Offset.IsNearlyZero() && FVector::DotProduct(Forward, Offset.GetSafeNormal()) >= MinimumDot)
        {
            Enemy->ReceiveDamageCHK(Damage, Offset.GetSafeNormal() * PushStrength);
            ++Hits;
        }
    }
    return Hits;
}

int32 ACHKCharacter::DamageEnemiesInRadius(float Damage, float Radius, float PushStrength)
{
    int32 Hits = 0;
    for (TActorIterator<ACHKEnemyCharacter> It(GetWorld()); It; ++It)
    {
        ACHKEnemyCharacter* Enemy = *It;
        if (!Enemy || !Enemy->IsAlive())
        {
            continue;
        }

        FVector Offset = Enemy->GetActorLocation() - GetActorLocation();
        Offset.Z = 0.0f;
        if (Offset.Size() <= Radius)
        {
            Enemy->ReceiveDamageCHK(Damage, Offset.GetSafeNormal() * PushStrength);
            ++Hits;
        }
    }
    return Hits;
}

void ACHKCharacter::RecalculateLevel()
{
    int32 CalculatedLevel = 1;
    int32 Threshold = 120;
    int32 Consumed = 0;
    while (Experience >= Consumed + Threshold && CalculatedLevel < 50)
    {
        Consumed += Threshold;
        ++CalculatedLevel;
        Threshold = 120 + CalculatedLevel * 85;
    }

    if (CalculatedLevel > Level)
    {
        Level = CalculatedLevel;
        UpdateHeroProfile(true);
    }
    else
    {
        Level = CalculatedLevel;
    }
}
