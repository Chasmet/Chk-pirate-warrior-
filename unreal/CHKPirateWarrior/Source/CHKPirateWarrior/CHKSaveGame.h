#pragma once

#include "CoreMinimal.h"
#include "GameFramework/SaveGame.h"
#include "CHKSaveGame.generated.h"

USTRUCT(BlueprintType)
struct FCHKTrainingData
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    int32 Force = 0;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    int32 Vitesse = 0;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    int32 Energie = 0;
};

UCLASS()
class CHKPIRATEWARRIOR_API UCHKSaveGame : public USaveGame
{
    GENERATED_BODY()

public:
    UPROPERTY(EditAnywhere, BlueprintReadWrite, SaveGame)
    FString HeroId = TEXT("cheikh");

    UPROPERTY(EditAnywhere, BlueprintReadWrite, SaveGame)
    int32 Zone = 0;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, SaveGame)
    int32 DestinationZone = 1;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, SaveGame)
    TArray<int32> UnlockedZones = {0};

    UPROPERTY(EditAnywhere, BlueprintReadWrite, SaveGame)
    FString Difficulty = TEXT("intermediaire");

    UPROPERTY(EditAnywhere, BlueprintReadWrite, SaveGame)
    int32 Level = 1;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, SaveGame)
    int32 Experience = 0;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, SaveGame)
    int32 Coins = 250;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, SaveGame)
    FCHKTrainingData Training;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, SaveGame)
    TArray<FString> DefeatedBosses;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, SaveGame)
    bool bVoiceEnabled = true;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, SaveGame)
    FString QualityPreset = TEXT("elevee");
};
