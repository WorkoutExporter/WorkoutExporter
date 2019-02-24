//
//  Workout.swift
//  GpxExport
//
//  Created by Mario Martelli on 30.11.17.
//  Copyright © 2017 Mario Martelli. All rights reserved.
//

import Foundation
import HealthKit
import MapKit

struct Workout {
    private var hkWorkout: HKWorkout
    var route: [CLLocation]
    var heartRate: [HKQuantitySample]
    var startDate: Date

    var activityType: String {
        return hkWorkout.formattedWorkoutType
    }

    var name: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .medium

        return "\(activityType) - \(formatter.string(from: startDate))"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .medium

        return formatter.string(from: startDate)
    }

    var polyline: MKPolyline {
        let coordinates = route.map { $0.coordinate }
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        return polyline
    }

    var maxHeartRate: Int {
        let bpmUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
        if let maxHeart = heartRate.map({ $0.quantity.doubleValue(for: bpmUnit) }).max() {
            return Int(maxHeart)
        } else {
            return 0
        }
    }

    var formattedMaxHeartRate: String {
        return String(format: "%d bpm", maxHeartRate)
    }

    var formattedAverageHeartRate: String {
        return String(format: "%d bpm", averageHeartRate)
    }

    private var summedHeartRate: Double {
        let bpmUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
        return heartRate.reduce(0.0, { $0 + $1.quantity.doubleValue(for: bpmUnit) })
    }

    var averageHeartRate: Int {
        return Int(summedHeartRate / Double(heartRate.count))
    }

    var duration: TimeInterval {
        return hkWorkout.duration
    }

    init(workout: HKWorkout, route: [CLLocation], heartRate: [HKQuantitySample]) {
        self.route = route
        self.heartRate = heartRate

        if let timestamp = route.first?.timestamp {
            self.startDate = timestamp
        } else {
            self.startDate = Date()
        }
        self.hkWorkout = workout
    }

    func writeFile(_ format: String) -> URL? {
        if format == "Fit" {
            return writeFit()
        }
        return writeGPX()
    }
}
