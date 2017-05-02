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

    func fire(afterAcceptDo completion: @escaping (_ partner: User) -> Void) {
        // check if request already exist
        self.dbRef.child("\(firFiredRequestNode)/\(partner.id!)+\(requester.id!)").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                // change request state
                self.dbRef.child("\(firFiredRequestNode)/\(self.partner.id!)+\(self.requester.id!)/\(firFiredRequestStateField)").setValue(true)
                // set partner id of self
                self.requester.setPartner(self.partner.id)
                // TODO: not sure if I should do this???
                // self.partner.setPartner(self.requester.id)
                completion(self.partner)
            } else {
                let dict: [String: AnyObject] = [firFiredRequestStateField: false as! AnyObject]
                self.dbRef.child("\(firFiredRequestNode)/\(self.requester.id!)+\(self.partner.id!)").setValue(dict)
                // listen to request state change
                var handle: UInt = 0
                let requestRef = self.dbRef.child("\(firFiredRequestNode)/\(self.requester.id!)+\(self.partner.id!)")
                handle = requestRef.observe(.value, with: { (snapshot) in
                    if snapshot.exists() {
                        let value = snapshot.value as? NSDictionary
                        let state = value?[firFiredRequestStateField] as? Bool ?? false
                        if state == true {
                            self.requester.setPartner(self.partner.id)
                            print("request accepted!")
                            requestRef.removeObserver(withHandle: handle)
                            completion(self.partner)
                        }
                    }
                })
            }
        })
        // if not then add new request
    }
}
