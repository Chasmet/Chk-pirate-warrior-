#include "CHKGameMode.h"
#include "CHKCharacter.h"

ACHKGameMode::ACHKGameMode()
{
    DefaultPawnClass = ACHKCharacter::StaticClass();
}
