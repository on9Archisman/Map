//
//  ViewController.swift
//  Map
//
//  Created by Archisman Banerjee on 12/03/19.
//  Copyright © 2019 Archisman Banerjee. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate
{
    let locationManager = CLLocationManager()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // MARK: CLLocation
        locationManager.delegate = self
//        locationManager.distanceFilter = kCLDistanceFilterNone
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        let status = CLLocationManager.authorizationStatus()
        handleLocationAuthorizationStatus(status: status)
    }
    
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
        }
    }
    
    func statusDeniedAlert()
    {
        let alertController = UIAlertController(title: "Location Access Disabled", message: "In order to show the location on map, please open this app's settings and set location access to 'While Using'", preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Open Settings", style: .`default`, handler: { action in
            
            let settingsURL = URL(string: UIApplication.openSettingsURLString)
            UIApplication.shared.open(settingsURL!, options: [:], completionHandler: nil)
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: CLLocation Manager Delegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        handleLocationAuthorizationStatus(status: status)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        if let currentLocation = locations.last
        {
            print("CLLocationManager Location = \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude)")
            
            locationManager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("CLLocationManager Error = \(error)")
    }
}
