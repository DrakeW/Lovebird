//
//  User.swift
//  lovebird
//
//  Created by Junyu Wang on 4/6/17.
//  Copyright © 2017 Junyu Wang. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth

class User {
    
    var id: String!
    var name: String!
    var email: String!
    var partnerId: String?
    var status: String?
    
    let dbRef = FIRDatabase.database().reference()
    
    init(_ id: String, _ name: String, _ email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
    
    static func getCurrentUser() -> User {
        let currentUser  = FIRAuth.auth()?.currentUser
        let name = currentUser?.displayName
        let id = currentUser?.uid
        let email = currentUser?.email
        return User.init(id!, name!, email!)
    }
    
    func isSingle() -> Bool {
        if partnerId != nil {
            return false
        }
        return true
    }
    
    func saveToDB() {
        let dict: [String: AnyObject] = ["displayName": name as! AnyObject,
                                         "email": email as! AnyObject,
                                         "partnerId": partnerId as! AnyObject,
                                         "status": status as! AnyObject]
        dbRef.child("Users/\(self.id!)").setValue(dict)
    }
}
