import Foundation

class SpotifyAPIManager {
    static let shared = SpotifyAPIManager()
    private let baseURL = "https://api.spotify.com/v1"

    func fetchUserData(accessToken: String, completion: @escaping (Result<UserData, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/me")
        var request = URLRequest(url: url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let data = data {
                do {
                    let userData = try JSONDecoder().decode(UserData.self, from: data)
                    completion(.success(userData))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}

struct UserData: Codable {
    let id: String // User's Spotify UID
    let display_name: String // User's Spotify username
    // Add more properties as needed
}
