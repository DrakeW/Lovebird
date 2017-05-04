//
//  FindPartnerViewController.swift
//  lovebird
//
//  Created by Junyu Wang on 4/13/17.
//  Copyright © 2017 Junyu Wang. All rights reserved.
//

import UIKit
import TextFieldEffects
import SCLAlertView

class FindPartnerViewController: UIViewController {

    @IBOutlet weak var partnerEmailTextField: KaedeTextField!
    
    var currentUser: User?
    var parentVC: ProfileViewController?
    
    override func viewDidLoad() {
        self.hideKeyboardWhenTappedAround()
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func sendButtonWasPressed(_ sender: UIButton) {
        if let partnerEmail = partnerEmailTextField.text {
            if partnerEmail == self.currentUser?.email || partnerEmail == "" {
                SCLAlertView().showError("Oops...", subTitle: "Please enter a valid email and try again.")
                return
            }
            User.getUser(from: partnerEmail, andDo: { (partner) in
                if let curUser = self.currentUser {
                    let req: Request = Request(from: curUser, to: partner!)
                    req.fire(afterAcceptDo: { (partner) in
                        // hide find partner view && reload table view
                        self.view.backgroundColor = UIColor.white.withAlphaComponent(0)
                        
                        self.parentVC?.profileTableView.reloadData()
                        self.parentVC?.partnerMapView.alpha = 1
                        self.parentVC?.profileTableView.alpha = 1
                        self.parentVC?.matchStatusImageView.alpha = 0
                        self.parentVC?.partner = partner
                        // start listening for partner's location data
                        self.currentUser?.startListeningToLocation(of: partner.id!, completion: { (location) in
                            self.parentVC?.centerMapOnLocation(location)
                        })
                    })
                    SCLAlertView().showSuccess("Success!", subTitle: "Request was sent.")
                    self.partnerEmailTextField.text = ""
                }
            })
        }
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
