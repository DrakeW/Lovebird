//
//  SignUpViewController.swift
//  lovebird
//
//  Created by Junyu Wang on 4/6/17.
//  Copyright © 2017 Junyu Wang. All rights reserved.
//

import UIKit
import TextFieldEffects
import FirebaseAuth

class SignUpViewController: UIViewController {

    @IBOutlet weak var displayNameTextField: HoshiTextField!
    @IBOutlet weak var emailTextField: HoshiTextField!
    @IBOutlet weak var passwordTextField: HoshiTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func signUpButtonWasPressed(_ sender: UIButton) {
        let email = emailTextField.text!
        let password = passwordTextField.text!
        let displayName = displayNameTextField.text!
        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user, error) in
            if let err = error {
                print(err)
            } else {
                let changeRequest = user!.profileChangeRequest()
                changeRequest.displayName = displayName
                changeRequest.commitChanges(completion: { (error) in
                    if let err = error {
                        print(err)
                    } else {
                        self.dismiss(animated: true, completion: nil)
                        print("User created")
                    }
                })
            }
        })
    }

    @IBAction func signInButtonWasPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}