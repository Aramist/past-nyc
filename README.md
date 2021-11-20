Original App Design Project - README Template
===

# PAST NYC (tbd)

## Table of Contents
1. [Overview](#Overview)
1. [Product Spec](#Product-Spec)
1. [Wireframes](#Wireframes)
2. [Schema](#Schema)

## Overview
### Description
This app will use your GPS location and show you how the area you're in looked like in the early 1900s. 

### App Evaluation
[Evaluation of your app across the following attributes]
- **Category:** Education
- **Mobile:** This app would most likely be mobile.
- **Story:** Analyzes location data and retrieves the closest image from the early 1900s taken nearest to your location. (e.g if you're standing on Astor Pl. you'll see the crossroad of Lafayette St. and Astor Pl. or Broadway and 8th St.)
- **Market:** Anyone will be able to use this app. No groupings neccesary
- **Habit:** This app could be used as often as one would like. It would mostly be used for educational purpose.
- **Scope:** First we can use this app to engage people with the history of NYC. This could evolve to other cities where different version of this app could exist like "PAST Paris" or "PAST London".

## Product Spec

### 1. User Stories (Required and Optional)

**Required Must-have Stories**

* User can view their location on a Map
* User can view pictures taken nearest to their location

**Optional Nice-to-have Stories**

* User can register for an account
* User can have a favorites section

### 2. Screen Archetypes

* Map View Screen
   * Allows user to view their current location on a map
   * Has a "show nearest picture" option

* Nearest Picture Screen
   * Shows user the picture of the nearest intersection.
   * Allows user to go back and forth with the next closest picture
   * Shows crossroad names.

### 3. Navigation

**Tab Navigation** (Tab to Screen)

* "View Map"
* "View Picture"

Optional:
* "Favorites"

**Flow Navigation** (Screen to Screen)

* Show All NYC -> Seperates by boroughs 
* Show Near me -> Shows pictures taken closest to user

## Wireframes
[Add picture of your hand sketched wireframes in this section]
<img src="https://imgur.com/a/ryN75f0" width=600>
Link: https://imgur.com/a/ryN75f0

### [BONUS] Digital Wireframes & Mockups

### [BONUS] Interactive Prototype

## Schema 
[This section will be completed in Unit 9]
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
| Thumbnail Image       | Image | http://oldnyc-assets.nypl.org/thumb/<id>.jpg |
| Full Resolution Image | Image | http://oldnyc-assets.nypl.org/600px/<id>.jpg |
