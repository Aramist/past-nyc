import json
import os
from os import path

import geopy.distance
import numpy as np
import pyproj
from scipy.spatial import cKDTree as Tree
from shapely.geometry import Point, shape


""" Loads data from json and does some minor preprocessing to merge groups of
images that are located at the same point or very close to each other.
This results in fewer overlapping image annotations within the app and allows
us to avoid the use of MKClusterAnnotation, which is bugged.
"""


class ImageGroup:
    """ A thin wrapper around the ImageGroup JSON objects that provides convenience
    methods for working with them
    """
    def __init__(self, json_object):
        self.json = json_object

    def distance_to(self, other):
        """ Distance between two ImageGroups in meters
        """
        p1 = self.json['latitude'], self.json['longitude']
        p2 = other.json['latitude'], other.json['longitude']
        return geopy.distance.distance(p1, p2).m

    def merge(self, other):
        """ Returns a new ImageGroup produced by merging self with another image group
        """
        merged_photos = self.json['photos'] + other.json['photos']
        avg_lat = (self.json['latitude'] + other.json['latitude']) / 2
        avg_lon = (self.json['longitude'] + other.json['longitude']) / 2
        return ImageGroup({'latitude': avg_lat, 'longitude': avg_lon, 'photos': merged_photos})

    def merge_many(self, others):
        """ Returns a new ImageGroup produced by merging self with many other image groups
        """
        lats = [self.json['latitude']] + [other.json['latitude'] for other in others]
        lons = [self.json['longitude']] + [other.json['longitude'] for other in others]
        avg_lat = sum(lats) / len(lats)
        avg_lon = sum(lons) / len(lons)
        images = list()
        for image_group in [self, *others]:
            images.extend(image_group.json['photos'])
        return ImageGroup({'latitude': avg_lat, 'longitude': avg_lon, 'photos': images})

    def nearest_group(self, image_groups):
        """ Finds the nearest ImageGroup to self in image_groups
        """
        nearest = None
        nearest_idx = 0
        nearest_dist = 1e10
        for n, group in enumerate(image_groups):
            dist = self.distance_to(group)
            if dist < nearest_dist:
                nearest = group
                nearest_idx = n
                nearest_dist = dist
        if nearest is None:
            return None
        return nearest, nearest_idx, nearest_dist

    def test_borough(self, boroughs):
        """ Hit test on all the boroughs to determine which one this
        ImageGroup belongs to
        """
        # Shapely uses a (longitude, latitude convention)
        coord = Point(self.json['longitude'], self.json['latitude'])
        for n, poly in enumerate(boroughs):
            if poly.contains(coord):
                return n
        # If it's not in any of the boroughs, return a dummy index corresponding
        # to this result. This could occur for images taken on bridges
        return len(boroughs)

    def full_json(self):
        return self.json

    def parent_json(self):
        result = {'latitude': self.json['latitude'], 'longitude': self.json['longitude']}
        if 'borough_code' in self.json:
            result['borough_code'] = self.json['borough_code']
        return result


def coords_from_fname(fname):
    """ As the data files contain the image's coordinates within the filename,
    the name must be parsed to extract this information.
    The files currently have the format <lat><long>.json
    Since all points in NYC have negative longitude, the negative sign is used
    here to determine where the longitude number starts.
    """
    no_extension = fname[:-5]  # remove the .json from the end
    lat,lon = no_extension.split('-')
    lat,lon = float(lat), float(lon)
    lon = -lon  # Account for the - we removed when splitting the string
    return lat, lon


def get_entries_from_file(fdir, fname):
    """ Converts a data file into an ImageGroup object.
    Also strips away several fields from the original data
    """
    with open(path.join(fdir, fname), 'r') as json_file:
        json_objs = json.load(json_file)
    coords = coords_from_fname(fname)
    for k, v in json_objs.items():
        # Originally, the image id is given as the name of the dictionary (within the larger json object)
        v['id'] = k  # Turn it into a property of the dictionary
        if 'years' in v:  # Usually doesn't contain data. Sometimes contains multiple years. Difficult to process
            del v['years']
        if 'original_title' in v:  # Also sparse
            del v['original_title']
        if 'title' in v:  # Alse sparse. `folder` provides a much more useful label to the ImageGroup
            del v['title']
    new_obj = dict()  # Create an object representing a single image group, contains coordinates and a list of images
    new_obj['latitude'] = coords[0]
    new_obj['longitude'] = coords[1]
    new_obj['photos'] = list(json_objs.values())
    return ImageGroup(new_obj)


def image_group_loader(json_directory):
    """ A generator that yields all ImageGroups within a directory (as JSON objects)
    """
    all_files = os.listdir(json_directory)
    all_files = [fname for fname in all_files if fname.endswith('.json')]
    for fname in all_files:
        yield get_entries_from_file(json_directory, fname)


def load_borough_polygons(geo_filename):
    """ Loads polygons from NYC borough geojson data for hit-testing
    """
    with open(geo_filename, 'r') as ctx:
        json_data = json.load(ctx)
    boroughs = list()
    for feature in json_data['features']:
        boro_name = feature['properties']['boro_name']
        boroughs.append(shape(feature['geometry']))
        # Print the index assigned to each borough
        # This determines the values given to the Borough enum in Swift
        print(f'Feature {len(boroughs) - 1}: {boro_name}')
    return boroughs


