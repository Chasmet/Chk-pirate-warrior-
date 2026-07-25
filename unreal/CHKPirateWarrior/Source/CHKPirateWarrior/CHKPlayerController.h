#pragma once

#include "CoreMinimal.h"
#include "GameFramework/PlayerController.h"
#include "CHKPlayerController.generated.h"

class ACHKCharacter;
class ACHKBoatPawn;

UCLASS()
class CHKPIRATEWARRIOR_API ACHKPlayerController : public APlayerController
{
    GENERATED_BODY()

public:
    ACHKPlayerController();

    virtual void Tick(float DeltaSeconds) override;
    virtual void SetupInputComponent() override;

    UFUNCTION(BlueprintCallable, Category="Interaction")
    void Interact();

    UFUNCTION(BlueprintCallable, Category="Save")
    void SaveProgress();

    UFUNCTION(BlueprintCallable, Category="Save")
    void LoadProgress();

    UFUNCTION(BlueprintPure, Category="HUD")
    ACHKCharacter* GetActiveCharacter() const;

    UFUNCTION(BlueprintPure, Category="HUD")
    ACHKBoatPawn* GetActiveBoat() const;

    UFUNCTION(BlueprintPure, Category="HUD")
    bool IsSailing() const;

    UFUNCTION(BlueprintPure, Category="HUD")
    float GetBoatSpeedKmh() const;

    UFUNCTION(BlueprintPure, Category="HUD")
    FString GetMissionText() const { return MissionText; }

    UFUNCTION(BlueprintPure, Category="HUD")
    FString GetCurrentIslandName() const { return CurrentIslandName; }

    UFUNCTION(BlueprintPure, Category="World")
    int32 GetCurrentIslandIndex() const { return CurrentIslandIndex; }

    UFUNCTION(BlueprintCallable, Category="World")
    void SetWorldStatus(const FString& NewIslandName, const FString& NewMission, int32 NewIslandIndex);

protected:
    virtual void BeginPlay() override;

private:
    void EnterNearestBoat();
    void ExitCurrentBoat();
    void TogglePause();
    void TouchPressed(ETouchIndex::Type FingerIndex, FVector Location);
    ACHKBoatPawn* FindNearestBoat(float MaximumDistance) const;
    void ApplyLoadedProgress();
    void ClampCameraPitch();
    bool IsTouchInsideButton(const FVector2D& TouchPosition, const FVector2D& ButtonCenter, float Radius) const;

    TWeakObjectPtr<ACHKCharacter> LandCharacter;
    TWeakObjectPtr<ACHKBoatPawn> ActiveBoat;
    FString MissionText = TEXT("Explore le Port des Naufragés et élimine les pirates.");
    FString CurrentIslandName = TEXT("Port des Naufragés");
    int32 CurrentIslandIndex = 0;
    float AutoSaveTimer = 15.0f;
    bool bPendingLoad = false;
};
