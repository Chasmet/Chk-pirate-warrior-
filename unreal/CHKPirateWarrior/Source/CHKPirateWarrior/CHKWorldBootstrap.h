#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "CHKWorldBootstrap.generated.h"

class UStaticMesh;
class AStaticMeshActor;
class ACHKEnemyCharacter;
class ACHKBoatPawn;

USTRUCT()
struct FCHKRuntimeZone
{
    GENERATED_BODY()

    FString Name;
    FVector Center = FVector::ZeroVector;
    float Radius = 10000.0f;
    FVector DockDirection = FVector::ForwardVector;
    FLinearColor GroundColor = FLinearColor::Green;
    FLinearColor AccentColor = FLinearColor::White;
    FString BossId;
};

UCLASS()
class CHKPIRATEWARRIOR_API ACHKWorldBootstrap : public AActor
{
    GENERATED_BODY()

public:
    ACHKWorldBootstrap();

    virtual void Tick(float DeltaSeconds) override;

    UFUNCTION(BlueprintPure, Category="World")
    int32 GetActiveZoneIndex() const { return ActiveZoneIndex; }

protected:
    virtual void BeginPlay() override;

private:
    void InitializeZones();
    void BuildLightingAndAtmosphere();
    void BuildOcean();
    void BuildArchipelago();
    void BuildIsland(int32 ZoneIndex);
    void BuildDock(const FCHKRuntimeZone& Zone);
    void BuildIslandProps(const FCHKRuntimeZone& Zone, int32 ZoneIndex);
    void SpawnStartingBoat();
    void SpawnEnemyWave(int32 ZoneIndex);
    void SpawnBoss(int32 ZoneIndex);
    void UpdateCurrentZone();
    void UpdateEncounterState();
    void ActivateZone(int32 ZoneIndex);
    void ClearActiveEncounter();

    AStaticMeshActor* SpawnPrimitive(
        UStaticMesh* Mesh,
        const FVector& Location,
        const FRotator& Rotation,
        const FVector& Scale,
        const FLinearColor& Color,
        bool bCollision,
        bool bCastShadow = true);

    void ApplyColor(AStaticMeshActor* Actor, const FLinearColor& Color) const;

    UPROPERTY()
    TObjectPtr<UStaticMesh> CubeMesh;

    UPROPERTY()
    TObjectPtr<UStaticMesh> CylinderMesh;

    UPROPERTY()
    TObjectPtr<UStaticMesh> SphereMesh;

    UPROPERTY()
    TObjectPtr<UStaticMesh> ConeMesh;

    UPROPERTY()
    TObjectPtr<UStaticMesh> PlaneMesh;

    UPROPERTY()
    TObjectPtr<ACHKBoatPawn> StartingBoat;

    TArray<FCHKRuntimeZone> Zones;
    TArray<bool> ZoneWaveStarted;
    TArray<bool> ZoneCleared;
    TArray<TWeakObjectPtr<ACHKEnemyCharacter>> ActiveEnemies;
    TWeakObjectPtr<ACHKEnemyCharacter> ActiveBoss;
    int32 ActiveZoneIndex = 0;
    bool bBossSpawnedForActiveZone = false;
    float ZoneProbeTimer = 0.0f;
    float EncounterProbeTimer = 0.0f;
};
