#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "CHKEnemyCharacter.generated.h"

class UStaticMeshComponent;
class ACHKCharacter;

UENUM(BlueprintType)
enum class ECHKEnemyArchetype : uint8
{
    Raider,
    Shooter,
    Brute,
    Healer,
    Assassin,
    Boss
};

UCLASS()
class CHKPIRATEWARRIOR_API ACHKEnemyCharacter : public ACharacter
{
    GENERATED_BODY()

public:
    ACHKEnemyCharacter();

    virtual void Tick(float DeltaSeconds) override;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Visual")
    TObjectPtr<UStaticMeshComponent> BodyVisual;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Visual")
    TObjectPtr<UStaticMeshComponent> HeadVisual;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Visual")
    TObjectPtr<UStaticMeshComponent> WeaponVisual;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Enemy")
    ECHKEnemyArchetype Archetype = ECHKEnemyArchetype::Raider;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Enemy")
    FString EnemyId = TEXT("raider_port");

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Enemy")
    float MaxHealth = 90.0f;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Enemy")
    float Health = 90.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Enemy")
    float Damage = 12.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Enemy")
    float AttackRange = 185.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Enemy")
    float ChaseRange = 3200.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Enemy")
    float AttackInterval = 1.25f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Enemy")
    int32 RewardExperience = 35;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Enemy")
    int32 RewardCoins = 18;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Enemy")
    FLinearColor IdentityColor = FLinearColor(0.52f, 0.09f, 0.05f, 1.0f);

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Enemy")
    bool bBoss = false;

    UFUNCTION(BlueprintCallable, Category="Enemy")
    void ConfigureEnemy(ECHKEnemyArchetype NewArchetype, const FString& NewId, bool bIsBoss, const FLinearColor& NewColor);

    UFUNCTION(BlueprintCallable, Category="Combat")
    void ReceiveDamageCHK(float Amount, const FVector& ImpulseDirection = FVector::ZeroVector);

    UFUNCTION(BlueprintPure, Category="Enemy")
    bool IsAlive() const { return Health > 0.0f; }

protected:
    virtual void BeginPlay() override;

private:
    void UpdateTarget();
    void UpdateMovement(float DeltaSeconds);
    void TryAttack(float DeltaSeconds);
    void UpdateBossPhase(float DeltaSeconds);
    void ApplyIdentityVisuals();
    void Die();

    TWeakObjectPtr<ACHKCharacter> TargetCharacter;
    float AttackCooldown = 0.0f;
    float TargetRefreshTimer = 0.0f;
    float SpecialCooldown = 4.0f;
    int32 BossPhase = 1;
    bool bDead = false;
};
