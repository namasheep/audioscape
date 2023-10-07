import Foundation
import Geohash
import CoreLocation
import FirebaseFunctions
import FirebaseFirestore
import FirebaseAuth
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager() // Create a singleton instance
    
    private let locationManager = CLLocationManager()

    @Published var lastKnownLocation: CLLocation?
    @Published var locationStatus: CLAuthorizationStatus?
    
    private var lastUpdatedLocation: CLLocation?
    
    private let significantDistanceThreshold: CLLocationDistance = 10.0 // Adjust as needed

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //locationManager.requestWhenInUseAuthorization()
        //locationManager.startUpdatingLocation()
        
        // Initialize lastUpdatedLocation as nil
        lastUpdatedLocation = nil
    }

    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate Methods

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            lastKnownLocation = location
            sendLocationIfUpdated()
        }
    }
    
    private func sendLocationIfUpdated() {
        if let location = lastKnownLocation {
            if let lastLocation = lastUpdatedLocation {
                // Calculate the distance between the current and last location
                let distance = location.distance(from: lastLocation)
                
                if distance >= significantDistanceThreshold {
                    // The location has changed significantly, so send it to your database
                    print(location)
                    
                    // Update the last updated location
                    lastUpdatedLocation = location
                }
            } else {
                // If lastUpdatedLocation is nil (first update), consider it significant
                print(location)
                if(Auth.auth().currentUser != nil){
                    do{
                        let latitude = location.coordinate.latitude
                        let longitude = location.coordinate.longitude
                        let geo = try Geohash.encode(latitude: latitude, longitude: longitude, precision: .custom(value: 9))
                        let usersCollection = Firestore.firestore().collection("users")
                        let userDocument = usersCollection.document(Auth.auth().currentUser!.uid)
                        /* Functions.functions().httpsCallable("uploadGeoHash").call(["geoHash":geo]) { result, error in
                         if let error = error {
                         print("Error calling function: \(error)")
                         return
                         }
                         
                         else{
                         self.lastUpdatedLocation = location
                         }
                         }*/
                        userDocument.setData([ "location": geo ], merge: true) { error in
                            if let error = error {
                                print("Error adding document: \(error)")
                            } else {
                                print("Document added with ID: \(userDocument.documentID)")
                            }
                        }
                    }
                    catch{
                        print("error encoding GEOHASH");
                    }
                }
                // Update the last updated location
                
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationStatus = status

        switch status {
        case .notDetermined:
            // Location authorization status is not yet determined
            print("not auth")
        case .authorizedWhenInUse, .authorizedAlways:
            // Location access is authorized, you can start updating the location
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            // Location access is denied or restricted
            // Handle the scenario where location services are not available
            print("DSDS")
        @unknown default:
            break
        }
    }

    // MARK: - Additional Convenience Methods

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    func requestLocationOnce() {
        locationManager.requestLocation()
    }

    func checkLocationServicesEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }

    func checkLocationAuthorizationStatus() -> CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }
    func getLocationHash() -> String?{
        do{
            let latitude = lastKnownLocation!.coordinate.latitude
            let longitude = lastKnownLocation!.coordinate.longitude
            let geo = try Geohash.encode(latitude: latitude, longitude: longitude, precision: .custom(value: 9))
            print(geo)
            return geo
        }
        catch{
            print("Error hashing current location")
            return nil
        }
    }
}
