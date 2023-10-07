import FirebaseFirestore
import FirebaseAuth
struct HomeModel {
    static private let db = Firestore.firestore()

    static func getUsersWithGeohash(targetGeohash: String, completion: @escaping ([UserSong]?) -> Void) {
        // Reference to the "users" collection
        let usersCollection = db.collection("users")

        // Create a query to filter users with the same geohash
        let query = usersCollection.whereField("location", isEqualTo: targetGeohash)

        // Execute the query
        query.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching users: \(error)")
                completion(nil)
                return
            }

            // Check if there are any documents
            guard let documents = querySnapshot?.documents else {
                print("No users found with the specified geohash.")
                completion([])
                return
            }

            // Create an array to store user data
            var users: [UserSong] = []

            // Iterate through the documents to access user data
            for document in documents {
                
                let userData = document.data()
                print(document.documentID)
                print(userData)
                if document.documentID != Auth.auth().currentUser!.uid {
                    if let songs = userData["songs"] as? [String], !songs.isEmpty {
                        let randomValue = Int(arc4random_uniform(UInt32(songs.count)))
                        
                        guard randomValue < songs.count else {
                            print("Invalid random value generated.")
                            continue // Skip this user if an invalid random value is generated
                        }
                        
                        let randomSongId = songs[randomValue]
                        print("Random Song ID: \(randomSongId)")
                        
                        let user = UserSong(uid: document.documentID, songid: randomSongId)
                            
                        users.append(user)
                            
                        
                    } else {
                        print("No songs or songs data is not an array of strings.")
                    }
                }
            }


            // Call the completion handler with the user data
            completion(users)
        }
    }

}
