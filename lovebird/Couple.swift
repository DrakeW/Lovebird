//
//  Couple.swift
//  lovebird
//
//  Created by Junyu Wang on 4/6/17.
//  Copyright © 2017 Junyu Wang. All rights reserved.
//

import Foundation

class Couple {
    var userOne: User?
    var userTwo: User?
    var since: Date?
    
    init(birdOne: User, birdTwo: User) {
        userOne = birdOne
        userTwo = birdTwo
    }
}
