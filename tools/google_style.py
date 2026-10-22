"""Build a Google Maps–like MapLibre style on free OpenStreetMap data (OpenFreeMap, no key).

Takes OpenFreeMap's Liberty style (OpenMapTiles schema), drops the layers Google doesn't show
(3D buildings, relief, shields, one-way arrows, POI icons) and recolors the rest with a Google-like palette.
Only colors change: road widths, zoom ranges and label rules stay Liberty's.

Usage: python3 tools/google_style.py  →  prototype/assets/map/style-google.json
"""
import json
import pathlib
import urllib.request

SRC = 'https://tiles.openfreemap.org/styles/liberty'
OUT = pathlib.Path(__file__).resolve().parent.parent / 'prototype/assets/map/style-google.json'

C = {
    'land': '#f1f3f4', 'park': '#c9e8c3', 'wood': '#bfe2b6', 'grass': '#d3edcb', 'sand': '#f5ecd5',
    'cemetery': '#d5eacd', 'hospital': '#fbe4e2', 'school': '#f3ecdf',
    'water': '#aadaff', 'water_text': '#3c78c4',
    'building': '#e6e7eb', 'building_line': '#d9dbe0',
    'road': '#ffffff', 'road_casing': '#dfe1e5',
    'motorway': '#fde293', 'motorway_casing': '#f1bf62',
    'path': '#d4d7dc', 'rail': '#c3c7cd', 'runway': '#ffffff', 'aeroway': '#e3e5e8',
    'boundary': '#9aa0a6', 'text': '#5f6368', 'place_text': '#3c4043', 'halo': '#ffffff',
}

DROP = {
    'natural_earth', 'park_outline', 'building-3d', 'road_area_pattern', 'landcover_ice',
    'road_one_way_arrow', 'road_one_way_arrow_opposite',
    'highway-shield-non-us', 'highway-shield-us-interstate', 'road_shield_us',
    'poi_r20', 'poi_r7', 'poi_r1', 'poi_transit',
}


def road_colors(lid):
    if 'motorway' in lid:
        return C['motorway'], C['motorway_casing']
    if 'rail' in lid:
        return C['rail'], C['rail']
    if 'path_pedestrian' in lid:
        return C['path'], C['road_casing']
    return C['road'], C['road_casing']


def recolor(layer):
    lid, typ, paint = layer['id'], layer['type'], layer.setdefault('paint', {})
    src = layer.get('source-layer')
    if typ == 'background':
        paint['background-color'] = C['land']
    elif typ == 'fill':
        color = {
            'park': C['park'], 'landcover_wood': C['wood'], 'landcover_grass': C['grass'],
            'landcover_wetland': C['grass'], 'landcover_sand': C['sand'], 'landuse_pitch': C['grass'],
            'landuse_track': C['grass'], 'landuse_cemetery': C['cemetery'], 'landuse_hospital': C['hospital'],
            'landuse_school': C['school'], 'landuse_residential': C['land'], 'water': C['water'],
            'aeroway_fill': C['aeroway'], 'building': C['building'],
        }.get(lid)
        if color:
            paint['fill-color'] = color
            paint.pop('fill-pattern', None)
            if 'fill-opacity' in paint:
                paint['fill-opacity'] = 1
            paint['fill-outline-color'] = C['building_line'] if lid == 'building' else color
    elif typ == 'line':
        if src == 'waterway':
            paint['line-color'] = C['water']
        elif src == 'aeroway':
            paint['line-color'] = C['runway']
        elif src == 'boundary':
            paint['line-color'] = C['boundary']
        elif src == 'transportation':
            fill, casing = road_colors(lid)
            paint['line-color'] = casing if lid.endswith('_casing') else fill
            if lid.startswith('tunnel_'):
                paint['line-opacity'] = 0.6
    elif typ == 'symbol':
        water = src in ('water_name', 'waterway')
        place = src == 'place'
        paint['text-color'] = C['water_text'] if water else C['place_text'] if place else C['text']
        paint['text-halo-color'] = C['halo']
        paint['text-halo-width'] = 1.5
        paint['text-halo-blur'] = 0
        if lid == 'label_city' or lid == 'label_city_capital':
            layer.get('layout', {}).pop('icon-image', None)   # no black dot next to city names


def main():
    req = urllib.request.Request(SRC, headers={'User-Agent': 'tripup-prototype/style-builder'})   # Python's default UA gets a 403
    style = json.load(urllib.request.urlopen(req))
    style['name'] = 'Google-like (OpenFreeMap)'
    style['sources'].pop('ne2_shaded', None)
    style['layers'] = [l for l in style['layers'] if l['id'] not in DROP]
    for layer in style['layers']:
        recolor(layer)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(style, separators=(',', ':')))
    print(f'{OUT}  ({len(style["layers"])} layers)')


if __name__ == '__main__':
    main()
