# PAST NYC

## Table of Contents
1. [Overview](#Overview)
2. [Product Spec](#Product-Spec)
4. [Schema](#Schema)

## Overview
### Description
This app will allow both GPS-based and freely controlled navigation of a collection of New York City's oldest photographs.

### App Evaluation
- **Category:** Entertainment
- **Purpose:** Analyzes location data and retrieves the closest image from the early 1900s taken nearest to your location. (e.g if you're standing on Astor Pl. you'll see the crossroad of Lafayette St. and Astor Pl. or Broadway and 8th St.)
- **Market:** This app is mostly directed toward residents and visitors of NYC.
- **Habit:** This app could be used as often as one would like. It could see use for both educational and entertainment purposes.
- **Scope:** In its current state, this app is designed to immerse people in the deep history of NYC. One planned feature in this vein is the addition of walking tours, which would guide the user through several sites of importance while providing historical imagery and written descriptions. As old photograph collections for more cities are digitized, this project could evolve to cover more parts of the world.

## Product Spec

### 1. Client-side features

**Bare minimum:**

- [x] User can view their location on a Map
- [x] User can view historical images captured near their location
- [x] User can pan around the map to view images captured throughout the city

**The cherry on top:**

- [ ] User can register for an account
- [ ] User can persistently save their favorate images
- [ ] User can opt to be guided on tours of locations with many images
- [ ] ? (Taking suggestions in issues page)

### 2. Screen Archetypes

* "Explore" Map
   * Allows user to view their current location on a map
   * User can explore the entire city and the images within:
   * <img src="https://github.com/Aramist/past-nyc/blob/main/docs/explore_scene_demo.gif" width="320"/>

* Nearest Images
   * Shows user a table of images closest to the user's current location
   * Shows crossroad names
   * <img src="https://github.com/Aramist/past-nyc/blob/main/docs/nearby_scene_demo.gif" width="320"/>

### 3. Navigation

**Tab Navigation**

* "'Explore' Map"
* "Nearby"
* "Favorites" (In the future?)

**Flow Navigation**

* Show All NYC -> Sort by borough
* Show Near me -> Table of pictures near the user -> Any description associated with tapped image

## Schema 
### Models
Historical Image model:
| Property     | Type   | Description                                                         |
|--------------|--------|---------------------------------------------------------------------|
| photoURL     | String | A URL to the historical image                                       |
| thumbnailURL | String | A URL to a minified version of the image                            |
| photoID      | String | A unique ID for the photograph in NYPL servers                      |
| latitude     | Float  | Latitude component of image location                                |
| longitude    | Float  | Longitude component of image location                               |
| intersection | String | A name for the intersection or address at which the photo was taken |


User model:
| Property       | Type              | Description                      |
|----------------|-------------------|----------------------------------|
| username       | String            | A unique identifier for the user |
| password       | String            | A secure code to verify the user |
| favoritePhotos | [HistoricalImage] | Images saved by the user         |

Firestore data model:
 - image_groups (collection)
    - latitude (float)
    - longitude (float)
    - borough (int, enum)
    - photos (collection)
        - id (str)
            * A string that uniquely identifies the image within the NYPL database
        - thumb_url (str)
            * A path to a small-res scan of the image
        - image_url (str)
            * A path to the full-res scan of the image
        - width (int)
            * Full-res image width (pixels)
        - height (int)
            * Full-res image height (pixels)
        - text (str)
            * Contains a string containing a description of the images. Not present for all images. Sometimes, a single image contains a description for multiple images, all taken at the same time.
        - folder (str)
            * The label of the folder in which the physical images resided. Usually contains the name of the image's subject (if of a building or structure) or the intersection at which the image was taken.


### Networking
- Requests:
    - Main map screen
        - (Read) Get nearby images from local cache:
        - ```swift
            fileprivate func fetchImages(inRange coordinateRange: [(Float, Float)], withContext context: NSManagedObjectContext) throws -> [HistoricalImage]?{
            let request = HistoricalImage.fetchRequest()
            request.fetchLimit = 5
            // The first element of coordinateRange is the south-west corner of the search region
            // The second element is the north-east corner
            let predicate = NSPredicate(
                format: "(%K >= %@) && (%K <= %@) && (%K >= %@) && (%K <= %@)",
                argumentArray: [
                    #keyPath(HistoricalImage.latitude), coordinateRange[0].0,
                    #keyPath(HistoricalImage.latitude), coordinateRange[1].0,
                    #keyPath(HistoricalImage.longitude), coordinateRange[0].1,
                    #keyPath(HistoricalImage.longitude), coordinateRange[1].1
                ]
            )
            request.predicate = predicate

            request.propertiesToFetch = ["photoID", "latitude", "longitude", "thumbnailURL", "imageWidth", "imageHeight"]

            do {
                let nearbyImages = try context.fetch(request)
                return nearbyImages
            }
            catch {
                print(error)
                return nil
            }
        }
    ```
Endpoints:
- NYPL Old NYC image database:

| Resource              | Type  | URL                                          |
|-----------------------|-------|----------------------------------------------|
| Thumbnail Image       | Image | http://oldnyc-assets.nypl.org/thumb/{id}.jpg |
| Full Resolution Image | Image | http://oldnyc-assets.nypl.org/600px/{id}.jpg |

