// InstrumentListViewController.swift
// SynthInC
//
// Created by Brad Howes
// Copyright (c) 2016 Brad Howes. All rights reserved.

import UIKit
import InAppSettingsKit
import AVFoundation

/**
 Main view controller for the application.
 */
class InstrumentListViewController: UIViewController {

    enum BarButtonItems: Int {
        case Add = 0, Edit, Done
    }

    /// Flag indicating if the settings pop-up is current shown
    var showingSettings = false
    
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!

    var normalRightButtons: [UIBarButtonItem] = []
    var editingRightButtons: [UIBarButtonItem] = []

    /**
     Table view of the instruments being used for playback.
     @IBOutlet weak var regenerateButton: UIButton!
     */
    @IBOutlet var instrumentSettings: UITableView!
    @IBOutlet weak var regenerateButton: UIButton!

    /**
     Shows and controls the current playback position of the music.
     */
    @IBOutlet var playbackPosition: ASValueTrackingSlider!
    
    /**
     Starts and pauses playback of music. Resuming starts playback at the current playback position, not at the
     beginning of the sequence.
     */
    @IBOutlet var playStopButton: UIButton!

    /**
     The current position of the music as reported by the SoundGenerator. This is a cached value for use when the
     instrument view updates.
     */
    var currentPosition: MusicTimeStamp = 0.0

    /**
     When playing music, this timer fires every second to update the instruments table view with the sequence they
     are currently playing (1-54)
     */
    var updateTimer: NSTimer? = nil

    /// Indication that the user is manipulating the playback slider.
    var sliderInUse = false

    /**
     Initialize and configure view after loading.
     */
    override func viewDidLoad() {

        instrumentSettings.delegate = self
        instrumentSettings.dataSource = self

        playbackPosition.minimumValue = 0.0
        playbackPosition.maximumValue = 1.0
        playbackPosition.value = 0.0
        playbackPosition.continuous = true

        playbackPosition.setThumbImage(UIImage(named:"Slider"), forState: .Normal)
        playbackPosition.setThumbImage(UIImage(named:"Slider"), forState: .Selected)
        playbackPosition.setThumbImage(UIImage(named:"Slider"), forState: .Highlighted)
        playbackPosition.popUpViewColor = UIColor.init(red: 12/255.0, green: 102/255.0, blue: 223/255.0, alpha: 1.0)
        playbackPosition.dataSource = self

        setNeedsStatusBarAppearanceUpdate()

        addButton.enabled = true
        editButton.enabled = true
        doneButton.enabled = true

        normalRightButtons = [editButton]
        editingRightButtons = [doneButton]

        navigationItem.setRightBarButtonItems(normalRightButtons, animated: false)
        
        super.viewDidLoad()
    }

    /**
     Tell the OS that we have a dark background
     
     - returns: UIStatusBarStyle.LigthContent
     */
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    /**
     Memory pressure in effect. Resources should be purged. But what?
     */
    override func didReceiveMemoryWarning() {
        print("*** memory pressure ***")
        super.didReceiveMemoryWarning()
    }
}

// MARK: Settings
extension InstrumentListViewController: IASKSettingsDelegate, UIPopoverPresentationControllerDelegate {

    /**
     IASKAppSettingsDelegate method which signals when the settings view is no longer on the screen.
     - parameter sender: the settings controller that was dismissed
     */
    func settingsViewControllerDidEnd(sender: IASKAppSettingsViewController!) {
        self.dismissViewControllerAnimated(true, completion: nil)
        normalRightButtons.forEach { $0.enabled = true }
        showingSettings = false
    }

    /**
     Notification from popover controller that the popover has been dismissed.
     
     - parameter popoverPresentationController: the controller
     */
    func popoverPresentationControllerDidDismissPopover(popoverPresentationController:
        UIPopoverPresentationController) {
        normalRightButtons.forEach { $0.enabled = true }
        showingSettings = false
    }
}

// MARK: Playback control
extension InstrumentListViewController: ASValueTrackingSliderDataSource {

    /**
     Update UI to show that music is playing.
     */
    private func startedPlaying() {
        let image = UIImage(named: "Pause")
        playStopButton.setImage(image, forState: .Normal)
        playStopButton.setImage(image, forState: .Highlighted)
        playStopButton.setImage(image, forState: .Selected)
        startUpdateTimer()
        updatePlaybackInfo()
        playbackPosition.showPopUpViewAnimated(true)
    }
    
    /**
     Update UI to show that music is not playing.
     */
    private func stoppedPlaying() {
        let image = UIImage(named: "Play")
        playStopButton.setImage(image, forState: .Normal)
        playStopButton.setImage(image, forState: .Highlighted)
        playStopButton.setImage(image, forState: .Selected)
        playbackPosition.hidePopUpViewAnimated(true)
        endUpdateTimer()
    }
    
    /**
     Begin update timer to refresh instruments view and slider.
     */
    private func startUpdateTimer() {
        updateTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self,
                                                             selector: #selector(showPlaybackPosition), userInfo: nil,
                                                             repeats: true)
    }

    /**
     Stop update timer.
     */
    private func endUpdateTimer() {
        updateTimer?.invalidate()
    }

    /**
     Update the playback slider to reflect the current time from the active MusicPlayer. Update does not take place
     if the user is actively manipulating the slider.
     */
    func showPlaybackPosition() {
        if sliderInUse { return }
        let length = audioController.sequenceLength
        currentPosition = audioController.getPlaybackPosition()
        if currentPosition < length {
            playbackPosition.value = Float(currentPosition / Double(length))
        }
        else {
            if audioController.isPlaying() {
                
                // The player has reached the end. Stop it and reset the slider to the start.
                //
                audioController.stop()
                stoppedPlaying()
                playbackPosition.value = 0.0
            }
        }
        updatePhrases()
    }

    /**
     Update instruments view and slider to reflect the current position of playing music.
     */
    func updatePlaybackInfo() {
        currentPosition = MusicTimeStamp(playbackPosition.value) * audioController.sequenceLength
        updatePhrases()
    }

    /**
     Update all of the phrase indicators using the current playback position.
     */
    func updatePhrases() {
        instrumentSettings.visibleCells.forEach {
            ($0 as! InstrumentsTableViewCell).updatePhrase(currentPosition)
        }
    }

    /**
     Delegate callback from playbackPosition slider to format the popup value text.
     
     - parameter slider: the slider needing an update
     - parameter value: the value of the slider to format
     
     - returns: string value in MM:SS format
     */
    func slider(slider: ASValueTrackingSlider!, stringForValue value: Float) -> String {
        // currentPosition is the number of beats. Rate is ~120 BPM. Return HH:MM format
        let bpm = 120.0
        let pos = Double(value) * audioController.sequenceLength
        let mins = pos / bpm
        let secs = mins * 60.0 - Double(Int(mins)) * 60.0
        return String(format:"%02ld:%02ld", Int(mins), Int(secs))
    }
    
    /**
     User moved the playback slider. Calculate approximate time value and direct SoundGenerator to play from that
     position
     - parameter sender: the slider reporting the change
     */
    @IBAction func changePlaybackPosition(sender: UISlider) {
        updatePlaybackInfo()
    }

    /**
     Notification that the user is manipulating the playback slider. Just set flag that this is the case so we won't
     change it during updates.
     
     - parameter sender: the UISlider being manipulated
     */
    @IBAction func beginChangePlaybackPosition(sender: UISlider) {
        sliderInUse = true
        print("sliderInUse true")
    }

    /**
     Notification that the user is no longer manipulating the playback slider. Clear the flag, and ask the current
     MusicPlayer to move to the timestamp indicated by the slider position.

     - parameter sender: playback slider
     */
    @IBAction func endChangePlaybackPosition(sender: UISlider) {
        sliderInUse = false
        audioController.setPlaybackPosition(MusicTimeStamp(playbackPosition.value) * audioController.sequenceLength)
    }

    /**
     User stopped or started playback. Update button to reflect what operation will happen with a subsequent tap.
     Command SoundGenerator to stop or start playback.
     - parameter sender: the button that was tapped
     */
    @IBAction func playStop(sender: UIButton) {
        if audioController.playOrStop() == .Play {
            startedPlaying()
        }
        else {
            stoppedPlaying()
        }
    }
}

// MARK: Regenerate
extension InstrumentListViewController {

    /**
     Generate a new sequence of "In C" phrases.
     
     - parameter sender: button that was touched
     */
    @IBAction func regenerate(sender: UIButton) {
        if audioController.createMusicSequence() {
            stoppedPlaying()
            playbackPosition.value = 0.0
            instrumentSettings.reloadData()
        }
    }
}

// MARK: UITableView
extension InstrumentListViewController: UITableViewDelegate, UITableViewDataSource {

    /**
     Support deselection of a row. If a row is already selected, deselect the row.
     
     - parameter tableView: the instruments view
     - parameter indexPath: the index of the row that will be selected
     
     - returns: indexPath if row should be selected, nil otherwise
     */
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        guard let currentRow = tableView.indexPathForSelectedRow?.row else { return indexPath }
        let newRow = indexPath.row
        if currentRow == newRow {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
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
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return audioController.activeInstruments.count
    }
    
    /**
     User tapped on the accessory button of a row. Show the instrument editor.
     
     - parameter tableView: the table view being edited
     - parameter indexPath: the row index to edit
     */
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        guard let cell = tableView.cellForRowAtIndexPath(indexPath) as? InstrumentsTableViewCell else { return }
        performSegueWithIdentifier("showDetail", sender: cell)
    }

}

// MARK: Instrument Editing
extension InstrumentListViewController: InstrumentEditorViewControllerDelegate {

    /**
     Obtain a UITableViewCell to use for an instrument, and fill it in with the instrument's values.
     - parameter tableView: the UITableView to work with
     - parameter indexPath: the row of the table to update
     - returns: UITableViewCell
     */
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let identifier = "InstrumentCell" // !!! This must match prototype in Main.storyboard !!!
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier) as! InstrumentsTableViewCell
        cell.instrument = audioController.activeInstruments[indexPath.row]
        cell.instrumentIndex?.text = "\(indexPath.row + 1)"
        cell.updateAll(currentPosition)
        cell.showsReorderControl = true
        
        let button = UIButton(type:.InfoLight)
        cell.accessoryView = button
        button.addTarget(self, action: #selector(editInstrument), forControlEvents: .TouchUpInside)
        
        return cell
    }

    /**
     Present the instrument editor.
     
     - parameter sender: the table view cell
     - parameter event: description of the event that triggered this call
     */
    func editInstrument(sender: UIButton, forEvent event: UIEvent) {
        
        // Use the last touch event to locate the row we are to edit
        //
        guard let touch = event.allTouches()?.first else { return }
        let position = touch.locationInView(instrumentSettings)
        guard let indexPath = instrumentSettings.indexPathForRowAtPoint(position) else { return }
        let cell = instrumentSettings.cellForRowAtIndexPath(indexPath)

        // Now present the editor
        //
        performSegueWithIdentifier("showDetail", sender: cell)
    }

    /**
     Setup position of the editor popover (if used). We want the popover to point to the right row.
     
     - parameter segue: the storyboard segue being used
     - parameter sender: the InstrumentTableViewCell of the instrument to edit
     */
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            guard let cell = sender as? InstrumentsTableViewCell,
                let nc = segue.destinationViewController as? UINavigationController,
                let vc = nc.topViewController as? InstrumentEditorViewController,
                let indexPath = instrumentSettings.indexPathForCell(cell) where
                (indexPath.row >= 0 && indexPath.row < audioController.activeInstruments.count) else { return }
            
            // Receive some update notifications when values change
            //
            vc.delegate = self
            
            // Remember the instrument and the row being edited
            //
            vc.editInstrument(audioController.activeInstruments[indexPath.row], row: indexPath.row)
            
            // Now if showing a popover, position it in the right spot
            //
            if let ppc = nc.popoverPresentationController {
                ppc.barButtonItem = nil // !!! Muy importante !!!
                ppc.sourceView = cell
                ppc.sourceRect = cell.accessoryView!.frame
            }
        }
        
        super.prepareForSegue(segue, sender: sender)
    }

    /**
     Editor has been dismissed.
     
     - parameter row: the row that was being edited
     - parameter reason: the reason for the dismissal: Cancel or Done
     */
    func instrumentEditorDismissed(row: Int, reason: InstrumentEditorDismissedReason) {
        self.dismissViewControllerAnimated(true, completion: nil)
        let cell = instrumentSettings.cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: 0))
            as! InstrumentsTableViewCell
        cell.updateAll(currentPosition)
    }

    /**
     Patch setting changed in the editor. Update the cell.
     
     - parameter row: the row that changed
     */
    func instrumentEditorPatchChanged(row: Int) {
        guard let cell = instrumentSettings.cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: 0))
            as? InstrumentsTableViewCell else { return }
        cell.updateTitle()
        cell.updateSoundFontName()
    }

    /**
     Volume setting changed in the editor. Update the cell.
     
     - parameter row: the row that changed
     */
    func instrumentEditorVolumeChanged(row: Int) {
        guard let cell = instrumentSettings.cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: 0))
            as? InstrumentsTableViewCell else { return }
        cell.updateVolume()
    }

    /**
     Pan setting changed in the editor. Update the cell.
     
     - parameter row: the row that changed
     */
    func instrumentEditorPanChanged(row: Int) {
        guard let cell = instrumentSettings.cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: 0))
            as? InstrumentsTableViewCell else { return }
        cell.updateVolume()
    }
    
    /**
     Mute setting changed in the editor. Update the cell.
     
     - parameter row: the row that changed
     */
    func instrumentEditorMuteChanged(row: Int) {
        guard let cell = instrumentSettings.cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: 0))
            as? InstrumentsTableViewCell else { return }
        cell.updateVolume()
    }

    /**
     Octave setting changed in the editor. Update the cell.
     
     - parameter row: the row that changed
     */
    func instrumentEditorOctaveChanged(row: Int) {
        guard let cell = instrumentSettings.cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: 0))
            as? InstrumentsTableViewCell else { return }
        cell.updateTitle()
    }

    /**
     Solo setting changed in the editor. Update the cell.
     
     - parameter row: the row that changed
     - parameter soloing: true if solo enabled, false otherwise
     */
    func instrumentEditorSoloChanged(row: Int, soloing state: Bool) {
        let instrument = audioController.activeInstruments[row]
        audioController.activeInstruments.forEach { $0.solo(instrument, active: state) }
        instrumentSettings.visibleCells.forEach { ($0 as! InstrumentsTableViewCell).updateVolume() }
    }
}

// MARK: Instrument List Editing
extension InstrumentListViewController {

    /**
     Notification from table view that editing is complete.
     
     - parameter tableView: the table view
     - parameter commitEditingStyle: the editing style that is coming to an end
     - parameter indexPath: the index of the row being edited
     */
    func tableView(tableView: UITableView, commitEditingStyle: UITableViewCellEditingStyle, forRowAtIndexPath
        indexPath: NSIndexPath) {
        guard commitEditingStyle == .Delete else { return }
        
        // Remove the instrument from the model, then tell table view to remove the corresponding view
        //
        audioController.removeInstrument(indexPath.row)
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        
        // We can definitely add a new instrument now
        addButton?.enabled = true
        if audioController.activeInstruments.count == 1 {
            
            // We cannot do any more deletions
            //
            tableView.setEditing(false, animated: true)
            navigationItem.setRightBarButtonItems([addButton!], animated: true)
        }
    }

    /**
     Handle row movement by the user.
     
     - parameter tableView: the table view
     - parameter sourceIndexPath: the original location of the instrument
     - parameter destinationIndexPath: the new location of the instrument
     */
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath,
                   toIndexPath destinationIndexPath: NSIndexPath) {
        audioController.reorderInstrument(fromPos: sourceIndexPath.row, toPos: destinationIndexPath.row)

        // Swap source and destination index values
        //
        let cellFrom = tableView.cellForRowAtIndexPath(sourceIndexPath) as! InstrumentsTableViewCell
        let cellTo = tableView.cellForRowAtIndexPath(destinationIndexPath) as! InstrumentsTableViewCell
        cellFrom.updateInstrumentIndex(destinationIndexPath.row + 1)
        cellTo.updateInstrumentIndex(sourceIndexPath.row + 1)
    }

    /**
     Add an instrument. If there is a selected row, insert the new instrument before it. Otherwise, append to the end
     of the list.
     
     - parameter sender: the button
     */
    @IBAction func addInstrument(sender: UIBarButtonItem) {
        let indexPath = instrumentSettings.indexPathForSelectedRow ??
            NSIndexPath(forRow: audioController.activeInstruments.count, inSection: 0)
        guard audioController.addInstrument(indexPath.row) else { return }
        
        // Add a view for the new instrument, select it, and scroll view to make it visible
        //
        instrumentSettings.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        instrumentSettings.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .None)
        instrumentSettings.scrollToRowAtIndexPath(indexPath, atScrollPosition: .None, animated: true)

        // Update buttons based on active instrument count
        //
        if audioController.activeInstruments.count == audioController.maxSamplerCount {
            addButton?.enabled = false
        }
        else if audioController.activeInstruments.count == 2 {
            editButton?.enabled = true
        }
    }

    /**
     Toggle edit state of the instruments view.
     
     - parameter sender: the button
     */
    @IBAction func editInstruments(sender: UIBarButtonItem) {
        if instrumentSettings.editing {
            instrumentSettings.setEditing(false, animated: true)
            navigationItem.setRightBarButtonItems(normalRightButtons, animated: true)
        }
        else {
            instrumentSettings.setEditing(true, animated: true)
            navigationItem.setRightBarButtonItems(editingRightButtons, animated: true)
        }
    }
}
