//: Playground - noun: a place where people can play

import SwiftMIDI
import GameKit
import AudioToolbox
import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true

let randoConfig = RandomSources.Config.init(seed: 123, minPhraseDurationSeconds: 15, maxPhraseDurationSeconds: 100, minSlopRange: 0, maxSlopRange: 0)
let rando = RandomSources(config: randoConfig)

var optionalMusicPlayer: MusicPlayer?
_ = IsAudioError("NewMusicPlayer", NewMusicPlayer(&optionalMusicPlayer))
let musicPlayer = optionalMusicPlayer!

let audioController = AudioController()

audioController.createEnsemble(ensembleSize: 4) {
    let performance = Performance(perfGen: BasicPerformanceGenerator(ensembleSize: audioController.ensemble.count, rando: rando))
    if let recording = Recording(performance: performance, rando: rando) {
        _ = IsAudioError("MusicPlayerSetSequence", MusicPlayerSetSequence(musicPlayer, recording.musicSequence))
        _ = IsAudioError("MusicPlayerSetTime", MusicPlayerSetTime(musicPlayer, 0.0))
    }
}

func start() { MusicPlayerStart(musicPlayer) }
func stop() { MusicPlayerStop(musicPlayer) }

