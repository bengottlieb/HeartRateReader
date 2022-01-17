//
//  HeartRateReader.Camera.swift
//  HeartRateTest
//
//  Created by Ben Gottlieb on 1/16/22.
//

import Foundation
import AVFoundation

// from https://github.com/athanasiospap/Pulse

extension AVCaptureDevice {
	func availableFormatsFor(preferredFPS: Float64) -> [AVCaptureDevice.Format] {
		var availableFormats: [AVCaptureDevice.Format] = []
		for format in formats {
			let ranges = format.videoSupportedFrameRateRanges
			for range in ranges where range.minFrameRate <= preferredFPS && preferredFPS <= range.maxFrameRate {
				availableFormats.append(format)
			}
		}
		return availableFormats
	}
	
	func formatFor(preferredSize: CGSize, availableFormats: [AVCaptureDevice.Format]) -> AVCaptureDevice.Format? {
		for format in availableFormats {
			let desc = format.formatDescription
			let dimensions = CMVideoFormatDescriptionGetDimensions(desc)
			
			if dimensions.width >= Int32(preferredSize.width) && dimensions.height >= Int32(preferredSize.height) {
				return format
			}
		}
		return nil
	}
	
	func updateFormatWithPreferredVideoSpec(fps: Float64 = 30, size: CGSize) {
		let availableFormats = availableFormatsFor(preferredFPS: fps)
		let selectedFormat = formatFor(preferredSize: size, availableFormats: availableFormats)
		
		if let selectedFormat = selectedFormat {
			do {
				try lockForConfiguration()
			} catch let error {
				print("Failed to lock the configuration: \(error)")
				return
			}
			activeFormat = selectedFormat
			
			activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(fps))
			activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(fps))
			unlockForConfiguration()
		}
	}
}

extension AVCaptureDevice.Position {
	func device(using priorities: [AVCaptureDevice.DeviceType] = [ .builtInUltraWideCamera, .builtInWideAngleCamera, .builtInTelephotoCamera ]) -> AVCaptureDevice? {
		let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTelephotoCamera, .builtInUltraWideCamera, .builtInWideAngleCamera], mediaType: AVMediaType.video, position: self).devices.filter { $0.position == self }
		
		for type in priorities {
			if let device = devices.first(where: { $0.deviceType == type }) {
				return device
			}
		}
		if let first = devices.first { return first }
		
		return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
	}
}
