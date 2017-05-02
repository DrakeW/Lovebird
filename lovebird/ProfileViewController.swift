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

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var profileTableView: UITableView!
    @IBOutlet weak var matchStatusImageView: UIImageView!
    @IBOutlet weak var findPartnerView: UIView!
    @IBOutlet weak var partnerMapView: MKMapView!
    
    var currentUser: User?
    var partner: User?
    
    let dbRef = FIRDatabase.database().reference()
    let locManager = CLLocationManager()
    
    var partnerCurLocation: CLLocation?
    var mapIsExpanded: Bool = false
    var originalMapFrame: CGRect?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        profileTableView.delegate = self
        profileTableView.dataSource = self
        if let curUser = currentUser {
            // choose view to show
            if curUser.isSingle() {
                self.showSingleUserPage()
            } else {
                self.showCouplePage()
                // listening to partner's location
                curUser.startListeningToLocation(of: curUser.partnerId!, completion: { (location) in
                    self.centerMapOnLocation(location)
                })
            }
        }
        // set up locatoin manager
        locManager.delegate = self
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        locManager.startUpdatingLocation()
        // set up mapview delegate
        self.partnerMapView.delegate = self
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
        if let _ = self.partner {
            self.performSegue(withIdentifier: "ProfileToPartnerRouteViewSegue", sender: view)
        } else {
            self.currentUser?.getPartner(completion: { (partner) in
                self.partner = partner
                self.performSegue(withIdentifier: "ProfileToPartnerRouteViewSegue", sender: view)
            })
        }
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
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = profileTableView.dequeueReusableCell(withIdentifier: "UserProfileCell", for: indexPath) as! UserTableViewCell
        if indexPath.row == 0 {
            if let currentUser = currentUser {
                cell.setUpCell(currentUser)
                cell.functionButton.titleLabel?.text = "Update"
                cell.functionButton.addTarget(self,
                                              action: #selector(self.updateButtonClicked(_:)),
                                              for: .touchUpInside)
            }
        } else {
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
        // TODO: add update status function
    }
    
    func breakUpButtonClicked(_ sender: AnyObject) {
        print("break up button clicked")
        self.currentUser?.breakUp(with: self.partner, completion: { (error) in
            if error == nil {
                self.showSingleUserPage()
            } else {
                print(error)
            }
        })
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
