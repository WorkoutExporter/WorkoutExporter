//
//  Workout.swift
//  GpxExport
//
//  Created by Mario Martelli on 30.11.17.
//  Copyright © 2017 Mario Martelli. All rights reserved.
//

import Foundation
import CoreLocation
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

    func writeFile() -> URL? {
        return writeGPX()
    }

    func gpxTrackPoint(location: CLLocation, heartrate: String) -> String {
        let isoFormatter = ISO8601DateFormatter()

        return """
        <trkpt lat=\"\(location.coordinate.latitude)" lon="\(location.coordinate.longitude)">
        <ele>\(location.altitude.magnitude)</ele>
        <time>\(isoFormatter.string(from: location.timestamp))</time>        \(heartrate)
        </trkpt>

        """
    }

    func gpxHeartRate(_ currentHeartrate: Double) -> String {
        return """

        <extensions>
        <gpxtpx:TrackPointExtension>
        <gpxtpx:hr>\(currentHeartrate)</gpxtpx:hr>
        </gpxtpx:TrackPointExtension>
        </extensions>
        """
    }
    func gpxHeader(title: String, startDate: Date) -> String {
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
}
