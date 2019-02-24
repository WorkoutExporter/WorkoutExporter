//
//  Workout+FitWriter.swift
//  GpxExport
//
//  Created by Mario Martelli on 23.02.19.
//  Copyright © 2019 Mario Martelli. All rights reserved.
//

import Foundation
import HealthKit
import CoreLocation
import FitDataProtocol
import FitnessUnits

extension Workout {
    func writeFit() -> URL? {
        var currentHeartrateIndex = 0
        var currentHeartrate: Double = -1
        let bpmUnit = HKUnit(from: "count/min")

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"

        let fileName = "\(formatter.string(from: startDate)) - \(activityType)"

        let targetURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(fileName)
            .appendingPathExtension("fit")

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

            let time = FitTime(date: Date())
            let duration = Measurement(value: self.duration, unit: UnitDuration.seconds)
            var messages: [FitMessage] = []
            let activity = ActivityMessage(timeStamp: time,
                                           totalTimerTime: duration,
                                           localTimeStamp: nil,
                                           numberOfSessions: nil,
                                           activity: Activity.manual,
                                           event: nil,
                                           eventType: nil,
                                           eventGroup: nil)
            messages.append(activity)
            let fileId = FileIdMessage(deviceSerialNumber: nil,
                                        fileCreationDate: time,
                                        manufacturer: .garmin,
                                        product: nil,
                                        fileNumber: nil,
                                        fileType: FileType.activity,
                                        productName: nil)

            let stanceTime = StanceTime.nilSelf
            let torqueEffectiveness = TorqueEffectiveness.nilSelf
            let pedalSmoothness = PedalSmoothness.nilSelf

            for location in self.route {
                var heartrate: UInt8 = 0
                while (currentHeartrateIndex < self.heartRate.count) && (location.timestamp > self.heartRate[currentHeartrateIndex].startDate) {
                    currentHeartrate = self.heartRate[currentHeartrateIndex].quantity.doubleValue(for: bpmUnit)
                    currentHeartrateIndex += 1
                    heartrate = UInt8(currentHeartrate)
                }
                let latitude = ValidatedMeasurement(value: location.coordinate.latitude, valid: true, unit: UnitAngle.garminSemicircle)
                let longitude = ValidatedMeasurement(value: location.coordinate.longitude, valid: true, unit: UnitAngle.garminSemicircle)
                let altitude = ValidatedMeasurement(value: location.altitude, valid: true, unit: UnitLength.meters)
                let record = RecordMessage(timeStamp: FitTime(date: location.timestamp),
                                           position: Position(latitude: latitude, longitude: longitude),
                                           distance: nil,
                                           timeFromCourse: nil,
                                           cycles: nil,
                                           totalCycles: nil,
                                           accumulatedPower: nil,
                                           altitude: altitude,
                                           speed: nil,
                                           power: nil,
                                           gpsAccuracy: nil,
                                           verticalSpeed: nil,
                                           calories: nil,
                                           verticalOscillation: nil,
                                           stanceTime: stanceTime,
                                           heartRate: heartrate,
                                           cadence: nil,
                                           grade: nil,
                                           resistance: nil,
                                           cycleLength: nil,
                                           temperature: nil,
                                           activity: nil,
                                           torqueEffectiveness: torqueEffectiveness,
                                           pedalSmoothness: pedalSmoothness,
                                           stroke: nil,
                                           zone: nil,
                                           ballSpeed: nil,
                                           deviceIndex: nil)
                messages.append(record)
            }

            do {
                let encoder = FitFileEncoder(dataValidityStrategy: .none)
                let data = try encoder.encode(fildIdMessage: fileId, messages: messages)
                file.write(data)

            } catch {
                print(error)
            }
        }
        return targetURL
    }
}
