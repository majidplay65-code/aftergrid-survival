# Build notes

## Manual Linux export

The repository already contains `export_presets.cfg` with a Linux preset named **Linux** and targets Godot **4.7.2**. No preset file change is required. In Godot Editor, open **Project > Export**, select **Linux**, confirm that the 4.7.2 export templates are installed, and click **Export Project**. Choose `build/aftergrid.x86_64` (or another local output path). The output extension is conventional for a 64-bit Linux build; the path is relative to the project directory.

The same preset can be exported from a terminal with:

```sh
godot --headless --path . --export-release "Linux" build/aftergrid.x86_64
```

The CI workflow is deliberately manual-only (`workflow_dispatch`) because downloading the editor and export templates is large and slow. It does not run on `push` or `pull_request`. The workflow uses Godot 4.7.2 and the matching export templates, then uploads `build/aftergrid.x86_64` as the `aftergrid-linux-x86_64` artifact.

The local Godot 4.7.2 validation export succeeded and produced a 71 MiB Linux binary. A real `gh workflow run export-build.yml --ref manus/perf-and-build-pipeline` dispatch was attempted after pushing this branch, but GitHub returned `404: workflow export-build.yml not found on the default branch`. GitHub only exposes a newly added workflow for dispatch after the workflow exists on the default branch, so no CI run or artifact link exists yet; the workflow remains unmerged as requested.

## Save/load reproduction and external fuzz

The exact existing-test command was rerun after a clean Godot import:

```sh
godot --headless --path . --verbose -s res://tests/save_load_test.gd
```

The engine was `4.7.2.stable.official.ed1daf0bf`. The complete imported log had 349 lines. It loaded these autoload scripts before the level and save test ran: `EventBus`, `GameState`, `SceneManager`, `SaveManager`, `InventoryManager`, `CraftingSystem`, and `AudioManager`. The test then loaded `user://saves/save_slot_1.tres`, printed `PASS: P4` checks, completed all 101 checks, printed `ALL TESTS PASSED (save/load)`, and exited successfully. The earlier Nil error was therefore an import-state artifact from deleted `.import` metadata, not reproduced after the documented import step. The full raw log was retained in the sandbox as `/tmp/save-load-full-imported.log`.

The passing test generated the real save artifact at `user://saves/save_slot_1.tres`, which resolved in this sandbox to `/home/ubuntu/.local/share/godot/app_userdata/Aftergrid/saves/save_slot_1.tres` and was 380 bytes. The external `tools/save_fuzz_test.py` then flipped 8 random bits with seed 1337 and launched the exported binary headlessly for 15 seconds. It reported `FUZZ_RESULT outcome=timeout_without_crash flips=8 bytes=380`; the captured output contained startup loading logs and no crash signal. The original save file was restored by the harness.

The official [Godot 4.7 command-line tutorial](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html) documents `-s` for scripts run by the Godot editor binary. **مطمئن نیستم** that an ordinary client release export is intended to accept arbitrary `-s` scripts; I did not rely on that undocumented behavior. Instead, the editor binary in headless mode ran the existing project save/load script, while the release binary was used for the actual fuzz launch. The official [dedicated-server documentation](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_dedicated_servers.html) confirms that release export templates can run with `--headless`.

## Exported-binary smoke test

The previously exported 71 MiB `aftergrid.x86_64` was executed directly, not through the Editor, with `--headless --audio-driver Dummy --verbose`. The official [Godot 4.7 dedicated-server documentation](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_dedicated_servers.html) states that an editor or debug/release export template can run with `--headless` on a machine without a GPU or display server. The real run stayed alive for the 15-second smoke timeout (exit 124 from `timeout`, not a process crash), and its verbose stdout showed the exported `res://ui/menus/main_menu.tscn` loading and completing. No `ERROR`, `SCRIPT ERROR`, `Parse Error`, or `Invalid` lines were present. The manual workflow now performs the same check after export and before artifact upload; timeout 124 is treated as expected because the client remains at the main menu.

Godot's official 4.7 documentation states that command-line export requires a named preset in `export_presets.cfg` and a matching export template: [Exporting projects](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_projects.html).
