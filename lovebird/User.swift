//
//  User.swift
//  lovebird
//
//  Created by Junyu Wang on 4/6/17.
//  Copyright © 2017 Junyu Wang. All rights reserved.
//

import Foundation

class User {
    var id: String?
    var name: String?
    var email: String?
    var isSingle: Bool?
    var partenrId: String?
    
    init(_ id: String, name: String, email: String, status: Bool) {
        self.id = id
        self.name = name
        self.email = email
        self.isSingle = status
    }
}
