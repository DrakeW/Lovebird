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

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {

    @IBOutlet weak var profileTableView: UITableView!
    @IBOutlet weak var matchStatusImageView: UIImageView!
    @IBOutlet weak var findPartnerView: UIView!
    @IBOutlet weak var partnerMapView: MKMapView!
    
    var currentUser: User?
    
    let dbRef = FIRDatabase.database().reference()
    let locManager = CLLocationManager()
    
    var partnerCurLocation: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        profileTableView.delegate = self
        profileTableView.dataSource = self
        // choose view to show
        if let curUser = currentUser {
            if curUser.isSingle() {
                self.findPartnerView.alpha = 1
                self.profileTableView.alpha = 0
                
                self.matchStatusImageView.alpha = 1
                self.partnerMapView.alpha = 0
            } else {
                self.findPartnerView.alpha = 0
                self.profileTableView.alpha = 1
                
                self.matchStatusImageView.alpha = 0
                self.partnerMapView.alpha = 1
            }
        }
        // set up locatoin manager
        locManager.delegate = self
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        locManager.startUpdatingLocation()
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
        // TODO: upload location data to firebase
        self.currentUser?.saveLocation(lastLocation)
        centerMapOnLocation(lastLocation)
    }
    
    
    let regionRadius: CLLocationDistance = 1000
    
    func centerMapOnLocation(_ location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius * 2.0,
                                                                  regionRadius * 2.0)
        // TODO: currently only showing self location && need to show partner location
        partnerMapView.setRegion(coordinateRegion, animated: true)
        addAnnotationToMap(location)
    }
    
    func addAnnotationToMap(_ location: CLLocation) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        annotation.title = self.currentUser?.name
        partnerMapView.addAnnotation(annotation)
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
                currentUser.getPartner(completion: { (partner) in
                    cell.setUpCell(partner)
                })
            }
        }
        return cell
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
            }
        }
    }

}
