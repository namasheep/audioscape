struct User {
    let userID: String
    //let songs: [String]
    let location: String
    

    init(userID: String, songs: [String], location: String) {
        self.userID = userID
        //self.songs = songs
        self.location = location
    }

    // Initialize from a dictionary of data (e.g., Firestore document data)
    init?(id : String, data: [String: Any]) {
        let userID = id
        guard
            //let songs = data["songs"] as? [String],
            let location = data["location"] as? String
        else {
            return nil
        }

        self.userID = userID
        //self.songs = songs
        self.location = location
    }
}
