#pragma once

#include "CoreMinimal.h"
#include "GameFramework/HUD.h"
#include "CHKHUD.generated.h"

UCLASS()
class CHKPIRATEWARRIOR_API ACHKHUD : public AHUD
{
    GENERATED_BODY()

public:
    virtual void DrawHUD() override;

private:
    void DrawFilledRect(const FVector2D& Position, const FVector2D& Size, const FLinearColor& Color) const;
    void DrawLabel(const FString& Text, const FVector2D& Position, const FLinearColor& Color, float Scale = 1.0f, bool bLarge = false) const;
    void DrawActionButton(const FString& Label, const FVector2D& Center, float Radius, const FLinearColor& Color) const;
};
