//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Matthias on 06/04/15.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var travelLocationsMapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        // Display previous region.
        if let region = NSUserDefaults.standardUserDefaults().objectForKey("travelLocationsMapViewRegion") as? [Double] {
            // Commented out as this does currently not work, this appears to be a bug with MapKit.
            // travelLocationsMapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: region[0], longitude: region[1]), span: MKCoordinateSpan(latitudeDelta: region[2], longitudeDelta: region[3])), animated: false)
        }

        // Install long pressure gesture recognizer.
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        travelLocationsMapView.addGestureRecognizer(gestureRecognizer)

        // Fetch pins using NSFetchedResultsController.
        var error: NSError?

        fetchedResultsController.delegate = self

        if !fetchedResultsController.performFetch(&error) {
            let alert = UIAlertController(title: nil, message: error!.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }

        // Add annotations for loaded pins.
        travelLocationsMapView.addAnnotations(fetchedResultsController.fetchedObjects)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Hide navigation bar.
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "albumSegue" {
            if let controller = segue.destinationViewController as? AlbumViewController {
                controller.pin = sender as Pin
            }
        }
    }

    // MARK: NSFetchedResultsController

    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "latitude", ascending: true) ]

        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStackManager.sharedInstance.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
    }()

    // MARK: NSFetchedResultsControllerDelegate

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            travelLocationsMapView.addAnnotation(anObject as Pin)
        case .Delete:
            travelLocationsMapView.removeAnnotation(anObject as Pin)
        case .Update:
            travelLocationsMapView.removeAnnotation(anObject as Pin)
            travelLocationsMapView.addAnnotation(anObject as Pin)
        default:
            break
        }
    }

    // MARK: UILongPressGestureRecognizer

    func handleLongPress(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == .Began {
            // Convert tap location to map coordinate.
            let touchPoint = gestureRecognizer.locationInView(travelLocationsMapView)
            let coordinate = travelLocationsMapView.convertPoint(touchPoint, toCoordinateFromView: travelLocationsMapView)

            // Create new pin for tapped location.
            let pin = Pin(dictionary: ["latitude": coordinate.latitude, "longitude": coordinate.longitude], context: CoreDataStackManager.sharedInstance.managedObjectContext!)

            // Save context.
            CoreDataStackManager.sharedInstance.saveContext()
        }
    }

    // MARK: MKMapViewDelegate

    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        let region: [Double] = [mapView.region.center.latitude, mapView.region.center.longitude, mapView.region.span.latitudeDelta, mapView.region.span.longitudeDelta]
        NSUserDefaults.standardUserDefaults().setObject(region, forKey: "travelLocationsMapViewRegion")
    }

    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        var view = mapView.dequeueReusableAnnotationViewWithIdentifier("pin") as MKPinAnnotationView!

        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            view.animatesDrop = true
        } else {
            view.annotation = annotation
        }

        return view
    }

    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        performSegueWithIdentifier("albumSegue", sender: view.annotation)
    }
}