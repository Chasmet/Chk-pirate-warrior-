#include "CHKWorldBootstrap.h"

#include "CHKBoatPawn.h"
#include "CHKCharacter.h"
#include "CHKEnemyCharacter.h"
#include "CHKPlayerController.h"
#include "Components/DirectionalLightComponent.h"
#include "Components/ExponentialHeightFogComponent.h"
#include "Components/SkyLightComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/DirectionalLight.h"
#include "Engine/ExponentialHeightFog.h"
#include "Engine/SkyAtmosphere.h"
#include "Engine/SkyLight.h"
#include "Engine/StaticMesh.h"
#include "Engine/StaticMeshActor.h"
#include "Kismet/GameplayStatics.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "UObject/ConstructorHelpers.h"

ACHKWorldBootstrap::ACHKWorldBootstrap()
{
    PrimaryActorTick.bCanEverTick = true;

    static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeAsset(TEXT("/Engine/BasicShapes/Cube.Cube"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> CylinderAsset(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> SphereAsset(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> ConeAsset(TEXT("/Engine/BasicShapes/Cone.Cone"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> PlaneAsset(TEXT("/Engine/BasicShapes/Plane.Plane"));

    CubeMesh = CubeAsset.Object;
    CylinderMesh = CylinderAsset.Object;
    SphereMesh = SphereAsset.Object;
    ConeMesh = ConeAsset.Object;
    PlaneMesh = PlaneAsset.Object;
}

void ACHKWorldBootstrap::BeginPlay()
{
    Super::BeginPlay();

    InitializeZones();
    BuildLightingAndAtmosphere();
    BuildOcean();
    BuildArchipelago();
    SpawnStartingBoat();
    ActivateZone(0);

    if (APawn* PlayerPawn = UGameplayStatics::GetPlayerPawn(this, 0))
    {
        PlayerPawn->SetActorLocation(FVector(0.0f, 0.0f, 430.0f), false, nullptr, ETeleportType::TeleportPhysics);
    }
}

void ACHKWorldBootstrap::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);

    ZoneProbeTimer -= DeltaSeconds;
    EncounterProbeTimer -= DeltaSeconds;

    if (ZoneProbeTimer <= 0.0f)
    {
        ZoneProbeTimer = 0.45f;
        UpdateCurrentZone();
    }

    if (EncounterProbeTimer <= 0.0f)
    {
        EncounterProbeTimer = 0.35f;
        UpdateEncounterState();
    }
}

void ACHKWorldBootstrap::InitializeZones()
{
    Zones.Reset();

    FCHKRuntimeZone Port;
    Port.Name = TEXT("Port des Naufragés");
    Port.Center = FVector(0.0f, 0.0f, 0.0f);
    Port.Radius = 10800.0f;
    Port.DockDirection = FVector(0.96f, 0.28f, 0.0f).GetSafeNormal();
    Port.GroundColor = FLinearColor(0.18f, 0.34f, 0.11f, 1.0f);
    Port.AccentColor = FLinearColor(0.72f, 0.44f, 0.12f, 1.0f);
    Port.BossId = TEXT("Brakor_Ancre_Noire");
    Zones.Add(Port);

    FCHKRuntimeZone Jungle;
    Jungle.Name = TEXT("Jungle Sauvage");
    Jungle.Center = FVector(31500.0f, -17500.0f, 0.0f);
    Jungle.Radius = 11600.0f;
    Jungle.DockDirection = FVector(-0.88f, 0.47f, 0.0f).GetSafeNormal();
    Jungle.GroundColor = FLinearColor(0.035f, 0.29f, 0.055f, 1.0f);
    Jungle.AccentColor = FLinearColor(0.22f, 0.75f, 0.10f, 1.0f);
    Jungle.BossId = TEXT("Mako_Roi_Crocodile");
    Zones.Add(Jungle);

    FCHKRuntimeZone Snow;
    Snow.Name = TEXT("Royaume des Neiges");
    Snow.Center = FVector(65500.0f, -7200.0f, 0.0f);
    Snow.Radius = 10400.0f;
    Snow.DockDirection = FVector(-0.99f, -0.08f, 0.0f).GetSafeNormal();
    Snow.GroundColor = FLinearColor(0.72f, 0.84f, 0.91f, 1.0f);
    Snow.AccentColor = FLinearColor(0.20f, 0.60f, 0.95f, 1.0f);
    Snow.BossId = TEXT("Kryl_Loup_Glace");
    Zones.Add(Snow);

    FCHKRuntimeZone Desert;
    Desert.Name = TEXT("Désert des Corsaires");
    Desert.Center = FVector(27500.0f, 26000.0f, 0.0f);
    Desert.Radius = 12200.0f;
    Desert.DockDirection = FVector(-0.62f, -0.78f, 0.0f).GetSafeNormal();
    Desert.GroundColor = FLinearColor(0.68f, 0.44f, 0.16f, 1.0f);
    Desert.AccentColor = FLinearColor(0.96f, 0.68f, 0.14f, 1.0f);
    Desert.BossId = TEXT("Scorpia_Reine_Dunes");
    Zones.Add(Desert);

    FCHKRuntimeZone Volcano;
    Volcano.Name = TEXT("Île Volcanique");
    Volcano.Center = FVector(62500.0f, 29500.0f, 0.0f);
    Volcano.Radius = 10200.0f;
    Volcano.DockDirection = FVector(-0.87f, -0.49f, 0.0f).GetSafeNormal();
    Volcano.GroundColor = FLinearColor(0.12f, 0.08f, 0.075f, 1.0f);
    Volcano.AccentColor = FLinearColor(0.95f, 0.12f, 0.015f, 1.0f);
    Volcano.BossId = TEXT("Volkan_Coeur_Lave");
    Zones.Add(Volcano);

    FCHKRuntimeZone Fortress;
    Fortress.Name = TEXT("Forteresse de la Tempête");
    Fortress.Center = FVector(95500.0f, 10500.0f, 0.0f);
    Fortress.Radius = 13200.0f;
    Fortress.DockDirection = FVector(-0.99f, 0.06f, 0.0f).GetSafeNormal();
    Fortress.GroundColor = FLinearColor(0.13f, 0.17f, 0.22f, 1.0f);
    Fortress.AccentColor = FLinearColor(0.30f, 0.60f, 1.0f, 1.0f);
    Fortress.BossId = TEXT("Vorga_Seigneur_Tempete");
    Zones.Add(Fortress);

    ZoneWaveStarted.Init(false, Zones.Num());
    ZoneCleared.Init(false, Zones.Num());
}

void ACHKWorldBootstrap::BuildLightingAndAtmosphere()
{
    if (!GetWorld())
    {
        return;
    }

    FActorSpawnParameters Params;
    Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;

    ADirectionalLight* Sun = GetWorld()->SpawnActor<ADirectionalLight>(FVector::ZeroVector, FRotator(-42.0f, -28.0f, 0.0f), Params);
    if (Sun && Sun->GetDirectionalLightComponent())
    {
        Sun->GetDirectionalLightComponent()->SetIntensity(7.2f);
        Sun->GetDirectionalLightComponent()->SetLightColor(FLinearColor(1.0f, 0.86f, 0.70f, 1.0f));
        Sun->GetDirectionalLightComponent()->SetCastShadows(true);
    }

    ASkyLight* Sky = GetWorld()->SpawnActor<ASkyLight>(FVector::ZeroVector, FRotator::ZeroRotator, Params);
    if (Sky && Sky->GetLightComponent())
    {
        Sky->GetLightComponent()->SetIntensity(1.1f);
        Sky->GetLightComponent()->SetMobility(EComponentMobility::Movable);
    }

    GetWorld()->SpawnActor<ASkyAtmosphere>(FVector::ZeroVector, FRotator::ZeroRotator, Params);

    AExponentialHeightFog* Fog = GetWorld()->SpawnActor<AExponentialHeightFog>(FVector(0.0f, 0.0f, -200.0f), FRotator::ZeroRotator, Params);
    if (Fog && Fog->GetComponent())
    {
        Fog->GetComponent()->SetFogDensity(0.006f);
        Fog->GetComponent()->SetFogHeightFalloff(0.18f);
        Fog->GetComponent()->SetFogInscatteringColor(FLinearColor(0.20f, 0.34f, 0.44f, 1.0f));
    }
}

void ACHKWorldBootstrap::BuildOcean()
{
    AStaticMeshActor* Ocean = SpawnPrimitive(
        PlaneMesh,
        FVector(45000.0f, 3000.0f, -18.0f),
        FRotator::ZeroRotator,
        FVector(2500.0f, 2500.0f, 1.0f),
        FLinearColor(0.012f, 0.18f, 0.31f, 0.96f),
        false,
        false);

    if (Ocean && Ocean->GetStaticMeshComponent())
    {
        Ocean->GetStaticMeshComponent()->SetReceivesDecals(false);
    }
}

void ACHKWorldBootstrap::BuildArchipelago()
{
    for (int32 ZoneIndex = 0; ZoneIndex < Zones.Num(); ++ZoneIndex)
    {
        BuildIsland(ZoneIndex);
        BuildDock(Zones[ZoneIndex]);
        BuildIslandProps(Zones[ZoneIndex], ZoneIndex);
    }
}

void ACHKWorldBootstrap::BuildIsland(int32 ZoneIndex)
{
    if (!Zones.IsValidIndex(ZoneIndex))
    {
        return;
    }

    const FCHKRuntimeZone& Zone = Zones[ZoneIndex];
    const float RadiusScale = Zone.Radius / 50.0f;

    SpawnPrimitive(
        CylinderMesh,
        Zone.Center + FVector(0.0f, 0.0f, 40.0f),
        FRotator::ZeroRotator,
        FVector(RadiusScale, RadiusScale, 2.8f),
        Zone.GroundColor,
        true);

    SpawnPrimitive(
        SphereMesh,
        Zone.Center + FVector(0.0f, 0.0f, -Zone.Radius * 0.39f),
        FRotator::ZeroRotator,
        FVector(RadiusScale * 0.94f, RadiusScale * 0.94f, RadiusScale * 0.46f),
        Zone.GroundColor * 0.55f,
        true);

    SpawnPrimitive(
        CylinderMesh,
        Zone.Center + FVector(0.0f, 0.0f, 205.0f),
        FRotator::ZeroRotator,
        FVector(RadiusScale * 0.56f, RadiusScale * 0.56f, 1.25f),
        FLinearColor::LerpUsingHSV(Zone.GroundColor, Zone.AccentColor, 0.18f),
        true);
}

void ACHKWorldBootstrap::BuildDock(const FCHKRuntimeZone& Zone)
{
    const FVector Direction = Zone.DockDirection.GetSafeNormal();
    const FVector Right = FVector::CrossProduct(FVector::UpVector, Direction).GetSafeNormal();
    const FVector Shore = Zone.Center + Direction * (Zone.Radius - 350.0f) + FVector(0.0f, 0.0f, 235.0f);

    for (int32 Index = 0; Index < 6; ++Index)
    {
        const FVector PlankLocation = Shore + Direction * (Index * 360.0f);
        SpawnPrimitive(
            CubeMesh,
            PlankLocation,
            Direction.Rotation(),
            FVector(3.8f, 1.35f, 0.14f),
            FLinearColor(0.34f, 0.13f, 0.035f, 1.0f),
            true);

        if (Index % 2 == 0)
        {
            SpawnPrimitive(CylinderMesh, PlankLocation + Right * 145.0f - FVector(0.0f, 0.0f, 170.0f), FRotator::ZeroRotator, FVector(0.20f, 0.20f, 4.2f), FLinearColor(0.18f, 0.055f, 0.015f, 1.0f), true);
            SpawnPrimitive(CylinderMesh, PlankLocation - Right * 145.0f - FVector(0.0f, 0.0f, 170.0f), FRotator::ZeroRotator, FVector(0.20f, 0.20f, 4.2f), FLinearColor(0.18f, 0.055f, 0.015f, 1.0f), true);
        }
    }
}

void ACHKWorldBootstrap::BuildIslandProps(const FCHKRuntimeZone& Zone, int32 ZoneIndex)
{
    FRandomStream Random(19820415 + ZoneIndex * 2014);

    for (int32 Index = 0; Index < 14; ++Index)
    {
        const float Angle = Random.FRandRange(0.0f, UE_TWO_PI);
        const float Distance = Random.FRandRange(Zone.Radius * 0.22f, Zone.Radius * 0.76f);
        const FVector BaseLocation = Zone.Center + FVector(FMath::Cos(Angle), FMath::Sin(Angle), 0.0f) * Distance + FVector(0.0f, 0.0f, 360.0f);
        const float Size = Random.FRandRange(0.75f, 1.55f);

        if (ZoneIndex == 0 || ZoneIndex == 1)
        {
            SpawnPrimitive(CylinderMesh, BaseLocation, FRotator::ZeroRotator, FVector(0.24f * Size, 0.24f * Size, 3.2f * Size), FLinearColor(0.19f, 0.065f, 0.018f, 1.0f), true);
            SpawnPrimitive(ConeMesh, BaseLocation + FVector(0.0f, 0.0f, 270.0f * Size), FRotator::ZeroRotator, FVector(1.45f * Size, 1.45f * Size, 1.15f * Size), ZoneIndex == 1 ? FLinearColor(0.02f, 0.34f, 0.04f, 1.0f) : FLinearColor(0.08f, 0.42f, 0.10f, 1.0f), false);
        }
        else if (ZoneIndex == 2)
        {
            SpawnPrimitive(ConeMesh, BaseLocation, FRotator::ZeroRotator, FVector(1.55f * Size, 1.55f * Size, 3.4f * Size), FLinearColor(0.08f, 0.27f, 0.20f, 1.0f), true);
            SpawnPrimitive(ConeMesh, BaseLocation + FVector(0.0f, 0.0f, 190.0f * Size), FRotator::ZeroRotator, FVector(1.20f * Size, 1.20f * Size, 2.2f * Size), FLinearColor(0.82f, 0.91f, 0.98f, 1.0f), false);
        }
        else
        {
            SpawnPrimitive(SphereMesh, BaseLocation, FRotator(Random.FRandRange(-25.0f, 25.0f), Random.FRandRange(0.0f, 180.0f), Random.FRandRange(-18.0f, 18.0f)), FVector(1.6f * Size, 1.15f * Size, 0.95f * Size), ZoneIndex == 4 ? FLinearColor(0.08f, 0.045f, 0.035f, 1.0f) : Zone.GroundColor * 0.62f, true);
        }
    }

    for (int32 BuildingIndex = 0; BuildingIndex < 4; ++BuildingIndex)
    {
        const float Angle = UE_TWO_PI * static_cast<float>(BuildingIndex) / 4.0f + ZoneIndex * 0.31f;
        const FVector Location = Zone.Center + FVector(FMath::Cos(Angle), FMath::Sin(Angle), 0.0f) * (Zone.Radius * 0.42f) + FVector(0.0f, 0.0f, 520.0f);
        const FVector BuildingScale = ZoneIndex == 5 ? FVector(5.2f, 5.2f, 7.8f) : FVector(3.4f, 3.0f, 4.2f);
        SpawnPrimitive(CubeMesh, Location, FRotator(0.0f, FMath::RadiansToDegrees(Angle), 0.0f), BuildingScale, ZoneIndex == 2 ? FLinearColor(0.42f, 0.52f, 0.62f, 1.0f) : FLinearColor(0.24f, 0.105f, 0.035f, 1.0f), true);
        SpawnPrimitive(ConeMesh, Location + FVector(0.0f, 0.0f, 450.0f), FRotator::ZeroRotator, FVector(BuildingScale.X * 0.86f, BuildingScale.Y * 0.86f, 2.2f), Zone.AccentColor, true);
    }

    if (ZoneIndex == 4)
    {
        SpawnPrimitive(ConeMesh, Zone.Center + FVector(0.0f, 0.0f, 950.0f), FRotator::ZeroRotator, FVector(34.0f, 34.0f, 18.0f), FLinearColor(0.055f, 0.035f, 0.03f, 1.0f), true);
        SpawnPrimitive(ConeMesh, Zone.Center + FVector(0.0f, 0.0f, 1880.0f), FRotator(180.0f, 0.0f, 0.0f), FVector(8.0f, 8.0f, 5.5f), FLinearColor(1.0f, 0.09f, 0.01f, 1.0f), false);
    }
}

void ACHKWorldBootstrap::SpawnStartingBoat()
{
    if (!GetWorld() || Zones.IsEmpty())
    {
        return;
    }

    const FCHKRuntimeZone& Port = Zones[0];
    const FVector BoatLocation = Port.Center + Port.DockDirection * (Port.Radius + 1950.0f) + FVector(0.0f, 0.0f, 35.0f);
    const FRotator BoatRotation = (-Port.DockDirection).Rotation();

    FActorSpawnParameters Params;
    Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AdjustIfPossibleButAlwaysSpawn;
    StartingBoat = GetWorld()->SpawnActor<ACHKBoatPawn>(BoatLocation, BoatRotation, Params);
}

void ACHKWorldBootstrap::SpawnEnemyWave(int32 ZoneIndex)
{
    if (!GetWorld() || !Zones.IsValidIndex(ZoneIndex))
    {
        return;
    }

    const FCHKRuntimeZone& Zone = Zones[ZoneIndex];
    ActiveEnemies.Reset();
    bBossSpawnedForActiveZone = false;

    const ECHKEnemyArchetype Archetypes[] = {
        ECHKEnemyArchetype::Raider,
        ECHKEnemyArchetype::Shooter,
        ECHKEnemyArchetype::Assassin,
        ECHKEnemyArchetype::Brute,
        ECHKEnemyArchetype::Healer
    };

    FRandomStream Random(15041982 + ZoneIndex * 8082017);
    for (int32 Index = 0; Index < 8; ++Index)
    {
        const float Angle = UE_TWO_PI * static_cast<float>(Index) / 8.0f + Random.FRandRange(-0.18f, 0.18f);
        const float Distance = Random.FRandRange(Zone.Radius * 0.26f, Zone.Radius * 0.54f);
        const FVector Location = Zone.Center + FVector(FMath::Cos(Angle), FMath::Sin(Angle), 0.0f) * Distance + FVector(0.0f, 0.0f, 520.0f);

        FActorSpawnParameters Params;
        Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AdjustIfPossibleButAlwaysSpawn;
        ACHKEnemyCharacter* Enemy = GetWorld()->SpawnActor<ACHKEnemyCharacter>(Location, FRotator::ZeroRotator, Params);
        if (Enemy)
        {
            const ECHKEnemyArchetype Archetype = Archetypes[(Index + ZoneIndex) % UE_ARRAY_COUNT(Archetypes)];
            const FLinearColor EnemyColor = FLinearColor::LerpUsingHSV(Zone.AccentColor, FLinearColor(0.46f, 0.03f, 0.025f, 1.0f), 0.55f);
            Enemy->ConfigureEnemy(Archetype, FString::Printf(TEXT("enemy_%d_%d"), ZoneIndex, Index), false, EnemyColor);
            ActiveEnemies.Add(Enemy);
        }
    }

    ZoneWaveStarted[ZoneIndex] = true;
}

void ACHKWorldBootstrap::SpawnBoss(int32 ZoneIndex)
{
    if (!GetWorld() || !Zones.IsValidIndex(ZoneIndex))
    {
        return;
    }

    const FCHKRuntimeZone& Zone = Zones[ZoneIndex];
    const FVector SpawnLocation = Zone.Center + FVector(Zone.Radius * 0.16f, 0.0f, 620.0f);

    FActorSpawnParameters Params;
    Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AdjustIfPossibleButAlwaysSpawn;
    ACHKEnemyCharacter* Boss = GetWorld()->SpawnActor<ACHKEnemyCharacter>(SpawnLocation, FRotator::ZeroRotator, Params);
    if (Boss)
    {
        Boss->ConfigureEnemy(ECHKEnemyArchetype::Boss, Zone.BossId, true, Zone.AccentColor);
        Boss->MaxHealth += ZoneIndex * 170.0f;
        Boss->Health = Boss->MaxHealth;
        Boss->Damage += ZoneIndex * 3.5f;
        ActiveBoss = Boss;
        bBossSpawnedForActiveZone = true;

        if (ACHKPlayerController* Controller = Cast<ACHKPlayerController>(UGameplayStatics::GetPlayerController(this, 0)))
        {
            Controller->SetWorldStatus(Zone.Name, FString::Printf(TEXT("BOSS • %s est apparu. Utilise les trois héros et leurs pouvoirs."), *Zone.BossId), ZoneIndex);
        }
    }
}

void ACHKWorldBootstrap::UpdateCurrentZone()
{
    APawn* PlayerPawn = UGameplayStatics::GetPlayerPawn(this, 0);
    if (!PlayerPawn || Zones.IsEmpty())
    {
        return;
    }

    int32 NearestZone = ActiveZoneIndex;
    float NearestDistance = TNumericLimits<float>::Max();
    for (int32 Index = 0; Index < Zones.Num(); ++Index)
    {
        const float Distance = FVector::Dist2D(PlayerPawn->GetActorLocation(), Zones[Index].Center);
        if (Distance < NearestDistance && Distance <= Zones[Index].Radius + 4200.0f)
        {
            NearestDistance = Distance;
            NearestZone = Index;
        }
    }

    if (NearestZone != ActiveZoneIndex)
    {
        ActivateZone(NearestZone);
    }
}

void ACHKWorldBootstrap::UpdateEncounterState()
{
    if (!Zones.IsValidIndex(ActiveZoneIndex) || ZoneCleared[ActiveZoneIndex])
    {
        return;
    }

    int32 AliveEnemies = 0;
    for (const TWeakObjectPtr<ACHKEnemyCharacter>& Enemy : ActiveEnemies)
    {
        if (Enemy.IsValid() && Enemy->IsAlive())
        {
            ++AliveEnemies;
        }
    }

    if (AliveEnemies > 0)
    {
        return;
    }

    if (!bBossSpawnedForActiveZone)
    {
        SpawnBoss(ActiveZoneIndex);
        return;
    }

    if (!ActiveBoss.IsValid() || !ActiveBoss->IsAlive())
    {
        ZoneCleared[ActiveZoneIndex] = true;
        const FCHKRuntimeZone& Zone = Zones[ActiveZoneIndex];
        if (ACHKPlayerController* Controller = Cast<ACHKPlayerController>(UGameplayStatics::GetPlayerController(this, 0)))
        {
            Controller->SetWorldStatus(Zone.Name, TEXT("ÎLE LIBÉRÉE • Trésor obtenu. Rejoins le bateau pour poursuivre l'archipel."), ActiveZoneIndex);
            Controller->SaveProgress();
        }
    }
}

void ACHKWorldBootstrap::ActivateZone(int32 ZoneIndex)
{
    if (!Zones.IsValidIndex(ZoneIndex))
    {
        return;
    }

    ClearActiveEncounter();
    ActiveZoneIndex = ZoneIndex;
    const FCHKRuntimeZone& Zone = Zones[ZoneIndex];

    if (ACHKPlayerController* Controller = Cast<ACHKPlayerController>(UGameplayStatics::GetPlayerController(this, 0)))
    {
        if (ZoneCleared[ZoneIndex])
        {
            Controller->SetWorldStatus(Zone.Name, TEXT("Région libérée • Explore ou repars vers le quai."), ZoneIndex);
        }
        else
        {
            Controller->SetWorldStatus(Zone.Name, TEXT("Élimine les 8 ennemis de l'île pour faire apparaître son boss."), ZoneIndex);
        }
    }

    if (!ZoneCleared[ZoneIndex])
    {
        SpawnEnemyWave(ZoneIndex);
    }
}

void ACHKWorldBootstrap::ClearActiveEncounter()
{
    for (const TWeakObjectPtr<ACHKEnemyCharacter>& Enemy : ActiveEnemies)
    {
        if (Enemy.IsValid())
        {
            Enemy->Destroy();
        }
    }
    ActiveEnemies.Reset();

    if (ActiveBoss.IsValid())
    {
        ActiveBoss->Destroy();
    }
    ActiveBoss.Reset();
    bBossSpawnedForActiveZone = false;
}

AStaticMeshActor* ACHKWorldBootstrap::SpawnPrimitive(
    UStaticMesh* Mesh,
    const FVector& Location,
    const FRotator& Rotation,
    const FVector& Scale,
    const FLinearColor& Color,
    bool bCollision,
    bool bCastShadow)
{
    if (!GetWorld() || !Mesh)
    {
        return nullptr;
    }

    FActorSpawnParameters Params;
    Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
    AStaticMeshActor* Actor = GetWorld()->SpawnActor<AStaticMeshActor>(Location, Rotation, Params);
    if (!Actor || !Actor->GetStaticMeshComponent())
    {
        return Actor;
    }

    UStaticMeshComponent* Component = Actor->GetStaticMeshComponent();
    Component->SetStaticMesh(Mesh);
    Component->SetMobility(EComponentMobility::Static);
    Component->SetCollisionEnabled(bCollision ? ECollisionEnabled::QueryAndPhysics : ECollisionEnabled::NoCollision);
    Component->SetCollisionProfileName(bCollision ? TEXT("BlockAll") : TEXT("NoCollision"));
    Component->SetCastShadow(bCastShadow);
    Actor->SetActorScale3D(Scale);
    ApplyColor(Actor, Color);
    return Actor;
}

void ACHKWorldBootstrap::ApplyColor(AStaticMeshActor* Actor, const FLinearColor& Color) const
{
    if (!Actor || !Actor->GetStaticMeshComponent())
    {
        return;
    }

    UMaterialInstanceDynamic* Material = Actor->GetStaticMeshComponent()->CreateAndSetMaterialInstanceDynamic(0);
    if (Material)
    {
        Material->SetVectorParameterValue(TEXT("Color"), Color);
    }
}
