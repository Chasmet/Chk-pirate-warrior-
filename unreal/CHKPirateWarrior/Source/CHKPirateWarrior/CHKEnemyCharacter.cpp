#include "CHKEnemyCharacter.h"

#include "CHKCharacter.h"
#include "Components/CapsuleComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "Kismet/GameplayStatics.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "UObject/ConstructorHelpers.h"

ACHKEnemyCharacter::ACHKEnemyCharacter()
{
    PrimaryActorTick.bCanEverTick = true;

    GetCapsuleComponent()->InitCapsuleSize(42.0f, 92.0f);
    GetCharacterMovement()->MaxWalkSpeed = 420.0f;
    GetCharacterMovement()->bOrientRotationToMovement = true;
    GetCharacterMovement()->RotationRate = FRotator(0.0f, 520.0f, 0.0f);
    GetCharacterMovement()->BrakingDecelerationWalking = 1200.0f;

    static ConstructorHelpers::FObjectFinder<UStaticMesh> CylinderMesh(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> SphereMesh(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeMesh(TEXT("/Engine/BasicShapes/Cube.Cube"));

    BodyVisual = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("BodyVisual"));
    BodyVisual->SetupAttachment(GetCapsuleComponent());
    BodyVisual->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    BodyVisual->SetRelativeLocation(FVector(0.0f, 0.0f, -4.0f));
    BodyVisual->SetRelativeScale3D(FVector(0.62f, 0.50f, 1.42f));
    if (CylinderMesh.Succeeded())
    {
        BodyVisual->SetStaticMesh(CylinderMesh.Object);
    }

    HeadVisual = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("HeadVisual"));
    HeadVisual->SetupAttachment(GetCapsuleComponent());
    HeadVisual->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    HeadVisual->SetRelativeLocation(FVector(0.0f, 0.0f, 82.0f));
    HeadVisual->SetRelativeScale3D(FVector(0.42f));
    if (SphereMesh.Succeeded())
    {
        HeadVisual->SetStaticMesh(SphereMesh.Object);
    }

    WeaponVisual = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("WeaponVisual"));
    WeaponVisual->SetupAttachment(GetCapsuleComponent());
    WeaponVisual->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    WeaponVisual->SetRelativeLocation(FVector(30.0f, 22.0f, 25.0f));
    WeaponVisual->SetRelativeRotation(FRotator(0.0f, 0.0f, 28.0f));
    WeaponVisual->SetRelativeScale3D(FVector(0.10f, 0.10f, 0.92f));
    if (CubeMesh.Succeeded())
    {
        WeaponVisual->SetStaticMesh(CubeMesh.Object);
    }
}

void ACHKEnemyCharacter::BeginPlay()
{
    Super::BeginPlay();
    Health = MaxHealth;
    ApplyIdentityVisuals();
    UpdateTarget();
}

void ACHKEnemyCharacter::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);

    if (bDead)
    {
        return;
    }

    TargetRefreshTimer -= DeltaSeconds;
    if (TargetRefreshTimer <= 0.0f || !TargetCharacter.IsValid())
    {
        TargetRefreshTimer = 0.65f;
        UpdateTarget();
    }

    AttackCooldown = FMath::Max(0.0f, AttackCooldown - DeltaSeconds);
    SpecialCooldown = FMath::Max(0.0f, SpecialCooldown - DeltaSeconds);

    if (bBoss)
    {
        UpdateBossPhase(DeltaSeconds);
    }

    UpdateMovement(DeltaSeconds);
    TryAttack(DeltaSeconds);
}

void ACHKEnemyCharacter::ConfigureEnemy(
    ECHKEnemyArchetype NewArchetype,
    const FString& NewId,
    bool bIsBoss,
    const FLinearColor& NewColor)
{
    Archetype = NewArchetype;
    EnemyId = NewId;
    bBoss = bIsBoss;
    IdentityColor = NewColor;

    switch (Archetype)
    {
        case ECHKEnemyArchetype::Shooter:
            MaxHealth = 72.0f;
            Damage = 10.0f;
            AttackRange = 900.0f;
            AttackInterval = 1.65f;
            GetCharacterMovement()->MaxWalkSpeed = 390.0f;
            WeaponVisual->SetRelativeScale3D(FVector(0.08f, 0.52f, 0.08f));
            break;
        case ECHKEnemyArchetype::Brute:
            MaxHealth = 175.0f;
            Damage = 24.0f;
            AttackRange = 235.0f;
            AttackInterval = 1.75f;
            GetCharacterMovement()->MaxWalkSpeed = 300.0f;
            BodyVisual->SetRelativeScale3D(FVector(0.86f, 0.74f, 1.55f));
            WeaponVisual->SetRelativeScale3D(FVector(0.24f, 0.24f, 1.12f));
            RewardExperience = 65;
            RewardCoins = 32;
            break;
        case ECHKEnemyArchetype::Healer:
            MaxHealth = 105.0f;
            Damage = 7.0f;
            AttackRange = 420.0f;
            AttackInterval = 2.2f;
            GetCharacterMovement()->MaxWalkSpeed = 350.0f;
            break;
        case ECHKEnemyArchetype::Assassin:
            MaxHealth = 82.0f;
            Damage = 19.0f;
            AttackRange = 190.0f;
            AttackInterval = 0.8f;
            GetCharacterMovement()->MaxWalkSpeed = 610.0f;
            BodyVisual->SetRelativeScale3D(FVector(0.48f, 0.40f, 1.34f));
            break;
        case ECHKEnemyArchetype::Boss:
            bBoss = true;
            MaxHealth = 1150.0f;
            Damage = 31.0f;
            AttackRange = 310.0f;
            AttackInterval = 1.25f;
            GetCharacterMovement()->MaxWalkSpeed = 350.0f;
            BodyVisual->SetRelativeScale3D(FVector(1.18f, 1.02f, 2.15f));
            HeadVisual->SetRelativeLocation(FVector(0.0f, 0.0f, 142.0f));
            HeadVisual->SetRelativeScale3D(FVector(0.67f));
            WeaponVisual->SetRelativeLocation(FVector(54.0f, 42.0f, 58.0f));
            WeaponVisual->SetRelativeScale3D(FVector(0.32f, 0.32f, 1.65f));
            RewardExperience = 850;
            RewardCoins = 420;
            break;
        default:
            MaxHealth = 90.0f;
            Damage = 12.0f;
            AttackRange = 185.0f;
            AttackInterval = 1.25f;
            GetCharacterMovement()->MaxWalkSpeed = 420.0f;
            break;
    }

    Health = MaxHealth;
    ApplyIdentityVisuals();
}

void ACHKEnemyCharacter::ReceiveDamageCHK(float Amount, const FVector& ImpulseDirection)
{
    if (bDead || Amount <= 0.0f)
    {
        return;
    }

    Health = FMath::Clamp(Health - Amount, 0.0f, MaxHealth);
    if (!ImpulseDirection.IsNearlyZero())
    {
        LaunchCharacter(ImpulseDirection.GetSafeNormal() * (bBoss ? 160.0f : 410.0f) + FVector(0.0f, 0.0f, 60.0f), true, true);
    }

    if (Health <= 0.0f)
    {
        Die();
    }
}

void ACHKEnemyCharacter::UpdateTarget()
{
    ACharacter* PlayerCharacter = UGameplayStatics::GetPlayerCharacter(this, 0);
    TargetCharacter = Cast<ACHKCharacter>(PlayerCharacter);
}

void ACHKEnemyCharacter::UpdateMovement(float DeltaSeconds)
{
    if (!TargetCharacter.IsValid())
    {
        return;
    }

    FVector Offset = TargetCharacter->GetActorLocation() - GetActorLocation();
    Offset.Z = 0.0f;
    const float Distance = Offset.Size();
    if (Distance > ChaseRange || Distance < 1.0f)
    {
        return;
    }

    const FVector Direction = Offset.GetSafeNormal();
    const bool bRanged = Archetype == ECHKEnemyArchetype::Shooter || Archetype == ECHKEnemyArchetype::Healer;
    if (bRanged && Distance < AttackRange * 0.72f)
    {
        AddMovementInput(-Direction, 0.82f, true);
    }
    else if (Distance > AttackRange * 0.86f)
    {
        AddMovementInput(Direction, 1.0f, true);
    }

    const FRotator DesiredRotation = Direction.Rotation();
    SetActorRotation(FMath::RInterpTo(GetActorRotation(), FRotator(0.0f, DesiredRotation.Yaw, 0.0f), DeltaSeconds, 8.0f));
}

void ACHKEnemyCharacter::TryAttack(float DeltaSeconds)
{
    if (!TargetCharacter.IsValid() || AttackCooldown > 0.0f)
    {
        return;
    }

    const float Distance = FVector::Dist2D(TargetCharacter->GetActorLocation(), GetActorLocation());
    if (Distance > AttackRange)
    {
        return;
    }

    AttackCooldown = AttackInterval;
    float AppliedDamage = Damage;
    if (Archetype == ECHKEnemyArchetype::Assassin && FMath::FRand() > 0.72f)
    {
        AppliedDamage *= 1.65f;
    }

    TargetCharacter->ReceiveDamageCHK(AppliedDamage);

    if (Archetype == ECHKEnemyArchetype::Brute || bBoss)
    {
        const FVector Push = (TargetCharacter->GetActorLocation() - GetActorLocation()).GetSafeNormal();
        TargetCharacter->LaunchCharacter(Push * (bBoss ? 820.0f : 520.0f) + FVector(0.0f, 0.0f, 110.0f), true, true);
    }
}

void ACHKEnemyCharacter::UpdateBossPhase(float DeltaSeconds)
{
    const float HealthRatio = Health / FMath::Max(MaxHealth, 1.0f);
    const int32 NewPhase = HealthRatio > 0.66f ? 1 : HealthRatio > 0.33f ? 2 : 3;
    if (NewPhase != BossPhase)
    {
        BossPhase = NewPhase;
        Damage *= 1.18f;
        AttackInterval = FMath::Max(0.55f, AttackInterval - 0.18f);
        GetCharacterMovement()->MaxWalkSpeed += 65.0f;
        BodyVisual->SetWorldScale3D(BodyVisual->GetComponentScale() * 1.04f);
    }

    if (SpecialCooldown > 0.0f || !TargetCharacter.IsValid())
    {
        return;
    }

    SpecialCooldown = FMath::Max(2.8f, 6.4f - static_cast<float>(BossPhase));
    const float Distance = FVector::Dist2D(TargetCharacter->GetActorLocation(), GetActorLocation());
    if (Distance < 850.0f)
    {
        TargetCharacter->ReceiveDamageCHK(Damage * (0.75f + 0.18f * BossPhase));
        const FVector Push = (TargetCharacter->GetActorLocation() - GetActorLocation()).GetSafeNormal();
        TargetCharacter->LaunchCharacter(Push * (720.0f + 180.0f * BossPhase) + FVector(0.0f, 0.0f, 180.0f), true, true);
    }
}

void ACHKEnemyCharacter::ApplyIdentityVisuals()
{
    TArray<UStaticMeshComponent*> Visuals = {BodyVisual, HeadVisual, WeaponVisual};
    for (UStaticMeshComponent* Visual : Visuals)
    {
        if (!Visual)
        {
            continue;
        }
        UMaterialInstanceDynamic* Material = Visual->CreateAndSetMaterialInstanceDynamic(0);
        if (Material)
        {
            Material->SetVectorParameterValue(TEXT("Color"), IdentityColor);
        }
    }
}

void ACHKEnemyCharacter::Die()
{
    if (bDead)
    {
        return;
    }

    bDead = true;
    GetCharacterMovement()->DisableMovement();
    GetCapsuleComponent()->SetCollisionEnabled(ECollisionEnabled::NoCollision);

    if (TargetCharacter.IsValid())
    {
        TargetCharacter->AddRewards(RewardExperience, RewardCoins);
    }

    SetLifeSpan(1.2f);
    SetActorEnableCollision(false);
    SetActorScale3D(GetActorScale3D() * 0.92f);
}
