//
//  User.swift
//  lovebird
//
//  Created by Junyu Wang on 4/6/17.
//  Copyright © 2017 Junyu Wang. All rights reserved.
//

import Foundation
import FirebaseAuth

class User {
    var name: String?
    var email: String?
    var isSingle: Bool?
    
    init(name: String, email: String) {
        self.name = name
        self.email = email
        self.isSingle = true
    }
    
    static func getCurrentUser() -> User? {
        if let user = FIRAuth.auth()?.currentUser {
            let name = user.displayName
            let email = user.email
            return User(name: name!, email: email!)
        }
        return nil
    }
}
