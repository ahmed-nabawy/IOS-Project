//
//  Movie.swift
//  Final
//
//  Created by iOS Training on 3/16/20.
//  Copyright © 2020 JETS. All rights reserved.
//

class Movie: NSObject {
    
    var title: String
    var image: String
    var relYear: String
    var rating: Double
    var desc: String
    var id: Int
    
    init(title: String, image: String, relYear: String, rate: Double, desc: String, id: Int) {
        self.title = title
        self.image = image
        self.relYear = relYear
        self.rating = rate
        self.desc = desc
        self.id = id
    }
}