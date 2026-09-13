# Performance notes

## Harness and provenance

The measurements below were produced by `tools/stress_test.gd` against `res://levels/test_level.tscn` with Godot **4.7.2.stable.official.ed1daf0bf**, in headless mode, on **2026-09-13**. The measured repository base commit was `fd27fd3c772445b548e613a2ca3fcc33a8fbe66a`; the implementation is intentionally kept separate from the normal functional-test suite. Each enemy step sampled 300 frames. The harness instantiated only the existing Shambler (`enemy.tscn`), Stalker (`enemy_stalker.tscn`), and Brute (`enemy_brute.tscn`) scenes.

The monitor enum names were checked against the official [Godot 4.7 `Performance` documentation](https://docs.godotengine.org/en/4.7/classes/class_performance.html): `TIME_FPS`, `TIME_PROCESS`, `TIME_PHYSICS_PROCESS`, `OBJECT_COUNT`, `OBJECT_ORPHAN_NODE_COUNT`, and `PHYSICS_3D_ACTIVE_OBJECTS`.

## Enemy scaling results

Times are seconds per frame. The warning column is mechanical: it is marked when either mean process time or mean physics time is more than twice the 10-enemy baseline. It is not a diagnosis of production code.

| Enemy target | FPS mean | Process mean / min / max | Physics mean / min / max | Scene nodes | Objects | Orphans | Active 3D physics | Warning |
|---:|---:|---:|---:|---:|---:|---:|---:|:---:|
| 10 | 76.8633 | 0.0063888 / 0.000208 / 0.014963 | 0.0033901 / 0.002367 / 0.065605 | 636 | 2,560 | 0 | 15 | No |
| 25 | 144.5167 | 0.0151166 / 0.000252 / 0.017107 | 0.0046471 / 0.003680 / 0.005879 | 891 | 2,862 | 0 | 30 | [هشدار عملکرد] |
| 50 | 143.3433 | 0.0163911 / 0.000252 / 0.030586 | 0.0082354 / 0.005879 / 0.010411 | 1,316 | 3,363 | 0 | 55 | [هشدار عملکرد] |
| 100 | 105.8500 | 0.0283259 / 0.000569 / 0.059557 | 0.0184628 / 0.010411 / 0.020902 | 2,166 | 4,369 | 0 | 105 | [هشدار عملکرد] |

The reported `PHYSICS_3D_ACTIVE_OBJECTS` count includes the existing level physics bodies as well as the stress enemies, so it is not expected to equal the enemy target. The 25-enemy FPS mean being higher than the 10-enemy sample reflects the headless measurement environment and the documented once-per-second update behavior of `TIME_FPS`; it should not be interpreted as a monotonic scaling claim.

## Pickup lifecycle result

The harness performed **200** create-and-`queue_free` cycles using the existing `water_bottle.tscn` pickup. The node count was **466 before and after**, and `OBJECT_ORPHAN_NODE_COUNT` was **0** after cleanup. The harness therefore reported **no suspected node leak** in this run.

Enemy cleanup was also checked independently: the node count returned from the 100-enemy step to the 466-node baseline after despawn, with no suspected node leak.

## Reproducibility and limits

Run from the project root with:

```sh
godot --headless --path . -s res://tools/stress_test.gd
```

The machine-readable output is `stress_test_results.json`; it is ignored by Git and is not part of the change. `gdparse tools/stress_test.gd` and `godot --headless --import --quit` completed successfully for this run.

This was a CPU/headless sandbox run without a user GPU or interactive display. **مطمئن نیستم این عدد نماینده‌ی عملکرد واقعی روی دستگاه کاربر است**; especially FPS and render-related behavior should be rechecked on the target hardware with the normal renderer. The results are measurements only, not a claim that the observed thresholds identify a production defect.

## Long soak test

A continuous **5,000-frame** soak with **50 fixed stress enemies** completed under Godot 4.7.2 headless. Samples were recorded every 250 frames. The node count stayed at 1,316 for every sample after setup; orphan nodes stayed at 0. `OBJECT_COUNT` moved from 3,367 to 3,378 in small non-monotonic steps and then remained flat, while the rolling `TIME_PROCESS` mean stayed in the observed 0.00454–0.00873 second range rather than rising continuously. This run did **not** show the requested pattern of a continuously rising node/object count or a creeping process-time trend.

| Soak frame | TIME_PROCESS sample | TIME_PROCESS rolling mean | Nodes | OBJECT_COUNT | Orphans |
|---:|---:|---:|---:|---:|---:|
| 250 | 0.000485 | 0.008730 | 1,316 | 3,367 | 0 |
| 500 | 0.000288 | 0.004538 | 1,316 | 3,367 | 0 |
| 750 | 0.016193 | 0.006154 | 1,317 | 3,374 | 0 |
| 1,000 | 0.000252 | 0.004715 | 1,316 | 3,371 | 0 |
| 1,250 | 0.019358 | 0.004829 | 1,316 | 3,371 | 0 |
| 1,500 | 0.000289 | 0.005091 | 1,316 | 3,371 | 0 |
| 1,750 | 0.016452 | 0.005624 | 1,316 | 3,377 | 0 |
| 2,000 | 0.000510 | 0.005072 | 1,316 | 3,377 | 0 |
| 2,250 | 0.016021 | 0.004924 | 1,316 | 3,377 | 0 |
| 2,500 | 0.000310 | 0.005043 | 1,316 | 3,377 | 0 |
| 2,750 | 0.015740 | 0.005286 | 1,316 | 3,377 | 0 |
| 3,000 | 0.000293 | 0.004994 | 1,316 | 3,377 | 0 |
| 3,250 | 0.016375 | 0.004854 | 1,316 | 3,377 | 0 |
| 3,500 | 0.000251 | 0.004997 | 1,316 | 3,377 | 0 |
| 3,750 | 0.000377 | 0.004684 | 1,316 | 3,377 | 0 |
| 4,000 | 0.000310 | 0.004988 | 1,316 | 3,377 | 0 |
| 4,250 | 0.017273 | 0.004842 | 1,316 | 3,377 | 0 |
| 4,500 | 0.000304 | 0.005016 | 1,316 | 3,378 | 0 |
| 4,750 | 0.000389 | 0.004788 | 1,316 | 3,378 | 0 |
| 5,000 | 0.000427 | 0.005157 | 1,316 | 3,378 | 0 |

The isolated one-node increase at frame 750 and the small object-count changes are not a continuous upward trend in this run. They are reported as observed values only; no production code was changed.

## Save-file fuzzing

A separate external script, `tools/save_fuzz_test.py`, performs random bit flips on a supplied generated save file, runs the exported binary headlessly, captures stdout/stderr, and restores the original bytes in a `finally` block. It does not read or modify `core/save/**`, and it does not attempt to repair parsing behavior; that ownership remains with the concurrent Arena work.

No generated save file was available in this sandbox. The existing `tests/save_load_test.gd` was run only to produce one, but it emitted repeated real errors (`Invalid assignment of property or key 'global_position' ... on a base object of type 'Nil'` at `tests/save_load_test.gd:126`) and did not produce a save artifact before it was stopped. The fuzz script therefore returned `FUZZ_SKIPPED missing_save=...` rather than fabricating a result. This means the bit-flip launch outcome is **not claimed** for this run. The Arena remote-branch audit found no `tools/`, `tests/save_load*`, or `core/save/**` changes, so work continued without touching those paths.

The long soak and the save-generation failure were both observed under a headless sandbox. **مطمئن نیستم این عدد نماینده‌ی عملکرد واقعی روی دستگاه کاربر است**; target-hardware validation remains necessary.
