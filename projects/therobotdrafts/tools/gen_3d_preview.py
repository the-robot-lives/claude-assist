#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Offline oblique-3D preview of the distinct node silhouettes that Uml3DNodeShape.Build now produces.
NOT the engine render (Unity won't open on this case-sensitive volume) — an approximation that extrudes
each silhouette outline (front=hue, sides darker, back darkest, top edge lighter) lit from upper-left,
so the '3D asset' shapes can be reviewed. The true per-kind gallery comes from Uml3DIconBaker.BakeAll.
"""
import math, os

def hx(c):
    c=c.lstrip('#')
    if len(c)==3: c=''.join(ch*2 for ch in c)
    return tuple(int(c[i:i+2],16) for i in (0,2,4))
def rgb(t): return '#%02X%02X%02X'%tuple(max(0,min(255,int(round(v)))) for v in t)
def shade(c,f): return rgb(tuple(v*f for v in hx(c)))
def mix(a,b,t):
    a,b=hx(a),hx(b); return rgb(tuple(a[i]+(b[i]-a[i])*t for i in range(3)))

OFF=(6.0,-6.0)  # oblique depth vector (up-right)

def poly(pts,fill,stroke=None,sw=1.6,op=1.0):
    p=' '.join('%.2f,%.2f'%(x,y) for x,y in pts)
    s=f'<polygon points="{p}" fill="{fill}"'
    if op!=1: s+=f' fill-opacity="{op}"'
    if stroke: s+=f' stroke="{stroke}" stroke-width="{sw}" stroke-linejoin="round"'
    return s+'/>'
def line(a,b,st,sw=1.6):
    return f'<line x1="{a[0]:.2f}" y1="{a[1]:.2f}" x2="{b[0]:.2f}" y2="{b[1]:.2f}" stroke="{st}" stroke-width="{sw}" stroke-linecap="round"/>'
def ell(cx,cy,rx,ry,fill,stroke=None,sw=1.6):
    s=f'<ellipse cx="{cx:.2f}" cy="{cy:.2f}" rx="{rx:.2f}" ry="{ry:.2f}" fill="{fill}"'
    if stroke: s+=f' stroke="{stroke}" stroke-width="{sw}"'
    return s+'/>'

def extrude(outline,hue,line_c):
    """Oblique-extrude a CCW/any polygon: back face, side walls, front face+outline."""
    dx,dy=OFF
    back=[(x+dx,y+dy) for x,y in outline]
    out=[poly(back, shade(hue,0.52), line_c, 1.2)]
    # side walls: draw each edge quad; near-side ones get covered by the front face
    n=len(outline)
    for i in range(n):
        a=outline[i]; b=outline[(i+1)%n]; bb=back[(i+1)%n]; ba=back[i]
        # shade by edge orientation: rightward/downward faces darker, up faces lighter
        mid=((a[0]+b[0])/2,(a[1]+b[1])/2)
        ex,ey=b[0]-a[0], b[1]-a[1]
        # outward normal (approx) sign vs light dir (upper-left => (-1,-1))
        nx,ny=ey,-ex
        lit=0.62+0.18*max(0,-(nx*0.7+ny*0.7)/(math.hypot(nx,ny)+1e-6))
        out.append(poly([a,b,bb,ba], shade(hue,lit), line_c,1.0))
    out.append(poly(outline, hue, line_c, 1.8))
    return out

# ---- outlines (centered ~ [-20,20]x[-16,16], SVG y down) ----
def rect_o(w=40,h=32): x,y=w/2,h/2; return [(-x,-y),(x,-y),(x,y),(-x,y)]
def roundrect_pts(w,h,r,seg=6):
    x,y=w/2,h/2; pts=[]
    def corner(cx,cy,a0):
        for i in range(seg+1):
            a=a0+i/seg*(math.pi/2); pts.append((cx+math.cos(a)*r, cy+math.sin(a)*r))
    corner(x-r,y-r,0); corner(-x+r,y-r,math.pi/2); corner(-x+r,-y+r,math.pi); corner(x-r,-y+r,1.5*math.pi)
    return pts
def ellipse_o(rx=20,ry=15,n=40): return [(math.cos(2*math.pi*i/n)*rx, math.sin(2*math.pi*i/n)*ry) for i in range(n)]
def diamond_o(w=38,h=32): x,y=w/2,h/2; return [(-x,0),(0,-y),(x,0),(0,y)]
def hexagon_o(w=40,h=30):
    x,y=w/2,h/2; ix=w*0.24; return [(-x,0),(-x+ix,-y),(x-ix,-y),(x,0),(x-ix,y),(-x+ix,y)]
def pentagon_o(w=40,h=30):
    x,y=w/2,h/2; n=w*0.28; return [(-x,-y),(x-n,-y),(x,0),(x-n,y),(-x,y)]
def accept_o(w=40,h=30):
    x,y=w/2,h/2; n=w*0.24; return [(-x,-y),(x,-y),(x,y),(-x,y),(-x+n,0)]
def chevron_o(w=40,h=30):
    x,y=w/2,h/2; t=w*0.22; return [(-x,-y),(x-t,-y),(x,0),(x-t,y),(-x,y),(-x+t,0)]
def paral_o(w=40,h=30): x,y=w/2,h/2; s=w*0.22; return [(-x+s,-y),(x,-y),(x-s,y),(-x,y)]
def stadium_o(w=42,h=26): return roundrect_pts(w,h,h/2,7)

# ---- special renderers ----
def r_cube(hue,lc):  # deep box / deployment
    return extrude(rect_o(34,30),hue,lc)
def r_cylinder(hue,lc):
    cx,cy,rx,ry,H=0,0,13,5,28
    out=[ # body
        poly([(-rx,-H/2),(rx,-H/2),(rx,H/2),(-rx,H/2)], hue, None),
        f'<path d="M{-rx},{-H/2} A{rx},{ry} 0 0 0 {rx},{-H/2}" fill="none" stroke="{lc}" stroke-width="1.4"/>',
        line((-rx,-H/2),(-rx,H/2),lc,1.6), line((rx,-H/2),(rx,H/2),lc,1.6),
        f'<path d="M{-rx},{H/2} A{rx},{ry} 0 0 0 {rx},{H/2} V{-H/2} A{rx},{ry} 0 0 1 {-rx},{-H/2} Z" fill="{shade(hue,0.9)}" stroke="{lc}" stroke-width="1.6"/>',
        ell(0,-H/2,rx,ry,shade(hue,1.12),lc,1.6)]
    return out
def r_cloud(hue,lc):
    d='M-14,8 a8,8 0 0 1 0.5,-15 a10,10 0 0 1 19,-3 a8,8 0 0 1 3,18 Z'
    dx,dy=OFF
    return [f'<path d="{d}" transform="translate({dx},{dy})" fill="{shade(hue,0.55)}" stroke="{lc}" stroke-width="1.2"/>',
            f'<path d="{d}" fill="{hue}" stroke="{lc}" stroke-width="1.8"/>']
def r_mind(hue,lc):
    return [ell(0,0,20,15,shade(hue,0.9),lc,1.6),
            f'<ellipse cx="-5" cy="-4" rx="11" ry="8" fill="{shade(hue,1.14)}" opacity="0.5"/>',
            ell(0,0,20,15,'none',lc,1.8)]
def r_disc(hue,lc): return extrude(ellipse_o(15,15,36),hue,lc)
def r_ring(hue,lc): # final state
    return [f'<circle cx="0" cy="0" r="15" fill="none" stroke="{lc}" stroke-width="2.4"/>',
            f'<circle cx="0" cy="0" r="7.5" fill="{hue}" stroke="{lc}" stroke-width="1.2"/>']
def r_bar(hue,lc): return extrude(rect_o(40,7),hue,lc)
def r_cross(hue,lc):
    return [line((-13,-13),(13,13),hue,5),line((13,-13),(-13,13),hue,5)]
def r_flowfinal(hue,lc):
    return [f'<circle cx="0" cy="0" r="15" fill="none" stroke="{lc}" stroke-width="2.2"/>',
            line((-8,-8),(8,8),lc,2.4),line((8,-8),(-8,8),lc,2.4)]
def r_folder(hue,lc):
    dx,dy=OFF
    body=[(-20,-13),(20,-13),(20,15),(-20,15)]; tab=[(-20,-13),(-3,-13),(-3,-19),(-18,-19)]
    return [poly([(x+dx,y+dy) for x,y in body],shade(hue,0.55),lc,1.2),
            *[poly([body[i],body[(i+1)%4],(body[(i+1)%4][0]+dx,body[(i+1)%4][1]+dy),(body[i][0]+dx,body[i][1]+dy)],shade(hue,0.66),lc,1.0) for i in range(4)],
            poly(tab,mix(hue,'#000',0.15),lc,1.6), poly(body,hue,lc,1.8)]
def r_dogear(hue,lc):
    f=10; o=[(-18,-16),(18,-16),(18,16),(-18+f,16),(-18,16-f)]
    out=extrude(o,hue,lc)
    out.append(poly([(-18+f,16),(-18,16-f),(-18+f,16-f)],mix(hue,'#000',0.2),lc,1.4))
    return out
def r_component(hue,lc):
    out=extrude(rect_o(32,30),hue,lc)
    for ty in (-8,6): out.append(poly([(-18,ty),(-10,ty),(-10,ty+6),(-18,ty+6)],mix(hue,'#000',0.1),lc,1.4))
    return out
def r_document(hue,lc):
    dx,dy=OFF
    d='M-20,-15 H20 V12 q-10,6 -20,0 t-20,0 Z'
    return [f'<path d="{d}" transform="translate({dx},{dy})" fill="{shade(hue,0.55)}" stroke="{lc}" stroke-width="1.2"/>',
            f'<path d="{d}" fill="{hue}" stroke="{lc}" stroke-width="1.8"/>']
def r_actor(hue,lc):
    return [f'<circle cx="0" cy="-13" r="6" fill="{hue}" stroke="{lc}" stroke-width="1.6"/>',
            line((0,-7),(0,9),hue,3),line((-11,0),(11,0),hue,3),
            line((0,9),(-9,20),hue,3),line((0,9),(9,20),hue,3)]

def ex(fn): return lambda hue,lc: extrude(fn(),hue,lc)

# family -> (renderer, label, example kinds, hue)
FAMILIES=[
 (ex(rect_o),        'Box (extruded)','Class · Interface · Enum · Table · SysML · most EA','#0072B2'),
 (lambda h,l: extrude(roundrect_pts(40,30,9),h,l),'Rounded slab','State · Activity · CallActivity','#5AB28A'),
 (lambda h,l: extrude(stadium_o(),h,l),'Stadium / pill','DmnInputData · Archi/UAF Service','#4F86C6'),
 (lambda h,l: extrude(ellipse_o(),h,l),'Elliptic disc','UseCase · Collaboration · BpmnEvent','#4E9BC4'),
 (r_disc,            'Face disc','StateStart · Junction · TOGAF phase','#2A2D34'),
 (r_ring,            'Ring + core','StateEnd (final)','#2A2D34'),
 (lambda h,l: extrude(diamond_o(),h,l),'Diamond','Decision · Gateway · WhiteboardDiamond','#E69F00'),
 (r_bar,             'Bar','ForkJoin · Activation · Port','#2A2D34'),
 (r_cross,           'Cross','Terminate','#2A2D34'),
 (r_flowfinal,       'Ring + X','FlowFinal','#2A2D34'),
 (r_cube,            'Deep box (3-D node)','Deployment · Server · ArchiNode · Device','#6E7B8B'),
 (r_folder,          'Folder','Package · Profile','#6E7B8B'),
 (r_cylinder,        'Cylinder','Database · BpmnDataStore','#4F86C6'),
 (r_cloud,           'Cloud','Cloud / service','#56B4E9'),
 (lambda h,l: extrude(pentagon_o(),h,l),'Send-signal pentagon','AsyncSend','#4FA3A0'),
 (lambda h,l: extrude(accept_o(),h,l),'Accept-event notch','AsyncReceive','#4FA3A0'),
 (r_dogear,          'Dog-ear page','Note · Artifact · BpmnDataObject','#F2E2A0'),
 (r_component,       'Component','Component · Archi App Component','#5B8AC4'),
 (lambda h,l: extrude(hexagon_o(),h,l),'Hexagon','BpmnConversation · UAF Op Node','#B9A6C8'),
 (lambda h,l: extrude(chevron_o(),h,l),'Chevron arrow','ValueStream · Value Chain · Archi Process','#E69F00'),
 (lambda h,l: extrude(paral_o(),h,l),'Parallelogram','FlowIO','#E69F00'),
 (r_document,        'Wavy document','FlowDocument','#B0A878'),
 (r_mind,            'Ovoid','MindNode','#4FA3A0'),
 (r_actor,           'Actor / robot','Actor · Person','#6B5B95'),
]

TILE=118; COLS=6; CELL=TILE
rows=(len(FAMILIES)+COLS-1)//COLS
W=COLS*TILE; H=rows*(TILE+16)+30
svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">',
     f'<rect width="{W}" height="{H}" fill="#14171c"/>',
     f'<text x="12" y="20" font-family="Helvetica,Arial" font-size="14" font-weight="700" fill="#e6edf3">Uml3DNodeShape — distinct 3-D node forms (offline oblique preview)</text>']
for i,(fn,label,ex_kinds,hue) in enumerate(FAMILIES):
    r,c=divmod(i,COLS); ox=c*TILE; oy=30+r*(TILE+16)
    lc=mix(hue,'#0d1420',0.45)
    svg.append(f'<g transform="translate({ox+TILE/2},{oy+TILE/2-6})">')
    svg+=fn(hue,lc)
    svg.append('</g>')
    svg.append(f'<text x="{ox+TILE/2}" y="{oy+TILE-10}" font-family="Helvetica,Arial" font-size="10.5" font-weight="700" fill="#cfd8e0" text-anchor="middle">{label}</text>')
    svg.append(f'<text x="{ox+TILE/2}" y="{oy+TILE+3}" font-family="Helvetica,Arial" font-size="8" fill="#7d8794" text-anchor="middle">{ex_kinds}</text>')
svg.append('</svg>')
out=os.path.join(os.path.dirname(__file__),'preview_3d.svg')
open(out,'w').write('\n'.join(svg))
print('wrote',out)
