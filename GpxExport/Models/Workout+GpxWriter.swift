//
//  Workout+GpxWriter.swift
//  GpxExport
//
//  Created by Mario Martelli on 23.02.19.
//  Copyright © 2019 Mario Martelli. All rights reserved.
//

import Foundation
import HealthKit

extension Workout {
    func writeGPX() -> URL? {
        var currentHeartrateIndex = 0
        var currentHeartrate: Double = -1
        let bpmUnit = HKUnit(from: "count/min")
        var heartrateString = ""

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"

        let fileName = "\(formatter.string(from: startDate)) - \(activityType)"

        let targetURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(fileName)
            .appendingPathExtension("gpx")

        DispatchQueue.global(qos: .background).async {
            let file: FileHandle

            do {
                let manager = FileManager.default
                if manager.fileExists(atPath: targetURL.path) {
                    try manager.removeItem(atPath: targetURL.path)
                }
                manager.createFile(atPath: targetURL.path, contents: Data())
                file = try FileHandle(forWritingTo: targetURL)
            } catch let err {
                print(err)
                return
            }

            if let header = self.gpxHeader(title: self.name, startDate: self.startDate).data(using: .utf8) {
                file.write(header)
            }

            for location in self.route {
                while (currentHeartrateIndex < self.self.heartRate.count) && (location.timestamp > self.heartRate[currentHeartrateIndex].startDate) {
                    currentHeartrate = self.heartRate[currentHeartrateIndex].quantity.doubleValue(for: bpmUnit)
                    currentHeartrateIndex += 1
                    heartrateString = self.gpxHeartRate(currentHeartrate)
                }
                if let trackpoint = self.gpxTrackPoint(location: location, heartrate: heartrateString).data(using: .utf8) {
                    file.write(trackpoint)
                }
            }
            file.write("""
  </trkseg>
  </trk>
  </gpx>

  """.data(using: .utf8)!)
            file.closeFile()
        }
        return targetURL

    }

}
