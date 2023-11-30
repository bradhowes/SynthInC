// Copyright © 2016 Brad Howes. All rights reserved.

import UIKit
import AVFoundation

/**
 Main view controller for the application.
 */
final class EnsembleViewController: UIViewController {

  enum BarButtonItems: Int {
    case add = 0, edit
  }

  let player = Player()
  let rando: Rando = RandomSources(config: RandomSources.Config(seed: Parameters.randomSeed))

  var audioController: AudioController = AudioController()

  var performance: Performance?
  var recording: Recording?

  var ensembleCount: Int { return performance?.parts.count ?? 0 }
  var loadedCount: Int = 0

  var normalizedCurrentPostion: CGFloat {
    guard let recording = self.recording else { return 0.0 }
    return  CGFloat(currentPosition / recording.sequenceLength)
  }

  var playbackReady: Bool = false

  @IBOutlet weak var loadingStackView: UIStackView!
  @IBOutlet weak var loadingProgressBar: UIProgressView!
  @IBOutlet weak var addButton: UIBarButtonItem!
  @IBOutlet weak var deleteButton: UIBarButtonItem!
  @IBOutlet weak var saveButton: UIBarButtonItem!
  @IBOutlet weak var ensemble: UITableView!
  @IBOutlet weak var regenerateButton: UIButton!
  @IBOutlet weak var playbackPosition: UISlider!
  @IBOutlet weak var playbackLabel: UILabel!
  @IBOutlet weak var playbackPositionTapGestureRecognizer: UITapGestureRecognizer!
  @IBOutlet weak var playStopButton: UIButton!

  /**
   The last reported position of the Player. Cached
   */
  var currentPosition: MusicTimeStamp = 0.0

  /**
   When playing music, this timer fires every second to update the instruments table view with the sequence they
   are currently playing (1-54)
   */
  var updateTimer: Timer? = nil

  /// Indication that the user is manipulating the playback slider.
  var sliderInUse = false

  /**
   Initialize and configure view after loading.
   */
  override func viewDidLoad() {

    NotificationCenter.default.addObserver(self, selector: #selector(ensembleReady), name: .ensembleReady,
                                           object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(instrumentReady), name: .instrumentReady,
                                           object: nil)

    loadingStackView.isHidden = false
    loadingProgressBar.progress = 0.0
    loadedCount = 0

    ensemble.delegate = self
    ensemble.dataSource = self

    playbackPosition.value = 0.0
    playbackLabel.text = "00:00"

    setNeedsStatusBarAppearanceUpdate()

    applyPlaybackPosition()

    if !UIApplication.beingTested {
      if let config = Parameters.ensemble {
        audioController.restoreEnsemble(data: config)
      }
      else {
        audioController.createEnsemble(ensembleSize: 8)
      }
    }

    super.viewDidLoad()
  }

  @objc func ensembleReady(notification: NSNotification) {
    Parameters.ensemble = audioController.encodeEnsemble()

    let performance: Performance
    if let data = Parameters.performance,
       let p = Performance(data: data) {
      performance = p
    } else {
      performance = Performance(perfGen: BasicPerformanceGenerator(ensembleSize: self.audioController.ensemble.count,
                                                                   rando: self.rando))
      Parameters.performance = performance.encodePerformance()
    }

    guard let recording = Recording(performance: performance, rando: self.rando) else { return }
    _ = recording.activate(audioController: self.audioController)

    DispatchQueue.main.async {
      self.loadingStackView.isHidden = true
      self.performance = performance
      self.recording = recording
      self.ensemble.reloadData()
      self.applyPlaybackPosition()
      self.player.load(recording: recording)
      self.applyPlaybackPosition()
    }
  }

  @objc func instrumentReady(notification: NSNotification) {
    loadedCount += 1
    DispatchQueue.main.async {
      self.loadingProgressBar.progress = Float(self.loadedCount) / Float(self.audioController.ensemble.count)
      print("progress:", self.loadedCount, self.loadingProgressBar.progress)
    }

    let allReady = audioController.ensemble.filter({ !$0.ready }).isEmpty
    if allReady {
      DispatchQueue.main.async {
        self.playbackReady = true
        self.applyPlaybackPosition()
      }
    }
  }

  fileprivate func ensembleIsReady(_ successful: Bool) {
    precondition(Thread.isMainThread == false)

    DispatchQueue.main.async {
      self.loadingStackView.isHidden = true
    }

    guard successful else { return }
    Parameters.ensemble = audioController.encodeEnsemble()

    let performance: Performance
    if let data = Parameters.performance,
       let p = Performance(data: data) {
      performance = p
    } else {
      performance = Performance(perfGen: BasicPerformanceGenerator(ensembleSize: self.audioController.ensemble.count,
                                                                   rando: self.rando))
      Parameters.performance = performance.encodePerformance()
    }

    guard let recording = Recording(performance: performance, rando: self.rando) else { return }
    _ = recording.activate(audioController: self.audioController)

    DispatchQueue.main.async {
      self.performance = performance
      self.recording = recording
      self.ensemble.reloadData()
      self.applyPlaybackPosition()
      self.player.load(recording: recording)
      self.applyPlaybackPosition()
    }
  }

  /**
   Tell the OS that we have a dark background

   - returns: UIStatusBarStyle.LigthContent
   */
  override var preferredStatusBarStyle : UIStatusBarStyle { .lightContent }

  /**
   Memory pressure in effect. Resources should be purged. But what?
   */
  override func didReceiveMemoryWarning() {
    print("*** memory pressure ***")
    super.didReceiveMemoryWarning()
  }

  /**
   Notification that the user is manipulating the playback slider. Just set flag that this is the case so we won't
   change it during updates.

   - parameter sender: the UISlider being manipulated
   */
  @IBAction func beginChangePlaybackPosition(_ sender: UISlider) {
    sliderInUse = true
    print("sliderInUse true")
  }

  /**
   Notification that the user is no longer manipulating the playback slider. Clear the flag, and ask the current
   MusicPlayer to move to the timestamp indicated by the slider position.

   - parameter sender: playback slider
   */
  @IBAction func endChangePlaybackPosition(_ sender: UISlider) {
    sliderInUse = false
    print("sliderInUse false")
    applyPlaybackPosition()
    player.position = currentPosition
  }
}

// MARK: Playback control

extension EnsembleViewController {

  @IBAction func playStop(_ sender: UIButton) {
    if player.playOrStop() == .play {
      startedPlaying()
    }
    else {
      stoppedPlaying()
    }
  }

  /**
   Update UI to show that music is playing.
   */
  fileprivate func startedPlaying() {
    let image = UIImage(named: "Pause")
    playStopButton.setImage(image, for: UIControl.State())
    playStopButton.setImage(image, for: .highlighted)
    playStopButton.setImage(image, for: .selected)
    startUpdateTimer()
    applyPlaybackPosition()
  }

  /**
   Update UI to show that music is not playing.
   */
  fileprivate func stoppedPlaying() {
    let image = UIImage(named: "Play")
    playStopButton.setImage(image, for: UIControl.State())
    playStopButton.setImage(image, for: .highlighted)
    playStopButton.setImage(image, for: .selected)
    endUpdateTimer()
  }

  /**
   Begin update timer to refresh instruments view and slider.
   */
  fileprivate func startUpdateTimer() {
    updateTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self,
                                       selector: #selector(fetchPlayerPosition), userInfo: nil,
                                       repeats: true)
  }

  /**
   Stop update timer.
   */
  fileprivate func endUpdateTimer() {
    updateTimer?.invalidate()
  }

  /**
   Update the playback slider to reflect the current time from the active MusicPlayer. Update does not take place
   if the user is actively manipulating the slider.
   */
  @objc func fetchPlayerPosition() {
    let length = recording?.sequenceLength ?? 0.0
    currentPosition = player.position

    guard !sliderInUse else { return }

    if currentPosition < length {
      playbackPosition.value = Float(currentPosition / length)
    }
    else {
      if player.isPlaying {
        _ = player.stop()
        stoppedPlaying()
        currentPosition = 0.0
        playbackPosition.value = 0.0
        player.position = currentPosition
      }
    }
    playbackLabel.text = formattedPlaybackPosition()
    updatePhrases()
  }

  /**
   Update instruments view and slider to reflect the current position of playing music.
   */
  func applyPlaybackPosition() {
    playStopButton.isEnabled = playbackReady && self.recording != nil
    regenerateButton.isEnabled = false
    playbackPosition.isEnabled = playbackReady && self.recording != nil
    updateBarButtons()
    currentPosition = MusicTimeStamp(playbackPosition.value) * (recording?.sequenceLength ?? 0.0)
    playbackLabel.text = formattedPlaybackPosition()
    updatePhrases()
  }

  /**
   Update all of the phrase indicators using the current playback position.
   */
  func updatePhrases() {
    ensemble.visibleCells.forEach {
      ($0 as! InstrumentCell).updatePhrase(normalizedCurrentPostion)
    }
  }

  func formattedPlaybackPosition() -> String {
    // currentPosition is the number of beats. Rate is ~120 BPM. Return HH:MM format
    guard let recording = self.recording else { return "" }
    let bpm = 120.0
    let pos = Double(playbackPosition.value) * recording.sequenceLength
    let mins = pos / bpm
    let secs = mins * 60.0 - Double(Int(mins)) * 60.0
    return String(format:"%02ld:%02ld", Int(mins), Int(secs))
  }

  /**
   User moved the playback slider. Calculate approximate time value and direct SoundGenerator to play from that
   position
   - parameter sender: the slider reporting the change
   */
  @IBAction func changePlaybackPosition(_ sender: UISlider) {
    applyPlaybackPosition()
  }

  /**
   Notification from gesture recoginizer that a tap happened in the playbackPosition slider.
   */
  @IBAction func tapPlaybackPosition(_ sender: UIGestureRecognizer) {
    guard !playbackPosition.isHighlighted else { return }
    let x = sender.location(in: playbackPosition).x - 2.5 // Minimum X value that affects slider
    let width = playbackPosition.bounds.width - 5.0 // Remove 2.5 from both sides of bounds
    let value = Float(x / width)
    playbackPosition.value = max(min(value, 1.0), 0.0)

    applyPlaybackPosition()
    player.position = currentPosition
  }
}

// MARK: Regenerate
extension EnsembleViewController {

  /**
   Generate a new sequence of "In C" phrases.

   - parameter sender: button that was touched
   */
  @IBAction func regenerate(_ sender: UIButton) {
    //        if audioController.createMusicSequence(randomSource: randomSource) {
    //            stoppedPlaying()
    //            playbackPosition.value = 0.0
    //            instrumentSettings.reloadData()
    //        }
  }
}

// MARK: UITableView

extension EnsembleViewController: UITableViewDelegate, UITableViewDataSource {

  private func updateBarButtons() {
    let reallyReady = playbackReady && recording != nil
    let selectedCount = ensemble.indexPathsForSelectedRows?.count ?? 0
    let noItemsSelected = selectedCount == 0
    let allItemsSelected = selectedCount == ensembleCount

    addButton.isEnabled = reallyReady
    deleteButton.isEnabled = reallyReady && ensembleCount > 0

    if !ensemble.isEditing {
      saveButton.isEnabled = reallyReady
      deleteButton.title = "Edit"
    }
    else {
      saveButton.isEnabled = false
      if noItemsSelected {
        deleteButton.title = "Done"
      }
      else if allItemsSelected {
        deleteButton.title = "Delete All";
      }
      else {
        deleteButton.title = "Delete \(selectedCount)"
      }
    }
  }

  /**
   Obtain the number of rows to display in the instruments view
   - parameter tableView: the UITableView to work with
   - parameter numberOfRowsInSection: which section to report on (only one in our view)
   - returns: number of instruments active in music playback
   */
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return ensembleCount
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let cell = ensemble.cellForRow(at: indexPath)
    performSegue(withIdentifier: "showDetail", sender: cell)
    tableView.deselectRow(at: indexPath, animated: true)
  }

  func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
  }

  /**
   Obtain a UITableViewCell to use for an instrument, and fill it in with the instrument's values.
   - parameter tableView: the UITableView to work with
   - parameter indexPath: the row of the table to update
   - returns: UITableViewCell
   */
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    precondition(self.performance != nil)

    let identifier = "InstrumentCell" // !!! This must match prototype in Main.storyboard !!!
    let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as! InstrumentCell
    let index = indexPath.row // (indexPath as NSIndexPath).row
    precondition(index >= 0 && index < audioController.ensemble.count)

    cell.part = self.performance!.parts[index]
    cell.instrument = audioController.ensemble[index]
    cell.showsReorderControl = true

    cell.isUserInteractionEnabled = cell.instrument.ready
    cell.updateAll(normalizedCurrentPostion)

    return cell
  }
}

// MARK: Instrument Editing
extension EnsembleViewController: InstrumentEditorViewControllerDelegate {

  /**
   Setup position of the editor popover (if used). We want the popover to point to the right row.

   - parameter segue: the storyboard segue being used
   - parameter sender: the InstrumentTableViewCell of the instrument to edit
   */
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "showDetail" {
      guard let cell = sender as? InstrumentCell,
            let nc = segue.destination as? UINavigationController,
            let vc = nc.topViewController as? InstrumentEditorViewController,
            let indexPath = ensemble.indexPath(for: cell),
            (indexPath.row >= 0 && indexPath.row < ensembleCount) else { return }

      // Receive some update notifications when values change
      //
      vc.delegate = self

      // Remember the instrument and the row being edited
      //
      let index = indexPath.row
      let instrument = audioController.ensemble[index]
      precondition(instrument.ready)

      vc.editInstrument(instrument, row: index)

      // Now if showing a popover, position it in the right spot
      //
      if let ppc = nc.popoverPresentationController {
        ppc.barButtonItem = nil // !!! Muy importante !!!
        ppc.sourceView = cell
        let rect = cell.bounds
        ppc.sourceRect = view.convert(rect, to: nil)
        vc.preferredContentSize.width = self.preferredContentSize.width
      }
    }

    super.prepare(for: segue, sender: sender)
  }

  /**
   Editor has been dismissed.

   - parameter row: the row that was being edited
   - parameter reason: the reason for the dismissal: Cancel or Done
   */
  func instrumentEditorDismissed(_ row: Int, reason: InstrumentEditorDismissedReason) {
    self.dismiss(animated: false, completion: nil)
    let cell = ensemble.cellForRow(at: IndexPath(row: row, section: 0)) as! InstrumentCell
    cell.updateAll(normalizedCurrentPostion)
    if reason == .done {
      Parameters.ensemble = audioController.encodeEnsemble()
    }
  }

  /**
   Patch setting changed in the editor. Update the cell.

   - parameter row: the row that changed
   */
  func instrumentEditorPatchChanged(_ row: Int) {
    guard let cell = ensemble.cellForRow(at: IndexPath(row: row, section: 0)) as? InstrumentCell else { return }
    cell.updateTitle()
    cell.updateSoundFontName()
  }

  /**
   Volume setting changed in the editor. Update the cell.

   - parameter row: the row that changed
   */
  func instrumentEditorVolumeChanged(_ row: Int) {
    guard let cell = ensemble.cellForRow(at: IndexPath(row: row, section: 0)) as? InstrumentCell else { return }
    cell.updateVolume()
  }

  /**
   Pan setting changed in the editor. Update the cell.

   - parameter row: the row that changed
   */
  func instrumentEditorPanChanged(_ row: Int) {
    guard let cell = ensemble.cellForRow(at: IndexPath(row: row, section: 0)) as? InstrumentCell else { return }
    cell.updateVolume()
  }

  /**
   Mute setting changed in the editor. Update the cell.

   - parameter row: the row that changed
   */
  func instrumentEditorMuteChanged(_ row: Int) {
    guard let cell = ensemble.cellForRow(at: IndexPath(row: row, section: 0)) as? InstrumentCell else { return }
    cell.updateVolume()
  }

  /**
   Octave setting changed in the editor. Update the cell.

   - parameter row: the row that changed
   */
  func instrumentEditorOctaveChanged(_ row: Int) {
    guard let cell = ensemble.cellForRow(at: IndexPath(row: row, section: 0)) as? InstrumentCell else { return }
    cell.updateTitle()
  }

  /**
   Solo setting changed in the editor. Update the cell.

   - parameter row: the row that changed
   - parameter soloing: true if solo enabled, false otherwise
   */
  func instrumentEditorSoloChanged(_ row: Int, soloing state: Bool) {
    let instrument = audioController.ensemble[row]
    audioController.ensemble.forEach { $0.soloChanged(instrument, active: state) }
    ensemble.visibleCells.forEach { ($0 as! InstrumentCell).updateVolume() }
  }
}

// MARK: Instrument List Editing
extension EnsembleViewController {

  /**
   Notification from table view that editing is complete.

   - parameter tableView: the table view
   - parameter commitEditingStyle: the editing style that is coming to an end
   - parameter indexPath: the index of the row being edited
   */
  func tableView(_ tableView: UITableView, commit commitEditingStyle: UITableViewCell.EditingStyle,
                 forRowAt indexPath: IndexPath) {
    guard commitEditingStyle == .delete else { return }

    // Remove the instrument from the model, then tell table view to remove the corresponding view
    //
    // _ = audioController.removeInstrument((indexPath as NSIndexPath).row)
    tableView.deleteRows(at: [indexPath], with: .fade)
  }

  func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
    updateBarButtons()
  }

  /**
   Handle row movement by the user.

   - parameter tableView: the table view
   - parameter sourceIndexPath: the original location of the instrument
   - parameter destinationIndexPath: the new location of the instrument
   */
  func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
    // audioController.reorderInstrument(fromPos: (sourceIndexPath as NSIndexPath).row, toPos: (destinationIndexPath as NSIndexPath).row)
  }

  /**
   Add an instrument. If there is a selected row, insert the new instrument before it. Otherwise, append to the end
   of the list.

   - parameter sender: the button
   */
  @IBAction func addInstrument(_ sender: UIBarButtonItem) {
    let indexPath = ensemble.indexPathForSelectedRow ??
    IndexPath(row: ensembleCount, section: 0)
    // guard audioController.addInstrument((indexPath as NSIndexPath).row) else { return }

    // Add a view for the new instrument, select it, and scroll view to make it visible
    //
    ensemble.insertRows(at: [indexPath], with: .automatic)
    ensemble.selectRow(at: indexPath, animated: true, scrollPosition: .none)
    ensemble.scrollToRow(at: indexPath, at: .none, animated: true)

    updateBarButtons()
  }

  /**
   Toggle edit state of the instruments view.

   - parameter sender: the button
   */
  @IBAction func editInstruments(_ sender: UIBarButtonItem) {
    if ensemble.isEditing {
      if let selectedRows = ensemble.indexPathsForSelectedRows {
        // let rows = selectedRows.map({ $0.row }).sorted().reversed()
        // rows.forEach { _ = audioController.removeInstrument($0) }
        ensemble.beginUpdates()
        ensemble.deleteRows(at: selectedRows, with: .fade)
        ensemble.endUpdates()
      }
      ensemble.setEditing(false, animated: true)
    }
    else {
      ensemble.setEditing(true, animated: true)
    }
    updateBarButtons()
  }

  @IBAction func saveSession(_ sender: UIBarButtonItem) {

  }
}
