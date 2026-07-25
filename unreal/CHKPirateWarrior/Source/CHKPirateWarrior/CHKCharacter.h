#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "CHKCharacter.generated.h"

class USpringArmComponent;
class UCameraComponent;
class UStaticMeshComponent;

UENUM(BlueprintType)
enum class ECHKHeroId : uint8
{
    Cheikh,
    Yvane,
    Nelvyn
};

UCLASS()
class CHKPIRATEWARRIOR_API ACHKCharacter : public ACharacter
{
    GENERATED_BODY()

public:
    ACHKCharacter();

    virtual void Tick(float DeltaSeconds) override;
    virtual void SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) override;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Camera")
    TObjectPtr<USpringArmComponent> CameraBoom;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Camera")
    TObjectPtr<UCameraComponent> FollowCamera;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Visual")
    TObjectPtr<UStaticMeshComponent> BodyVisual;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Visual")
    TObjectPtr<UStaticMeshComponent> HeadVisual;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Visual")
    TObjectPtr<UStaticMeshComponent> WeaponVisual;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Hero")
    ECHKHeroId HeroId = ECHKHeroId::Cheikh;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Hero")
    float MaxHealth = 165.0f;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Hero")
    float Health = 165.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Hero")
    float MaxEnergy = 100.0f;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Hero")
    float Energy = 100.0f;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Progression")
    int32 Level = 1;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Progression")
    int32 Experience = 0;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Progression")
    int32 Coins = 250;

    UFUNCTION(BlueprintCallable, Category="Combat")
    void ReceiveDamageCHK(float Amount);

    UFUNCTION(BlueprintCallable, Category="Combat")
    void RequestAttack();

    UFUNCTION(BlueprintCallable, Category="Combat")
    void RequestSkill();

    UFUNCTION(BlueprintCallable, Category="Movement")
    void RequestDodge();

    UFUNCTION(BlueprintCallable, Category="Hero")
    void SwitchHero();

    UFUNCTION(BlueprintCallable, Category="Progression")
    void AddRewards(int32 ExperienceReward, int32 CoinReward);

    UFUNCTION(BlueprintCallable, Category="Progression")
    void ApplySavedProgress(ECHKHeroId SavedHero, int32 SavedLevel, int32 SavedExperience, int32 SavedCoins);

    UFUNCTION(BlueprintPure, Category="Hero")
    FString GetHeroDisplayName() const;

    UFUNCTION(BlueprintPure, Category="Hero")
    FString GetSkillDisplayName() const;

    UFUNCTION(BlueprintPure, Category="Hero")
    float GetHealthRatio() const;

    UFUNCTION(BlueprintPure, Category="Hero")
    float GetEnergyRatio() const;

    UFUNCTION(BlueprintImplementableEvent, Category="Combat")
    void OnAttackRequested();

    UFUNCTION(BlueprintImplementableEvent, Category="Combat")
    void OnSkillRequested(ECHKHeroId ActiveHero);

    UFUNCTION(BlueprintImplementableEvent, Category="Hero")
    void OnHeroChanged(ECHKHeroId ActiveHero);

protected:
    virtual void BeginPlay() override;

private:
    void MoveForward(float Value);
    void MoveRight(float Value);
    void TurnCamera(float Value);
    void LookCamera(float Value);
    void UpdateHeroProfile(bool bRestoreHealth);
    void UpdateVisualIdentity();
    int32 DamageEnemiesInArc(float Damage, float Radius, float MinimumDot, float PushStrength);
    int32 DamageEnemiesInRadius(float Damage, float Radius, float PushStrength);
    void RecalculateLevel();

    float DodgeCooldown = 0.0f;
    float AttackCooldown = 0.0f;
    float SkillCooldown = 0.0f;
    float DamageInvulnerability = 0.0f;
};
