#!/usr/bin/env python3
"""Validation statique du prototype Unreal autonome de CHK Pirate Warrior.

Cette vérification ne remplace pas UnrealBuildTool, mais bloque les régressions de
structure, les fichiers tronqués, les délimiteurs déséquilibrés et les systèmes
indispensables manquants avant la compilation réelle du moteur.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Source" / "CHKPirateWarrior"

REQUIRED_FILES = {
    "CHKCharacter.h": ["RequestAttack", "RequestSkill", "SwitchHero", "AddRewards"],
    "CHKCharacter.cpp": ["DamageEnemiesInArc", "ÉPÉE INFERNALE", "BOULE DU BIG BANG"],
    "CHKBoatPawn.h": ["SetPilotCharacter", "FindSafeExitLocation", "GetSpeedKmh"],
    "CHKBoatPawn.cpp": ["SmoothedSteeringInput", "OverlapBlockingTestByChannel", "UpdatePilotPresentation"],
    "CHKEnemyCharacter.h": ["ECHKEnemyArchetype", "ConfigureEnemy", "bBoss"],
    "CHKEnemyCharacter.cpp": ["UpdateBossPhase", "RewardExperience"],
    "CHKPlayerController.h": ["Interact", "SaveProgress", "GetBoatSpeedKmh", "IsTouchInsideButton"],
    "CHKPlayerController.cpp": ["BindTouch", "ClampCameraPitch", "FindSafeExitLocation", "IsTouchInsideButton"],
    "CHKHUD.h": ["DrawHUD"],
    "CHKHUD.cpp": ["ATTAQUE", "POUVOIR", "ACCOSTER", "NAVIGATION"],
    "CHKWorldBootstrap.h": ["FCHKRuntimeZone", "BuildArchipelago"],
    "CHKWorldBootstrap.cpp": ["Port des Naufragés", "Forteresse de la Tempête", "SpawnBoss"],
    "CHKGameMode.cpp": ["ACHKWorldBootstrap", "ACHKHUD", "ACHKPlayerController"],
    "CHKSaveGame.h": ["UnlockedZones", "DefeatedBosses"],
}


def remove_comments_and_strings(text: str) -> str:
    text = re.sub(r"//.*", "", text)
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    text = re.sub(r'L?TEXT\("(?:\\.|[^"\\])*"\)', "TEXT", text)
    text = re.sub(r'"(?:\\.|[^"\\])*"', '""', text)
    text = re.sub(r"'(?:\\.|[^'\\])*'", "''", text)
    return text


def balanced(text: str, opening: str, closing: str) -> bool:
    depth = 0
    for char in text:
        if char == opening:
            depth += 1
        elif char == closing:
            depth -= 1
            if depth < 0:
                return False
    return depth == 0


def fail(message: str) -> None:
    print(f"ERREUR: {message}", file=sys.stderr)


def main() -> int:
    failures = 0
    total_lines = 0

    for filename, markers in REQUIRED_FILES.items():
        path = SOURCE / filename
        if not path.is_file():
            fail(f"fichier obligatoire absent: {path.relative_to(ROOT)}")
            failures += 1
            continue

        text = path.read_text(encoding="utf-8")
        total_lines += text.count("\n") + 1
        if len(text.strip()) < 40:
            fail(f"fichier probablement tronqué: {filename}")
            failures += 1

        for marker in markers:
            if marker not in text:
                fail(f"marqueur fonctionnel absent dans {filename}: {marker}")
                failures += 1

        cleaned = remove_comments_and_strings(text)
        for opening, closing, label in [("{", "}", "accolades"), ("(", ")", "parenthèses"), ("[", "]", "crochets")]:
            if not balanced(cleaned, opening, closing):
                fail(f"{label} déséquilibrés dans {filename}")
                failures += 1

        if "TODO" in text or "PLACEHOLDER" in text:
            fail(f"code provisoire interdit dans {filename}")
            failures += 1

    input_config = (ROOT / "Config" / "DefaultInput.ini").read_text(encoding="utf-8")
    for action in ["Attack", "Skill", "Dodge", "Interact", "SwitchHero"]:
        if f'ActionName="{action}"' not in input_config:
            fail(f"commande absente de DefaultInput.ini: {action}")
            failures += 1

    engine_config = (ROOT / "Config" / "DefaultEngine.ini").read_text(encoding="utf-8")
    for marker in ["GlobalDefaultGameMode=/Script/CHKPirateWarrior.CHKGameMode", "TargetSDKVersion=35", "bBuildForArm64=True"]:
        if marker not in engine_config:
            fail(f"configuration obligatoire absente: {marker}")
            failures += 1

    print(f"CHK_TURNKEY_SOURCE_FILES={len(REQUIRED_FILES)}")
    print(f"CHK_TURNKEY_SOURCE_LINES={total_lines}")
    print("CHK_TURNKEY_SYSTEMS=HEROES,COMBAT,POWERS,BOAT,SAFE_DOCKING,ARCHIPELAGO,ENEMIES,BOSSES,HUD,TOUCH,SAVE")

    if failures:
        print(f"CHK_TURNKEY_VALIDATION_FAILED={failures}", file=sys.stderr)
        return 1

    print("CHK_TURNKEY_VALIDATION_OK=1")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
