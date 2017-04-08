//
//  ProfileViewController.swift
//  lovebird
//
//  Created by Junyu Wang on 4/7/17.
//  Copyright © 2017 Junyu Wang. All rights reserved.
//

import UIKit
import FirebaseDatabase

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var profileTableView: UITableView!
    @IBOutlet weak var matchStatusImageView: UIImageView!
    var currentUser: User?
    
    let dbRef = FIRDatabase.database().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        profileTableView.delegate = self
        profileTableView.dataSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let user = currentUser {
            if user.isSingle() {
                return 1
            } else {
                return 2
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // TODO: view partner's info
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = profileTableView.dequeueReusableCell(withIdentifier: "UserProfileCell") as! UserTableViewCell
        if indexPath.row == 0 {
            if let currentUser = currentUser {
                cell.setUpCell(currentUser)
            }
        } else {
            if let currentUser = currentUser {
                let partnerId = currentUser.partnerId
                dbRef.child("users/\(partnerId!)").observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists() {
                        let value = snapshot.value as? NSDictionary
                        let displayName = value?["displayName"] as? String ?? ""
                        let status = value?["status"] as? String ?? ""
                        cell.userDisplayNameLabel.text = displayName
                        cell.userStatusLabel.text = status
                    }
                })
            }
        }
        return cell
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
