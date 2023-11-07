import ComposableArchitecture
import Foundation
import XCTestDynamicOverlay
import SwiftUI

struct AuthClient {
    var fetch: @Sendable (String) async throws -> String
    private var spotifyClientID = "efd582f277e04d36a7886c96b1390a08";
    private let redirectURLScheme = "audioscape://callback";
    private let scopes = ["user-read-email", "playlist-read-private"]
    @Environment(\.openURL) private var openURL
    
    
    private func authenticateWithSpotifyAuthFlow() {
        
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

extension DependencyValues {
  var authClient: AuthClient {
    get { self[AuthClient.self] }
    set { self[AuthClient.self] = newValue }
  }
}

extension AuthClient: DependencyKey {
  /// This is the "live" fact dependency that reaches into the outside world to fetch trivia.
  /// Typically this live implementation of the dependency would live in its own module so that the
  /// main feature doesn't need to compile it.
  static let liveValue = Self(
    fetch: { number in
      try await Task.sleep(for: .seconds(1))
      let (data, _) = try await URLSession.shared
        .data(from: URL(string: "http://numbersapi.com/\(number)/trivia")!)
      return String(decoding: data, as: UTF8.self)
    }
  )

  /// This is the "unimplemented" fact dependency that is useful to plug into tests that you want
  /// to prove do not need the dependency.
  static let testValue = Self(
    fetch: unimplemented("\(Self.self).fetch")
  )
}


