import json
import os
from os import path

import geopy.distance


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
        if 'years' in v:
            del v['years']
        if 'original_title' in v:
            del v['original_title']
        if 'title' in v:
            del v['title']
    new_obj = dict()
    new_obj['latitude'] = coords[0]
    new_obj['longitude'] = coords[1]
    new_obj['photos'] = list(json_objs.values())
    return new_obj


def run(json_directory):
    all_files = os.listdir(json_directory)
    big_json = list()
    for fname in all_files:
        big_json.append(get_file_entries(json_directory, fname))
    return big_json


def merged_entry(a, b):
    """ Merges ImageGroups a and b, returns the result
    """
    merged_photos = a['photos'] + b['photos']
    avg_lat = (a['latitude'] + b['latitude']) / 2
    avg_lon = (a['longitude'] + b['longitude']) / 2
    return {'latitude': avg_lat, 'longitude': avg_lon, 'photos': merged_photos}


def dist_meters(g1, g2):
    """ Estimates the distance between image groups
    p1 and p2 in meters
    """
    p1 = g1['latitude'], g1['longitude']
    p2 = g2['latitude'], g2['longitude']
    return geopy.distance.distance(p1, p2).m


def closest_group(arr, group):
    """ Finds the nearest image group to group in arr
    """
    nearest = None
    nearest_idx = 0
    nearest_dist = 999999
    for n, g in enumerate(arr):
        dist = dist_meters(group, g)
        if dist < nearest_dist:
            nearest = g
            nearest_idx = n
            nearest_dist = dist
    return nearest, nearest_idx, nearest_dist


def quadratic_merge_points(image_groups, thresh_distance=500):
    """ Merges points within a certain distance of eachother in quadratic time
    dist is given in meters
    """
    new_groups = [ image_groups[0] ]
    counter = 0
    smallest_seen = 9999
    for n, group in enumerate(image_groups[1:]):
        print(f'find nearest for idx {n} in arr of size {len(new_groups)}')
        nearest, nearest_idx, dist = closest_group(new_groups, group)
        if dist < thresh_distance:
            if dist < smallest_seen:
                smallest_seen = dist
                print(f'New min: {smallest_seen}')
            counter += 1
            print(f'Hit #{counter}')
            del new_groups[nearest_idx]
            new_groups.append(merged_entry(nearest, group))
        else:
            new_groups.append(group)
    return new_groups


if __name__ == '__main__':
    json_direc = 'json'
    # output_file = 'historical_images_compact.json'
    # non_compact = 'historical_images.json'
    output_file = 'local_image_dataset.json'
    initial = run(json_direc)
    initial = quadratic_merge_points(initial)

    pretty_print = False
    with open(output_file, 'w') as out:
        indentation = 4 if pretty_print else None
        json.dump(initial, out, indent=indentation)

