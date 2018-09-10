//
//  Player.swift
//  SwiftMIDI
//
//  Created by Brad Howes on 7/24/18.
//  Copyright © 2018 Brad Howes. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

public final class Player : NSObject {
    private let musicPlayer : MusicPlayer?
    private var remotePlayTarget: Any? = nil
    private var remotePauseTarget: Any? = nil

    public var isPlaying : Bool {
        guard let mp = musicPlayer else { return false }
        var playing: DarwinBoolean = false
        return MusicPlayerIsPlaying(mp, &playing) == 0 && playing.boolValue
    }
    
    public var position : MusicTimeStamp {
        get {
            var position: MusicTimeStamp = 0
            guard let mp = musicPlayer else { return position }
            return MusicPlayerGetTime(mp, &position) == 0 ? position : 0.0
        }
        set {
            guard let mp = musicPlayer else { return }
            MusicPlayerSetTime(mp, newValue)
        }
    }
    
    public override init() {
        var mp : MusicPlayer?
        NewMusicPlayer(&mp)
        musicPlayer = mp

        super.init()
        
        setupRemoteCommandCenterCommands()
    }

    deinit {
        removeRemoteCommandCenterCommands()
    }

    /**
     Enumeration for the result of the playOrStop method.
     - Play: indication that the MusicPlayer is playing
     - Stop: indication that the MusicPlayer is **not** playing
     */
    public enum PlayOrStop {
        case play, stop
    }
    
    /**
     Toggle the state of the player: if not playing, begin playing; if playing, stop
     
     - Returns: new state of the player
     */
    public func playOrStop() -> PlayOrStop {
        return isPlaying ? (stop() ? .stop : .stop) : (play() ? .play : .stop)
    }

    public func play() -> Bool {
        guard let mp = musicPlayer else { return false }
        return MusicPlayerStart(mp) == 0
    }

    public func stop() -> Bool {
        guard let mp = musicPlayer else { return false }
        return MusicPlayerStop(mp) == 0
    }

    public func load(recording: Recording) {
        guard let mp = musicPlayer else { return }
        _ = IsAudioError("MusicPlayerSetSequence", MusicPlayerSetSequence(mp, recording.musicSequence))
        _ = IsAudioError("MusicPlayerPreroll", MusicPlayerPreroll(mp))
        _ = IsAudioError("MusicPlayerSetTime", MusicPlayerSetTime(mp, 0.0))
    }

    private func setupRemoteCommandCenterCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        remotePlayTarget = commandCenter.playCommand.addTarget { [unowned self] event in
            return (!self.isPlaying && self.play()) ? .success : .commandFailed
        }
        
        remotePauseTarget = commandCenter.pauseCommand.addTarget { [unowned self] event in
            return (self.isPlaying && self.stop()) ? .success : .commandFailed
        }
    }
    
    private func removeRemoteCommandCenterCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.removeTarget(remotePlayTarget)
        commandCenter.pauseCommand.removeTarget(remotePauseTarget)
    }
}
