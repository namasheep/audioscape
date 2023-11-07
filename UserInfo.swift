struct UserInfo : Equatable{
    static func == (lhs: UserInfo, rhs: UserInfo) -> Bool {
        return lhs.userID == rhs.userID &&
                   lhs.dispName == rhs.dispName &&
                   lhs.href == rhs.href &&
                   lhs.songs == rhs.songs
                   
    }
    
    let userID: String
    //var image
    var dispName : String
    var href : String
    var profilePics : ProfilePicture?
    var songs: [String]?
    
    

    init(userID: String, songs: [String]?, href : String, dispName : String, img : ProfilePicture?) {
        self.dispName = dispName
        //self.songs = songs
        self.userID = userID
        self.songs = songs
        self.href = href
        self.profilePics = img
    }

    // Initialize from a dictionary of data (e.g., Firestore document data)
    /*init?(data: [String: Any], songs : [String]) {
        
        //self.songs = songs
        guard
            //let songs = data["songs"] as? [String],
            let userID = data["id"] as? String,
            let dispName = data["display_name"] as? String,
            let href = data["href"] as? String,
            let songsList = data["songs"] as? [String],
            let profPics = data["images"] as? [ProfilePicture]
            
        else {
            return nil
        }

        self.userID = userID
        self.href = href
        self.dispName = dispName
        self.songs = songs
        self.profilePics = profPics
        
    }*/
}
