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
    var email: String?
    var partnerId: String?
    var status: String?
    
    static let dbRef = FIRDatabase.database().reference()
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
    
    static func getCurrentUser(completion: @escaping (User) -> Void) {
        let currentUser  = FIRAuth.auth()?.currentUser
        let user_id = currentUser?.uid
        if let user_id = user_id {
            dbRef.child("\(firUserNode)/\(user_id)").observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists() {
                    let value = snapshot.value as? NSDictionary
                    let displayName = value?["displayName"] as? String ?? ""
                    let status = value?["status"] as? String ?? ""
                    let email = value?["email"] as? String ?? ""
                    let partnerId = value?["partnerId"] as? String ?? ""
                    let curUser: User = User(id: user_id, name: displayName)
                    curUser.status = status
                    curUser.email = email
                    curUser.partnerId = partnerId
                    completion(curUser)
                } else {
                    print("WTF")
                }
            })
        }
    }
    
    func isSingle() -> Bool {
        if self.partnerId != "" {
            return false
        }
        return true
    }
    
    func getPartner(completion: @escaping (User) -> Void) {
        let partnerId = self.partnerId
        User.dbRef.child("\(firUserNode)/\(partnerId!)").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                let value = snapshot.value as? NSDictionary
                let displayName = value?["displayName"] as? String ?? ""
                let status = value?["status"] as? String ?? ""
                let partner = User(id: partnerId!, name: displayName)
                partner.status = status
                completion(partner)
            }
        })
    }
    
    func saveToDB() {
        let dict: [String: AnyObject] = ["displayName": name as! AnyObject,
                                         "partnerId": partnerId as! AnyObject,
                                         "status": status as! AnyObject]
        User.dbRef.child("\(firUserNode)/\(self.id!)").setValue(dict)
    }
}
