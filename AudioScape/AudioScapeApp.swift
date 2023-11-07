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
import ComposableArchitecture
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure();
            // Other setup code
        Firestore.firestore()
        
        return true
    }
    
}
struct AppStore : Reducer{
    var spotifyClientID = "efd582f277e04d36a7886c96b1390a08";
    private let redirectURLScheme = "audioscape://callback";
    @Environment(\.openURL) private var openURL
    struct State:Equatable{
        var loggedIn = Auth.auth().currentUser == nil ? false : true
        var contentState = ContentDomain.State()
    }
    enum Action : Equatable{
        case startOAuth
        case contentAction(ContentDomain.Action)
        
    }
    var body: some ReducerOf<Self> {
        Scope(state: \.contentState, action: /AppStore.Action.contentAction) {
              ContentDomain()
            }
        Reduce { state, action in
            switch action{
            case .startOAuth:
                return .none
            case .contentAction(let contentA):
                return .none
            }
            
        }
    }
    func authSpotifyStart(){
        let scope = "user-read-email playlist-read-private" // Add any required scopes here

                // Construct the Spotify authentication URL
                var components = URLComponents(string: "https://accounts.spotify.com/authorize")
                    components?.queryItems = [
                        URLQueryItem(name: "client_id", value: spotifyClientID),
                        URLQueryItem(name: "response_type", value: "code"),
                        URLQueryItem(name: "redirect_uri", value: redirectURLScheme),
                        URLQueryItem(name: "scope", value: scope),
                        URLQueryItem(name: "show_dialog", value: "true")
                    ]

                // Convert the URL components to a URL object
                if let authURL = components?.url {
                    openURL(authURL);
                }
                
    }
    
    
}
@main
struct AudioScapeApp: App {
    //@StateObject private var authManager = AuthManager()
    
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var firestoreManager = FirestoreManager()
    var body: some Scene {
        WindowGroup {
            /*
            LoginView(
                store: Store(initialState: LoginDomain.State(ninePlay: NinePlayDomain.State())) {
                LoginDomain()
              }
            )*/
                ContentView(
                    store: Store(initialState: ContentDomain.State()) {
                    ContentDomain()
                  }
                )/*
                    .onOpenURL { url in
                        // Handle the opened URL here using your view model
                        authManager.handleSpotifyCallback(url)
                        authManager.loadUser()
                    }*/
                    //.environmentObject(authManager)
                    .environmentObject(locationManager)
            }
        
    }
}

