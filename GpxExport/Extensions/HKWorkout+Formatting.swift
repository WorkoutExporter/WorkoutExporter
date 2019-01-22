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
}
