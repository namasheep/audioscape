struct UserInfo {
    let userID: String
    //var image
    var dispName : String
    var href : String
    //var songs: [String]
    
    

    init(userID: String, songs: [String], href : String, dispName : String) {
        self.dispName = dispName
        //self.songs = songs
        self.userID = userID
        //self.songs = songs
        self.href = href
    }

    // Initialize from a dictionary of data (e.g., Firestore document data)
    init?(data: [String: Any], songs : [String]) {
        
        //self.songs = songs
        guard
            //let songs = data["songs"] as? [String],
            let userID = data["id"] as? String,
            let dispName = data["display_name"] as? String,
            let href = data["href"] as? String
            
        else {
            return nil
        }

        self.userID = userID
        self.href = href
        self.dispName = dispName
       // self.songs = songs
        
    }
}
