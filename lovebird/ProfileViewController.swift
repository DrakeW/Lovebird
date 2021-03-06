//
//  ProfileViewController.swift
//  lovebird
//
//  Created by Junyu Wang on 4/7/17.
//  Copyright © 2017 Junyu Wang. All rights reserved.
//

import UIKit
import FirebaseDatabase
import CoreLocation
import MapKit
import FirebaseAuth
import FBSDKLoginKit
import Whisper
import ChameleonFramework
import SCLAlertView

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var profileTableView: UITableView!
    @IBOutlet weak var matchStatusImageView: UIImageView!
    @IBOutlet weak var findPartnerView: UIView!
    @IBOutlet weak var partnerMapView: MKMapView!
    
    let fbLoginManager = FBSDKLoginManager()
    
    var currentUser: User?
    var partner: User?
    
    let dbRef = FIRDatabase.database().reference()
    let locManager = CLLocationManager()
    
    var partnerCurLocation: CLLocation?
    var mapIsExpanded: Bool = false
    var originalMapFrame: CGRect?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        // Do any additional setup after loading the view.
        FIRAuth.auth()?.addStateDidChangeListener({ (auth, user) in
            if let _ = user {
                // choose view to show
                if let curUser = self.currentUser {
                    self.profileTableView.delegate = self
                    self.profileTableView.dataSource = self
                    if curUser.isSingle() {
                        self.showSingleUserPage()
                    } else {
                        self.showCouplePage()
                        // listening to partner's location
                        curUser.startListeningToLocation(of: curUser.partnerId!, completion: { (location) in
                            self.centerMapOnLocation(location)
                        })
                        curUser.startListeningToPartnerCheckingEvent(with: { (checkNum) in
                            self.showBeingCheckedAlert(with: checkNum)
                        })
                        curUser.startListeningToBreakUp {
                            self.showSingleUserPage()
                        }
                    }
                    self.initLocationManager()
                    self.partnerMapView.delegate = self
                }
            } else {
                // present login page
                self.performSegue(withIdentifier: "ProfileToSignInViewSegue", sender: self)
            }
        })
    }
    
    func initLocationManager() {
        locManager.delegate = self
        locManager.distanceFilter = CLLocationDistance(User.LOC_UPDATE_MIN_DIST) // only if user has moved 30 meters
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        locManager.allowDeferredLocationUpdates(untilTraveled: CLLocationDistance(), timeout: TimeInterval(User.LOC_UPDATE_MIN_FREQ))
        locManager.allowsBackgroundLocationUpdates = true
        locManager.startUpdatingLocation()
    }
    
    func showSingleUserPage() {
        self.findPartnerView.alpha = 1
        
        self.profileTableView.alpha = 0
        self.matchStatusImageView.alpha = 1
        self.partnerMapView.alpha = 0
    }
    
    func showCouplePage() {
        // hide find partner view without setting the alpha of its subviews
        self.findPartnerView.backgroundColor = UIColor.white.withAlphaComponent(0)
        
        self.profileTableView.alpha = 1
        self.matchStatusImageView.alpha = 0
        self.partnerMapView.alpha = 1
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        enableLocationService()
    }
    
    // MARK: - Location related service
    
    func enableLocationService()  {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            break
        case .notDetermined:
            locManager.requestAlwaysAuthorization()
        case .authorizedWhenInUse, .restricted, .denied:
            showLocationServiceAlert()
            break
        }
    }
    
    func showLocationServiceAlert() {
        let alertController = UIAlertController(title: "Background Location Access Denied",
                                                message: "In order to collect location data, please open Settings and set location access for this app to 'Always'.",
                                                preferredStyle: .alert)
        let openSettingAction = UIAlertAction(title: "Open Settings",
                                       style: .default) { (action) in
                                        if let url = NSURL(string: UIApplicationOpenSettingsURLString) {
                                            UIApplication.shared.open(url as URL,
                                                                      options: [:],
                                                                      completionHandler: nil)
                                        }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(openSettingAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLocation = locations[locations.count - 1]
        self.currentUser?.saveLocation(lastLocation)
    }
    
    let regionRadius: CLLocationDistance = 1000
    
    func centerMapOnLocation(_ location: CLLocation) {
        partnerMapView.removeAnnotations(partnerMapView.annotations)
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius * 2.0,
                                                                  regionRadius * 2.0)
        partnerMapView.setRegion(coordinateRegion, animated: true)
        addAnnotationToMap(location)
    }
    
    func addAnnotationToMap(_ location: CLLocation) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        annotation.title = "Last Seen"
        annotation.subtitle = self.partner?.name ?? "Loading..."
        partnerMapView.addAnnotation(annotation)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let reuseId = "partnerLocPin"
        var annotationView = self.partnerMapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if let annotationView = annotationView {
            annotationView.annotation = annotation
        } else {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            annotationView?.canShowCallout = true
            annotationView?.animatesDrop = true
            annotationView?.pinTintColor = .purple
            annotationView?.rightCalloutAccessoryView = UIButton.init(type: .detailDisclosure)
        }
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        self.currentUser?.checkPartnerRoute(self.partner, completion: { (checkNum) in
            // TODO: add dailly limit functionality
            if let _ = self.partner {
                self.performSegue(withIdentifier: "ProfileToPartnerRouteViewSegue", sender: view)
            } else {
                self.currentUser?.getPartner(completion: { (partner) in
                    self.partner = partner
                    self.performSegue(withIdentifier: "ProfileToPartnerRouteViewSegue", sender: view)
                })
            }
        })
    }
    
    func showBeingCheckedAlert(with checkNum: Int) {
        showAnouncement(title: "Shh...", subtitle: "You are being checked", image: nil)
    }
    
    func showAnouncement(title: String, subtitle: String, image: UIImage?) {
        let anouncement = Announcement(title: title, subtitle: subtitle, duration: 2) {
            print("user was checked")
        }
        Whisper.show(shout: anouncement, to: self)
    }
    
    // MARK: - user information
    
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = profileTableView.dequeueReusableCell(withIdentifier: "UserProfileCell", for: indexPath) as! UserTableViewCell
        cell.selectionStyle = .none
        if indexPath.row == 0 {
            if let currentUser = currentUser {
                cell.profileImageView.image = #imageLiteral(resourceName: "bird2")
                cell.profileImageView.backgroundColor = UIColor.randomFlat.lighten(byPercentage: 0.5)
                cell.setUpCell(currentUser)
                cell.functionButton.titleLabel?.text = "Update"
                cell.functionButton.addTarget(self,
                                              action: #selector(self.updateButtonClicked(_:)),
                                              for: .touchUpInside)
            }
        } else {
            cell.profileImageView.image = #imageLiteral(resourceName: "bird1")
            cell.profileImageView.backgroundColor = UIColor.randomFlat.lighten(byPercentage: 0.5)
            cell.userStatusTextField.isUserInteractionEnabled = false
            if let currentUser = currentUser {
                currentUser.getPartner(completion: { (partner) in
                    self.partner = partner
                    cell.setUpCell(partner)
                    cell.functionButton.titleLabel?.text = "Bye"
                    cell.functionButton.addTarget(self,
                                                  action: #selector(self.breakUpButtonClicked(_:)),
                                                  for: .touchUpInside)
                })
            }
        }
        return cell
    }
    
    func updateButtonClicked(_ sender: AnyObject) {
        print("update button clicked")
        let curUserCell: UserTableViewCell = self.profileTableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! UserTableViewCell
        if let status = curUserCell.userStatusTextField.text {
            self.currentUser?.updateStatus(status, completion: { (error) in
                if let error = error {
                    // TODO: show update failure message
                    SCLAlertView().showError("Error", subTitle: error.localizedDescription)
                } else {
                    SCLAlertView().showSuccess("Success", subTitle: "Status updated!")
                }
            })
        }
    }
    
    func breakUpButtonClicked(_ sender: AnyObject) {
        print("break up button clicked")
        let alertViewAppearance = SCLAlertView.SCLAppearance(
            showCloseButton: false
        )
        let alertView = SCLAlertView(appearance: alertViewAppearance)
        alertView.addButton("Yes") { 
            self.currentUser?.breakUp(with: self.partner, completion: { (error) in
                if error == nil {
                    self.showSingleUserPage()
                } else {
                    print(error)
                }
            })
        }
        alertView.addButton("No") { 
            print("Thank God")
        }
        alertView.showWarning("Sorry...", subTitle: "Are you sure to break up with \(self.partner?.name ?? "your partner?")")
        
    }
    
    // MARK: - sign out
    
    @IBAction func signOutButtonWasPressed(_ sender: UIButton) {
        print("User signs out")
        if let firAuth = FIRAuth.auth() {
            do {
                if FBSDKAccessToken.current() != nil {
                    fbLoginManager.logOut()
                }
                try firAuth.signOut()
            } catch let sigNoutError as NSError {
                print("Error signing out: %@", sigNoutError)
            }
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let identifier = segue.identifier {
            if identifier == "ProfileViewToFindPartnerViewSegue" {
                if let dest = segue.destination as? FindPartnerViewController {
                    if let curUser = self.currentUser {
                        dest.currentUser = curUser
                        dest.parentVC = self
                    }
                }
            } else if identifier == "ProfileToPartnerRouteViewSegue" {
                if let dest = segue.destination as? PartnerRouteViewController {
                    if let curUser = self.currentUser {
                        dest.currentUser = curUser
                        dest.partner = self.partner
                    }
                }
            }
        }
    }

}
