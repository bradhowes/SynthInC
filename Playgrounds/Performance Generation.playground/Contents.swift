import SwiftMIDI
import GameKit

//func calculate() {
//    let maxPhrase = 4
//    let minPhrase = 0
//    for currentPhrase in 0...maxPhrase {
//        let behind = max(maxPhrase - currentPhrase, 0) * 25
//        let ahead = max(currentPhrase - maxPhrase, 0) * 25
//        let prob = behind - ahead
//        print("\(minPhrase) \(currentPhrase) \(maxPhrase) - \(prob)")
//    }
//}
//
//calculate()

let rando = RandomSources()

//var p = Performer(index: 0, rando: rando)
//while !p.isDone {
//    p.tick(elapsed: p.remainingBeats, minPhrase: p.currentPhrase, maxPhrase: p.currentPhrase)
//}
//
// p.history.enumerated().forEach { print("\($0.0) - \(Double($0.1) * 0.25)") }

let performance = Performance(perfGen: BasicPerformanceGenerator(ensembleSize: 8, rando: rando))
//print(performance.playCounts())
//print(performance.timelines())
