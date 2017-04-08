//
//  ViewController.swift
//  lovebird
//
//  Created by Junyu Wang on 4/6/17.
//  Copyright © 2017 Junyu Wang. All rights reserved.
//

import UIKit
import TextFieldEffects
import FirebaseAuth
import FBSDKLoginKit

class SignInViewController: UIViewController, FBSDKLoginButtonDelegate {

    @IBOutlet weak var emailTextField: HoshiTextField!
    @IBOutlet weak var passwordTextField: HoshiTextField!
    @IBOutlet weak var facebookLoginButton: FBSDKLoginButton!
    
    var curUser: User?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        facebookLoginButton.delegate = self
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if let err = error {
            print(err.localizedDescription)
        } else if result.isCancelled {
            print("Facebook user cancelled login")
        } else {
            let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
            FIRAuth.auth()?.signIn(with: credential) { (user, error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                print("Facebook user signed in")
                // TODO: facebook user save name & segue to profile view
                if FBSDKAccessToken.current() != nil {
                    FBSDKGraphRequest.init(graphPath: "me", parameters: nil).start(completionHandler: { (conn, result, error) in
                        if let error = error {
                            print(error)
                            return
                        }
                        let res = result as? NSDictionary
                        self.curUser = User.getCurrentUser()
                        self.curUser?.name = res?["name"] as! String
                        self.curUser?.saveToDB()
                        self.performSegue(withIdentifier: "signInToProfileViewSegue", sender: self)
                    })
                }
            }
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("Facebook user Logged Out")
        let firebaseAuth = FIRAuth.auth()
        do {
            try firebaseAuth?.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func signInButtonWasPressed(_ sender: UIButton) {
        let email = emailTextField.text!
        let password = passwordTextField.text!
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
            if let err = error {
                print(err)
            } else {
                print("User signed in")
                // TODO: normal user segue to profile view
                self.curUser = User.getCurrentUser()
                if self.curUser != nil {
                    self.performSegue(withIdentifier: "signInToProfileViewSegue", sender: self)
                }
            }
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            if identifier == "signInToProfileViewSegue" {
                if let dest = segue.destination as? ProfileViewController {
                    if let curUser = self.curUser {
                        dest.currentUser = curUser
                    }
                }
            }
        }
    }
}

