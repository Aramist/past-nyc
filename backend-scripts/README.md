# A collection of scripts for working with the Firebase backend

## Scripts
* firebase\_import.py:
	* Loads all data from the local JSON files, formats it, and uploads it to a Cloud Firestore database.
* image\_merger.py
	* Functions related to merging groups of images located close to each other. Serves the purpose of preventing overlapping annotations
* json\_loader.py
	* Functions related to loading and formatting data from the raw local dataset.

## Subdirectories
* json
	* The complete OldNYC dataset. Each file corresponds to a single annotation (prior to merging via image\_merger.py).
* minijson
	* A small subset of the complete dataset. For testing
* unmaintained
	* Older, undocumented versions of the above scripts.

