//
//  Workout+GpxWriter.swift
//  GpxExport
//
//  Created by Mario Martelli on 23.02.19.
//  Copyright © 2019 Mario Martelli. All rights reserved.
//

import Foundation
import HealthKit
import CoreLocation

extension Workout {
    func writeGPX(completionHandler: @escaping(_ url: URL?) -> Void) {
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

                DispatchQueue.main.async {
                    completionHandler(nil)
                }
                return
            }

            if let header = self.gpxHeader(title: self.name, startDate: self.startDate).data(using: .utf8) {
                file.write(header)
            }

            for location in self.route {
                while (currentHeartrateIndex < self.heartRate.count) && (location.timestamp > self.heartRate[currentHeartrateIndex].startDate) {
                    currentHeartrate = self.heartRate[currentHeartrateIndex].quantity.doubleValue(for: bpmUnit)
                    currentHeartrateIndex += 1
                    heartrateString = self.gpxHeartRate(currentHeartrate)
                }
                if let trackpoint = self.gpxTrackPoint(location: location, heartrate: heartrateString).data(using: .utf8) {
                    file.write(trackpoint)
                }
            }

            if let footerData = self.gpxFooter().data(using: .utf8) {
                file.write(footerData)
            }

            file.closeFile()

            DispatchQueue.main.async {
                completionHandler(targetURL)
            }
        }
    }

    private func gpxTrackPoint(location: CLLocation, heartrate: String) -> String {
        let isoFormatter = ISO8601DateFormatter()

        return """
        <trkpt lat=\"\(location.coordinate.latitude)" lon="\(location.coordinate.longitude)">
        <ele>\(location.altitude.magnitude)</ele>
        <time>\(isoFormatter.string(from: location.timestamp))</time>        \(heartrate)
        </trkpt>

        """
    }

    private func gpxHeartRate(_ currentHeartrate: Double) -> String {
        return """

        <extensions>
        <gpxtpx:TrackPointExtension>
        <gpxtpx:hr>\(currentHeartrate)</gpxtpx:hr>
        </gpxtpx:TrackPointExtension>
        </extensions>
        """
    }

    private func gpxHeader(title: String, startDate: Date) -> String {
        let isoFormatter = ISO8601DateFormatter()

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        // swiftlint:disable line_length
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx creator="WorkoutExporter" version="1.1" xmlns="http://www.topografix.com/GPX/1/1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd http://www.garmin.com/xmlschemas/GpxExtensions/v3 http://www.garmin.com/xmlschemas/GpxExtensionsv3.xsd http://www.garmin.com/xmlschemas/TrackPointExtension/v1 http://www.garmin.com/xmlschemas/TrackPointExtensionv1.xsd http://www.garmin.com/xmlschemas/GpxExtensions/v3 http://www.garmin.com/xmlschemas/GpxExtensionsv3.xsd http://www.garmin.com/xmlschemas/TrackPointExtension/v1 http://www.garmin.com/xmlschemas/TrackPointExtensionv1.xsd http://www.garmin.com/xmlschemas/GpxExtensions/v3 http://www.garmin.com/xmlschemas/GpxExtensionsv3.xsd http://www.garmin.com/xmlschemas/TrackPointExtension/v1 http://www.garmin.com/xmlschemas/TrackPointExtensionv1.xsd" xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1" xmlns:gpxx="http://www.garmin.com/xmlschemas/GpxExtensions/v3">

        <metadata>
        <time>\(isoFormatter.string(from: startDate))</time>
        </metadata>
        <trk>
        <name>\(title)</name>
        <trkseg>

        """
        // swiftlint:enable line_length
    }

    private func gpxFooter() -> String {
        return """
        </trkseg>
        </trk>
        </gpx>

        """
    }
}
