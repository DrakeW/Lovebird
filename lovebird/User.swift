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
import MapKit

class User {
    
    var id: String!
    var name: String!
    var email: String?
    var partnerId: String?
    var status: String?
    
    var locationBuffer: [CLLocation] = []
    static let LOC_BUFFER_LIMIT = 30 // TODO: update every 10s. Need to tweak the numbers
    
    var partnerLocations: [CLLocation] = []
    
    static let dbRef = FIRDatabase.database().reference()
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
    
    // MARK: - general User related logic
    
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
    
    // MARK: - partner related logic
    
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
        self.partnerId = partnerId
        User.dbRef.child("\(firUserNode)/\(self.id!)/partnerId").setValue(partnerId)
    }
    
    // MARK: - location related logic
    
    func saveLocation(_ location: CLLocation) {
        locationBuffer.append(location)
        if locationBuffer.count == User.LOC_BUFFER_LIMIT {
            uploadLocationDataToServer()
            locationBuffer.removeAll()
        }
    }
    
    func uploadLocationDataToServer() {
        let userLocationRef = User.dbRef.child("\(firLocationNode)/\(self.id!)")
        let lastLocation: CLLocation = locationBuffer[locationBuffer.count - 1]
        let locDict: [NSString: AnyObject] = ["lat": lastLocation.coordinate.latitude as! AnyObject,
                                              "lon": lastLocation.coordinate.longitude as! AnyObject]
        userLocationRef.childByAutoId().setValue(locDict)
    }
    
    func startListeningToLocation(of partnerId: String, completion: @escaping (CLLocation) -> Void) {
        User.dbRef.child("\(firLocationNode)/\(partnerId)").observe(.childAdded, with: { (snapshot) in
            if snapshot.exists() {
                let value = snapshot.value as? NSDictionary
                let lat = value?["lat"] as? CLLocationDegrees ?? 0
                let lon = value?["lon"] as? CLLocationDegrees ?? 0
                let location: CLLocation = CLLocation(latitude: lat, longitude: lon)
                // save partner location
                self.partnerLocations.append(location)
                completion(location)
            }
        })
    }
    
    func breakUp(with partner: User?, completion: @escaping (Error!) -> Void) {
        if let partner = partner {
            let deletionUpdates = ["\(self.id!)/partnerId": NSNull(),
                                   "\(partner.id!)/partnerId": NSNull()]
            // 1. delete partner id from both user
            User.dbRef.child("\(firUserNode)").updateChildValues(deletionUpdates, withCompletionBlock: { (error, dbRef) in
                if let error = error {
                    completion(error)
                } else {
                    // 2. remove fired request of them
                    User.dbRef.child("\(firFiredRequestNode)/\(self.id!)+\(partner.id!)").removeValue()
                    User.dbRef.child("\(firFiredRequestNode)/\(partner.id!)+\(self.id!)").removeValue()
                    // 3. stop listening to each other's location update
                    User.dbRef.child("\(firLocationNode)/\(self.id)").removeAllObservers()
                    User.dbRef.child("\(firLocationNode)/\(partner.id)").removeAllObservers()
                    completion(nil)
                }
            })
        } else {
            completion(nil)
        }
    }
    
    // MARK: - save user info to DB
    
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
