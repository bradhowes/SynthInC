// InstrumentListViewController.swift
// SynthInC
//
// Created by Brad Howes
// Copyright (c) 2016 Brad Howes. All rights reserved.

import UIKit
import InAppSettingsKit
import AVFoundation
import ASValueTrackingSlider
import SwiftMIDI
import GameKit

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

    var performance: Performance? {
        didSet {
            self.recording = nil
            self.ensemble.reloadData()
            guard let p = self.performance else { return }
            DispatchQueue.global(qos: .utility).async {
                self.recording = Recording(performance: p, rando: self.rando)
            }
        }
    }

    var recording: Recording? {
        didSet {
            guard let r = recording else {
                DispatchQueue.main.async {
                    self.applyPlaybackPosition()
                }
                return
            }

            DispatchQueue.global(qos: .utility).async {
                _ = r.activate(audioController: self.audioController)
                self.player.load(recording: r)
                DispatchQueue.main.async {
                    self.applyPlaybackPosition()
                }
            }
        }
    }

    var ensembleCount: Int { return performance?.parts.count ?? 0 }

    var normalizedCurrentPostion: CGFloat {
        guard let recording = self.recording else { return 0.0 }
        return  CGFloat(currentPosition / recording.sequenceLength)
    }

    var playbackReady: Bool = false

    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var ensemble: UITableView!
    @IBOutlet weak var regenerateButton: UIButton!
    @IBOutlet weak var playbackPosition: ASValueTrackingSlider!
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

        ensemble.delegate = self
        ensemble.dataSource = self

        playbackPosition.setThumbImage(UIImage(named:"Slider"), for: UIControlState())
        playbackPosition.setThumbImage(UIImage(named:"Slider"), for: .selected)
        playbackPosition.setThumbImage(UIImage(named:"Slider"), for: .highlighted)

        playbackPosition.popUpViewColor = UIColor.init(red: 12/255.0, green: 102/255.0, blue: 223/255.0, alpha: 1.0)
        playbackPosition.dataSource = self

        setNeedsStatusBarAppearanceUpdate()
        
        applyPlaybackPosition()

        if !UIApplication.beingTested {
            if let config = Parameters.ensemble {
                _ = audioController.restoreEnsemble(data: config, instrumentDoneCallback: self.instrumentIsReady, finishedCallback: ensembleIsReady)
            }
            else {
                _ = audioController.createEnsemble(ensembleSize: 8, instrumentDoneCallback:  self.instrumentIsReady, finishedCallback: ensembleIsReady)
            }
        }

        super.viewDidLoad()
    }
    
    fileprivate func ensembleIsReady(_ successful: Bool) {
        precondition(Thread.isMainThread == false)

        guard successful else { return }
        Parameters.ensemble = audioController.encodeEnsemble()

        var performance: Performance? = nil
        if let data = Parameters.performance {
            performance = Performance(data: data)
        }

        if performance == nil {
            performance = Performance(perfGen: BasicPerformanceGenerator(ensembleSize: self.audioController.ensemble.count, rando: self.rando))
            Parameters.performance = performance!.encodePerformance()
        }

        DispatchQueue.main.async {
            self.performance = performance
        }
    }

    /**
     Tell the OS that we have a dark background
     
     - returns: UIStatusBarStyle.LigthContent
     */
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }

    /**
     Memory pressure in effect. Resources should be purged. But what?
     */
    override func didReceiveMemoryWarning() {
        print("*** memory pressure ***")
        super.didReceiveMemoryWarning()
    }
}

// MARK: Playback control

extension EnsembleViewController: ASValueTrackingSliderDataSource {

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
        playStopButton.setImage(image, for: UIControlState())
        playStopButton.setImage(image, for: .highlighted)
        playStopButton.setImage(image, for: .selected)
        startUpdateTimer()
        applyPlaybackPosition()
        playbackPosition.showPopUpView(animated: true)
    }
    
    /**
     Update UI to show that music is not playing.
     */
    fileprivate func stoppedPlaying() {
        let image = UIImage(named: "Play")
        playStopButton.setImage(image, for: UIControlState())
        playStopButton.setImage(image, for: .highlighted)
        playStopButton.setImage(image, for: .selected)
        playbackPosition.hidePopUpView(animated: true)
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

    /**
     Delegate callback from playbackPosition slider to format the popup value text.
     
     - parameter slider: the slider needing an update
     - parameter value: the value of the slider to format
     
     - returns: string value in MM:SS format
     */
    func slider(_ slider: ASValueTrackingSlider!, stringForValue value: Float) -> String {
        // currentPosition is the number of beats. Rate is ~120 BPM. Return HH:MM format
        guard let recording = self.recording else { return "" }
        let bpm = 120.0
        let pos = Double(value) * recording.sequenceLength
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

        // Briefly show the new time position, but only dismiss it if the value
        // is the same as what we set it to
        playbackPosition.showPopUpView(animated: true)
        Timer.after(2.seconds) {
            if self.playbackPosition.value == value {
                self.playbackPosition.hidePopUpView(animated: true)
            }
        }

        applyPlaybackPosition()
        player.position = currentPosition
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

    private func instrumentIsReady(_ index: Int) {
        precondition(Thread.isMainThread == false)
        let allReady = audioController.ensemble.filter({ !$0.ready }).isEmpty
        DispatchQueue.main.async {
            if allReady {
                self.playbackReady = true
                self.applyPlaybackPosition()
            }
        }
    }

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
     Support deselection of a row. If a row is already selected, deselect the row.
     
     - parameter tableView: the instruments view
     - parameter indexPath: the index of the row that will be selected
     
     - returns: indexPath if row should be selected, nil otherwise
     */
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let currentRow = (tableView.indexPathForSelectedRow as NSIndexPath?)?.row else { return indexPath }
        let newRow = (indexPath as NSIndexPath).row
        if currentRow == newRow {
            tableView.deselectRow(at: indexPath, animated: true)
            return nil
        }
        return indexPath
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
        updateBarButtons()
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        updateBarButtons()
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

//        let button = UIButton(type:.infoLight)
//        button.isEnabled = cell.instrument.ready
//        button.addTarget(self, action: #selector(editInstrument), for: .touchUpInside)
//        cell.accessoryView = button

        cell.updateAll(normalizedCurrentPostion)

        return cell
    }
    
   /**
     User tapped on the accessory button of a row. Show the instrument editor.
     
     - parameter tableView: the table view being edited
     - parameter indexPath: the row index to edit
     */
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        print("accessorybuttonTappedForRowWith: \(indexPath.row)")
        
        // NOTE: we don't need to do anything here.
        // guard let cell = tableView.cellForRow(at: indexPath) as? InstrumentCell else { return }
        // performSegue(withIdentifier: "showDetail", sender: cell)
    }

}

// MARK: Instrument Editing
extension EnsembleViewController: InstrumentEditorViewControllerDelegate {

    /**
     Present the instrument editor.
     
     - parameter sender: the table view cell
     - parameter event: description of the event that triggered this call
     */
//    @objc func editInstrument(_ sender: UIButton, forEvent event: UIEvent) {
//
//        // Use the last touch event to locate the row we are to edit
//        //
//        guard let touch = event.allTouches?.first else { return }
//        let position = touch.location(in: ensemble)
//
//        guard let indexPath = ensemble.indexPathForRow(at: position) else { return }
//        let cell = ensemble.cellForRow(at: indexPath)
//
//        // Now present the editor
//        //
//        performSegue(withIdentifier: "showDetail", sender: cell)
//    }

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
                
                // Focus on the indicator -- this may not be correct for all locales.
                let rect = cell.bounds
                ppc.sourceRect = view.convert(CGRect(origin: rect.offsetBy(dx: rect.width - 32, dy: 0).origin, size: CGSize(width: 32.0, height: rect.height)), to: nil)
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
        audioController.ensemble.forEach { $0.solo(instrument, active: state) }
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
    func tableView(_ tableView: UITableView, commit commitEditingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
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
