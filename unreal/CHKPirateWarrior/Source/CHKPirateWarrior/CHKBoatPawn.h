#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Pawn.h"
#include "CHKBoatPawn.generated.h"

class UStaticMeshComponent;
class USpringArmComponent;
class UCameraComponent;
class ACHKCharacter;

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

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Boat")
    TObjectPtr<UStaticMeshComponent> Deck;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Boat")
    TObjectPtr<UStaticMeshComponent> Mast;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Boat")
    TObjectPtr<UStaticMeshComponent> Sail;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Boat")
    TObjectPtr<UStaticMeshComponent> Rudder;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Boat")
    TObjectPtr<UStaticMeshComponent> Helm;

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

    UFUNCTION(BlueprintCallable, Category="Boat")
    void SetPilotCharacter(ACHKCharacter* NewPilot);

    UFUNCTION(BlueprintCallable, Category="Boat")
    void ClearPilotCharacter();

    UFUNCTION(BlueprintPure, Category="Boat")
    FVector GetExitLocation() const;

    UFUNCTION(BlueprintCallable, Category="Boat")
    bool FindSafeExitLocation(FVector& OutLocation) const;

    UFUNCTION(BlueprintPure, Category="Boat")
    FTransform GetHelmTransform() const;

    UFUNCTION(BlueprintPure, Category="Boat")
    bool HasPilot() const { return PilotCharacter.IsValid(); }

    UFUNCTION(BlueprintPure, Category="Boat")
    float GetSpeedKmh() const { return FMath::Abs(CurrentSpeed) * 0.036f; }

protected:
    virtual void BeginPlay() override;

private:
    void Throttle(float Value);
    void Steering(float Value);
    void TurnCamera(float Value);
    void LookCamera(float Value);
    void UpdatePilotPresentation(float DeltaSeconds);
    void ApplyBoatMaterials();

    float ThrottleInput = 0.0f;
    float SteeringInput = 0.0f;
    float SmoothedThrottleInput = 0.0f;
    float SmoothedSteeringInput = 0.0f;
    float WaveTime = 0.0f;
    TWeakObjectPtr<ACHKCharacter> PilotCharacter;
};
