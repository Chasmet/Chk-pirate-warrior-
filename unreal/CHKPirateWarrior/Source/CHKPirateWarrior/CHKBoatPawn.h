#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Pawn.h"
#include "CHKBoatPawn.generated.h"

class UStaticMeshComponent;
class USpringArmComponent;
class UCameraComponent;

UCLASS()
class CHKPIRATEWARRIOR_API ACHKBoatPawn : public APawn
{
    GENERATED_BODY()

public:
    ACHKBoatPawn();

    virtual void Tick(float DeltaSeconds) override;
    virtual void SetupPlayerInputComponent(UInputComponent* PlayerInputComponent) override;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Boat")
    TObjectPtr<UStaticMeshComponent> Hull;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Camera")
    TObjectPtr<USpringArmComponent> CameraBoom;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Camera")
    TObjectPtr<UCameraComponent> BoatCamera;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Boat")
    float MaximumForwardSpeed = 1800.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Boat")
    float MaximumReverseSpeed = 520.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Boat")
    float Acceleration = 620.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Boat")
    float TurnSpeedDegrees = 44.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Boat")
    float WaterLevel = 35.0f;

    UPROPERTY(BlueprintReadOnly, Category="Boat")
    float CurrentSpeed = 0.0f;

protected:
    virtual void BeginPlay() override;

private:
    void Throttle(float Value);
    void Steering(float Value);
    void TurnCamera(float Value);
    void LookCamera(float Value);

    float ThrottleInput = 0.0f;
    float SteeringInput = 0.0f;
    float WaveTime = 0.0f;
};
