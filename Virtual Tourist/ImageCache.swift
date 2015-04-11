//
//  ImageCache.swift
//  Virtual Tourist
//
//  Created by Matthias on 09/04/15.
//

import UIKit

class ImageCache {

    private var cache = NSCache()

    func loadImageWithIdentifier(identifier: String) -> UIImage? {
        let path = pathForIdentifier(identifier)

        if let image = cache.objectForKey(path) as? UIImage {
            return image
        } else if let data = NSData(contentsOfFile: path) {
            if let image = UIImage(data: data) {
                cache.setObject(image, forKey: path)
                return image
            }
        }

        return nil
    }

    func storageImageWithIdentifier(image: UIImage, identifier: String) {
        let path = pathForIdentifier(identifier)

        // Cache image in memory.
        cache.setObject(image, forKey: path)

        // Write image to disk.
        let data = UIImageJPEGRepresentation(image, 0.9)
        data.writeToFile(path, atomically: true)
    }

    func removeImageWithIdentifier(identifier: String) {
        let path = pathForIdentifier(identifier)
        NSFileManager.defaultManager().removeItemAtPath(path, error: nil)
    }

    private func pathForIdentifier(identifier: String) -> String {
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as NSURL
        return documentsDirectoryURL.URLByAppendingPathComponent(identifier.lastPathComponent).path!
    }
}