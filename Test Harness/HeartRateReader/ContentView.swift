//
//  ContentView.swift
//  HeartRateTest
//
//  Created by Ben Gottlieb on 1/16/22.
//

import SwiftUI

struct ContentView: View {
	@ObservedObject var reader = HeartRateReader.instance
    var body: some View {
		 VStack() {
			 if reader.isRunning {
				 if let pulse = reader.heartRate {
					 Text("Heart Rate: \(Int(pulse))")
				 } else if reader.isMeasuring {
					 Text("Measuring…")
				 } else {
					 Text("Please cover the camera with your finger")
				 }
				 HeartRateCameraView()
					 .frame(width: 200, height: 200)
					 .clipShape(Circle())
			 }
			 Button(reader.isRunning ? "Stop" : "Start") {
				 if reader.isRunning {
					 reader.stop()
				 } else {
					 try? reader.start()
				 }
			 }
			 .padding()

			 if !reader.isRunning, reader.canReset {
				 Button("Reset") {
					 reader.reset()
				 }
				 .padding()
			 }
		 }
	 }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
