#!/usr/bin/env python3
"""
Matplotlib-based render of sight_housing.scad (v3 EOTech-style).
Geometry faithfully follows the SCAD parameters.
Output: hardware/cad/sight_render.png
"""

import argparse
from pathlib import Path
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection

# ── Parameters (mirror SCAD exactly) ─────────────────────────────────────────
wall        = 2.50
shroud_wall = 3.00
clearance   = 0.30
body_height = 20.00
lip_h       = 10.00
angle_deg   = 45
angle       = np.radians(angle_deg)

disp_pcb_w    = 42.20;  disp_pcb_h    = 29.00
disp_active_w = 38.00;  disp_active_h = 24.80

lens_w     = 24.00;  lens_h     = 34.00
lens_t     =  2.74;  lens_top_r = 16.97

body_w = disp_pcb_w + 2*wall          # 47.20
body_d = disp_pcb_h + 2*wall          # 34.00

arm_w   = lens_h + 2*wall             # 39.00  (landscape: lens_h=34 along X)
frame_y = lens_t + 2*wall             #  7.74
frame_z = lens_w + 2*wall             # 29.00
x_off   = (body_w - arm_w) / 2       #  4.10

clearance_body = 5
glass_cz = body_height + clearance_body + lens_w/2 * np.sin(angle)
glass_cy = body_d / 2

frame_tip_z = (glass_cz + (frame_z/2)*np.sin(angle)
               + (frame_y/2)*np.cos(angle))
shroud_h = frame_tip_z - body_height + shroud_wall + 4

# Display window bounds on top face
win_x1 = wall + (disp_pcb_w - disp_active_w)/2   # 4.60
win_y1 = wall + (disp_pcb_h - disp_active_h)/2   # 4.60
win_x2 = win_x1 + disp_active_w
win_y2 = win_y1 + disp_active_h

bz = body_height

# ── Geometry helpers ──────────────────────────────────────────────────────────

def rot_x(pts, a):
    pts = np.atleast_2d(np.array(pts, dtype=float))
    c, s = np.cos(a), np.sin(a)
    y = pts[:,1]*c - pts[:,2]*s
    z = pts[:,1]*s + pts[:,2]*c
    return np.column_stack([pts[:,0], y, z])

def box_faces(x0,y0,z0, x1,y1,z1):
    return [
        np.array([[x0,y0,z0],[x1,y0,z0],[x1,y1,z0],[x0,y1,z0]]),  # bottom
        np.array([[x0,y0,z1],[x1,y0,z1],[x1,y1,z1],[x0,y1,z1]]),  # top
        np.array([[x0,y0,z0],[x1,y0,z0],[x1,y0,z1],[x0,y0,z1]]),  # rear
        np.array([[x0,y1,z0],[x1,y1,z0],[x1,y1,z1],[x0,y1,z1]]),  # front
        np.array([[x0,y0,z0],[x0,y1,z0],[x0,y1,z1],[x0,y0,z1]]),  # left
        np.array([[x1,y0,z0],[x1,y1,z0],[x1,y1,z1],[x1,y0,z1]]),  # right
    ]

def arc_strip_faces(cx, cz, r, y0, y1, t_start, t_end, n=18):
    thetas = np.linspace(t_start, t_end, n+1)
    faces = []
    for i in range(n):
        t0, t1 = thetas[i], thetas[i+1]
        x0_ = cx + r*np.cos(t0);  z0_ = cz + r*np.sin(t0)
        x1_ = cx + r*np.cos(t1);  z1_ = cz + r*np.sin(t1)
        faces.append(np.array([[x0_,y0,z0_],[x1_,y0,z1_],[x1_,y1,z1_],[x0_,y1,z0_]]))
    return faces

# ── Screen body ───────────────────────────────────────────────────────────────
body_faces = []
body_faces.append(np.array([[0,0,0],[body_w,0,0],[body_w,body_d,0],[0,body_d,0]]))
body_faces.append(np.array([[0,0,0],[body_w,0,0],[body_w,0,bz],[0,0,bz]]))
body_faces.append(np.array([[0,body_d,0],[body_w,body_d,0],[body_w,body_d,bz],[0,body_d,bz]]))
body_faces.append(np.array([[0,0,0],[0,body_d,0],[0,body_d,bz],[0,0,bz]]))
body_faces.append(np.array([[body_w,0,0],[body_w,body_d,0],[body_w,body_d,bz],[body_w,0,bz]]))
# Top strips around display window
body_faces.append(np.array([[0,0,bz],[win_x1,0,bz],[win_x1,body_d,bz],[0,body_d,bz]]))
body_faces.append(np.array([[win_x2,0,bz],[body_w,0,bz],[body_w,body_d,bz],[win_x2,body_d,bz]]))
body_faces.append(np.array([[win_x1,0,bz],[win_x2,0,bz],[win_x2,win_y1,bz],[win_x1,win_y1,bz]]))
body_faces.append(np.array([[win_x1,win_y2,bz],[win_x2,win_y2,bz],[win_x2,body_d,bz],[win_x1,body_d,bz]]))

display_face = np.array([[win_x1,win_y1,bz],[win_x2,win_y1,bz],[win_x2,win_y2,bz],[win_x1,win_y2,bz]])

# ── EOTech shroud (only OUTER surfaces visible from outside) ──────────────────
# We render only the faces you'd see: left outer, right outer, top outer,
# rear lip outer, front lip outer — NOT the inner faces (too busy).
sw = shroud_wall
sh = shroud_h

shroud_faces = []
# Left side wall — only outer face (X=0) and top/bottom
shroud_faces.extend(box_faces(0,        0, bz,   sw,       body_d, bz+sh))
# Right side wall
shroud_faces.extend(box_faces(body_w-sw, 0, bz,  body_w,   body_d, bz+sh))
# Top hood bar
shroud_faces.extend(box_faces(0, 0, bz+sh-sw,    body_w,   body_d, bz+sh))
# Rear lower lip
shroud_faces.extend(box_faces(sw, 0, bz,          body_w-sw, sw,    bz+lip_h))
# Front lower lip
shroud_faces.extend(box_faces(sw, body_d-sw, bz,  body_w-sw, body_d, bz+lip_h))

# ── Lens frame (glass_frame_mount) ────────────────────────────────────────────
# SCAD transform chain:
#   translate([body_w/2, glass_cy, glass_cz])
#   rotate([90-angle, 0, 0])          ← axis X, angle = 90-45 = 45°
#   translate([-arm_w/2, -frame_y/2, -frame_z/2])
#   → lens_frame() local: X∈[0,arm_w], Y∈[0,frame_y], Z∈[0,frame_z]

rot_angle = np.radians(90 - angle_deg)   # = 45°

def lens_transform(pts):
    f = np.atleast_2d(np.array(pts, dtype=float))
    f = f + [-arm_w/2, -frame_y/2, -frame_z/2]
    f = rot_x(f, rot_angle)
    f = f + [body_w/2, glass_cy, glass_cz]
    return f

# SCAD derived values
inner_hc = np.sqrt(lens_top_r**2 - (lens_w/2)**2)   # 12.00
p_lcx = wall + lens_top_r                             # 19.47
p_rcx = wall + lens_h - lens_top_r                    # 19.53
p_cz  = wall + lens_w / 2                             # 14.50
R_outer = lens_top_r + wall                           # 19.47
outer_hc = np.sqrt(max(R_outer**2 - (frame_z/2)**2, 0))
outer_lx = p_lcx - outer_hc                           #  6.48
outer_rx = p_rcx + outer_hc                           # 32.52
inner_lx = p_lcx - inner_hc                           #  7.47
inner_rx = p_rcx + inner_hc                           # 31.53

local_lens_faces = []
# Straight middle section outer shell
local_lens_faces.extend(box_faces(outer_lx, 0, 0,  outer_rx, frame_y, frame_z))
# Left arc cap (pi/2 → pi covers X from p_lcx down to p_lcx-R_outer)
local_lens_faces.extend(arc_strip_faces(p_lcx, p_cz, R_outer, 0, frame_y,
                                         np.pi/2, np.pi, 18))
# Left end discs Y=0 and Y=frame_y
for yf in [0, frame_y]:
    ts = np.linspace(np.pi/2, np.pi, 19)
    pts = [[p_lcx + R_outer*np.cos(t), yf, p_cz + R_outer*np.sin(t)] for t in ts]
    pts += [[outer_lx, yf, 0], [outer_lx, yf, frame_z]]
    local_lens_faces.append(np.array(pts[:19]))

# Right arc cap (0 → pi/2)
local_lens_faces.extend(arc_strip_faces(p_rcx, p_cz, R_outer, 0, frame_y,
                                         0, np.pi/2, 18))
for yf in [0, frame_y]:
    ts = np.linspace(0, np.pi/2, 19)
    pts = [[p_rcx + R_outer*np.cos(t), yf, p_cz + R_outer*np.sin(t)] for t in ts]
    local_lens_faces.append(np.array(pts))

lens_frame_faces = [lens_transform(f) for f in local_lens_faces]

# ── Lens glass ────────────────────────────────────────────────────────────────
# Visible entry face (local Y=0) of glass pocket, straight section
glass_local = np.array([
    [inner_lx, 0, wall],
    [inner_rx, 0, wall],
    [inner_rx, 0, wall + lens_w],
    [inner_lx, 0, wall + lens_w],
], dtype=float)
glass_world = lens_transform(glass_local)

# ── Figure ────────────────────────────────────────────────────────────────────
fig = plt.figure(figsize=(18, 13), facecolor='#0d1117')
ax  = fig.add_subplot(111, projection='3d', facecolor='#0d1117')

# Draw in back-to-front order; body first
bc = Poly3DCollection(body_faces, alpha=0.93, linewidth=0.5, zsort='average')
bc.set_facecolor('#8fa3b8'); bc.set_edgecolor('#5a6e82')
ax.add_collection3d(bc)

dc = Poly3DCollection([display_face], alpha=0.97)
dc.set_facecolor('#05080d'); dc.set_edgecolor('#1a2535')
ax.add_collection3d(dc)

# Reticle dot
dot_cx = (win_x1 + win_x2) / 2
dot_cy = (win_y1 + win_y2) / 2
dot_r  = 1.5
th = np.linspace(0, 2*np.pi, 24)
dot_pts = np.array([[dot_cx+dot_r*np.cos(t), dot_cy+dot_r*np.sin(t), bz+0.02] for t in th])
dot_c = Poly3DCollection([dot_pts], alpha=1.0)
dot_c.set_facecolor('#ff4444'); dot_c.set_edgecolor('#ff4444')
ax.add_collection3d(dot_c)

# Shroud
sc = Poly3DCollection(shroud_faces, alpha=0.82, linewidth=0.4, zsort='average')
sc.set_facecolor('#6e8898'); sc.set_edgecolor('#4a6070')
ax.add_collection3d(sc)

# Lens frame
lc = Poly3DCollection(lens_frame_faces, alpha=0.92, linewidth=0.4, zsort='average')
lc.set_facecolor('#a0bace'); lc.set_edgecolor('#6a8898')
ax.add_collection3d(lc)

# Glass (semi-transparent, drawn last)
gc = Poly3DCollection([glass_world], alpha=0.38)
gc.set_facecolor('#a8d8f0'); gc.set_edgecolor('#c8e8ff')
ax.add_collection3d(gc)

# ── Axis bounds ───────────────────────────────────────────────────────────────
all_pts = np.vstack(body_faces + shroud_faces + lens_frame_faces + [glass_world])
pad = 6
xl = [all_pts[:,0].min()-pad, all_pts[:,0].max()+pad]
yl = [all_pts[:,1].min()-pad, all_pts[:,1].max()+pad]
zl = [all_pts[:,2].min()-pad, all_pts[:,2].max()+pad]
ax.set_xlim(xl); ax.set_ylim(yl); ax.set_zlim(zl)
ax.set_box_aspect([xl[1]-xl[0], yl[1]-yl[0], zl[1]-zl[0]])

# ── Angle arc annotation ──────────────────────────────────────────────────────
arc_r  = 22
arc_cx = body_w / 2
arc_cy = glass_cy
arc_cz = body_height + 4

thetas_ann = np.linspace(0, angle, 32)
ax.plot([arc_cx]*len(thetas_ann),
        arc_cy + arc_r*np.cos(thetas_ann),
        arc_cz + arc_r*np.sin(thetas_ann),
        color='#f6c90e', lw=2.0, alpha=0.9, zorder=10)
mid = angle / 2
ax.text(arc_cx,
        arc_cy + (arc_r+6)*np.cos(mid),
        arc_cz + (arc_r+6)*np.sin(mid),
        f'{angle_deg}°', color='#f6c90e', fontsize=12, fontweight='bold')

# ── Dimension callouts ────────────────────────────────────────────────────────
ax.text(body_w/2, -5, -3, f'{body_w:.1f} mm', color='#99bbcc', fontsize=8, ha='center')
ax.text(-6, body_d/2, -3, f'{body_d:.1f} mm', color='#99bbcc', fontsize=8, ha='center')
ax.text(-6, -5, body_height/2, f'{body_height:.0f} mm', color='#99bbcc', fontsize=8, ha='center')

# ── View, grid, labels ────────────────────────────────────────────────────────
ax.tick_params(colors='#445566', labelsize=7)
for pane in [ax.xaxis.pane, ax.yaxis.pane, ax.zaxis.pane]:
    pane.fill = False
    pane.set_edgecolor('#1e2a35')
ax.grid(True, alpha=0.10, color='#7799aa')
ax.set_xlabel('X', color='#556677', labelpad=4, fontsize=8)
ax.set_ylabel('Y (rear→front)', color='#556677', labelpad=4, fontsize=8)
ax.set_zlabel('Z', color='#556677', labelpad=4, fontsize=8)

# Viewpoint: from rear-left elevated, looking at front-right — exposes top of
# body (display) + the open front aperture of the shroud + tilted lens frame
ax.view_init(elev=28, azim=225)

fig.text(0.5, 0.96, 'Exacto Reflex Sight Housing — v3 EOTech-style',
         ha='center', color='#cce8ff', fontsize=16, fontweight='bold')
fig.text(0.5, 0.92,
         (f'Lens: {lens_h:.0f}×{lens_w:.0f} mm  |  '
          f'Body: {body_w:.0f}×{body_d:.0f}×{body_height:.0f} mm  |  '
          f'Shroud: {shroud_h:.1f} mm tall  |  Angle: {angle_deg}°'),
         ha='center', color='#8899aa', fontsize=10)

plt.tight_layout(rect=[0, 0, 1, 0.91])

# ── Save ──────────────────────────────────────────────────────────────────────
parser = argparse.ArgumentParser()
parser.add_argument('--out', default='/home/user/exacto/hardware/cad/sight_render.png')
args, _ = parser.parse_known_args()

out_path = Path(args.out)
out_path.parent.mkdir(parents=True, exist_ok=True)
plt.savefig(str(out_path), dpi=180, bbox_inches='tight', facecolor='#0d1117')
print(str(out_path))
