//
//  AlbumCollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Matthias on 08/04/15.
//

import UIKit

class AlbumCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var imageView: UIImageView!

    var imageTask: NSURLSessionTask? {
        didSet {
            oldValue?.cancel()
        }
    }
}