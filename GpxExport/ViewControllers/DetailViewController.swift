//
//  DetailViewController.swift
//  GpxExport
//
//  Created by Mario Martelli on 01.12.17.
//  Copyright © 2017 Mario Martelli. All rights reserved.
//

import UIKit
import HealthKit
import MapKit

class WorkoutDetailViewController: UIViewController, MKMapViewDelegate {

  var hkWorkout: HKWorkout!
  var workout: Workout?


  lazy private var workoutStore: WorkoutDataStore = {
    return WorkoutDataStore()
  }()


  @IBOutlet weak var displayName: UILabel!

  @IBOutlet weak var displayDuration: UILabel!
  @IBOutlet weak var displayDistance: UILabel!
  @IBOutlet weak var mapView: MKMapView!

  var overlay = MKPolyline()

  @IBAction func sharingAsGPX(_ sender: Any) {
    if let targetURL = workout?.writeFile() {
      let activityViewController = UIActivityViewController(
        activityItems: [targetURL],
        applicationActivities: nil)
      if let popoverPresentationController = activityViewController.popoverPresentationController {
        popoverPresentationController.barButtonItem = nil
      }
      self.present(activityViewController, animated: true, completion: nil)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    mapView.delegate = self
    // Do any additional setup after loading the view, typically from a nib.
  }

  override func viewWillAppear(_ animated: Bool) {

    workoutStore.heartRate(for: hkWorkout){
      (rates, error) in

      guard let heartRateSamples = rates, error == nil else {
        print(error as Any)
        return
      }

      self.workoutStore.route(for: self.hkWorkout){
        (maybe_locations, error) in
        guard let locations = maybe_locations, error == nil else {
          print(error as Any)
          return
        }

        self.workout = Workout(workout: self.hkWorkout, route: locations, heartRate: heartRateSamples)
        DispatchQueue.main.async {
          self.displayName.text = "\(self.workout!.name)"
          self.displayDistance.text = String(format: "%.2f km", (self.hkWorkout.totalDistance?.doubleValue(for: HKUnit.meter()))! / 1000)
          self.displayDuration.text = String(format: "%.2f min", self.hkWorkout.duration / 60)
          if let wk = self.workout {
            self.mapView.add(wk.poly)
            var region = MKCoordinateRegionForMapRect(wk.poly.boundingMapRect)
            region.span.latitudeDelta *= 1.2   // Increase span by 20% to add some margin
            region.span.longitudeDelta *= 1.2
            self.mapView.setRegion(region, animated: false)
          }
        }
      }
    }
  }


  // MARK: Map View Methods
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    let pr = MKPolylineRenderer(overlay: overlay)
    if overlay is MKPolyline {
      pr.strokeColor = UIColor.blue.withAlphaComponent(0.5);
      pr.lineWidth = 3
    }
    return pr;
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

}
