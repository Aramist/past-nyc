import json
import os
from os import path


def coords_from_fname(fname):
    no_ext = fname[:-5]
    lat, lon = no_ext.split('-')
    lat, lon = float(lat), float(lon)
    lon = -lon
    return lat, lon


def get_file_entries(fdir, fname):
    with open(path.join(fdir, fname), 'r') as json_file:
        json_objs = json.load(json_file)
    coords = coords_from_fname(fname)
    for k, v in json_objs.items():
        v['id'] = k  # Reformat the dictionary key as a field
        v['latitude'] = coords[0]
        v['longitude'] = coords[1]
        if 'years' in v:
            del v['years']
        if 'original_title' in v:
            del v['original_title']
    return list(json_objs.values())


def run(json_directory, output_json_path, pretty_print=True):
    all_files = os.listdir(json_directory)
    big_json = list()
    for fname in all_files:
        big_json.extend(get_file_entries(json_directory, fname))
    with open(output_json_path, 'w') as out:
        indentation = 4 if pretty_print else None
        json.dump(big_json, out, indent=indentation)


if __name__ == '__main__':
    json_direc = 'json'
    output_file = 'historical_images_compact.json'
    non_compact = 'historical_images.json'
    run(json_direc, output_file, False)
    run(json_direc, non_compact, True)

