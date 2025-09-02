//
//  LocationModel.swift
//  Corbo
//
//  Created by Agustín Nanni on 08/07/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import Foundation
import CoreLocation
import SwiftUI

@Observable
class LocationModel: NSObject, CLLocationManagerDelegate {
    static let shared = LocationModel()
    private let locationManager = CLLocationManager()
    private(set) var locationStatus: CLAuthorizationStatus?
    private var lastLocation: CLLocation?
    private var lastUserFacingLocation: Location?
    private var lastSuccesfulGeocode: Date?
    
    var shouldRequestPermission: Bool {
        switch self.locationStatus {
        case .notDetermined:
            return true
        case .restricted:
            return true
        case .denied:
            return false
        case .authorizedAlways:
            return false
        case .authorizedWhenInUse:
            return false
        case .authorized:
            return false
        default:
            return true
        }
    }
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.startUpdatingLocation()
    }
    
    func requestPermission() {
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.locationStatus = status
    }
    
    func updateLocation() {
        self.locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        AppLogs.defaultLogger.error("Location error: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let foundLocation = locations.last else { return }
        
        if lastSuccesfulGeocode == nil || Date.now.timeIntervalSince(lastSuccesfulGeocode!) > 70 {
            
            self.lastLocation = foundLocation
            AppLogs.defaultLogger.info("Geocoding API called, last call was: \(self.lastSuccesfulGeocode?.formatted() ?? "nil")")
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(foundLocation,
                        completionHandler: { (placemarks, error) in
                if error == nil {
                    let firstLocation = placemarks?[0]
                    self.lastUserFacingLocation = Location(lat: foundLocation.coordinate.latitude, lon: foundLocation.coordinate.longitude, geocode: self.parseLocation(location: foundLocation, placemark: firstLocation))
                    self.lastSuccesfulGeocode = Date.now
                }
                else {
                    AppLogs.defaultLogger.error("locationManager: unable to geocode location")
                }
            })
        }
    }
    
    func parseLocation(location: CLLocation, placemark: CLPlacemark?) -> String {
        var result = ""
        if let placemark = placemark {
            if let sublocality = placemark.subLocality {
                result += sublocality
            }
            if !result.isEmpty {
                result += ", "
            }
            if let state = placemark.postalAddress?.state {
                result += state
            }
            if !result.isEmpty {
                result += ", "
            }
            if let country = placemark.isoCountryCode {
                result += country
            }
        } else {
            result += location.coordinate.latitude.formatted()
            result += ", "
            result += location.coordinate.longitude.formatted()
        }
        
        return result
    }
    
    func getLastLocation() -> Location? {
        return self.lastUserFacingLocation
    }
}
