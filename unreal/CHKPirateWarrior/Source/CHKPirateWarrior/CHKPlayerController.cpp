#include "CHKPlayerController.h"

#include "CHKBoatPawn.h"
#include "CHKCharacter.h"
#include "CHKSaveGame.h"
#include "Engine/Engine.h"
#include "EngineUtils.h"
#include "GameFramework/CharacterMovementComponent.h"
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

    ClampCameraPitch();

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
    MissionText = TEXT("EN MER • Joystick gauche pour naviguer, joystick droit pour la caméra. Approche un quai pour accoster.");
    SaveProgress();
}

void ACHKPlayerController::ExitCurrentBoat()
{
    ACHKBoatPawn* Boat = GetActiveBoat();
    if (!Boat || !LandCharacter.IsValid())
    {
        return;
    }

    FVector ExitLocation;
    if (!Boat->FindSafeExitLocation(ExitLocation))
    {
        MissionText = TEXT("ACCOSTAGE IMPOSSIBLE • Ralentis et rapproche le navire d'un quai ou d'une rive.");
        return;
    }

    ACHKCharacter* Character = LandCharacter.Get();
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
    for (int32 Index = 0; Index <= CurrentIslandIndex; ++Index)
    {
        Save->UnlockedZones.AddUnique(Index);
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

ACHKBoatPawn* ACHKPlayerController::GetActiveBoat() const
{
    if (ActiveBoat.IsValid())
    {
        return ActiveBoat.Get();
    }
    return Cast<ACHKBoatPawn>(GetPawn());
}

bool ACHKPlayerController::IsSailing() const
{
    return GetActiveBoat() != nullptr;
}

float ACHKPlayerController::GetBoatSpeedKmh() const
{
    const ACHKBoatPawn* Boat = GetActiveBoat();
    return Boat ? Boat->GetSpeedKmh() : 0.0f;
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
    (void)FingerIndex;

    int32 Width = 1;
    int32 Height = 1;
    GetViewportSize(Width, Height);

    const float UiScale = FMath::Clamp(static_cast<float>(Height) / 1080.0f, 0.70f, 1.35f);
    const FVector2D TouchPosition(Location.X, Location.Y);

    if (IsSailing())
    {
        const FVector2D DockButton(static_cast<float>(Width) - 115.0f * UiScale, static_cast<float>(Height) * 0.48f);
        if (IsTouchInsideButton(TouchPosition, DockButton, 78.0f * UiScale))
        {
            Interact();
        }
        return;
    }

    ACHKCharacter* Character = GetActiveCharacter();
    if (!Character)
    {
        return;
    }

    const float Radius = 68.0f * UiScale;
    const FVector2D AttackButton(static_cast<float>(Width) - 105.0f * UiScale, static_cast<float>(Height) * 0.44f);
    const FVector2D SkillButton(static_cast<float>(Width) - 285.0f * UiScale, static_cast<float>(Height) * 0.44f);
    const FVector2D DodgeButton(static_cast<float>(Width) - 105.0f * UiScale, static_cast<float>(Height) * 0.63f);
    const FVector2D BoatButton(static_cast<float>(Width) - 285.0f * UiScale, static_cast<float>(Height) * 0.63f);
    const FVector2D HeroButton(static_cast<float>(Width) - 105.0f * UiScale, static_cast<float>(Height) * 0.20f);

    if (IsTouchInsideButton(TouchPosition, AttackButton, Radius))
    {
        Character->RequestAttack();
    }
    else if (IsTouchInsideButton(TouchPosition, SkillButton, Radius))
    {
        Character->RequestSkill();
    }
    else if (IsTouchInsideButton(TouchPosition, DodgeButton, Radius))
    {
        Character->RequestDodge();
    }
    else if (IsTouchInsideButton(TouchPosition, BoatButton, Radius))
    {
        Interact();
    }
    else if (IsTouchInsideButton(TouchPosition, HeroButton, 54.0f * UiScale))
    {
        Character->SwitchHero();
    }
}

void ACHKPlayerController::ClampCameraPitch()
{
    FRotator ControlRotation = GetControlRotation();
    const float NormalizedPitch = FMath::UnwindDegrees(ControlRotation.Pitch);
    const float MinimumPitch = IsSailing() ? -52.0f : -68.0f;
    const float MaximumPitch = IsSailing() ? 20.0f : 34.0f;
    const float ClampedPitch = FMath::Clamp(NormalizedPitch, MinimumPitch, MaximumPitch);

    if (!FMath::IsNearlyEqual(ControlRotation.Pitch, ClampedPitch, 0.01f) || !FMath::IsNearlyZero(ControlRotation.Roll, 0.01f))
    {
        ControlRotation.Pitch = ClampedPitch;
        ControlRotation.Roll = 0.0f;
        SetControlRotation(ControlRotation);
    }
}

bool ACHKPlayerController::IsTouchInsideButton(const FVector2D& TouchPosition, const FVector2D& ButtonCenter, float Radius) const
{
    return FVector2D::Distance(TouchPosition, ButtonCenter) <= Radius;
}
