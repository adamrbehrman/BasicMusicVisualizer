//
//  ContentView.swift
//  BasicMusicVisualizer
//
//  Created by Adam Behrman on 8/26/22.
//

import SwiftUI
import AVFoundation
import Keyboard

struct ContentView: View {
    
    /// Creates an instance of AVAudioEngine.
    private let audioEngine: AVAudioEngine = AVAudioEngine()
    
    /// Holds the camera transform properties.
    private var camTransform:simd_float4x4?
    
    /// Default values for frequency bins.
    private static let general:[Float] = [ 0.002, 0.65, 1.0, 10.0, 2000.0]
    
    ///  Holds the note information
    @State private var notes:[Note] = []
    
    /// Background color
    @State private var bgCol:Color = Color.white
    
    
//    let timer = Timer.publish (
//            every: 2,       // Second
//            tolerance: 0.1, // Gives tolerance so that SwiftUI makes optimization
//            on: .main,      // Main Thread
//            in: .common     // Common Loop
//        ).autoconnect()
//
//    @State var offset: CGSize = .zero
    
    
    var body: some View {
//        HStack {
//            VStack {
//                ForEach (notes) { note in
//                    Text(note.name)
//                        .font(.system(size: CGFloat(note.magnitude * 1000 + 50)))
//                        .foregroundColor(Color(note.color))
//                }
//
//    //            Circle()
//    //                .frame(width: 50, height: 50, alignment: .center)
//    //                .offset(offset)
//    //                .padding()
//
//                Spacer()
//
//                HStack {
//
//                    Spacer()
//
//                    VStack{
//
//                        Button {
//                            startAudioEngine()
//                        } label: {
//                            Text("Start tracking music!")
//                        }.padding()
//
//                        Button {
//                            stopAudioEngine()
//                        } label: {
//                            Text("Stop tracking music!")
//                        }.padding()
//
//                    }
//
//                    Spacer()
//                }
//            }
//    //        .onReceive(timer) { (_) in
//    //
//    //            let widthBound = UIScreen.main.bounds.width / 2
//    //            let heightBound = UIScreen.main.bounds.height / 2
//    //
//    //
//    //            let randomOffset = CGSize(
//    //                width: CGFloat.random(in: -widthBound...widthBound),
//    //                height: CGFloat.random(in: -heightBound...heightBound)
//    //            )
//    //            withAnimation(.linear(duration: 2.0)) {
//    //
//    //                self.offset = randomOffset
//    //            }
//    //        }
//            Spacer()
//        }
//        .onAppear {
//            checkMicPermission()
//        }
//        .background(bgCol)
        
//                ForEach (notes) { note in
//                    Text(note.name)
//                        .font(.system(size: CGFloat(note.magnitude * 1000 + 50)))
//                        .foregroundColor(Color(note.color))
//                }
            
        HStack {

            Spacer()
        }.onAppear {
            checkMicPermission()
        }
    }
    
    
    func startAudioEngine() {
        if !audioEngine.isRunning {
            do {
                try audioEngine.start()
            } catch let error as NSError {
                print("Got an error starting the AudioEngine: \(error.domain), \(error)")
            }
        }
    }
    
    func stopAudioEngine() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
    }
    
    func checkMicPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
            
            case .authorized:
                self.setupAudioEngine(bus: 0, bufferSize: 1024)
                self.startAudioEngine()
            
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    if granted {
                        self.setupAudioEngine(bus: 0, bufferSize: 1024)
                        self.startAudioEngine()
                    }
                }
            
            case .denied:
                return

            case .restricted:
                return
        }
    }
    
    /// Installs a tap on the audio engine's inputNode to enable real-time audio processing.
    /// - Establishes the inputNode and installs a 'tap' according to parameters bus and bufferSize.
    /// - Parameter bus: An Int representing the input bus of the tap.
    /// - Parameter bufferSize: An UInt32 representing the buffer size of the tap.
    func setupAudioEngine(bus:Int, bufferSize: UInt32) {
        // Get audio engine's input node (microphone access required - handled in 'Info.plist')
        let inputNode = self.audioEngine.inputNode
            
        // Installs a 'tap' on the input node.
        // A tap monitors and can record the output of the node.
        inputNode.installTap(onBus: bus,         // Single input.
            bufferSize: bufferSize,               // Though this value could change...
            format: nil,                          // No format translation.
            block: {
                // buffer is the buffer (AVAudioPCMBuffer); when gives the capture time (AVAudioTime).
                (buffer, when) in
                // floatChannelData gives pointers to each sample's data.
                let rawChannelData = buffer.floatChannelData
                
                // channelDataValue holds an array of modified Floats (UnsafeMutablePointer<Float>).
                let channelDataValue = rawChannelData!.pointee
                
                // Use the stride function to get an array of floats.
                // Goes from 0 to bufferSize by its channel difference.
                let pcmData = stride(from: 0,
                                     to: Int(buffer.frameLength),
                                     // Use the map funcition to return the channelDataValue at the new location.
                    // $0 is the first parameter.
                    by: buffer.stride).map{ channelDataValue[$0] }
                
                let avgPower: Float = SoundAnalyzer.getAveragePower(data: pcmData, frames:Float(buffer.frameLength))
                
                let meterLevel = SoundAnalyzer.getVUMeter(power: avgPower, minDb: -80.0)
                
                self.onAudioTap(meterLevel: meterLevel, sampleRate: Float(when.sampleRate), pcmData: pcmData)
        })
    }
    
    /// Manages the addition, modification and removal of nodes.
    /// - Parameter meterLevel: The adjusted VU Meter power level.
    /// - Parameter sampleRate: The sampling rate from which the data was derived.
    /// - Parameter pcmData: The data from the buffer.
    func onAudioTap(meterLevel: Float, sampleRate: Float, pcmData: [Float]) {
        let fftValues = SoundAnalyzer.performFFT(pcmData)
        let frequencyInterval = sampleRate / (Float(fftValues.count))
        
        let start = DispatchTime.now() 
        
        let guesses = SoundAnalyzer.getNotes(fftValues: fftValues, frequencyInterval: frequencyInterval, threshold: 0.001, percentage: 0.7, notes: 2, minBinSize: 3, lowFrequency: 10.0, highFrequency: 1000.0)
        
        let end = DispatchTime.now()
        
        print("elapsed time: ", round(Float(end.uptimeNanoseconds - start.uptimeNanoseconds) / Float(1000000000) * 10000) / 10000.0)
        
        print()
        for note in guesses {
            print(note)
        }
        
        notes = guesses
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
