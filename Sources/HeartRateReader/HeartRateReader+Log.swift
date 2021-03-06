//
//  HeartRateReader+Log.swift
//  HeartRateTest
//
//  Created by Ben Gottlieb on 1/16/22.
//

import Foundation
import QuartzCore
import Combine

private let averageSize = 20
private let maxPeriodsToStore = 20
private let invalidPulsePeriod = -1
private let maxPeriod = 1.5
private let minPeriod = 0.1
private let invalidEntry: Double = -100

extension HeartRateReader {
	class PulseDetector {
		private var publisher: ObservableObjectPublisher
		private var upVals = [Double](repeating: 0.0, count: averageSize)
		private var downVals = [Double](repeating: 0.0, count: averageSize)
		private var upValIndex = 0
		private var downValIndex = 0
		private var lastVal: Float = 0.0
		private var periods = [Double](repeating: 0.0, count: maxPeriodsToStore)
		private var periodTimes = [Double](repeating: 0.0, count: maxPeriodsToStore)
		private var periodIndex = 0
		private var started = false
		private var freq: Float = 0.0
		private var average: Float = 0.0
		private var wasDown = false
		private var recentPulses: [PulseRecord] = []
		
		private var periodStart: Double = 0.0
		
		struct PulseRecord {
			let rate: Float
			let date = Date()
		}
		
		init(publisher: ObservableObjectPublisher) {
			// set everything to invalid
			self.publisher = publisher
			reset()
		}
		
		func addNewValue(newVal: Double, atTime time: Double) -> Float {
			if newVal > 0 {
		 upVals[upValIndex] = newVal
		 upValIndex += 1
		 if upValIndex >= averageSize {
			  upValIndex = 0
		 }
	}
	
	if newVal < 0 {
		 downVals[downValIndex] = -newVal
		 downValIndex += 1
		 if downValIndex >= averageSize {
			  downValIndex = 0
		 }
	}
	
	// work out the average value above zero
	var count: Double = 0
	var total: Double = 0
	for i in 0..<averageSize {
		 if upVals[i] != invalidEntry {
			  count += 1
			  total += upVals[i]
		 }
	}
	
	let averageUp: Double = total/count
	// and the average value below zero
	count = 0
	total = 0
	for i in 0..<averageSize {
		 if downVals[i] != invalidEntry {
			  count += 1
			  total += downVals[i]
		 }
	}
	let averageDown: Double = total/count
	
	if newVal < -0.5 * averageDown {
		if !wasDown, let avg = getAverage(smoothed: false) {
			if let date = recentPulses.first?.date, abs(date.timeIntervalSinceNow) > 30 { recentPulses.remove(at: 0) }
			if recentPulses.count > 20 { recentPulses.remove(at: 0) }
			recentPulses.append(PulseRecord(rate: avg))
			DispatchQueue.main.async { self.publisher.send() }
		}
		 wasDown = true
	}
	// is the new value an up value and were we previously in the down state?
	if newVal >= 0.5 * averageUp && wasDown {
		 wasDown = false
		 // work out the difference between now and the last time this happenned
		 if time - periodStart < maxPeriod && time - periodStart > minPeriod {
			  periods[periodIndex] = time - periodStart
			  periodTimes[periodIndex] = time
			  periodIndex += 1
			  if periodIndex >= maxPeriodsToStore {
					periodIndex = 0
			  }
		 }
		 // track when the transition happened
		 periodStart = time
	}
	// return up or down
	if newVal < -0.5 * averageDown {
		 return -1
	} else if newVal > 0.5 * averageUp {
		 return 1
	}
	return 0
}
		
		func getAverage(smoothed: Bool = true) -> Float? {
			if smoothed, !recentPulses.isEmpty {
				let raw = recentPulses.map { $0.rate }
				return raw.reduce(0, +) / Float(raw.count)
			}
			let time = CACurrentMediaTime()
			var total: Double = 0
			var count: Double = 0
			for i in 0..<maxPeriodsToStore {
				// only use upto 10 seconds worth of data
				if periods[i] != invalidEntry && time - periodTimes[i] < 10 {
					count += 1
					total += periods[i]
				}
			}
			// do we have enough values?
			if count > 2 {
				return Float(total / count)
			}
			return nil
		}
		
		func reset() {
			for i in 0..<maxPeriodsToStore {
				periods[i] = invalidEntry
			}
			for i in 0..<averageSize {
				upVals[i] = invalidEntry
				downVals[i] = invalidEntry
			}
			freq = 0.5
			periodIndex = 0
			downValIndex = 0
			upValIndex = 0
		}
	}
	
}
