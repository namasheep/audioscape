//
//  Song.swift
//  AudioScape
//
//  Created by Namashi Sivaram on 2023-10-29.
//

import Foundation

struct Song: Equatable {
    var id: String
    var name: String
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
    
    static func == (lhs: Song, rhs: Song) -> Bool {
        // Compare the id and name properties for equality
        return lhs.id == rhs.id && lhs.name == rhs.name
    }
}
