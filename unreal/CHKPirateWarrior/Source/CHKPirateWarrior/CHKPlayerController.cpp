#include "CHKPlayerController.h"

#include "CHKBoatPawn.h"
#include "CHKCharacter.h"
#include "CHKSaveGame.h"
#include "Engine/Engine.h"
#include "EngineUtils.h"
#include "Kismet/GameplayStatics.h"

namespace
{
    constexpr TCHAR SaveSlotName[] = TEXT("CHK_Pirate_Warrior_UE5");
}

ACHKPlayerController::ACHKPlayerController()
{
    PrimaryActorTick.bCanEverTick = true;
    bEnableTouchEvents = true;
    bEnableClickEvents = false;
    bShowMouseCursor = false;
}

void ACHKPlayerController::BeginPlay()
{
    Super::BeginPlay();

    LandCharacter = Cast<ACHKCharacter>(GetPawn());
    LoadProgress();
}

void ACHKPlayerController::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);

    if (!LandCharacter.IsValid())
    {
        LandCharacter = Cast<ACHKCharacter>(GetPawn());
        if (bPendingLoad && LandCharacter.IsValid())
        {
            ApplyLoadedProgress();
        }
    }

    AutoSaveTimer -= DeltaSeconds;
    if (AutoSaveTimer <= 0.0f)
    {
        AutoSaveTimer = 15.0f;
        SaveProgress();
    }
}

void ACHKPlayerController::SetupInputComponent()
{
    Super::SetupInputComponent();

    InputComponent->BindAction(TEXT("Interact"), IE_Pressed, this, &ACHKPlayerController::Interact);
    InputComponent->BindAction(TEXT("Pause"), IE_Pressed, this, &ACHKPlayerController::TogglePause);
    InputComponent->BindTouch(IE_Pressed, this, &ACHKPlayerController::TouchPressed);
}

void ACHKPlayerController::Interact()
{
    if (ActiveBoat.IsValid() || Cast<ACHKBoatPawn>(GetPawn()))
    {
        ExitCurrentBoat();
    }
    else
    {
        EnterNearestBoat();
    }
}

void ACHKPlayerController::EnterNearestBoat()
{
    ACHKCharacter* Character = Cast<ACHKCharacter>(GetPawn());
    if (!Character)
    {
        return;
    }

    ACHKBoatPawn* Boat = FindNearestBoat(1850.0f);
    if (!Boat)
    {
        MissionText = TEXT("Approche-toi du quai et du navire pour embarquer.");
        return;
    }

    LandCharacter = Character;
    ActiveBoat = Boat;
    Character->GetCharacterMovement()->StopMovementImmediately();
    Boat->SetPilotCharacter(Character);
    Possess(Boat);
    MissionText = TEXT("EN MER • Pilote le navire jusqu'à l'île suivante. INTERACTION pour accoster.");
    SaveProgress();
}

void ACHKPlayerController::ExitCurrentBoat()
{
    ACHKBoatPawn* Boat = ActiveBoat.IsValid() ? ActiveBoat.Get() : Cast<ACHKBoatPawn>(GetPawn());
    if (!Boat || !LandCharacter.IsValid())
    {
        return;
    }

    ACHKCharacter* Character = LandCharacter.Get();
    const FVector ExitLocation = Boat->GetExitLocation();
    Boat->ClearPilotCharacter();
    Character->SetActorHiddenInGame(false);
    Character->SetActorLocation(ExitLocation, false, nullptr, ETeleportType::TeleportPhysics);
    Possess(Character);
    ActiveBoat.Reset();
    MissionText = TEXT("Accostage réussi • Explore l'île, combats et cherche les trésors.");
    SaveProgress();
}

ACHKBoatPawn* ACHKPlayerController::FindNearestBoat(float MaximumDistance) const
{
    const APawn* CurrentPawn = GetPawn();
    if (!CurrentPawn)
    {
        return nullptr;
    }

    ACHKBoatPawn* Nearest = nullptr;
    float NearestDistance = MaximumDistance;
    for (TActorIterator<ACHKBoatPawn> It(GetWorld()); It; ++It)
    {
        ACHKBoatPawn* Boat = *It;
        const float Distance = FVector::Dist2D(CurrentPawn->GetActorLocation(), Boat->GetActorLocation());
        if (Distance < NearestDistance)
        {
            NearestDistance = Distance;
            Nearest = Boat;
        }
    }
    return Nearest;
}

void ACHKPlayerController::SaveProgress()
{
    ACHKCharacter* Character = GetActiveCharacter();
    if (!Character)
    {
        return;
    }

    UCHKSaveGame* Save = Cast<UCHKSaveGame>(UGameplayStatics::CreateSaveGameObject(UCHKSaveGame::StaticClass()));
    if (!Save)
    {
        return;
    }

    Save->HeroId = Character->HeroId == ECHKHeroId::Cheikh
        ? TEXT("cheikh")
        : Character->HeroId == ECHKHeroId::Yvane ? TEXT("yvane") : TEXT("nelvyn");
    Save->Zone = CurrentIslandIndex;
    Save->DestinationZone = FMath::Clamp(CurrentIslandIndex + 1, 0, 5);
    Save->Level = Character->Level;
    Save->Experience = Character->Experience;
    Save->Coins = Character->Coins;
    if (!Save->UnlockedZones.Contains(CurrentIslandIndex))
    {
        Save->UnlockedZones.Add(CurrentIslandIndex);
    }

    UGameplayStatics::SaveGameToSlot(Save, SaveSlotName, 0);
}

void ACHKPlayerController::LoadProgress()
{
    if (!UGameplayStatics::DoesSaveGameExist(SaveSlotName, 0))
    {
        bPendingLoad = false;
        return;
    }

    bPendingLoad = true;
    ApplyLoadedProgress();
}

void ACHKPlayerController::ApplyLoadedProgress()
{
    ACHKCharacter* Character = GetActiveCharacter();
    if (!Character)
    {
        return;
    }

    UCHKSaveGame* Save = Cast<UCHKSaveGame>(UGameplayStatics::LoadGameFromSlot(SaveSlotName, 0));
    if (!Save)
    {
        bPendingLoad = false;
        return;
    }

    ECHKHeroId LoadedHero = ECHKHeroId::Cheikh;
    if (Save->HeroId.Equals(TEXT("yvane"), ESearchCase::IgnoreCase))
    {
        LoadedHero = ECHKHeroId::Yvane;
    }
    else if (Save->HeroId.Equals(TEXT("nelvyn"), ESearchCase::IgnoreCase))
    {
        LoadedHero = ECHKHeroId::Nelvyn;
    }

    CurrentIslandIndex = FMath::Clamp(Save->Zone, 0, 5);
    Character->ApplySavedProgress(LoadedHero, Save->Level, Save->Experience, Save->Coins);
    bPendingLoad = false;
}

ACHKCharacter* ACHKPlayerController::GetActiveCharacter() const
{
    if (LandCharacter.IsValid())
    {
        return LandCharacter.Get();
    }
    return Cast<ACHKCharacter>(GetPawn());
}

bool ACHKPlayerController::IsSailing() const
{
    return ActiveBoat.IsValid() || Cast<ACHKBoatPawn>(GetPawn()) != nullptr;
}

void ACHKPlayerController::SetWorldStatus(const FString& NewIslandName, const FString& NewMission, int32 NewIslandIndex)
{
    CurrentIslandName = NewIslandName;
    MissionText = NewMission;
    CurrentIslandIndex = FMath::Clamp(NewIslandIndex, 0, 5);
}

void ACHKPlayerController::TogglePause()
{
    const bool bNewPaused = !UGameplayStatics::IsGamePaused(this);
    SetPause(bNewPaused);
}

void ACHKPlayerController::TouchPressed(ETouchIndex::Type FingerIndex, FVector Location)
{
    int32 Width = 1;
    int32 Height = 1;
    GetViewportSize(Width, Height);
    const float X = Location.X / FMath::Max(1.0f, static_cast<float>(Width));
    const float Y = Location.Y / FMath::Max(1.0f, static_cast<float>(Height));

    ACHKCharacter* Character = GetActiveCharacter();
    if (!Character)
    {
        return;
    }

    if (X > 0.84f && Y > 0.68f)
    {
        Character->RequestAttack();
    }
    else if (X > 0.70f && Y > 0.69f)
    {
        Character->RequestSkill();
    }
    else if (X > 0.84f && Y > 0.43f)
    {
        Character->RequestDodge();
    }
    else if (X > 0.68f && Y > 0.43f)
    {
        Interact();
    }
    else if (X > 0.84f && Y < 0.26f && !IsSailing())
    {
        Character->SwitchHero();
    }
}
