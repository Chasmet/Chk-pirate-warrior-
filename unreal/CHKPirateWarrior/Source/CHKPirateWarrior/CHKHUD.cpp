#include "CHKHUD.h"

#include "CHKCharacter.h"
#include "CHKPlayerController.h"
#include "CanvasItem.h"
#include "Engine/Canvas.h"
#include "Engine/Engine.h"

void ACHKHUD::DrawHUD()
{
    Super::DrawHUD();

    if (!Canvas)
    {
        return;
    }

    const ACHKPlayerController* Controller = Cast<ACHKPlayerController>(GetOwningPlayerController());
    const ACHKCharacter* Character = Controller ? Controller->GetActiveCharacter() : nullptr;
    if (!Controller || !Character)
    {
        return;
    }

    const float Width = Canvas->SizeX;
    const float Height = Canvas->SizeY;
    const float UiScale = FMath::Clamp(Height / 1080.0f, 0.70f, 1.35f);

    DrawFilledRect(FVector2D(24.0f * UiScale, 22.0f * UiScale), FVector2D(610.0f * UiScale, 152.0f * UiScale), FLinearColor(0.005f, 0.012f, 0.025f, 0.78f));
    DrawLabel(Character->GetHeroDisplayName(), FVector2D(46.0f * UiScale, 36.0f * UiScale), FLinearColor(1.0f, 0.76f, 0.18f, 1.0f), UiScale, true);
    DrawLabel(FString::Printf(TEXT("NIVEAU %d  •  %d PIÈCES"), Character->Level, Character->Coins), FVector2D(46.0f * UiScale, 76.0f * UiScale), FLinearColor::White, 0.86f * UiScale);

    const FVector2D HealthPosition(46.0f * UiScale, 108.0f * UiScale);
    const FVector2D EnergyPosition(46.0f * UiScale, 138.0f * UiScale);
    const FVector2D BarSize(520.0f * UiScale, 18.0f * UiScale);
    DrawFilledRect(HealthPosition, BarSize, FLinearColor(0.08f, 0.02f, 0.025f, 0.92f));
    DrawFilledRect(HealthPosition, FVector2D(BarSize.X * Character->GetHealthRatio(), BarSize.Y), FLinearColor(0.78f, 0.035f, 0.025f, 0.95f));
    DrawFilledRect(EnergyPosition, BarSize, FLinearColor(0.015f, 0.035f, 0.08f, 0.92f));
    DrawFilledRect(EnergyPosition, FVector2D(BarSize.X * Character->GetEnergyRatio(), BarSize.Y), FLinearColor(0.035f, 0.42f, 0.92f, 0.95f));

    DrawFilledRect(FVector2D(Width * 0.21f, 24.0f * UiScale), FVector2D(Width * 0.58f, 84.0f * UiScale), FLinearColor(0.005f, 0.012f, 0.025f, 0.72f));
    DrawLabel(Controller->GetCurrentIslandName(), FVector2D(Width * 0.235f, 36.0f * UiScale), FLinearColor(0.92f, 0.72f, 0.20f, 1.0f), 0.95f * UiScale, true);
    DrawLabel(Controller->GetMissionText(), FVector2D(Width * 0.235f, 74.0f * UiScale), FLinearColor::White, 0.72f * UiScale);

    const float Radius = 68.0f * UiScale;
    DrawActionButton(TEXT("ATTAQUE"), FVector2D(Width - 105.0f * UiScale, Height - 115.0f * UiScale), Radius, FLinearColor(0.62f, 0.04f, 0.025f, 0.74f));
    DrawActionButton(TEXT("POUVOIR"), FVector2D(Width - 285.0f * UiScale, Height - 115.0f * UiScale), Radius, FLinearColor(0.08f, 0.25f, 0.78f, 0.74f));
    DrawActionButton(TEXT("ESQUIVE"), FVector2D(Width - 105.0f * UiScale, Height - 320.0f * UiScale), Radius, FLinearColor(0.10f, 0.58f, 0.40f, 0.72f));
    DrawActionButton(Controller->IsSailing() ? TEXT("ACCOSTER") : TEXT("BATEAU"), FVector2D(Width - 285.0f * UiScale, Height - 320.0f * UiScale), Radius, FLinearColor(0.68f, 0.42f, 0.08f, 0.72f));

    if (!Controller->IsSailing())
    {
        DrawActionButton(TEXT("HÉROS"), FVector2D(Width - 105.0f * UiScale, 165.0f * UiScale), 54.0f * UiScale, FLinearColor(0.45f, 0.10f, 0.65f, 0.72f));
    }

    DrawFilledRect(FVector2D(Width * 0.33f, Height - 68.0f * UiScale), FVector2D(Width * 0.34f, 44.0f * UiScale), FLinearColor(0.005f, 0.012f, 0.025f, 0.72f));
    DrawLabel(Character->GetSkillDisplayName(), FVector2D(Width * 0.355f, Height - 58.0f * UiScale), FLinearColor(1.0f, 0.78f, 0.22f, 1.0f), 0.78f * UiScale);
}

void ACHKHUD::DrawFilledRect(const FVector2D& Position, const FVector2D& Size, const FLinearColor& Color) const
{
    if (!Canvas)
    {
        return;
    }
    FCanvasTileItem Tile(Position, Size, Color);
    Tile.BlendMode = SE_BLEND_Translucent;
    Canvas->DrawItem(Tile);
}

void ACHKHUD::DrawLabel(const FString& Text, const FVector2D& Position, const FLinearColor& Color, float Scale, bool bLarge) const
{
    if (!Canvas || !GEngine)
    {
        return;
    }

    UFont* Font = bLarge ? GEngine->GetLargeFont() : GEngine->GetSmallFont();
    FCanvasTextItem TextItem(Position, FText::FromString(Text), Font, Color);
    TextItem.Scale = FVector2D(Scale);
    TextItem.EnableShadow(FLinearColor::Black);
    Canvas->DrawItem(TextItem);
}

void ACHKHUD::DrawActionButton(const FString& Label, const FVector2D& Center, float Radius, const FLinearColor& Color) const
{
    DrawFilledRect(Center - FVector2D(Radius), FVector2D(Radius * 2.0f), Color);
    DrawLabel(Label, Center - FVector2D(Radius * 0.72f, 10.0f), FLinearColor::White, 0.70f);
}
