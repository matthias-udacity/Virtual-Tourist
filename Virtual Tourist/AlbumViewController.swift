//
//  AlbumViewController.swift
//  Virtual Tourist
//
//  Created by Matthias on 07/04/15.
//

import UIKit
import MapKit
import CoreData

class AlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {

    var pin: Pin!
    var pendingInserts = [NSIndexPath]()
    var pendingDeletes = [NSIndexPath]()
    let imageCache = ImageCache()

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var albumCollectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        // Fetch photos using NSFetchedResultsController.
        var error: NSError?

        fetchedResultsController.delegate = self

        if !fetchedResultsController.performFetch(&error) {
            let alert = UIAlertController(title: nil, message: error!.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Show navigation bar.
        navigationController?.setNavigationBarHidden(false, animated: false)

        // Add annotation for selected pin.
        mapView.addAnnotation(pin)

        // Center map on selected pin.
        mapView.setCenterCoordinate(pin.coordinate, animated: false)

        if let height = navigationController?.navigationBar.frame.height {
            mapView.setVisibleMapRect(mapView.visibleMapRect, edgePadding: UIEdgeInsets(top: height, left: 0, bottom: 0, right: 0), animated: false)
        }

        // Download photos if this is a new pin, otherwise enable "New Collection" button.
        if pin.photos.isEmpty {
            downloadPhotos()
        } else {
            newCollectionButton.enabled = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func downloadPhotos() {
        FlickrApiClient().taskForSearch(pin.coordinate) { results, error in
            if error != nil {
                let alert = UIAlertController(title: nil, message: error!.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    // Create photos based on results.
                    for (id, imageURL) in results! {
                        let photo = Photo(dictionary: ["id": id, "imageURL": imageURL], context: self.sharedContext)
                        photo.pin = self.pin
                    }

                    // Save context.
                    CoreDataStackManager.sharedInstance.saveContext()
                }
            }
        }
    }

    // MARK: IBActions

    @IBAction func newCollectionButtonTouchUpInside(sender: AnyObject) {
        // Disable "New Collection" button.
        newCollectionButton.enabled = false

        // Delete all photos for this pin.
        for photo in fetchedResultsController.fetchedObjects as [Photo] {
            imageCache.removeImageWithIdentifier(photo.imageURL)
            sharedContext.deleteObject(photo)
        }

        // Download new photos.
        downloadPhotos()
    }

    // MARK: NSManagedObjectContext

    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.managedObjectContext!
    }

    // MARK: NSFetchedResultsController

    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "id", ascending: true) ]

        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
    }()

    // MARK: NSFetchedResultsControllerDelegate

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.albumCollectionView!.performBatchUpdates({
            if !self.pendingInserts.isEmpty {
                self.albumCollectionView.insertItemsAtIndexPaths(self.pendingInserts)
            }
            if !self.pendingDeletes.isEmpty {
                self.albumCollectionView.deleteItemsAtIndexPaths(self.pendingDeletes)
            }
        }, completion: { finished in
            self.pendingInserts.removeAll(keepCapacity: false)
            self.pendingDeletes.removeAll(keepCapacity: false)

            dispatch_async(dispatch_get_main_queue()) {
                if !self.fetchedResultsController.fetchedObjects!.isEmpty {
                    self.newCollectionButton.enabled = true
                }
            }
        })
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            pendingInserts.append(newIndexPath!)
        case .Delete:
            pendingDeletes.append(indexPath!)
        default:
            break
        }
    }

    // MARK: UICollectionViewDataSource

    func configureCell(cell: AlbumCollectionViewCell, photo: Photo) {
        if let image = imageCache.loadImageWithIdentifier(photo.imageURL) {
            cell.imageView.image = image

            // Show image instead of activity indicator.
            cell.imageView.hidden = false
            cell.activityIndicatorView.stopAnimating()
        } else {
            // Show activity indicator instead of image.
            cell.imageView.hidden = true
            cell.activityIndicatorView.startAnimating()

            cell.imageTask = FlickrApiClient().taskForImage(photo.imageURL) { data, error in
                if data != nil {
                    dispatch_async(dispatch_get_main_queue()) {
                        if let image = UIImage(data: data!) {
                            cell.imageView.image = image

                            // Show image instead of activity indicator.
                            cell.imageView.hidden = false
                            cell.activityIndicatorView.stopAnimating()

                            // Store image in cache.
                            self.imageCache.storageImageWithIdentifier(image, identifier: photo.imageURL)
                        }
                    }
                }
            }
        }
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as Photo

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photo", forIndexPath: indexPath) as AlbumCollectionViewCell
        configureCell(cell, photo: photo)

        return cell
    }

    // MARK: UICollectionViewDelegate

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as Photo
        imageCache.removeImageWithIdentifier(photo.imageURL)
        sharedContext.deleteObject(photo)
        CoreDataStackManager.sharedInstance.saveContext()
    }
}