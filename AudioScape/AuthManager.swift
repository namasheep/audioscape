import Foundation

import SwiftUI
import FirebaseAuth
import CommonCrypto
import FirebaseFunctions
var spotifyClientID = "efd582f277e04d36a7886c96b1390a08";
private let redirectURLScheme = "audioscape://callback";
let scopes = ["user-read-email", "playlist-read-private"]

class AuthManager: ObservableObject {
    @Published var userInfo: UserInfo? = nil
    @Environment(\.openURL) private var openURL
    var accessToken: String = ""
    var fireToken: String = ""
    var refreshToken: String = ""
    var uid: String = ""
    @Published var isUserLoggedIn: Bool = Auth.auth().currentUser != nil
    @Published var isLoadingSignIn: Bool = false
    
    init() {
            // Load user information when the AuthManager is initialized
            loadUser()
        }
    
    func loadUser() {
        /*
            if let currentUser = Auth.auth().currentUser {
                print("HERE LOAD USER")
                Functions.functions().httpsCallable("getUserInfo").call(["uid": currentUser.uid]) { result, error in
                    print(result?.data)
                    if let error = error as NSError? {
                        if error.domain == FunctionsErrorDomain {
                            print(error)
                        }
                        // Handle the error here if needed
                        self.userInfo = nil // Set userInfo to nil when there's an error
                    } else if let data = result?.data as? [String: Any] {
                        self.userInfo = UserInfo(data: data, songs: [])
                        // Store the loaded user info
                        print("SUCCEED USER INFO")
                    } else {
                        print("FAIL USER INFO")
                        self.userInfo = nil // Set userInfo to nil if user info is not available
                    }
                }
            } else {
                self.userInfo = nil // Set userInfo to nil if there is no authenticated user
            }
         */
        }

    func authenticateWithSpotifyAuthFlow() {
        self.isLoadingSignIn = true
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
    
    func authenticateWithSpotifyPKCE() {
        print(self.accessToken)
        let (codeVerifier, codeChallenge) = generatePKCEChallenge()

        // Save the code verifier in a secure way for later use during token exchange
        UserDefaults.standard.set(codeVerifier, forKey: "codeVerifier")

        let scope = "user-read-email playlist-read-private" // Add any required scopes here

        // Construct the Spotify authentication URL with the code challenge
        var components = URLComponents(string: "https://accounts.spotify.com/authorize")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: spotifyClientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURLScheme),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: codeChallenge)
        ]

        // Convert the URL components to a URL object
        if let authURL = components?.url {
            openURL(authURL)
        }
    }
    func exchangeAuthorizationCodeForTokens(code: String) {
        guard let codeVerifier = UserDefaults.standard.string(forKey: "codeVerifier") else {
            // Handle error, code verifier not found
            return
        }

        let tokenExchangeURL = URL(string: "https://accounts.spotify.com/api/token")!

        var request = URLRequest(url: tokenExchangeURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let requestBody = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectURLScheme,
            "code_verifier": codeVerifier,
            "client_id": spotifyClientID // Add your client ID here
        ]

        let requestBodyString = requestBody
            .map { key, value in
                return "\(key)=\(value)"
            }
            .joined(separator: "&")

        request.httpBody = requestBodyString.data(using: .utf8)
        print(request)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                print(String(data: data, encoding: .utf8))
                if let tokenResponse = try? JSONDecoder().decode(TokenResponse.self, from: data) {
                    // Update your view model's properties with the received tokens
                    DispatchQueue.main.async {
                        self.accessToken = tokenResponse.access_token
                        self.refreshToken = tokenResponse.refresh_token
                        print(self.accessToken)
                        // Handle other token properties as needed
                    }
                } else {
                    // Handle decoding error
                    let decodingError = NSError(domain: "Token Decoding Error", code: 0, userInfo: nil)
                    print(decodingError)
                }
            } else if let error = error {
                // Handle network error
                print(error)
            }
        }.resume()

    }


    private func generatePKCEChallenge() -> (codeVerifier: String, codeChallenge: String) {
        let codeVerifier = generateRandomString(length: 64)
        let codeChallenge = codeVerifier.sha256().base64URLEncodedString()
        return (codeVerifier, codeChallenge)
    }
    func generateRandomString(length: Int) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
    func handleSpotifyCallbackPKCE(_ url: URL) {
        guard let code = extractAuthorizationCode(from: url) else {
            // Handle error, unable to extract code from the URL
            return
        }
        
        exchangeAuthorizationCodeForTokens(code: code)
        Auth.auth().signIn(withCustomToken: accessToken) { user, error in
            if let error = error {
                    // Handle error: Unable to sign in with custom token
                    print("Error signing in with custom token: \(error.localizedDescription)")
                    return
                }

                if let user = user {
                    // User successfully signed in with the custom token
                    // You can perform actions based on the signed-in user
                    // For example, update UI, fetch user data, navigate to a new screen, etc.
                    print("User successfully signed in: \(user)")
                    
                    // Now you might want to fetch additional user data or perform other actions
                    // ...

                } else {
                    // User is nil, indicating an issue with the sign-in process
                    print("User is nil after signing in with custom token")
                }
        }
    }
    func handleSpotifyCallback(_ url: URL) {
        guard let code = extractAuthorizationCode(from: url) else {
            // Handle error, unable to extract code from the URL
            return
        }
        
        print(code)
        lazy var functions = Functions.functions();
        functions.httpsCallable("authToken").call(["code":code,"redirect_uri":redirectURLScheme]) { result, error in
            print(result?.data)
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    print(error);
                }
                // ...
                
            }
            
            if let data = result?.data as? [String: Any],
               let customToken = data["fire_token"] as? String,
               let accessToken = data["access_token"] as? String,
               let uid = data["id"] as? String {
               
                Auth.auth().signIn(withCustomToken: customToken) { authResult, signInError in
                    print("SIGN IN")
                    if let signInError = signInError {
                        print("Firebase Authentication error: \(signInError.localizedDescription)")
                        // Handle sign-in error
                    } else {
                        // User signed in successfully
                        self.accessToken = accessToken
                        self.uid = uid
                        self.isUserLoggedIn = true
                        
                        
                        print("User signed in: \(authResult?.user.uid ?? "")")
                        // You can perform any further actions after the user is signed in
                    }
                }
            }
            self.isLoadingSignIn = false
            
        }
        
        
        
    }
    
    private func extractAuthorizationCode(from url: URL) -> String? {
        // Extract the authorization code from the URL query
        if let code = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "code" })?.value {
            return code
        }
        return nil
    }
    
    
    func callGenerateCustomTokenFunction() {
        let functions = Functions.functions()

        let data: [String: Any] = [
            "uid": "user123",
            "spotifyAccessToken": accessToken,
        ]

        functions.httpsCallable("generateCustomToken").call(data) { result, error in
            if let error = error {
                print("Error calling function: \(error)")
                return
            }

            if let customToken = (result?.data as? [String: Any])?["customToken"] as? String {
                print("Custom Token: \(customToken)")
                // Use the custom token as needed
            }
        }
    }
    
    // You can add methods to handle the Spotify callback and exchange the authorization code for access tokens
    // These methods will communicate with your backend server (Firebase Cloud Function) to securely handle sensitive operations
}
extension Data {
    func base64URLEncodedString() -> String {
        var base64String = self.base64EncodedString()
        base64String = base64String.replacingOccurrences(of: "+", with: "-")
        base64String = base64String.replacingOccurrences(of: "/", with: "_")
        base64String = base64String.replacingOccurrences(of: "=", with: "")
        return base64String
    }
    // ... (existing base64URLEncodedString extension)
}

extension String {
    func sha256() -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        if let data = self.data(using: .utf8) {
            data.withUnsafeBytes {
                _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
            }
        }
        return Data(hash)
    }
}
struct TokenResponse: Decodable {
    let access_token: String
    let refresh_token: String
    // Include other properties as needed
}
