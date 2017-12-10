//
//  DateFormatting.swift
//  GpxExport
//
//  Created by Mario Martelli on 09.12.17.
//  Copyright © 2017 Mario Martelli. All rights reserved.
//

import Foundation

extension Formatter {
  static let year: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "y"
    return formatter
  }()
  static let month: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "LLLL"
    return formatter
  }()
}
extension Date {
  var year: String  { return Formatter.year.string(from: self) }
  var month: String  { return Formatter.month.string(from: self) }
}
