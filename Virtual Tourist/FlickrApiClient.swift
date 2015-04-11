//
//  FlickrApiClient.swift
//  Virtual Tourist
//
//  Created by Matthias on 07/04/15.
//

import Foundation
import CoreLocation

class FlickrApiClient {

    let apiKey = "753851a648a7b7065deabda545519e35"
    let baseURL = "https://api.flickr.com/services/rest/"

    func taskForSearch(coordinate: CLLocationCoordinate2D, completionHandler: (results: [String: String]?, error: NSError?) -> Void) -> NSURLSessionDataTask {
        let parameters: [String: AnyObject] = ["method": "flickr.photos.search", "format": "json", "api_key": apiKey, "nojsoncallback": 1,
            "lat": coordinate.latitude, "lon": coordinate.longitude, "accuracy": 11]
        return taskForRequest(NSURLRequest(URL: urlWithParameters(baseURL, parameters: parameters))) { jsonObject, error in
            if error != nil {
                completionHandler(results: nil, error: error)
            } else {
                var results = [String: String]()

                if let photos = jsonObject?["photos"] as? [String: AnyObject] {
                    if let photo = photos["photo"] as? [[String: AnyObject]] {
                        for photo in photo {
                            let id     = photo["id"]     as? String
                            let secret = photo["secret"] as? String
                            let server = photo["server"] as? String
                            let farm   = photo["farm"]   as? Int

                            if id != nil && secret != nil && server != nil && farm != nil {
                                results[id!] = "http://farm\(farm!).staticflickr.com/\(server!)/\(id!)_\(secret!)_b.jpg"
                            }
                        }
                    }
                }

                completionHandler(results: results, error: nil)
            }
        }
    }

    func taskForImage(imageURL: String, completionHandler: (data: NSData?, error: NSError?) -> Void) -> NSURLSessionDataTask {
        let request = NSURLRequest(URL: NSURL(string: imageURL)!)

        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
            if error != nil {
                completionHandler(data: nil, error: error)
            } else {
                completionHandler(data: data, error: nil)
            }
        }

        task.resume()

        return task
    }

    private func urlWithParameters(url: String, parameters: [String: AnyObject]) -> NSURL {
        return NSURL(string: "\(url)?" + join("&", parameters.keys.map { key in
            let value = "\(parameters[key]!)"
            return "\(key)=\(value.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())!)"
        }))!
    }

    private func taskForRequest(request: NSURLRequest, completionHandler: (jsonObject: [String: AnyObject]?, error: NSError?) -> Void) -> NSURLSessionDataTask {
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
            if error != nil {
                completionHandler(jsonObject: nil, error: error)
            } else {
                self.parseResponseWithCompletionHandler(response, data: data, completionHandler: completionHandler)
            }
        }

        task.resume()

        return task
    }

    private func parseResponseWithCompletionHandler(response: NSURLResponse, data: NSData, completionHandler: (jsonObject: [String: AnyObject]?, error: NSError?) -> Void) {
        var error: NSError?

        let jsonObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: &error)

        if error != nil {
            completionHandler(jsonObject: nil, error: error)
        } else {
            if let jsonObject = jsonObject as? [String: AnyObject] {
                completionHandler(jsonObject: jsonObject, error: nil)
            }
        }
    }
}