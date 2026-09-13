# Build notes

## Manual Linux export

The repository already contains `export_presets.cfg` with a Linux preset named **Linux** and targets Godot **4.7.2**. No preset file change is required. In Godot Editor, open **Project > Export**, select **Linux**, confirm that the 4.7.2 export templates are installed, and click **Export Project**. Choose `build/aftergrid.x86_64` (or another local output path). The output extension is conventional for a 64-bit Linux build; the path is relative to the project directory.

The same preset can be exported from a terminal with:

```sh
godot --headless --path . --export-release "Linux" build/aftergrid.x86_64
```

The CI workflow is deliberately manual-only (`workflow_dispatch`) because downloading the editor and export templates is large and slow. It does not run on `push` or `pull_request`. The workflow uses Godot 4.7.2 and the matching export templates, then uploads `build/aftergrid.x86_64` as the `aftergrid-linux-x86_64` artifact.

The local Godot 4.7.2 validation export succeeded and produced a 71 MiB Linux binary. A real `gh workflow run export-build.yml --ref manus/perf-and-build-pipeline` dispatch was attempted after pushing this branch, but GitHub returned `404: workflow export-build.yml not found on the default branch`. GitHub only exposes a newly added workflow for dispatch after the workflow exists on the default branch, so no CI run or artifact link exists yet; the workflow remains unmerged as requested.

Godot's official 4.7 documentation states that command-line export requires a named preset in `export_presets.cfg` and a matching export template: [Exporting projects](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_projects.html).
