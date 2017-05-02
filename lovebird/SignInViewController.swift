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
        self.hideKeyboardWhenTappedAround()
        if let _ = FIRAuth.auth()?.currentUser {
            User.getCurrentUser(completion: { (curUser) in
                self.curUser = curUser
                self.performSegue(withIdentifier: "signInToProfileViewSegue", sender: self)
            })
        } else {
            // Do any additional setup after loading the view, typically from a nib.
            facebookLoginButton.delegate = self
            facebookLoginButton.readPermissions = ["email"]
        }
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
                if FBSDKAccessToken.current() != nil {
                    FBSDKGraphRequest.init(graphPath: "me", parameters: ["fields": "email,name"]).start(completionHandler: { (conn, result, error) in
                        if let error = error {
                            print(error)
                            return
                        }
                        let res = result as? NSDictionary
                        let name = res?["name"] as! String 
                        let email = res?["email"] as! String
                        let fbUser: User = User(id: (FIRAuth.auth()?.currentUser?.uid)!, name: name)
                        fbUser.email = email
                        fbUser.saveToDB()
                        self.curUser = fbUser
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
                User.getCurrentUser(completion: { (curUser) in
                    self.curUser = curUser
                    self.performSegue(withIdentifier: "signInToProfileViewSegue", sender: self)
                })
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

