//
//  File.swift
//  VirtualTourist
//
//  Created by Dustin Howell on 6/13/17.
//  Copyright © 2017 Dustin Howell. All rights reserved.
//

import Foundation

class FlickrClient {
    static let shared = FlickrClient()
    private init() {}
    
    // MARK: Properties
    private let session = URLSession.shared
    
    func photoSearch(latitude: Double, longitude: Double, radius: Int = 5, handler: @escaping (DataResult<[URL], AppError>) -> ()) {
        var params: [String:Any] = [:]
        params[RequestKeys.latitude] = latitude
        params[RequestKeys.longitude] = longitude
        params[RequestKeys.radius] = radius
        
        let _ = doGetTask(forMethod: Methods.photoSearch, withParams: params) { (result) in
            switch result {
            case .success(let data):
                let urls = self.getImageUrls(data: data)
                handler(.success(urls))
            case .failure(let error):
                handler(.failure(error))
            }
        }
    }
    
    // MARK: Helper Methods
    
    private func doGetTask(forMethod method: String, withParams params: [String:Any]? = nil, handleResult: @escaping (DataResult<Data, AppError>) -> () ) -> URLSessionDataTask {
        let url = buildURL(forMethod: method, withParams: params)
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { (data, resp, err) in
            let dataResult = self.convertToDataResult(data: data, response: resp, error: err)
            handleResult(dataResult)
        }
        task.resume()
        return task
    }
    
    private func buildURL(forMethod method: String, withParams params: [String:Any]? = nil) -> URL {
        var components = URLComponents()
        components.scheme = Components.scheme
        components.host = Components.host
        components.path = Components.basePath
        
        let apiKeyQueryItem = URLQueryItem(name: RequestKeys.apiKey, value: RequestValues.apiKey)
        let methodQueryItem = URLQueryItem(name: RequestKeys.method, value: method)
        let formatQueryItem = URLQueryItem(name: RequestKeys.responseFormat, value: RequestValues.jsonFormat)
        let extrasQueryItem = URLQueryItem(name: RequestKeys.extras, value: RequestValues.extraUrlM)
        let noJsonCallbackQueryItem = URLQueryItem(name: RequestKeys.noJsonCallback, value: RequestValues.noJsonCallback)
        var queryItems = [apiKeyQueryItem, methodQueryItem, formatQueryItem, extrasQueryItem, noJsonCallbackQueryItem]
        if let params = params {
            for (key, value) in params {
                let queryItem = URLQueryItem(name: key, value: "\(value)")
                queryItems.append(queryItem)
            }
        }
        
        components.queryItems = queryItems
        let url = components.url!
        print("Built URL: \(url.absoluteString)")
        return url
    }
    
    private func convertToDataResult(data: Data?, response: URLResponse?, error: Error?) -> DataResult<Data, AppError> {
        if let data = data {
            return .success(data)
        }
        let statusCode = (response as? HTTPURLResponse)?.statusCode
        return DataResult.failure(.NetworkError(domain:"FlickrClient", description:"Status Code: \(String(describing: statusCode))\n \(String(describing: error))"))
    }
    
    private func getImageUrls(data: Data) -> [URL] {
        guard let json = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String:Any] else {
            print("Error parsing photo search data")
            return []
        }
        
        guard let photos = json[ResponseKeys.photos] as? [String:Any] else {
            print("Error extracting key: '\(ResponseKeys.photos)' from dict: \(json)")
            return []
        }
        
        guard let photoList = photos[ResponseKeys.photo] as? [[String:Any]] else {
            print("Error extracting key: '\(ResponseKeys.photo)' from dict: \(photos)")
            return []
        }
        
        var urls = [URL]()
        for photo in photoList {
            guard let urlString = photo[ResponseKeys.urlM] as? String else {
                print("Error extracting key: '\(ResponseKeys.urlM)' from dict: \(photo)")
                continue
            }
            if let url = URL(string: urlString) {
                urls.append(url)
            }
        }
        return urls
    }
    
}
