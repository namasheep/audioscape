//
//  ProfilePicture.swift
//  AudioScape
//
//  Created by Namashi Sivaram on 2023-10-14.
//

import Foundation
struct ProfilePicture : Codable{
    var height : Int
    var width : Int
    var url : String
    
    init(height: Int, width: Int, url: String){
        self.height = height
        self.width = width
        self.url = url
        
    }
}
