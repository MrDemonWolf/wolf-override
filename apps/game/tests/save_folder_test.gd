extends "res://tests/support/game_suite.gd"
## Keeps players' saves and settings where they were before the game was renamed.
##
## Godot puts user:// in a folder named after application/config/name unless the project sets a
## custom one. Up to 0.15.0 the name was "WOLF//OVERRIDE", and Godot 4.7's OS::get_safe_dir_name
## (core/os/os.cpp, 4.7.2-stable) turns each "/" into "-", so saves lived in
## <data dir>/<Godot|godot>/app_userdata/WOLF--OVERRIDE. On October 17, 2026 the name became
## "WOLF OVERRIDE", which would have moved user:// to a new, empty ".../WOLF OVERRIDE" folder.
## project.godot therefore sets application/config/use_custom_user_dir and names the old folder in
## custom_user_dir_name. A custom name is put straight under the OS data dir, so it has to repeat the
## engine folder Godot would add itself: "Godot" on macOS and Windows (OS_MacOS / OS_Windows
## get_godot_dir_name capitalises it), lowercase "godot" on Linux/BSD and the web (the OS default),
## hence the .linuxbsd and .web feature overrides. Android and iOS ignore the name and always use the
## app's own data folder, so they need nothing.
##
## Run headless with an isolated HOME (scripts/check-game.sh does): it reads paths only and writes
## nothing.

## The folder under the engine folder that 0.15.0 and earlier saved into; never change it.
const LEGACY_FOLDER: String = "app_userdata/WOLF--OVERRIDE"


func _initialize() -> void:
	check_name = "Save folder"
	_expect(str(ProjectSettings.get_setting("application/config/name")) == "WOLF OVERRIDE", "the project is named WOLF OVERRIDE")
	var engine_folder: String = "godot" if OS.has_feature("linuxbsd") or OS.has_feature("web") else "Godot"
	var expected: String = OS.get_data_dir().path_join(engine_folder).path_join(LEGACY_FOLDER)
	_expect(OS.get_user_data_dir() == expected, "user:// stays in the folder the old name gave (%s, got %s)" % [expected, OS.get_user_data_dir()])
	_expect(ProjectSettings.globalize_path("user://m0-save.json") == expected.path_join("m0-save.json"), "the checkpoint save resolves inside that folder")
	finish("Save folder checks passed")
