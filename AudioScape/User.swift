struct User : Equatable{
    let userID: String
    let songs: [String]
    
    

    init(userID: String, songs: [String]) {
        self.userID = userID
        self.songs = songs
        
    }

    // Initialize from a dictionary of data (e.g., Firestore document data)
}
