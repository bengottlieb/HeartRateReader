//
//  HeartRateReader.swift
//  HeartRateTest
//
//  Created by Ben Gottlieb on 1/16/22.
//

import SwiftUI
import AVFoundation

public class HeartRateReader: NSObject, ObservableObject {
	public static let instance = HeartRateReader()
	@Published public var isRunning = false
	@Published public var isMeasuring = false

	public static var position: AVCaptureDevice.Position = .back
	public static var viewPortSize = CGSize(width: 300, height: 300)

	enum HeartRateError: Error { case cantAddVideoDevice, cantAddOutput, noCameraFound }
	
	var previewLayer: AVCaptureVideoPreviewLayer?

	private let captureSession = AVCaptureSession()
	private var videoDevice: AVCaptureDevice!
	private var videoConnection: AVCaptureConnection!
	private var videoDeviceInput: AVCaptureDeviceInput!
	private var videoDataOutput: AVCaptureVideoDataOutput!

	var validFrameCounter = 0
	let hueFilter = Filter()
	var rates = PulseDetector()
	
	private override init() { super.init() }
	
	public func start() throws {
		if videoDevice == nil {
			rates = PulseDetector()
			guard let device = Self.position.device() else { throw HeartRateError.noCameraFound }
			
			videoDevice = device
			captureSession.sessionPreset = .low
			videoDevice.updateFormatWithPreferredVideoSpec(fps: 32, size: Self.viewPortSize)
			
			videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
			guard captureSession.canAddInput(videoDeviceInput) else { throw HeartRateError.cantAddVideoDevice }
			captureSession.addInput(videoDeviceInput)
			
			let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
			previewLayer.contentsGravity = CALayerContentsGravity.resizeAspectFill
			previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
			self.previewLayer = previewLayer

			videoDataOutput = AVCaptureVideoDataOutput()
			videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
			videoDataOutput.alwaysDiscardsLateVideoFrames = true
			let queue = DispatchQueue(label: "com.standalone.heartratereader")
			videoDataOutput.setSampleBufferDelegate(self, queue: queue)
			guard captureSession.canAddOutput(videoDataOutput) else { throw HeartRateError.cantAddOutput }
			captureSession.addOutput(videoDataOutput)
			videoConnection = videoDataOutput.connection(with: .video)
		}

		captureSession.startRunning()
		DispatchQueue.main.async { self.isRunning = true }
	}
	
	public var canReset: Bool { videoConnection != nil }
	public func reset() {
		if isRunning {
			print("Please stop before resetting")
			return
		}
		
		if let input = videoDeviceInput { captureSession.removeInput(input) }
		if let output = videoDataOutput { captureSession.removeOutput(output) }
		
		videoDeviceInput = nil
		videoDataOutput = nil
		videoDevice = nil
		videoConnection = nil
	}
	
	public func stop() {
		captureSession.stopRunning()
		DispatchQueue.main.async { self.isRunning = false }
	}
	
	var heartRate: Float? {
		guard let average = self.rates.getAverage() else { return nil }
		let pulse = 60.0/average
		return pulse
	}
}

extension HeartRateReader: AVCaptureVideoDataOutputSampleBufferDelegate {
	public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		if connection.videoOrientation != .portrait {
			connection.videoOrientation = .portrait
			return
		}
		
		handle(buffer: sampleBuffer)
	}
}
