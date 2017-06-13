//
//  FlickrConstants.swift
//  VirtualTourist
//
//  Created by Dustin Howell on 6/13/17.
//  Copyright © 2017 Dustin Howell. All rights reserved.
//

import Foundation

extension FlickrClient {
    struct RequestKeys {
        static let method = "method"
        static let apiKey = "api_key"
        static let responseFormat = "format"
        static let latitude = "lat"
        static let longitude = "lon"
        static let radius = "radius"
        static let extras = "extras"
        static let noJsonCallback = "nojsoncallback"
    }
    
    struct RequestValues {
        static let jsonFormat = "json"
        static let apiKey = "2f26ae7c70ffc7b58c0e789797f95033"
        static let extraUrlM = "url_m"
        static let noJsonCallback = "1"
    }
    
    struct ResponseKeys {
        static let photos = "photos"
        static let photo = "photo"
        static let photoId = "id"
        static let urlM = "url_m"
    }
    
    struct Components {
        static let endpoint = "https://api.flickr.com/services"
        static let scheme = "https"
        static let host = "api.flickr.com"
        static let basePath = "/services/rest"
    }
    
    struct Methods {
        static let photoSearch = "flickr.photos.search"
    }
}
