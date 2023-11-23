import SwiftUI
import FirebaseAuth
import CoreLocation // Import Core Location
import FirebaseFunctions
import ComposableArchitecture
extension Notification.Name {
    static let AuthSuccess = Notification.Name("AuthSuccess")
}
struct ContentDomain : Reducer{
    var spotifyClientID = "efd582f277e04d36a7886c96b1390a08";
    private let redirectURLScheme = "audioscape://callback";
    @Environment(\.openURL) private var openURL
    struct State : Equatable{
        var loggedIn = Auth.auth().currentUser == nil ? false : true
        var loadingLogin = false
        var loadingText = " "
        var home = HomeDomain.State()
    }
    enum Action : Equatable{
        case startOAuthLogin
        case authCallback(URL)
        case firebaseError
        case spotifyAuthError
        case signInSuccess
        case homeAction(HomeDomain.Action)
        case logOutSuccess
    }
    var body: some ReducerOf<Self> {
        Scope(state: \.home, action: /Action.homeAction) {
            HomeDomain(locationManager: AppEnvironment.locationManager)
            }
        Reduce { state, action in
            switch action{
            case .startOAuthLogin:
                authSpotifyStart()
                return .none
            case .authCallback(let url):
                print("CALLBACK CONTENT")
                guard let code = extractAuthorizationCode(from: url) else {
                    // Handle error, unable to extract code from the URL
                    print("ERROR IN CALLBACK", url)
                    return .none
                }
                state.loadingLogin = true
                state.loadingText = "Authenticating with Spotify"
                return .run { send in
                    Task {
                        do {
                            let result = try await Functions.functions().httpsCallable("authToken").call(["code": code, "redirect_uri": redirectURLScheme])
                            if let data = result.data as? [String: Any],
                               let customToken = data["fire_token"] as? String,
                               let accessToken = data["access_token"] as? String,
                               let uid = data["id"] as? String {
                                do {
                                    let authResult = try await Auth.auth().signIn(withCustomToken: customToken)
                                    print("User signed in: \(authResult.user.uid ?? "")")
                                    await send(.signInSuccess)
                                }
                                catch{
                                    print("ERROR in FIREBASE")
                                }
                            }
                        } catch {
                            print("Error during authentication: \(error)")
                        }
                    }
                }
                
            case .firebaseError:
                return .none
            case .spotifyAuthError:
                return .none
            case .signInSuccess:
                state.loggedIn = true
                state.loadingLogin = false
                NotificationCenter.default.post(name: .AuthSuccess, object: nil)
                return .none
           case .homeAction(let action):
                if(action == HomeDomain.Action.logOut){
                    //state.user = Auth.auth().currentUser
                    return .run{
                        send in
                        do {
                            print("DSDSDSAADS")
                            try Auth.auth().signOut()
                            await send(.logOutSuccess)
                            
                            
                        } catch let error {
                            print("Error signing out: \(error.localizedDescription)")
                        }

                    }
                    
                }
                return .none
            case .logOutSuccess:
                state.loggedIn = false
                return .none
            
                
            }
        }
    }
    private func extractAuthorizationCode(from url: URL) -> String? {
        // Extract the authorization code from the URL query
        if let code = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "code" })?.value {
            return code
        }
        return nil
    }
    func authSpotifyStart(){
        let scope = "user-read-email playlist-read-private user-read-private" // Add any required scopes here

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

struct AppEnvironment{
    static var locationManager = LocationManager.shared
}
struct ContentView: View {
    
    @State private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    let store: StoreOf<ContentDomain>
    // Replace with your user identifier
    @EnvironmentObject private var authManager: AuthManager
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ZStack{
                if(viewStore.loadingLogin){
                    ProgressView("Loading ...")
                }
                else if(viewStore.loggedIn == false && viewStore.loadingLogin == false){
                    Button("LOGIN"){
                        viewStore.send(.startOAuthLogin)
                    }
                }
                
                else{
                    HomeView(
                        store: self.store.scope(
                            state: \.home,
                            action: ContentDomain.Action.homeAction
                        )
                    )
                    /*HomeView(
                        store: Store(initialState: HomeDomain.State()) {
                            HomeDomain(locationManager: AppEnvironment.locationManager)
                        }
                    )*/
                }
            }
            .onOpenURL { url in
                viewStore.send(.authCallback(url))
                //authManager.loadUser()
            }
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
        ContentView(
            store: Store(initialState: ContentDomain.State()) {
            ContentDomain()
          }
        )
    }
}

