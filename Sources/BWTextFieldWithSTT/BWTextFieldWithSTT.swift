import SwiftUI
import Speech

@available(iOS 17.0, *)
public struct BWTextFieldWithSTT: View {
    
    @Binding var inputText: String
    var action: () -> Void
    
    @State private var isRecording = false
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    public init(inputText: Binding<String>, action: @escaping () -> Void) {
        self._inputText = inputText
        self.action = action
    }
    
    public var body: some View {
        VStack {
            RoundedRectangle(cornerSize: .init(width: 16, height: 16))
                .fill(Color.gray)
                .opacity(0.08)
                .frame(height: 55)
                .overlay(
                    HStack {
                        Button(action: {
                            if isRecording {
                                stopRecording()
                            } else {
                                startRecording()
                            }
                        })
                        {
                            if isRecording {
                                Image(systemName: "mic")
                                    .foregroundColor(.gray)
                                    .symbolEffect(.pulse.byLayer)
                            } else {
                                Image(systemName: "mic")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.leading)
                        
                        TextField("Please enter a keyword.", text: $inputText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.vertical, 15)
                            .disabled(isRecording)
                            .foregroundColor(.gray)
                        
                        Button(action: action) {
                            Image(systemName: "arrow.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing)
                    }
                )
                .padding(.horizontal)
        }
    }
    
    
    func startRecording() {
        //check if the speech recognizer is available. iOS 10.0+ needed
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("DEBUG: Recognizer is not available")
            return
        }
        
        //Create recognitionRequest. It will provide recognition request results.
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        //Create Audio Session. We will recode audio and Activate Audio session to start recoding.
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("DEBUG: Audio session setup errors")
            return
        }
        
        //install an audio tap on the audio. input node of the AVAudioEngine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
            self.recognitionRequest?.append(buffer)
        }
        
        //Start The Audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("DEBUG: Audio engine start errors")
            return
        }
        
        //Create a Speech Recognition Task, Provide recognition request results
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest!) { result, error in
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                self.inputText = transcription
            }
        }
        
        isRecording = true
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        isRecording = false
    }
}
