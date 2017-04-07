//
//  User.swift
//  lovebird
//
//  Created by Junyu Wang on 4/6/17.
//  Copyright © 2017 Junyu Wang. All rights reserved.
//

import Foundation

class User {
    var name: String?
    var email: String?
    var isSingle: Bool?
    
    init(name: String, email: String) {
        self.name = name
        self.email = email
        self.isSingle = true
    }
}
