//
//  HKWorkout+Formatting.swift
//  GpxExport
//
//  Created by Patrick Steiner on 22.01.19.
//  Copyright © 2019 Mario Martelli. All rights reserved.
//

import HealthKit

extension HKWorkout {
    var formattedTotalDistance: String {
        let totalDistance = self.totalDistance?.doubleValue(for: HKUnit.meter()) ?? 0

        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 2

        let lengthFormatter = LengthFormatter()
        lengthFormatter.unitStyle = .short
        lengthFormatter.numberFormatter = numberFormatter

        return lengthFormatter.string(fromMeters: totalDistance)
    }

    var formattedStartDate: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .medium

        return formatter.string(from: startDate)
    }

    var formattedStartDateForSection: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        return formatter.string(from: startDate)
    }

    var formattedWorkoutType: String {
        switch workoutActivityType {
        case .cycling:
            return NSLocalizedString("workout.activity.type.cycling", comment: "Workout Activity Type: Cycle")
        case .running:
            return NSLocalizedString("workout.activity.type.running", comment: "Workout Activity Type: Run")
        case .walking:
            return NSLocalizedString("workout.activity.type.walking", comment: "Workout Activity Type: Walk")
        case .hiking:
            return NSLocalizedString("workout.activity.type.hiking", comment: "Workout Activity Type: Hike")
        case .swimming:
            return NSLocalizedString("workout.activity.type.swimming", comment: "Workout Activity Type: Swim")
        default:
            return NSLocalizedString("workout.activity.type.default", comment: "Workout Activity Type: Default - Workout")
        }
    }
}
