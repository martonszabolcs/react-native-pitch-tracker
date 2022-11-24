import Foundation
import UIKit

@objc(PitchTracker)
class PitchTracker: RCTEventEmitter {

    // MARK: Objects Handling Core Functionality
    private var modelDataHandler: ModelDataHandler? =
        ModelDataHandler(modelFileInfo: ConvActions.modelInfo)
    private var audioInputManager: AudioInputManager?
    
    // MARK: Instance Variables
    private var result : [Dictionary<String, Any>]?
    private var prevKeys: [Int] = Array(repeating: 0, count: 88)
    private var bufferSize: Int = 0
    private var threshold: Int = 10

    @objc
    func start() {
        prevKeys = Array(repeating: 0, count: 88)

        guard let workingAudioInputManager = audioInputManager else {
            return
        }
        print("Audio Manager Loaded")
        
        bufferSize = workingAudioInputManager.bufferSize

        workingAudioInputManager.startTappingMicrophone()
    }

    @objc
    func stop() {
        guard let workingAudioInputManager = audioInputManager else {
            return
        }
        workingAudioInputManager.stopTappingMicrophone()
    }

    @objc
    func prepare() {
        guard let handler = modelDataHandler else {
            return
        }
        if(audioInputManager != nil) {
            return
        }
        audioInputManager = AudioInputManager(sampleRate: handler.sampleRate, sequenceLength: handler.sequenceLength)
        audioInputManager?.delegate = self
        
        guard let workingAudioInputManager = audioInputManager else {
            return
        }
        workingAudioInputManager.prepareMicrophone()
    }

    private func runModel(onBuffer buffer: [Int16]) {
        self.result = modelDataHandler?.runModel(onBuffer: buffer)
        guard let eventList = result else { return }
        if (!eventList.isEmpty){
            sendEvent(withName: "NoteOn", body: ["midiNum": eventList])
        }
    }    

    override func supportedEvents() -> [String]! {
        return ["NoteOn", "NoteOff"]
    }

    override static func requiresMainQueueSetup() -> Bool {
        return true;
    }
}

extension PitchTracker: AudioInputManagerDelegate {
    func didOutput(channelData: [Int16]) {

        guard let handler = modelDataHandler else {
            return
        }
        bufferSize = (handler.sampleRate * handler.sequenceLength) / 1000

        self.runModel(onBuffer: Array(channelData[0..<bufferSize]))
    }
}

