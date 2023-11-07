//
//  UserSong.swift
//  AudioScape
//
//  Created by Namashi Sivaram on 2023-09-08.
//

import Foundation
struct UserSong: Equatable, Hashable {
    var uid: String
    var songid: String
    
    init(uid: String, songid: String) {
        self.uid = uid
        self.songid = songid
    }
    
    // Implement the Hashable protocol
    func hash(into hasher: inout Hasher) {
        hasher.combine(uid)
        hasher.combine(songid)
    }
}
