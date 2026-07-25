using UnrealBuildTool;
using System.Collections.Generic;

public class CHKPirateWarriorEditorTarget : TargetRules
{
    public CHKPirateWarriorEditorTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Editor;
        DefaultBuildSettings = BuildSettingsVersion.Latest;
        IncludeOrderVersion = EngineIncludeOrderVersion.Latest;
        ExtraModuleNames.Add("CHKPirateWarrior");
    }
}
