#!/usr/bin/env python3
"""تولید navmesh دستی هم‌لبه (بدون T-junction) برای levels/test_level.tscn.

الگوریتم: شبکه‌ای از همه‌ی لبه‌های محوطه‌های مانع + مرز نقشه‌ی قابل‌عبور.
هر خانه‌ای که مرکزش داخل مانع باشد حذف می‌شود؛ رأس‌های استفاده‌نشده حذف می‌شوند.
وفاداری با navmesh فعلی (۶ ساختمان، ۱۳۴ رأس / ۱۷۲ مثلث) اثبات می‌شود.
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path

# سطح قابل‌عبور فعلی (همان [-40,40]²).
BOUNDS = (-40.0, 40.0, -40.0, 40.0)  # xmin, xmax, zmin, zmax

# محوطه‌ی جهانیِ ۶ مانع فعلی (transform × vertices در test_level.tscn).
OLD_FOOTPRINTS: list[tuple[float, float, float, float]] = [
    # ObstacleB1 Bldg1
    (-26.5, -7.5, -25.5, -8.5),
    # ObstacleB2 Bldg2
    (8.5, 23.5, -21.5, -8.5),
    # ObstacleB3 Bldg3
    (-22.5, -7.5, 9.5, 22.5),
    # ObstacleB4 Bldg4
    (7.5, 26.5, 9.5, 24.5),
    # ObstacleB5 Bldg5
    (0.5, 11.5, -26.5, -17.5),
    # ObstacleB6 Bldg6
    (2.5, 13.5, 19.5, 28.5),
]

# محوطه‌ی جهانیِ سازه‌های جدید فاز ۹ (انبار/کانتینر/سوله + حاشیه‌ی ۰.۵).
NEW_FOOTPRINTS: list[tuple[float, float, float, float]] = [
    # WarehouseA at (34, -5), half (4, 3.5) + 0.5
    (29.5, 38.5, -9.0, -1.0),
    # WarehouseB at (34, 7), same
    (29.5, 38.5, 3.0, 11.0),
    # Container1 at (36, -16), half (3, 1.2) + 0.5
    (32.5, 39.5, -17.7, -14.3),
    # Container2 at (36, 1.5)
    (32.5, 39.5, -0.2, 3.2),
    # Container3 at (36, 18)
    (32.5, 39.5, 16.3, 19.7),
    # Shed at (30, 22), half (2, 2) + 0.5
    (27.5, 32.5, 19.5, 24.5),
    # SafeShop at (-10, 6), half (2.5, 2.5) + 0.5
    (-13.0, -7.0, 3.0, 9.0),
]


def _fmt(n: float) -> str:
    if abs(n - round(n)) < 1e-9:
        return str(int(round(n)))
    text = f"{n:.4f}".rstrip("0").rstrip(".")
    return text


def _inside(x: float, z: float, boxes: list[tuple[float, float, float, float]]) -> bool:
    for xmin, xmax, zmin, zmax in boxes:
        if xmin < x < xmax and zmin < z < zmax:
            return True
    return False


def build_mesh(
    boxes: list[tuple[float, float, float, float]],
    bounds: tuple[float, float, float, float] = BOUNDS,
) -> tuple[list[tuple[float, float]], list[tuple[int, int, int]]]:
    xmin, xmax, zmin, zmax = bounds
    xs: set[float] = {xmin, xmax}
    zs: set[float] = {zmin, zmax}
    for bx0, bx1, bz0, bz1 in boxes:
        xs.add(bx0)
        xs.add(bx1)
        zs.add(bz0)
        zs.add(bz1)
    x_list = sorted(xs)
    z_list = sorted(zs)

    cells: list[tuple[int, int]] = []
    index_of: dict[tuple[int, int], int] = {}
    vertices: list[tuple[float, float]] = []

    def _use(i: int, j: int) -> int:
        key = (i, j)
        if key not in index_of:
            index_of[key] = len(vertices)
            vertices.append((x_list[i], z_list[j]))
        return index_of[key]

    # پیمایش نوارهای z بیرونی و x درونی — همان ترتیب رأس‌های navmesh فعلی.
    for j in range(len(z_list) - 1):
        for i in range(len(x_list) - 1):
            cx = (x_list[i] + x_list[i + 1]) * 0.5
            cz = (z_list[j] + z_list[j + 1]) * 0.5
            if _inside(cx, cz, boxes):
                continue
            cells.append((i, j))
            _use(i, j)
            _use(i + 1, j)
            _use(i + 1, j + 1)
            _use(i, j + 1)

    polygons: list[tuple[int, int, int]] = []
    for i, j in cells:
        a = index_of[(i, j)]
        b = index_of[(i + 1, j)]
        c = index_of[(i + 1, j + 1)]
        d = index_of[(i, j + 1)]
        polygons.append((a, b, c))
        polygons.append((a, c, d))
    return vertices, polygons


def format_navmesh_block(
    vertices: list[tuple[float, float]],
    polygons: list[tuple[int, int, int]],
) -> str:
    verts = ", ".join(f"{_fmt(x)}, 0, {_fmt(z)}" for x, z in vertices)
    polys = ", ".join(
        f"PackedInt32Array({a}, {b}, {c})" for a, b, c in polygons
    )
    return (
        "[sub_resource type=\"NavigationMesh\" id=\"navpoly\"]\n"
        f"vertices = PackedVector3Array({verts})\n"
        f"polygons = [{polys}]\n"
    )


def parse_existing(path: Path) -> tuple[int, int]:
    text = path.read_text(encoding="utf-8")
    v_match = re.search(
        r"vertices = PackedVector3Array\(([^)]*)\)", text
    )
    p_match = re.search(r"polygons = \[([^\]]*)\]", text)
    if v_match is None or p_match is None:
        raise RuntimeError("navmesh block not found")
    v_nums = [n for n in v_match.group(1).split(",") if n.strip()]
    vertex_count = len(v_nums) // 3
    poly_count = p_match.group(1).count("PackedInt32Array")
    return vertex_count, poly_count


def replace_navmesh(path: Path, block: str) -> None:
    text = path.read_text(encoding="utf-8")
    new_text, n = re.subn(
        r"\[sub_resource type=\"NavigationMesh\" id=\"navpoly\"\]\n"
        r"vertices = PackedVector3Array\([^)]*\)\n"
        r"polygons = \[[^\]]*\]\n",
        block,
        text,
        count=1,
    )
    if n != 1:
        raise RuntimeError(f"expected 1 navmesh block, replaced {n}")
    path.write_text(new_text, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--verify-old",
        action="store_true",
        help="مقایسه با navmesh فعلی (باید ۱۳۴/۱۷۲ باشد)",
    )
    parser.add_argument(
        "--apply-new",
        action="store_true",
        help="با ردپای قدیمی+جدید navmesh را بازنویسی کن",
    )
    args = parser.parse_args()
    level = Path(__file__).resolve().parents[1] / "levels" / "test_level.tscn"

    old_v, old_p = build_mesh(OLD_FOOTPRINTS)
    print(f"generated-old vertices={len(old_v)} polygons={len(old_p)}")
    file_v, file_p = parse_existing(level)
    print(f"file-old vertices={file_v} polygons={file_p}")
    if args.verify_old:
        if (len(old_v), len(old_p)) != (file_v, file_p):
            raise SystemExit("FIDELITY FAIL: generated old mesh != file")
        # مقایسه‌ی رأس‌به‌رأس
        v_match = re.search(
            r"vertices = PackedVector3Array\(([^)]*)\)",
            level.read_text(encoding="utf-8"),
        )
        assert v_match is not None
        raw = [float(x.strip()) for x in v_match.group(1).split(",") if x.strip()]
        file_verts = [(raw[i], raw[i + 2]) for i in range(0, len(raw), 3)]
        if file_verts != old_v:
            raise SystemExit("FIDELITY FAIL: vertex list differs")
        print("FIDELITY OK")

    new_v, new_p = build_mesh(OLD_FOOTPRINTS + NEW_FOOTPRINTS)
    print(f"generated-new vertices={len(new_v)} polygons={len(new_p)}")
    if args.apply_new:
        replace_navmesh(level, format_navmesh_block(new_v, new_p))
        print(f"applied new navmesh to {level}")


if __name__ == "__main__":
    main()
