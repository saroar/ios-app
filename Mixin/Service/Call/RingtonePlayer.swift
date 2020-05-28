import Foundation
import AVFoundation.AVFAudio

class RingtonePlayer {
    
    enum Ringtone {
        case incoming
        case outgoing
    }
    
    private lazy var incomingPlayer: AVAudioPlayer? = {
        guard let player = try? AVAudioPlayer(contentsOf: R.file.callCaf()!) else {
            return nil
        }
        player.numberOfLoops = -1
        player.volume = 1
        incomingPlayerIfLoaded = player
        return player
    }()
    
    private lazy var outgoingPlayer: AVAudioPlayer? = {
        guard let player = try? AVAudioPlayer(contentsOf: R.file.ringtone_outgoingCaf()!) else {
            return nil
        }
        player.numberOfLoops = -1
        player.volume = 1
        outgoingPlayerIfLoaded = player
        return player
    }()
    
    private weak var incomingPlayerIfLoaded: AVAudioPlayer?
    private weak var outgoingPlayerIfLoaded: AVAudioPlayer?
    
    func play(ringtone: Ringtone) {
        stop()
        let session = AVAudioSession.sharedInstance()
        switch ringtone {
        case .incoming:
            try? session.setCategory(.playback, mode: .default, options: [])
            incomingPlayer?.play()
        case .outgoing:
            try? session.setCategory(.playAndRecord, mode: .voiceChat, options: [])
            outgoingPlayer?.play()
        }
    }
    
    func stop() {
        incomingPlayerIfLoaded?.stop()
        outgoingPlayerIfLoaded?.stop()
    }
    
}
