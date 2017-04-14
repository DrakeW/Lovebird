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
    
    init(from user: User, To partner: User) {
        self.requester = user
        self.partner = user
    }
    
    func fire(completion: @escaping (Void) -> Void) {
        
    }
    
}
