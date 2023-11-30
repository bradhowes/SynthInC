import AVFoundation

class Performer {
  private let index: Int
  private let rando: Rando
  private var currentPhrase = 0
  private var remainingBeats: Int
  private var phraseRepetition: Int = 0
  private var desiredRepetition: Int = 1
  private var phraseRepetitions: [Int] = []
  private(set) var duration: MusicTimeStamp = 0.0

  var stats: PerformerStats { .init(remainingBeats: remainingBeats, currentPhrase: currentPhrase) }

  init(index: Int, rando: Rando) {
    self.index = index
    self.rando = rando
    self.remainingBeats = Score.beats[0]
    self.phraseRepetitions.reserveCapacity(Score.phrases.count)
  }

  func tick(elapsed: Int, minPhrase: Int, maxPhrase: Int) -> PerformerStats {
    if currentPhrase == Score.phrases.count {
      return PerformerStats(currentPhrase: currentPhrase)
    }

    remainingBeats -= elapsed
    if remainingBeats == 0 {
      phraseRepetition += 1
      let moveProb = currentPhrase == 0 ? 100 :
      max(maxPhrase - currentPhrase, 0) * 15 - max(currentPhrase - minPhrase, 0) * 15 +
      max(phraseRepetition - desiredRepetition + 1, 0) * 100

      if rando.passes(threshold: moveProb) {
        phraseRepetitions.append(phraseRepetition)
        duration += MusicTimeStamp(phraseRepetition) * Score.phrases[currentPhrase].duration
        currentPhrase += 1
        if currentPhrase == Score.phrases.count {
          return PerformerStats(currentPhrase: currentPhrase)
        }

        phraseRepetition = 0
        desiredRepetition = rando.phraseRepetitions(phraseIndex: currentPhrase)
      }

      remainingBeats = Score.beats[currentPhrase]
    }

    return PerformerStats(remainingBeats: remainingBeats, currentPhrase: currentPhrase)
  }

  func finish(goal: MusicTimeStamp) {
    precondition(phraseRepetitions.count == Score.phrases.count)
    guard let lastPhrase = Score.phrases.last else { return }
    while duration + lastPhrase.duration < goal {
      phraseRepetitions[Score.phrases.count - 1] += 1
      duration += lastPhrase.duration
    }
  }
}

extension Performer {
  func generatePart() -> Part {
    return Part(index: index, phraseRepetitions: phraseRepetitions, duration: duration)
  }
}
