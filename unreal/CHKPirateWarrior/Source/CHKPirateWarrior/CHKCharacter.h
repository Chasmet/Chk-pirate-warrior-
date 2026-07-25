#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "CHKCharacter.generated.h"

class USpringArmComponent;
class UCameraComponent;

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

    UFUNCTION(BlueprintCallable, Category="Combat")
    void ReceiveDamageCHK(float Amount);

    UFUNCTION(BlueprintImplementableEvent, Category="Combat")
    void OnAttackRequested();

    UFUNCTION(BlueprintImplementableEvent, Category="Combat")
    void OnSkillRequested(ECHKHeroId ActiveHero);

protected:
    virtual void BeginPlay() override;

private:
    void MoveForward(float Value);
    void MoveRight(float Value);
    void TurnCamera(float Value);
    void LookCamera(float Value);
    void Attack();
    void Skill();
    void Dodge();

    float CameraTargetYaw = 0.0f;
    float CameraTargetPitch = -12.0f;
    float DodgeCooldown = 0.0f;
};
