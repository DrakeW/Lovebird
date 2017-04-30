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
    
    static func getUser(from email: String, andDo completion: @escaping (User) -> Void) {
        dbRef.child("\(firEmailNode)").queryOrdered(byChild: "email").queryEqual(toValue: email).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                let value = snapshot.value as? NSDictionary
                let uid: String = (value?.allKeys as! [String])[0]
                if uid != "" {
                    User.getUser(uid, andDo: { (user) in
                        completion(user)
                    })
                }
            }
        })
    }
    
    static func getUser(_ user_id: String, andDo completion: @escaping (User) -> Void) {
        dbRef.child("\(firUserNode)/\(user_id)").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                let value = snapshot.value as? NSDictionary
                let displayName = value?["displayName"] as? String ?? ""
                let status = value?["status"] as? String ?? ""
                let email = value?["email"] as? String ?? ""
                let partnerId = value?["partnerId"] as? String ?? ""
                let user: User = User(id: user_id, name: displayName)
                user.status = status
                user.email = email
                user.partnerId = partnerId
                completion(user)
            } else {
                print("WTF")
            }
        })
    }
    
    static func getCurrentUser(completion: @escaping (User) -> Void) {
        let currentUser  = FIRAuth.auth()?.currentUser
        let user_id = currentUser?.uid
        if let user_id = user_id {
            User.getUser(user_id, andDo: { (user) in
                completion(user)
            })
        }
    }
    
    func isSingle() -> Bool {
        if let partnerId = self.partnerId {
            if partnerId == "" {
                return true
            }
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
    
    func setPartner(_ partnerId: String) {
        User.dbRef.child("\(firUserNode)/\(self.id)/partnerId").setValue(partnerId)
    }
    
    func saveToDB() {
        let dict: [String: AnyObject] = ["displayName": name as! AnyObject,
                                         "partnerId": partnerId as! AnyObject,
                                         "status": status as! AnyObject]
        User.dbRef.child("\(firUserNode)/\(self.id!)").setValue(dict)
        
        let dict2: [String: AnyObject] = ["email": email as! AnyObject,
                                          "uid": self.id! as! AnyObject]
        User.dbRef.child("\(firEmailNode)/\(self.id!)").setValue(dict2)
    }
}
