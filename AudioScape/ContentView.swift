import SwiftUI
import FirebaseAuth
import CoreLocation // Import Core Location
struct ContentView: View {
    
    @State private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    @EnvironmentObject private var locationManager: LocationManager
    
    // Replace with your user identifier
    @EnvironmentObject private var authManager: AuthManager
    
    var body: some View {
        ZStack {
            if (!authManager.isUserLoggedIn) {
                LoginView(loginAction: login)
            } else if (authManager.isLoadingSignIn) {
                ProgressView()
            } else if((authManager.userInfo) != nil){
                HomeView(logoutAction: logout)
            }
        }
        .onReceive(authManager.$isUserLoggedIn) { isLoggedIn in
                    // When isUserLoggedIn changes, you can start or stop location updates here
            if(isLoggedIn){
                locationManager.requestLocation()
            }
            
        }
        .onDisappear {

        }
    }
    
    private func login() {
        authManager.authenticateWithSpotifyAuthFlow()
    }
    
    private func logout() {
        do {
            try Auth.auth().signOut()
            authManager.isUserLoggedIn = false
        } catch let error {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
