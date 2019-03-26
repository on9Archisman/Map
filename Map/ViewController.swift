//
//  ViewController.swift
//  Map
//
//  Created by Archisman Banerjee on 12/03/19.
//  Copyright © 2019 Archisman Banerjee. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import GooglePlaces

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate
{
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var textField: UITextField!
    
    let locationManager = CLLocationManager()
    var route: MKRoute?
    var flag = false
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // MARK: CLLocation
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        /*
        let status = CLLocationManager.authorizationStatus()
        handleLocationAuthorizationStatus(status: status)
        */
    }
    
    // MARK: CLLocation Manager Delegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        handleLocationAuthorizationStatus(status: status)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        locationManager.stopUpdatingLocation()
        
        if let currentLocation = locations.last
        {
            print("CLLocationManager Location = \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude)")
            
            let span: MKCoordinateSpan = MKCoordinateSpan.init(latitudeDelta: 0.015, longitudeDelta: 0.015)
            
            let region: MKCoordinateRegion = MKCoordinateRegion.init(center: currentLocation.coordinate, span: span)
            
            mapView.setRegion(region, animated: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("CLLocationManager Error = \(error)")
    }
    
    // MARK: Location Miscellaneous
    func handleLocationAuthorizationStatus(status: CLAuthorizationStatus)
    {
        print("CLLocationManager AuthorizationStatus = \(status.rawValue)")
        
        switch status
        {
        case .notDetermined:
            print("Location services is not determined")
            locationManager.requestWhenInUseAuthorization()
            
        case .authorizedWhenInUse, .authorizedAlways:
            print("Location services is running")
            locationManager.startUpdatingLocation()
            
        case .denied:
            print("Location services were previously denied. Please enable location services for this app in Settings")
            statusDeniedAlert()
            
        case .restricted:
            print("Access to location services is restricted. Please enable location services for this app in Settings")
            statusDeniedAlert()
        
        @unknown default:
            //fatalError()
            //fatalError(String)
            break
        }
    }
    
    func statusDeniedAlert()
    {
        let alertController = UIAlertController(title: "Location Access Disabled", message: "In order to show the location on map, please open this app's settings and set location access to 'While Using'", preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Open Settings", style: .default, handler: { action in
            
            let settingsURL = URL(string: UIApplication.openSettingsURLString)
            UIApplication.shared.open(settingsURL!, options: [:], completionHandler: nil)
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: MKMapView Delegate
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation)
    {
        print("Map View Delegates : Did Update User Location = \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        if annotation is MKUserLocation
        {
            /*
             let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "user") ?? MKAnnotationView()
             annotationView.image = UIImage(named: "iconUserLocation")
             return annotationView
             */
            
            return nil
        }
        else
        {
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "rest") ?? MKAnnotationView()
            
            annotationView.image = UIImage(named: "iconPin")
            annotationView.canShowCallout = true
            annotationView.isDraggable = true
            
            return annotationView
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer
    {
        let renderer = MKPolylineRenderer(overlay: overlay)
        
        if (mapView.mapType == .standard || mapView.mapType == .mutedStandard)
        {
            renderer.strokeColor = UIColor.purple
        }
        else if (mapView.mapType == .satellite || mapView.mapType == .satelliteFlyover)
        {
            renderer.strokeColor = UIColor.yellow
        }
        else
        {
            renderer.strokeColor = UIColor.white
        }
        
        renderer.lineWidth = 3.0
        
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState)
    {
        switch newState
        {
        case .starting:
            view.dragState = .dragging
        case .ending, .canceling:
            view.dragState = .none
            // New Coordinates
            if let newCoordinate = view.annotation?.coordinate
            {
                print("New Coordinate =",newCoordinate)
                
                geocode(latitude: newCoordinate.latitude, longitude: newCoordinate.longitude) { (result, error) in
                    
                    print("geocode resut =", result as Any)
                    print("geocode error =", error as Any)
                    
                    if let placemark = result?.first
                    {
                        //annotation.title = "\(placemark.thoroughfare ?? "") \(placemark.subLocality ?? "")"
                        self.textField.text = "\(placemark.thoroughfare ?? "") \(placemark.subLocality ?? "")"
                    }
                    else
                    {
                        //annotation.title = "Destination"
                        self.textField.text = "Destination"
                    }
                    
                    if let userLocation = self.locationManager.location?.coordinate
                    {
                        self.addRouteToMapView(source: userLocation, destination: newCoordinate)
                    }
                }
            }
        default: break
        }
    }
    
    // MARK: IBAction
    @IBAction func actionTextFieldTapped(_ sender: UITextField)
    {
        textField.resignFirstResponder()
        
        let acController = GMSAutocompleteViewController()
        acController.delegate = self
        present(acController, animated: true, completion: nil)
    }
    
    @IBAction func actionUserLocation(_ sender: Any)
    {
        locationManager.startUpdatingLocation()
    }
    
    @IBAction func actionMapType(_ sender: Any)
    {
        let actionSheet = UIAlertController(title: "The type of map to display", message: "Please select !!", preferredStyle: .actionSheet)
        
        let actionButtonStandard = UIAlertAction(title: "Standard", style: .default, handler: alertAction)
        actionSheet.addAction(actionButtonStandard)
        
        let actionButtonSatellite = UIAlertAction(title: "Satellite", style: .default, handler: alertAction)
        actionSheet.addAction(actionButtonSatellite)
        
        let actionButtonHybrid = UIAlertAction(title: "Hybrid", style: .default, handler: alertAction)
        actionSheet.addAction(actionButtonHybrid)
        
        let actionButtonMutedStandard = UIAlertAction(title: "Muted Standard", style: .default, handler: alertAction)
        actionSheet.addAction(actionButtonMutedStandard)
        
        let actionButtonSatelliteFlyover = UIAlertAction(title: "Satellite Flyover", style: .default, handler: alertAction)
        actionSheet.addAction(actionButtonSatelliteFlyover)
        
        let actionButtonHybridFlyover = UIAlertAction(title: "Hybrid Flyover", style: .default, handler: alertAction)
        actionSheet.addAction(actionButtonHybridFlyover)
        
        let actionButtonCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            
            self.dismiss(animated: true, completion: nil)
        })
        
        actionSheet.addAction(actionButtonCancel)
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func actionPinDescription(_ sender: Any)
    {
        let alertController = UIAlertController(title: "Drop a Pin", message: "Please long press into the map, Pin automatically placed on that location", preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { action in
            
            self.dismiss(animated: true, completion: nil)
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func actionAddAnnotationWithLongGesture(_ sender: UILongPressGestureRecognizer)
    {
        let location = sender.location(in: mapView)
        print("Long PressLocation = \(location)")
        
        let coordinate: CLLocationCoordinate2D = mapView.convert(location, toCoordinateFrom: mapView)
        print("Long Press Coordinate = \(coordinate)")
        
        let annotation = MKPointAnnotation()
        
        annotation.coordinate = coordinate
        
        geocode(latitude: coordinate.latitude, longitude: coordinate.longitude) { (result, error) in
            
            print("geocode resut =", result as Any)
            print("geocode error =", error as Any)
            
            if let placemark = result?.first
            {
                annotation.title = "\(placemark.thoroughfare ?? "") \(placemark.subLocality ?? "")"
                self.textField.text = "\(placemark.thoroughfare ?? "") \(placemark.subLocality ?? "")"
            }
            else
            {
                annotation.title = "Destination"
                self.textField.text = "Destination"
            }
            
            self.mapView.removeAnnotations(self.mapView.annotations)
            
            self.mapView.addAnnotation(annotation)
            
            if let userLocation = self.locationManager.location?.coordinate
            {
                self.addRouteToMapView(source: userLocation, destination: coordinate)
            }
        }
    }
    
    // MARK: Map Type Miscellaneous
    func alertAction(action: UIAlertAction)
    {
        switch action.title
        {
        case "Standard":
            self.mapView.mapType = .standard
        case "Satellite":
            self.mapView.mapType = .satellite
        case "Hybrid":
            self.mapView.mapType = .hybrid
        case "Muted Standard":
            self.mapView.mapType = .mutedStandard
        case "Satellite Flyover":
            self.mapView.mapType = .satelliteFlyover
        case "Hybrid Flyover":
            self.mapView.mapType = .hybridFlyover
        default:
            break
        }
        
        if (self.flag)
        {
            //add rout to our mapview
            self.mapView.removeOverlays(self.mapView.overlays)
            self.mapView.addOverlay(self.route!.polyline, level: .aboveRoads)
        }
    }
    
    // MARK: Add Route To Mapview
    func addRouteToMapView(source: CLLocationCoordinate2D, destination: CLLocationCoordinate2D)
    {
        let sourcePlaceMark = MKPlacemark(coordinate: source)
        let destinationPlaceMark = MKPlacemark(coordinate: destination)
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = MKMapItem(placemark: sourcePlaceMark)
        directionRequest.destination = MKMapItem(placemark: destinationPlaceMark)
        directionRequest.transportType = .automobile
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { (response, error) in
            guard let directionResonse = response
                else
            {
                if let error = error
                {
                    print("We have error getting directions = \(error.localizedDescription)")
                }
                
                // If Faliure
                self.mapView.removeOverlays(self.mapView.overlays)
                self.flag = false
                
                return
            }
            
            //get route and assign to our route variable
            self.route = directionResonse.routes[0]
            self.flag = true
            
            //add route to our mapview
            self.mapView.removeOverlays(self.mapView.overlays)
            self.mapView.addOverlay(self.route!.polyline, level: .aboveRoads)
            
            //setting rect of our mapview to fit the two locations
            let rect = self.route!.polyline.boundingMapRect
            self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
        }
    }
    
    // MARK: Reverse Geocode
    func geocode(latitude: Double, longitude: Double, completion: @escaping (_ placemark: [CLPlacemark]?, _ error: Error?) -> Void)
    {
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: latitude, longitude: longitude)) { placemark, error in
            
            guard let placemark = placemark, error == nil
                else
            {
                completion(nil, error)
                return
            }
            
            completion(placemark, nil)
        }
    }
}

extension ViewController: GMSAutocompleteViewControllerDelegate
{
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace)
    {
        // Get the place from 'GMSAutocompleteViewController'
        print("Place", place)
        
        var destinationName: String?
        
        if let name = place.name
        {
            destinationName = name
        }
        else
        {
            destinationName = "Destination"
        }
        
        if let address = place.formattedAddress
        {
            textField.text = address
        }
        
        if let coordinate = place.coordinate as CLLocationCoordinate2D?
        {
            // Add Annotation
            let annotation = MKPointAnnotation()
            
            annotation.coordinate = coordinate
            annotation.title = destinationName
            
            mapView.removeAnnotations(mapView.annotations)
            
            mapView.addAnnotation(annotation)
            
            if let userLocation = locationManager.location?.coordinate
            {
                addRouteToMapView(source: userLocation, destination: coordinate)
            }
        }
        
        // Dismiss the GMSAutocompleteViewController when something is selected
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error)
    {
        // Handle the error
        print("Error: ", error.localizedDescription)
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController)
    {
        // Dismiss when the user canceled the action
        dismiss(animated: true, completion: nil)
    }
}
