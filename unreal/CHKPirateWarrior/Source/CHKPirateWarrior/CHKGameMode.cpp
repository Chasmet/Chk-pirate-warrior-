#include "CHKGameMode.h"

#include "CHKCharacter.h"
#include "CHKHUD.h"
#include "CHKPlayerController.h"
#include "CHKWorldBootstrap.h"
#include "Engine/World.h"

ACHKGameMode::ACHKGameMode()
{
    DefaultPawnClass = ACHKCharacter::StaticClass();
    PlayerControllerClass = ACHKPlayerController::StaticClass();
    HUDClass = ACHKHUD::StaticClass();
}

void ACHKGameMode::StartPlay()
{
    Super::StartPlay();

    if (!GetWorld())
    {
        return;
    }

    FActorSpawnParameters Params;
    Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
    GetWorld()->SpawnActor<ACHKWorldBootstrap>(FVector::ZeroVector, FRotator::ZeroRotator, Params);
}
