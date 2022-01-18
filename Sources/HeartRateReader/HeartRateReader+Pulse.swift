//
//  HeartRateReader+Pulse.swift
//  HeartRateTest
//
//  Created by Ben Gottlieb on 1/16/22.
//

import Foundation
import AVFoundation
import CoreImage

extension HeartRateReader {
	func handle(buffer: CMSampleBuffer) {
		var redmean:CGFloat = 0.0;
		var greenmean:CGFloat = 0.0;
		var bluemean:CGFloat = 0.0;
		
		let pixelBuffer = CMSampleBufferGetImageBuffer(buffer)
		let cameraImage = CIImage(cvPixelBuffer: pixelBuffer!)
		
		let extent = cameraImage.extent
		let inputExtent = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)
		let averageFilter = CIFilter(name: "CIAreaAverage",
											  parameters: [kCIInputImageKey: cameraImage, kCIInputExtentKey: inputExtent])!
		let outputImage = averageFilter.outputImage!
		
		let ctx = CIContext(options:nil)
		let cgImage = ctx.createCGImage(outputImage, from:outputImage.extent)!
		
		let rawData:NSData = cgImage.dataProvider!.data!
		let pixels = rawData.bytes.assumingMemoryBound(to: UInt8.self)
		let bytes = UnsafeBufferPointer<UInt8>(start:pixels, count:rawData.length)
		var BGRA_index = 0
		for pixel in UnsafeBufferPointer(start: bytes.baseAddress, count: bytes.count) {
			switch BGRA_index {
			case 0:
				bluemean = CGFloat (pixel)
			case 1:
				greenmean = CGFloat (pixel)
			case 2:
				redmean = CGFloat (pixel)
			case 3:
				break
			default:
				break
			}
			BGRA_index += 1
		}
		
		let hsv = rgb2hsv((red: redmean, green: greenmean, blue: bluemean, alpha: 1.0))
		if (hsv.saturation > 0.5 && hsv.brightness > 0.5) {			// is the lens covered?
			if !isMeasuring { DispatchQueue.main.async { self.isMeasuring = true } }
			validFrameCounter += 1
//			if validFrameCounter > 60 {
				let newValue = Double(hsv.hue)
				let filtered = hueFilter.processValue(value: newValue)
				_ = rates.addNewValue(newVal: filtered, atTime: CACurrentMediaTime())
//			}
		} else {
			if isMeasuring { DispatchQueue.main.async { self.isMeasuring = false } }
			validFrameCounter = 0
			rates.reset()
		}
	}
}
