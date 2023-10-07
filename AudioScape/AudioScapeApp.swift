//
//  AudioScapeApp.swift
//  AudioScape
//
//  Created by Namashi Sivaram on 2023-08-05.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseFunctions
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure();
            // Other setup code
        Firestore.firestore()
        
        return true
    }
    
}

@main
struct AudioScapeApp: App {
    @StateObject private var authManager = AuthManager()
    
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var firestoreManager = FirestoreManager()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                        // Handle the opened URL here using your view model
                        authManager.handleSpotifyCallback(url)
                        authManager.loadUser()
                    }
                .environmentObject(authManager)
                .environmentObject(locationManager)
        }
    }
}

