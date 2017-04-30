//
//  Request.swift
//  lovebird
//
//  Created by Junyu Wang on 4/13/17.
//  Copyright © 2017 Junyu Wang. All rights reserved.
//

import Foundation
import FirebaseDatabase

class Request {
    
    var requester: User
    var partner: User
    
    let dbRef = FIRDatabase.database().reference()
    
    init(from user: User, to partner: User) {
        self.requester = user
        self.partner = partner
    }
    
    func fire(completion: @escaping (Void) -> Void) {
        // check if request already exist
        dbRef.child("\(firFiredRequestNode)/\(partner.id!)+\(requester.id!)").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                // set partner for both users
                self.requester.setPartner(self.partner.id)
                self.partner.setPartner(self.requester.id)
            } else {
                let dict: [String: AnyObject] = ["state": false as! AnyObject]
                self.dbRef.child("\(firFiredRequestNode)/\(self.requester.id!)+\(self.partner.id!)").setValue(dict)
            }
        })
        // if not then add new request
    }
}
