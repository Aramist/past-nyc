import json
import random
import requests

import cv2
import numpy as np


with open('historical_images.json', 'r') as ctx:
    json_arr = json.load(ctx)

# Flatten it
flat_arr = list()
for group in json_arr:
    flat_arr.extend(group['photos'])

sample = random.sample(flat_arr, 50)
print(len(sample))

def get_image(image_json):
    thumb_url = image_json['thumb_url']
    full_url = image_json['image_url']
    thumb_req = requests.get(thumb_url)
    full_req = requests.get(full_url)

    thumb_image = cv2.imdecode(
            np.frombuffer(thumb_req.content, np.uint8),
            cv2.IMREAD_COLOR)
    full_image = cv2.imdecode(
            np.frombuffer(full_req.content, np.uint8),
            cv2.IMREAD_COLOR)
    thumb_ratio = thumb_image.shape[1] / thumb_image.shape[0]
    full_ratio = full_image.shape[1] / full_image.shape[0]
    json_ratio = image_json['width'] / image_json['height']
    diff = ((full_ratio - thumb_ratio) / full_ratio) < 0.05
    print('{:.3f} {:.3f} {:.3f} {}'.format(thumb_ratio, full_ratio, json_ratio, diff))

