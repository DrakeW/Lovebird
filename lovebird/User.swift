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
    var checkNum: Int = 0
    
    static let LOC_UPDATE_MIN_FREQ = 30
    static let LOC_UPDATE_MIN_DIST = 100
    
    var partnerLocations: [CLLocation] = []
    
    static let dbRef = FIRDatabase.database().reference()
    
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
    
    // MARK: - general User related logic
    
    static func getUser(from email: String, andDo completion: @escaping (User?) -> Void) {
        dbRef.child("\(firUserNode)").queryOrdered(byChild: firUserEmailField).queryEqual(toValue: email).observeSingleEvent(of: .value, with: { (snapshot) in
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
    
    static func getUser(_ user_id: String, andDo completion: @escaping (User?) -> Void) {
        dbRef.child("\(firUserNode)/\(user_id)").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                let value = snapshot.value as? NSDictionary
                let displayName = value?[firUserDisplayNameField] as? String ?? ""
                let status = value?[firUserStatusField] as? String ?? ""
                let email = value?[firUserEmailField] as? String ?? ""
                let partnerId = value?[firUserPartnerIdField] as? String ?? ""
                let user: User = User(id: user_id, name: displayName)
                user.status = status
                user.partnerId = partnerId
                user.email = email
                completion(user)
            } else {
                completion(nil)
            }
        })
    }
    
    static func getCurrentUser(completion: @escaping (User?) -> Void) {
        let currentUser  = FIRAuth.auth()?.currentUser
        let user_id = currentUser?.uid
        if let user_id = user_id {
            User.getUser(user_id, andDo: { (user) in
                if let user = user {
                    completion(user)
                } else {
                    completion(nil)
                }
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
                let displayName = value?[firUserDisplayNameField] as? String ?? ""
                let status = value?[firUserStatusField] as? String ?? ""
                let partner = User(id: partnerId!, name: displayName)
                partner.status = status
                completion(partner)
            }
        })
    }
    
    func setPartner(_ partnerId: String) {
        self.partnerId = partnerId
        User.dbRef.child("\(firUserNode)/\(self.id!)/\(firUserPartnerIdField)").setValue(partnerId)
    }
    
    func checkPartnerRoute(_ partner: User?, completion: @escaping (Int) -> Void) {
        if let partner = partner {
            User.dbRef.child("\(firUserNode)/\(partner.id!)").observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists() {
                    let value = snapshot.value as? NSDictionary
                    var check_in_num = value?[firUserCheckNumField] as? Int ?? 0
                    check_in_num += 1
                    User.dbRef.child("\(firUserNode)/\(partner.id!)/\(firUserCheckNumField)").setValue(check_in_num)
                    completion(check_in_num)
                }
            })
        }
    }
    
    func startListeningToPartnerCheckingEvent(with completion: @escaping (Int) -> Void) {
        User.dbRef.child("\(firUserNode)/\(self.id!)/\(firUserCheckNumField)").observe(.value, with: { (snapshot) in
            if snapshot.exists() {
                let value = snapshot.value as? Int
                if let checkNum = value {
                    if checkNum > self.checkNum {
                        self.checkNum = checkNum
                        completion(self.checkNum)
                    }
                }
            }
        })
    }
    
    // MARK: - location related logic
    
    func saveLocation(_ location: CLLocation) {
        let userLocationRef = User.dbRef.child("\(firLocationNode)/\(self.id!)")
        let locDict: [String: AnyObject] = [firLocationLatField: location.coordinate.latitude as! AnyObject,
                                            firLocationLonField: location.coordinate.longitude as! AnyObject]
        userLocationRef.childByAutoId().setValue(locDict)
    }
    
    func startListeningToLocation(of partnerId: String, completion: @escaping (CLLocation) -> Void) {
        User.dbRef.child("\(firLocationNode)/\(partnerId)").observe(.childAdded, with: { (snapshot) in
            if snapshot.exists() {
                let value = snapshot.value as? NSDictionary
                let lat = value?[firLocationLatField] as? CLLocationDegrees ?? 0
                let lon = value?[firLocationLonField] as? CLLocationDegrees ?? 0
                let location: CLLocation = CLLocation(latitude: lat, longitude: lon)
                // save partner location
                self.partnerLocations.append(location)
                completion(location)
            }
        })
    }
    
    func breakUp(with partner: User?, completion: @escaping (Error!) -> Void) {
        if let partner = partner {
            let deletionUpdates = ["\(self.id!)/\(firUserPartnerIdField)": NSNull(),
                                   "\(partner.id!)/\(firUserPartnerIdField)": NSNull()]
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
    
    func startListeningToBreakUp(completion: @escaping (Void) -> (Void)) {
        User.dbRef.child("\(firUserNode)/\(self.id!)/\(firUserPartnerIdField)").observe(.value, with: { (snapshot) in
            if !snapshot.exists() {
                completion()
            }
        })
    }
    
    // MARK: - status related logic
    
    func updateStatus(_ status: String, completion: @escaping (Error!) -> Void) {
        User.dbRef.child("\(firUserNode)/\(self.id!)/\(firUserStatusField)").setValue(status) { (error, dbRef) in
            if let _ = error {
                completion(error)
            } else {
                completion(nil)
            }
        }
    }
    
    // MARK: - save user info to DB
    
    func saveToDB() {
        let dict: [String: AnyObject] = [firUserDisplayNameField: name as! AnyObject,
                                         firUserPartnerIdField: partnerId as! AnyObject,
                                         firUserStatusField: status as! AnyObject,
                                         firUserEmailField: email as! AnyObject]
        User.dbRef.child("\(firUserNode)/\(self.id!)").setValue(dict)
    }
}
