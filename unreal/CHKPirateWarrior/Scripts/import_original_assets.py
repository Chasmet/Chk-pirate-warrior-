"""Importe les assets originaux CHK dans Unreal Engine.

Exécution :
Unreal Editor > Tools > Execute Python Script
Puis choisir ce fichier.
"""

from __future__ import annotations

import os
import unreal

DESTINATION = "/Game/CHK/Props/Original"
ASSET_NAMES = (
    "SM_CHK_Crate.obj",
    "SM_CHK_Rock_A.obj",
    "SM_CHK_Anchor.obj",
    "SM_CHK_DockModule.obj",
)


def build_task(filename: str) -> unreal.AssetImportTask:
    task = unreal.AssetImportTask()
    task.filename = filename
    task.destination_path = DESTINATION
    task.automated = True
    task.replace_existing = True
    task.replace_existing_settings = True
    task.save = True

    options = unreal.FbxImportUI()
    options.import_as_skeletal = False
    options.import_mesh = True
    options.import_materials = True
    options.import_textures = False
    options.static_mesh_import_data.combine_meshes = True
    options.static_mesh_import_data.generate_lightmap_u_vs = True
    options.static_mesh_import_data.auto_generate_collision = True
    task.options = options
    return task


def main() -> None:
    source_dir = os.path.abspath(
        os.path.join(unreal.Paths.project_dir(), "ContentSource", "Original")
    )
    tasks: list[unreal.AssetImportTask] = []

    for asset_name in ASSET_NAMES:
        source_path = os.path.join(source_dir, asset_name)
        if not os.path.isfile(source_path):
            unreal.log_warning(f"Asset source absent : {source_path}")
            continue
        tasks.append(build_task(source_path))

    if not tasks:
        raise RuntimeError("Aucun asset original CHK n'a été trouvé.")

    unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks(tasks)

    imported = []
    for task in tasks:
        imported.extend(task.imported_object_paths)
        for object_path in task.imported_object_paths:
            asset = unreal.EditorAssetLibrary.load_asset(object_path)
            if isinstance(asset, unreal.StaticMesh):
                asset.set_editor_property("light_map_resolution", 64)
                unreal.EditorAssetLibrary.save_loaded_asset(asset, only_if_is_dirty=False)

    unreal.log(f"CHK : {len(imported)} assets originaux importés dans {DESTINATION}")


if __name__ == "__main__":
    main()
