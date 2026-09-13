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
