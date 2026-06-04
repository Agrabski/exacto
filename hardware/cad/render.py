#!/usr/bin/env python3
"""Render sight_housing.scad from 3 angles using OpenSCAD + xvfb.

Usage:
    python hardware/cad/render.py [--out PATH]

Requires: openscad, xvfb-run, Pillow, matplotlib.
"""

import argparse
import subprocess
import tempfile
from pathlib import Path

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
from PIL import Image

SCAD = Path(__file__).parent / 'sight_housing.scad'
DEFAULT_OUT = Path(__file__).parent / 'sight_render.png'

# Camera: (label, rx, rz, dist)
#   rx = elevation — 50 gives isometric, 10 gives near-horizontal side view
#   rz = azimuth   — 0=front, 90=right, 180=rear, 270=left
#   dist = mm from look-at point to camera
VIEWS = [
    ('Rear-right isometric', 50,  30, 230),
    ('Side profile',          10,  95, 200),
    ('Front-left isometric',  50, 215, 230),
]

# Approximate model centre (mm) — body 47×34, total height ~61
CX, CY, CZ = 24, 17, 27

IMGW, IMGH   = 900, 700
COLORSCHEME  = 'DeepOcean'


def render_view(label: str, rx: int, rz: int, dist: int, out: Path) -> None:
    cmd = [
        'xvfb-run', '-a',
        'openscad', '--render',
        f'--imgsize={IMGW},{IMGH}',
        f'--camera={CX},{CY},{CZ},{rx},0,{rz},{dist}',
        f'--colorscheme={COLORSCHEME}',
        '-o', str(out),
        str(SCAD),
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f'openscad failed for {label!r}:\n{result.stderr}')


def composite(frames: list[tuple[str, Path]], out: Path) -> None:
    fig, axes = plt.subplots(1, 3, figsize=(18, 7), facecolor='#0d1117')
    fig.suptitle(
        'Exacto Reflex Sight — EOTech-style (OpenSCAD render)',
        color='#cce8ff', fontsize=13, fontweight='bold', y=0.98,
    )
    for ax, (label, path) in zip(axes, frames):
        ax.imshow(np.array(Image.open(path)))
        ax.set_title(label, color='#cce8ff', fontsize=10, pad=6)
        ax.axis('off')
        ax.set_facecolor('#0d1117')
    plt.tight_layout(rect=[0, 0, 1, 0.95])
    plt.savefig(str(out), dpi=150, bbox_inches='tight', facecolor='#0d1117')
    print(f'saved {out}')


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, default=DEFAULT_OUT,
                        help='output PNG path')
    args = parser.parse_args()

    with tempfile.TemporaryDirectory() as tmp:
        frames: list[tuple[str, Path]] = []
        for i, (label, rx, rz, dist) in enumerate(VIEWS):
            png = Path(tmp) / f'view_{i}.png'
            print(f'Rendering {label!r} …')
            render_view(label, rx, rz, dist, png)
            frames.append((label, png))
        composite(frames, args.out)


if __name__ == '__main__':
    main()
