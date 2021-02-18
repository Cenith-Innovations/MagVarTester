// ********************** AircraftParametersController *********************************
// * Copyright © Cenith Innovations, LLC - All Rights Reserved
// * Created on 2/18/21, for MagVar
// * Matthew Elmore <matt@cenithinnovations.com>
// * Unauthorized copying of this file is strictly prohibited
// ********************** AircraftParametersController *********************************

import CoreLocation
import UIKit
import Combine
import SwiftUI
import U2Gonk

class AircraftParametersController: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    public static var shared = AircraftParametersController()
    
    private let locationManager = CLLocationManager()
    @Published var lat = 0.0
    @Published var long = 0.0
    @Published var heading: Double = 0.0
    @Published var altitude: Double = 0.0
    @Published var speed: Double = 0.0
    @Published var locationAvailable = false
    @Published var magneticVariation: Double = 0.0
    
    @Published var magHeading: Double = 0.0
    @Published var trueHeading: Double = 0.0
    
    override init() {
        super.init()
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingHeading()
        locationManager.startUpdatingLocation()
        locationAvailable = CLLocationManager.locationServicesEnabled()
        locationManager.delegate = self
        checkLocationServices(locationManager)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        altitude = location.altitude.metersToFeet
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard let currentSpeed = manager.location?.speed else { return }
        guard let location = manager.location else { return }
        lat = location.coordinate.latitude
        long = location.coordinate.longitude
        speed = currentSpeed.metersPerSecondToNauticalMilesPerHour
        magneticVariation = getMagVariation(trueHeading: newHeading.trueHeading, magHeading: newHeading.magneticHeading)
        heading = newHeading.magneticHeading
        magHeading = newHeading.magneticHeading
        trueHeading = newHeading.trueHeading
    }
    
    // MARK: - 🔅 MAGNETIC VARIATION CALULATION
    // MARK: 👉 ChaCha: this is what I'm testing. Specifically the "case _ where result < -90:"
    // MARK: 👉 I'm switching on if the value is > 90 or < -90 because the only time that happens is when the two values straddle 360°. Everything else falls into the default.
    // MARK: 👉 Also, since you like this shit, the U2Gonk package is a work in progress and would love it if you proof read that too. It's linked in this project but here's a link to the GitHub if you feel like pulling and looking through it:
    //https://github.com/Cenith-Innovations/U2Gonk
    func getMagVariation(trueHeading: Double, magHeading: Double) -> Double {
        var result = magHeading - trueHeading
        switch result {
        case _ where result > 90:
            // MARK: 👉 Western Hemisphere
            let magHeadingDis = abs(360.0.distance(to: magHeading))
            let trueHeadingDis = abs(trueHeading.distance(to: 0))
            result = -1 * (magHeadingDis + trueHeadingDis)
        case _ where result < -90:
            // MARK: 👉 This needs to be tested in the Eastern Hemisphere
            let magHeadingDis = abs(magHeading.distance(to: 0))
            let trueHeadingDis = abs(360.0.distance(to: trueHeading))
            result = magHeadingDis + trueHeadingDis
        default:
            result = magHeading - trueHeading
        }
        return result
    }
    
    func checkLocationServices(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways , .authorizedWhenInUse:
            locationAvailable = true
        case .notDetermined , .denied , .restricted:
            locationAvailable = false
        default:
            break
        }
    }
    
    func rangeBearingAndCourseTo(latitude: Double, longitude: Double) -> (range: Double, bearing: Double, course: Double) {
        // MARK: 👉 I could prob make this a little more accurate with Using the haversine formula but this is fine for the fidelity of this application.
        //The lin below is where I got the mathematics for this function
        //https://www.movable-type.co.uk/scripts/latlong.html
        let majEarthAxis_WGS84: Double = 6_378_137.0
        let minEarthAxis_WGS84: Double = 6_356_752.314_245
        let lat_01 = lat.degreesToRadians
        let long_01 = long.degreesToRadians
        let lat_02 = latitude.degreesToRadians
        let long_02 = longitude.degreesToRadians
        let difLong = (longitude.degreesToRadians - long.degreesToRadians)
        //1: Earth RadiusCorrectionFactor()
        let a1 = 1.0 / (majEarthAxis_WGS84 * majEarthAxis_WGS84)
        let b1 = (tan(lat_01) * tan(lat_01)) / (minEarthAxis_WGS84 * minEarthAxis_WGS84)
        let c1 = 1.0 / ((a1+b1).squareRoot())
        let d1 = c1 / (cos(lat_01))
        //2: Law of Cosines
        let range = (acos(sin(lat_01)*sin(lat_02) + cos(lat_01)*cos(lat_02) * cos(difLong)) * d1).metersToNauticalMiles
        //3: Calculating Course and Bearing
        let a3 = sin(long_02 - long_01) * cos(lat_02)
        let b3 = cos(lat_01) * sin(lat_02) - sin(lat_01) * cos(lat_02) * cos(long_02 - long_01)
        var course = (atan2(a3, b3).radiansToDegrees)
        course = (course + 360).truncatingRemainder(dividingBy: 360) + magneticVariation
        let bearing = toCourse(course)
        return (range: range, bearing: bearing, course: course)
    }
    
    
    func toCourse(_ heading: Double) -> Double {
        var result: Double
        switch heading {
        case _ where heading >= 180 && heading < 360:
            result = heading - 180
        case _ where heading < 180:
            result = heading + 180
        default:
            result = 999999.9
        }
        return result
    }
}

extension Double {
    var radiansToDegrees: Double { self * 180 / Double.pi }
    var degreesToRadians: Double { self * Double.pi / 180 }
    var metersToFeet: Double { self * 3.2808399 }
    var feetToMeters: Double { self * 0.3048 }
    var metersToNauticalMiles: Double { self * 0.0005396118248380001 }
    var nauticalMilesToMeters: Double { self * 1852 }
    var knotsPHrToNMperMin: Double { self / 60.0 }
    var metersPerSecondToNauticalMilesPerHour: Double { self * 1.944}
    
    func toStringWithDec(_ num: Int) -> String {
        "\(String(format: "%.\(num)f",self))"
    }
    
    enum CoordType { case lat, long}
    func coordToString(decPlaces: Int, coordType: CoordType) -> String {
        switch coordType {
        case .lat:
            return self.toStringWithDec(decPlaces).replacingOccurrences(of: "-", with: "") + (self < 0 ? "°S" : "°N")
        case .long:
            return self.toStringWithDec(decPlaces).replacingOccurrences(of: "-", with: "") + (self < 0 ? "°W" : "°E")
        }
    }
}

extension Array where Element: Hashable {
    /// Removes duplicate items from an array.
    /// - Returns: Returns an array with duplicates removed.
    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()
        
        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }
    
    mutating func removeDuplicates() {
        self = self.removingDuplicates()
    }
}
