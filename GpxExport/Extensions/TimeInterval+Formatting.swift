//
//  TimeInterval+Formatting.swift
//  GpxExport
//
//  Created by Patrick Steiner on 22.01.19.
//  Copyright © 2019 Mario Martelli. All rights reserved.
//

import Foundation

extension TimeInterval {
    var formatted: String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = [.pad]

        return formatter.string(from: self)
    }
}
