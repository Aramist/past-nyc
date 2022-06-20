import datetime
import os

import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

import image_merger
import json_loader


def load_image_groups(data_directory, borough_poly_path):
    """ Loads image groups from the dataset.
    data_directory refers to the directory containing OldNYC json data
    borough_poly_path is a path to the geojson file defining the NYC borough boundaries
    """
    boroughs = json_loader.load_borough_polygons(borough_poly_path)
    image_groups = list(json_loader.image_group_loader(data_directory))

    for image_group in image_groups:
        image_group.json['borough_code'] = image_group.test_borough(boroughs)

    image_groups = image_merger.merge_nearby_points(image_groups)
    return image_groups


def load_firestore_db():
    """ To use this script, generate and download a private certificate in the
    firestore control panel, store it locally (outside the repo), and create
    an environment variable pointing to it.
    """
    cert_path = os.getenv('FIREBASE_CERTIFICATE_PATH')
    if cert_path is None:
        raise ValueError('Failed to find certificate to connect to Firebase as admin. Double-check the FIREBASE_CERTIFICATE_PATH environment variable')
    cred = credentials.Certificate(cert_path)
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    return db


def batch_upload_image_groups(image_groups, database, batch_size=500):
    """ Attempts to upload all data to firestore in batches of limited size
    """
    batch_counter = 1
    doc_counter = 0
    print(f'{datetime.datetime.now()}: Beginning upload of batch {batch_counter}')
    batch = database.batch()
    for image_group in image_groups:
        ig_ref = database.collection(u'nyc-image-groups').document()
        batch.set(ig_ref, image_group.parent_json())
        doc_counter += 1
        if doc_counter >= batch_size:
            batch.commit()
            batch = database.batch()
            doc_counter = 0
            batch_counter += 1
            print(f'{datetime.datetime.now()}: Beginning upload of batch {batch_counter}')
        photo_coll = ig_ref.collection(u'photos')
        for photo in image_group.full_json()['photos']:
            photo_id = photo['id']
            photo_ref = photo_coll.document(photo_id)
            batch.set(photo_ref, photo)
            doc_counter += 1
            if doc_counter >= batch_size:
                batch.commit()
                batch = database.batch()
                doc_counter = 0
                batch_counter += 1
                print(f'{datetime.datetime.now()}: Beginning upload of batch {batch_counter}')

    print('Batched upload complete')


if __name__ == '__main__':
    db = load_firestore_db()
    image_groups = load_image_groups('json', 'borough_boundaries.geojson')
    batch_upload_image_groups(image_groups, db, 400)

