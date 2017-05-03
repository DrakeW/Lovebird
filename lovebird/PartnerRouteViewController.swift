//
//  PartnerRouteViewController.swift
//  lovebird
//
//  Created by Junyu Wang on 5/1/17.
//  Copyright © 2017 Junyu Wang. All rights reserved.
//

import UIKit
import MapKit

class PartnerRouteViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var partnerRouteMapView: MKMapView!
    @IBOutlet weak var backButton: UIButton!
    
    var currentUser: User?
    var partner: User?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.partnerRouteMapView.delegate = self
        drawRouteOnMap()
    }
    
    func drawRouteOnMap() {
        if let locationList = self.currentUser?.partnerLocations {
            // add annotation to most recent location
            self.addAnnotationToMap(locationList[locationList.count - 1])
            // draw route
            let coords: [CLLocationCoordinate2D] = locationList.map({ (location) -> CLLocationCoordinate2D in
                return location.coordinate
            })
            let route: MKPolyline = MKPolyline(coordinates: coords, count: coords.count)
            self.partnerRouteMapView.add(route)
            self.partnerRouteMapView.setVisibleMapRect(route.boundingMapRect,
                                                       edgePadding: UIEdgeInsetsMake(20.0, 20.0, 20.0, 20.0),
                                                       animated: true)
        }
    }
    
    func addAnnotationToMap(_ location: CLLocation) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        annotation.title = "Last Seen"
        annotation.subtitle = self.partner?.name ?? "Loading..."
        self.partnerRouteMapView.addAnnotation(annotation)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer! {
        if overlay is MKPolyline {
            let polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor.flatWatermelon
            polylineRenderer.lineWidth = 5
            return polylineRenderer
        }
        return nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func backButtonWasPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
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
