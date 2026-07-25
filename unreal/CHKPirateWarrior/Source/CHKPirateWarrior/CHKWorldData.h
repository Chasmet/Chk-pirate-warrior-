#pragma once

#include "CoreMinimal.h"
#include "CHKWorldData.generated.h"

UENUM(BlueprintType)
enum class ECHKWeather : uint8
{
    Soleil,
    Pluie,
    Neige,
    Cendres,
    Tempete
};

USTRUCT(BlueprintType)
struct FCHKIslandDefinition
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    FName Id;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    FText DisplayName;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    FVector Center = FVector::ZeroVector;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    float Radius = 10000.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    FVector DockDirection = FVector::ForwardVector;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    ECHKWeather Weather = ECHKWeather::Soleil;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    FName BossId;
};

struct CHKPIRATEWARRIOR_API FCHKWorldData
{
    static TArray<FCHKIslandDefinition> BuildDefaultArchipelago()
    {
        TArray<FCHKIslandDefinition> Islands;
        Islands.Reserve(6);

        auto AddIsland = [&Islands](FName Id, const TCHAR* Name, FVector Center, float Radius, FVector Dock, ECHKWeather Weather, FName BossId)
        {
            FCHKIslandDefinition Island;
            Island.Id = Id;
            Island.DisplayName = FText::FromString(Name);
            Island.Center = Center;
            Island.Radius = Radius;
            Island.DockDirection = Dock.GetSafeNormal();
            Island.Weather = Weather;
            Island.BossId = BossId;
            Islands.Add(Island);
        };

        AddIsland(TEXT("port"), TEXT("Port des Naufrages"), FVector(0.0f, 0.0f, 0.0f), 10800.0f, FVector(0.96f, 0.28f, 0.0f), ECHKWeather::Soleil, TEXT("brakor"));
        AddIsland(TEXT("jungle"), TEXT("Jungle Sauvage"), FVector(31500.0f, -17500.0f, 0.0f), 11600.0f, FVector(-0.88f, 0.47f, 0.0f), ECHKWeather::Pluie, TEXT("scorpia"));
        AddIsland(TEXT("neige"), TEXT("Royaume des Neiges"), FVector(65500.0f, -7200.0f, 0.0f), 10400.0f, FVector(-0.99f, -0.08f, 0.0f), ECHKWeather::Neige, TEXT("kryl"));
        AddIsland(TEXT("desert"), TEXT("Desert des Corsaires"), FVector(27500.0f, 26000.0f, 0.0f), 12200.0f, FVector(-0.62f, -0.78f, 0.0f), ECHKWeather::Soleil, TEXT("mako"));
        AddIsland(TEXT("volcan"), TEXT("Ile Volcanique"), FVector(62500.0f, 29500.0f, 0.0f), 10200.0f, FVector(-0.87f, -0.49f, 0.0f), ECHKWeather::Cendres, TEXT("volkan"));
        AddIsland(TEXT("tempete"), TEXT("Forteresse de la Tempete"), FVector(95500.0f, 10500.0f, 0.0f), 13200.0f, FVector(-0.99f, 0.06f, 0.0f), ECHKWeather::Tempete, TEXT("vorga"));

        return Islands;
    }
};
