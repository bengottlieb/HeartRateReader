//
//  HeartRateCameraView.swift
//  HeartRateTest
//
//  Created by Ben Gottlieb on 1/16/22.
//

import Combine
import SwiftUI

struct HeartRateCameraView: UIViewRepresentable {
	var size: CGSize = .init(width: 40, height: 40)

	typealias UIViewType = CameraView
	@ObservedObject var reader = HeartRateReader.instance

	func makeUIView(context: Context) -> CameraView {
		CameraView(size: size)
	}
	
	func updateUIView(_ uiView: CameraView, context: Context) {
		uiView.setupLayers()
	}
	
	
	
	
	class CameraView: UIView {
		var cancellable: AnyCancellable?
		init(size: CGSize) {
			super.init(frame: .zero)
			setupLayers()
		}
		
		required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
		
		func setupLayers() {
			if let layer = HeartRateReader.instance.previewLayer {
				self.layer.addSublayer(layer)
			}
			
			HeartRateReader.instance.previewLayer?.frame = self.bounds
		}
	}
}
