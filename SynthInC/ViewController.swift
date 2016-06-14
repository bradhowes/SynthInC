// ViewController.swift
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
class ViewController: UIViewController {
    
    enum BarButtonItems: Int {
        case Add = 0, Edit, Done
    }

    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var myNavigationItem: UINavigationItem!
    
    /**
     Button to show the in-app settings.
     */
    @IBOutlet weak var settings: UIBarButtonItem!
    
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
     The SoundGenerator instance that manages all aspects of the music generation and performance.
     */
    lazy var gen: AudioController = {
        let gen = AudioController()
        return gen
    }()
    
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
     On-demand IASKAppSettingsViewController instance.
     */
    lazy var settingsViewController: IASKAppSettingsViewController = {
        let settingsViewController = IASKAppSettingsViewController()
        settingsViewController.delegate = self
        return settingsViewController
    }()

    /**
     On-demand PatchSelectViewController instance.
     */
    lazy var patchSelectViewController: PatchSelectViewController = {
        let patchSelectViewController = PatchSelectViewController()
        patchSelectViewController.delegate = self
        patchSelectViewController.modalPresentationStyle = .Popover
        return patchSelectViewController
    }()

    /**
     Initialize and configure view after loading.
     */
    override func viewDidLoad() {
        super.viewDidLoad()

        instrumentSettings.delegate = self
        instrumentSettings.dataSource = self
        playbackPosition.minimumValue = 0.0
        playbackPosition.maximumValue = 1.0
        playbackPosition.value = 0.0

        playbackPosition.setThumbImage(UIImage(named:"Slider"), forState: .Normal)
        playbackPosition.setThumbImage(UIImage(named:"Slider"), forState: .Selected)
        playbackPosition.setThumbImage(UIImage(named:"Slider"), forState: .Highlighted)
        playbackPosition.popUpViewColor = UIColor.init(red: 12/255.0, green: 102/255.0, blue: 223/255.0, alpha: 1.0)
        playbackPosition.dataSource = self

        setNeedsStatusBarAppearanceUpdate()

        addButton.enabled = true
        editButton.enabled = true
        doneButton.enabled = true

        normalRightButtons = [addButton, editButton]
        editingRightButtons = [doneButton]

        myNavigationItem.setRightBarButtonItems(normalRightButtons, animated: false)

        updateTitle()
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
    
    func updateTitle() {
        let count = gen.activeInstruments.count
        let plural = count == 1 ? "" : "s"
        myNavigationItem.title = "\(gen.activeInstruments.count) Instrument\(plural)"
    }
    
    override func showDetailViewController(vc: UIViewController, sender: AnyObject?) {
        super.showDetailViewController(vc, sender: sender)
    }
}

// MARK: Settings
extension ViewController: IASKSettingsDelegate, UIPopoverPresentationControllerDelegate {

    /**
     IASKAppSettingsDelegate method which signals when the settings view is no longer on the screen.
     - parameter sender: the settings controller that was dismissed
     */
    func settingsViewControllerDidEnd(sender: IASKAppSettingsViewController!) {
        self.dismissViewControllerAnimated(true, completion: nil)
        normalRightButtons.forEach { $0.enabled = true }
        showingSettings = false
    }

    func popoverPresentationControllerDidDismissPopover(popoverPresentationController: UIPopoverPresentationController) {
        normalRightButtons.forEach { $0.enabled = true }
        showingSettings = false
    }
    
    /**
     Show the in-app settings view.
     - parameter sender: the button that invoked this method
     */
    @IBAction func showSettings(sender: UIBarButtonItem) {
        let idiom: UIUserInterfaceIdiom = UIDevice.currentDevice().userInterfaceIdiom

        if showingSettings {
            self.dismissViewControllerAnimated(false, completion: nil)
        }

        if idiom == .Pad {
            settingsViewController.modalPresentationStyle = .Popover;
            settingsViewController.popoverPresentationController?.barButtonItem = settings
            settingsViewController.popoverPresentationController?.delegate = self
            presentViewController(settingsViewController, animated:true, completion:nil)
        }
        else {
            settingsViewController.showDoneButton = true
            let aNavController = UINavigationController(rootViewController: settingsViewController)
            aNavController.modalPresentationStyle = .PageSheet;
            presentViewController(aNavController, animated:true, completion:nil)
        }

        normalRightButtons.forEach { $0.enabled = false }
        showingSettings = true
    }
}

// MARK: Playback control
extension ViewController: ASValueTrackingSliderDataSource {

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
        updateTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(updatePlaybackInfo),
                                                             userInfo: nil, repeats: true)
    }
    
    /**
     Stop update timer.
     */
    private func endUpdateTimer() {
        updateTimer?.invalidate()
    }

    /**
     Update instruments view and slider to reflect the current position of playing music.
     */
    func updatePlaybackInfo() {
        let length = gen.sequenceLength
        currentPosition = gen.getPlaybackPosition()
        if currentPosition >= length {
            gen.stop()
            stoppedPlaying()
            gen.setPlaybackPosition(0.0)
            currentPosition = 0.0
        }
        
        if !sliderInUse {
            playbackPosition.setValue(Float(currentPosition / Double(length)), animated: false)
        }

        // Need to protect the selection
        let savedSelection = instrumentSettings.indexPathForSelectedRow
        instrumentSettings.reloadData()
        instrumentSettings.selectRowAtIndexPath(savedSelection, animated: false, scrollPosition: .None)
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
        let pos = Double(value) * gen.sequenceLength
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
        let when: MusicTimeStamp = Double(sender.value) * gen.sequenceLength
        gen.setPlaybackPosition(when)
        updatePlaybackInfo()
        sliderInUse = false
    }

    /**
     Notification that the user is manipulating the playback slider. Just set flag that this is the case so we won't
     change it during updates.
     
     - parameter sender: the UISlider being manipulated
     */
    @IBAction func beginChangePlaybackPosition(sender: UISlider) {
        sliderInUse = true
    }

    /**
     User stopped or started playback. Update button to reflect what operation will happen with a subsequent tap.
     Command SoundGenerator to stop or start playback.
     - parameter sender: the button that was tapped
     */
    @IBAction func playStop(sender: UIButton) {
        if gen.playOrStop() == .Play {
            startedPlaying()
        }
        else {
            stoppedPlaying()
        }
    }
}

// MARK: Regenerate
extension ViewController {

    /**
     Generate a new sequence of "In C" phrases.
     
     - parameter sender: button that was touched
     */
    @IBAction func regenerate(sender: UIButton) {
        if gen.createMusicSequence() {
            stoppedPlaying()
            playbackPosition.value = 0.0
            instrumentSettings.reloadData()
        }
    }
}

// MARK: UITableView
extension ViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        guard let currentRow = tableView.indexPathForSelectedRow?.row else { return indexPath }
        let newRow = indexPath.row
        if currentRow == newRow {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            return nil
        }
        return indexPath
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print(indexPath.row)
    }

    /**
     Obtain a UITableViewCell to use for an instrument, and fill it in with the instrument's values.
     - parameter tableView: the UITableView to work with
     - parameter indexPath: the row of the table to update
     - returns: UITableViewCell
     */
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let identifier = "InstrumentCell" // !!! This must match prototype in Main.storyboard !!!
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier) as! InstrumentsTableViewCell

        // Row shows the patch name the instrument is using, and the current sequence it is playing
        //
        let instrument = gen.activeInstruments[indexPath.row]

        cell.instrumentIndex?.text = "\(indexPath.row + 1)"

        let octaveTag: String
        if instrument.octave > 0 {
            octaveTag = " (+\(instrument.octave))"
        }
        else if instrument.octave < 0 {
            octaveTag = " (\(instrument.octave))"
        }
        else {
            octaveTag = ""
        }

        cell.patchName?.text = instrument.patch.name + octaveTag
        cell.soundFontName?.text = instrument.patch.soundFont?.name
        
        let phrase = instrument.getSectionPlaying(currentPosition)
        cell.phrase?.text = phrase >= 0 ? "P\(phrase)" : ""

        cell.volumeLevel.muted = instrument.muted
        cell.volumeLevel.volume = instrument.volume
        cell.volumeLevel.pan = instrument.pan

        return cell
    }

    /**
     Obtain the number of rows to display in the instruments view
     - parameter tableView: the UITableView to work with
     - parameter numberOfRowsInSection: which section to report on (only one in our view)
     - returns: number of instruments active in music playback
     */
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return gen.activeInstruments.count
    }

    /**
     Provide instruments table view with a cell containing the appropriate row data
     
     - parameter tableView: the table view to work with
     - parameter indexPath: the row being requested
     */
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        guard let cell = tableView.cellForRowAtIndexPath(indexPath) else { return }
        tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: .None)
        let psvc = patchSelectViewController
        psvc.editInstrument(gen.activeInstruments[indexPath.row], row: indexPath.row)
        if let popover = psvc.popoverPresentationController {
            popover.sourceView = cell
            popover.sourceRect = cell.bounds
            presentViewController(psvc, animated: true, completion: nil)
        }
    }
    
    func tableView(tableView: UITableView, didEndEditingRowAtIndexPath indexPath: NSIndexPath) {
    }
}

// MARK: Instrument configuration
extension ViewController: PatchSelectViewControllerDelegate {

    /**
     `PatchSelectViewControllerDelegate` method invoked when the patch picker is no longer showing. Update the 
     instrument's row in case values changed.
     */
    func patchSelectDismissed(row: Int, reason: PatchSelectDismissedReason) {
        self.dismissViewControllerAnimated(true, completion: nil)
        
        // Need to protect the selection
        let savedSelection = instrumentSettings.indexPathForSelectedRow
        instrumentSettings.reloadRowsAtIndexPaths([NSIndexPath(forRow: row, inSection: 0)],
                                                  withRowAnimation: .Automatic)
        instrumentSettings.selectRowAtIndexPath(savedSelection, animated: false, scrollPosition: .None)
        
        if reason == .Done {
            
        }
    }
}

// MARK: Cell Editing
extension ViewController {

    func tableView(tableView: UITableView, commitEditingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if commitEditingStyle == .Delete {
            
            instrumentSettings.beginUpdates()
            gen.removeInstrument(indexPath.row)
            instrumentSettings.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            instrumentSettings.endUpdates()

            updateTitle()
            updatePlaybackInfo()

            addButton?.enabled = true
            if gen.activeInstruments.count == 1 {
                tableView.setEditing(false, animated: true)
                myNavigationItem.setRightBarButtonItems([addButton!], animated: true)
                settings.enabled = true
            }
        }
    }

    @IBAction func addInstrument(sender: UIBarButtonItem) {
        print("addInstrument")
        instrumentSettings.beginUpdates()
        let selection = instrumentSettings.indexPathForSelectedRow ?? NSIndexPath(forRow: gen.activeInstruments.count,
                                                                                  inSection: 0)
        if gen.addInstrument(selection.row) {
            instrumentSettings.insertRowsAtIndexPaths([selection], withRowAnimation: .Automatic)
            updateTitle()
            updatePlaybackInfo()
            if gen.activeInstruments.count == gen.maxSamplerCount {
                addButton?.enabled = false
            }
            else if gen.activeInstruments.count == 2 {
                editButton?.enabled = true
            }
        }

        instrumentSettings.endUpdates()
    }

    @IBAction func editInstruments(sender: UIBarButtonItem) {
        print("editInstruments")
        if instrumentSettings.editing {
            instrumentSettings.setEditing(false, animated: true)
            myNavigationItem.setRightBarButtonItems(normalRightButtons, animated: true)
            settings.enabled = true
        }
        else {
            instrumentSettings.setEditing(true, animated: true)
            myNavigationItem.setRightBarButtonItems(editingRightButtons, animated: true)
            settings.enabled = false
        }
    }

}
