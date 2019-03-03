//
//  HKWorkout+FitActivity.swift
//  GpxExport
//
//  Created by Mario Martelli on 03.03.19.
//  Copyright © 2019 Mario Martelli. All rights reserved.
//

import Foundation
import AntMessageProtocol
import HealthKit

extension HKWorkout {
    var antActivity: Sport {
        switch workoutActivityType {
        case .cycling:  return .cycling
        case .running:  return .running
        case .walking:  return .walking
        case .hiking:   return .hiking
        case .swimming: return .swimming
        default:        return .generic
        }
    }
}
