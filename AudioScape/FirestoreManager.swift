//
//  FirestoreManager.swift
//  HarmonyHub
//
//  Created by Namashi Sivaram on 2023-07-23.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore
import Geohash
class FirestoreManager: ObservableObject {
    let db: Firestore

    init() {
        // If you haven't done it already in your AppDelegate or SceneDelegate
        db = Firestore.firestore()
    }
    func updateGeoHash(){
        
    }
    func addUserData(uid: String, latitude: Double, longitude: Double, songNames: [String]) {
            let usersCollection = db.collection("users")
            let userDocument = usersCollection.document(uid)
        do{
            let s = try Geohash.encode(latitude: latitude, longitude: longitude, precision: .custom(value: 9))
            let userProfile: [String: Any] = [
                "uid": uid,
                "latitude": latitude,
                "longitude": longitude,
                "geohash" : s,
                "songNames": songNames
            ]

            userDocument.setData(userProfile) { error in
                if let error = error {
                    print("Error adding document: \(error)")
                } else {
                    print("Document added with ID: \(userDocument.documentID)")
                }
            }
        }
        catch {
            print("Error while encoding Geohash: \(error)")
        }
           
        }
}
