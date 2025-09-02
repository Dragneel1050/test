//

import AVFoundation
import Speech
import SwiftUI
import Combine

class SpeechReconitionModel {
    static let shared = SpeechReconitionModel()
    
    enum RecognizerError: Error {
        case nilRecognizer
        case notAuthorizedToRecognize
        case notPermittedToRecord
        case recognizerIsUnavailable
        case whisperTranscriptionError
        
        var message: String {
            switch self {
                case .nilRecognizer: return "Can't initialize speech recognizer"
                case .notAuthorizedToRecognize: return "Not authorized to recognize speech"
                case .notPermittedToRecord: return "Not permitted to record audio"
                case .recognizerIsUnavailable: return "Recognizer is unavailable"
                case .whisperTranscriptionError: return "Whisper transcription error"
            }
        }
    }
    var intents = PassthroughSubject<CNNModelResultTypes, Never>()
    
    private var audioFileURL: URL? = nil
    private var recorder: AVAudioRecorder? = nil
    var recording = false
    
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer: SFSpeechRecognizer?
    
    let cnn = CNNModel()
    /**
     Initializes a new speech recognizer. If this is the first time you've used the class, it
     requests access to the speech recognizer and the microphone.
     */
    init() {
        recognizer = SFSpeechRecognizer()
        guard recognizer != nil else {
            transcribe(RecognizerError.nilRecognizer)
            return
        }
        
        Task {
            do {
                guard await SFSpeechRecognizer.hasAuthorizationToRecognize() else {
                    throw RecognizerError.notAuthorizedToRecognize
                }
            } catch {
                transcribe(error)
            }
        }
    }
    
    var transcripts = PassthroughSubject<String, Never>()
    
    func startTranscribingAndRecording() {
        let session = transcribe()
        startRecording(session: session)
    }
    
    /**
     Begin transcribing audio.
     
     Creates a `SFSpeechRecognitionTask` that transcribes speech to text until you call `stopTranscribing()`.
     The resulting transcription is continuously written to the published `transcript` property.
     */
    func transcribe() -> AVAudioSession? {
        guard let recognizer, recognizer.isAvailable else {
            self.transcribe(RecognizerError.recognizerIsUnavailable)
            return nil
        }
        
        do {
            let (audioEngine, request, session) = try Self.prepareEngine()
            self.audioEngine = audioEngine
            self.request = request
        
            self.task = recognizer.recognitionTask(with: request, resultHandler: { [weak self] result, error in
                self?.recognitionHandler(audioEngine: audioEngine, result: result, error: error)
            })
            return session
        } catch {
            self.reset()
            self.transcribe(error)
            return nil
        }
    }
    
    /// Reset the speech recognizer.
    func reset() {
        task?.cancel()
        audioEngine?.stop()
        recorder?.stop()
        audioEngine = nil
        request = nil
        task = nil
    }
    
    private static func prepareEngine() throws -> (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest, AVAudioSession) {
        let audioEngine = AVAudioEngine()
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true        
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            request.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
        
        return (audioEngine, request, audioSession)
    }
    
    private func recognitionHandler(audioEngine: AVAudioEngine, result: SFSpeechRecognitionResult?, error: Error?) {
        let receivedFinalResult = result?.isFinal ?? false
        let receivedError = error != nil
        
        if receivedFinalResult || receivedError {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        if let result {
            transcribe(result.bestTranscription.formattedString)
        }
    }
    
    
    private func transcribe(_ message: String) {
        Task(priority: .userInitiated) {
            transcripts.send(message)
            await updateIntent(message)
        }
    }
    
    @MainActor
    func updateIntent(_ lastTranscript: String) {
        if lastTranscript.split(separator: " ").count > 1 {
            do {
                let prediction = try self.cnn.predict(lastTranscript).strongest()
                self.intents.send(prediction)
            } catch let err {
                AppLogs.defaultLogger.error("transcribe: \(err)")
            }
        }
    }
    
    private func transcribe(_ error: Error) {
        var errorMessage = ""
        if let error = error as? RecognizerError {
            errorMessage += error.message
        } else {
            errorMessage += error.localizedDescription
        }
        self.transcripts.send("<< \(errorMessage) >>")
    }
    
    
    private func startRecording(session: AVAudioSession? = nil) {
        let recordingSession = {
            if session != nil {
                session!
            } else {
                AVAudioSession.sharedInstance()
            }
        }()
        
        audioFileURL = URL(filePath: NSTemporaryDirectory().appending("recording.mp4"))
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            AVAudioApplication.requestRecordPermission(completionHandler:{ allowed in
                DispatchQueue.main.async { [self] in
                    if allowed {
                        let settings = [
                            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                            AVSampleRateKey: 12000,
                            AVNumberOfChannelsKey: 1,
                            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
                        ]
                        do {
                            self.recorder = try AVAudioRecorder(url: self.audioFileURL!, settings: settings)
                            self.recorder!.record()
                            self.recorder!.isMeteringEnabled = true
                            self.recording = true
                        } catch {
                            AppLogs.defaultLogger.error("startRecording: \(error)")
                        }
                    } else {
                        AppLogs.defaultLogger.error("startRecording: Unable to record, check permissions")
                    }
                }
            })
            
            
        } catch {
            AppLogs.defaultLogger.error("startRecording: Unable to record, check permissions")
            return
        }
        
        return
    }
    
    
    func stopRecording() {
        if self.recording {
            self.recording = false
            self.recorder?.stop()
        }
    }
    
    func stopRecordingAndTranscribeUsingWhisper() async throws -> whisperAudioResponse {
        stopRecording()
        
        do {
            let data = try Data(contentsOf: audioFileURL!)
            let response = try await ApiModel.shared.transcribeWhisperAudio(data: data)
            
            return response
        } catch let error {
            AppLogs.defaultLogger.error("stopRecordingAndTranscribeUsingWhisper: \(error)")
            throw RecognizerError.whisperTranscriptionError
        }
    }
}


extension SFSpeechRecognizer {
    static func hasAuthorizationToRecognize() async -> Bool {
        await withCheckedContinuation { continuation in
            requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}
