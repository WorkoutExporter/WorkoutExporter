//
//  DetailViewController.swift
//  GpxExport
//
//  Created by Mario Martelli on 01.12.17.
//  Copyright © 2017 Mario Martelli. All rights reserved.
//

import UIKit
import HealthKit

class WorkoutDetailViewController: UIViewController {

  var hkWorkout: HKWorkout!
  var workout: Workout?


  lazy private var workoutStore: WorkoutDataStore = {
    return WorkoutDataStore()
  }()


  @IBOutlet weak var displayTitle: UILabel!

  @IBOutlet weak var displayName: UILabel!
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
  }

  override func viewWillAppear(_ animated: Bool) {


    displayTitle.text = hkWorkout.debugDescription

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
          self.displayName.text = "\(self.workout!.name) - \(heartRateSamples.count)"
        }



        //        if let targetURL = workout.writeFile() {
        //          let activityViewController = UIActivityViewController(
        //            activityItems: [targetURL],
        //            applicationActivities: nil)
        //          if let popoverPresentationController = activityViewController.popoverPresentationController {
        //            popoverPresentationController.barButtonItem = nil
        //          }
        //          self.present(activityViewController, animated: true, completion: nil)
        //        }
      }
    }

  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

}
