// PatchSelect.swift
// SynthInC
//
// Created by Brad Howes
// Copyright (c) 2016 Brad Howes. All rights reserved.

import Foundation
import UIKit

/**
 Dismissed reason
 
 - Done: user pressed the Done button
 - Cancel: user pressed the Cancel button
 */
enum PatchSelectDismissedReason {
    case Done, Cancel
}

/**
 @brief Delegate protocol for the PatchSelectViewController.
 */
protocol PatchSelectViewControllerDelegate : NSObjectProtocol {

    /**
     Notify the delegate when the patch select view is dismissed.
     
     - parameter row: the UITableView row associated with the edit
     - parameter reason: the `PatchSelectDismissedReason` value
     */
    func patchSelectDismissed(row: Int, reason: PatchSelectDismissedReason)
}

/// View controller for the instrument editing view.
class PatchSelectViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var picker: UIPickerView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var panSlider: ASValueTrackingSlider!
    @IBOutlet weak var volumeSlider: ASValueTrackingSlider!
    @IBOutlet weak var soloSwitch: UISwitch!
    @IBOutlet weak var octaveChange: UIStepper!
    @IBOutlet weak var octaveLabel: UILabel!
    @IBOutlet weak var instrumentTitle: UILabel!

    weak var delegate: PatchSelectViewControllerDelegate?
    var instrument: Instrument?
    var instrumentRow: Int = -1
    var originalPatch: Patch?
    var originalOctave = 0
    var originalVolume: Float = 1.0
    var originalPan: Float = 0.0
    var soundFontIndex = 0
    var patchIndex = 0

    /**
     Create new instance and its associated view from the PatchSelectView nib.
     */
    convenience init() {
        self.init(nibName: "PatchSelectView", bundle: nil)
    }

    /**
     Finish setting up the view after loading.
     */
    override func viewDidLoad() {
        picker.delegate = self
        picker.dataSource = self
        UIPickerView.appearance().backgroundColor = UIColor.blackColor()

        octaveChange.minimumValue = -2.0
        octaveChange.maximumValue =  2.0
        octaveChange.stepValue = 1.0
        octaveChange.value = 0.0

        volumeSlider.minimumValue = 0.0
        volumeSlider.maximumValue = 100.0
        let thumb = UIImage(named: "Slider")
        volumeSlider.setThumbImage(thumb, forState: .Normal)
        volumeSlider.setThumbImage(thumb, forState: .Selected)
        volumeSlider.setThumbImage(thumb, forState: .Highlighted)
        volumeSlider.popUpViewColor = UIColor.init(red: 12/255.0, green: 102/255.0, blue: 223/255.0, alpha: 1.0)

        panSlider.minimumValue = -1.0
        panSlider.maximumValue = 1.0
        panSlider.setThumbImage(thumb, forState: .Normal)
        panSlider.setThumbImage(thumb, forState: .Selected)
        panSlider.setThumbImage(thumb, forState: .Highlighted)
        panSlider.popUpViewColor = UIColor.init(red: 12/255.0, green: 102/255.0, blue: 223/255.0, alpha: 1.0)
    }

    /**
     Tell the OS that we have a dark background
     
     - returns: UIStatusBarStyle.LigthContent
     */
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    /**
     Set the instrument that will be edited.
     
     - parameter instrument: Instrument instance to modify
     - parameter row: the row index in the instruments table view in the main view
     */
    func editInstrument(instrument: Instrument, row: Int) {
        self.instrument = instrument
        self.instrumentRow = row
        
        // Record current Instrument settings in case we need to restore them when user touches "Cancel"
        //
        originalPatch = instrument.patch
        originalOctave = instrument.octave
        originalPan = instrument.pan
        originalVolume = instrument.volume
        soundFontIndex = SoundFont.indexForName(originalPatch!.soundFont!.name)
        patchIndex = originalPatch!.soundFont!.findPatchIndex(originalPatch!.name)!
    }

    /**
     Update view with current Instrument settings just before view is shown to user.

     - parameter animated: true if the view is being animated while it is shown
     */
    override func viewWillAppear(animated: Bool) {
        precondition(originalPatch != nil && instrument != nil)

        instrumentTitle.text = "Instrument \(instrumentRow + 1)"

        picker.selectRow(soundFontIndex, inComponent: 0, animated: false)
        picker.reloadComponent(1)
        picker.selectRow(patchIndex, inComponent: 1, animated: false)

        octaveChange.value = Double(originalOctave)
        octaveLabel.text = "Octave \(originalOctave)"

        volumeSlider.value = originalVolume * 100.0
        panSlider.value = originalPan

        soloSwitch.on = false
        super.viewWillAppear(animated)
    }

    /**
     Restore the Instrument instance settings to original values.
     */
    func restoreInstrument() {
        guard let instrument = self.instrument else { return }
        instrument.patch = originalPatch!
        instrument.volume = originalVolume
        instrument.octave = originalOctave
        self.instrument = nil
    }

    /**
     Notification that the view is being dismissed. Stop any solo activity, and if restore the original Instrument
     settings if not accepted by the user.
     
     - parameter animated: true if the view will disappear in animated fashion
     */
    override func viewWillDisappear(animated: Bool) {
        stopSolo()
        restoreInstrument()
        super.viewWillDisappear(animated)
    }

    /**
     Provide patch picker view with number of elements in a component. The first component is the sound font list, and
     the second is the list of patches available in the sound font.
     
     - parameter pickerView: the view asking for data
     - parameter component: the component in the view being asked about
     
     - returns: number of elements in the component
     */
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return component == 0 ? SoundFont.keys.count : SoundFont.getByIndex(soundFontIndex).patches.count
    }
    
    func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int,
                    forComponent component: Int) -> NSAttributedString? {
        var text: String
        if component == 0 {
            text = SoundFont.keys[row]
        }
        else {
            let soundFont = SoundFont.getByIndex(soundFontIndex)
            precondition(row < soundFont.patches.count)
            text = soundFont.patches[row].name
        }

        return NSAttributedString(string: text, attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])
    }

    /**
     Notification that the user picked an element of a component. If a new sound font was picked, load the patches into
     the second component. Otherwise, apply the patch to the edited instrument.
     
     - parameter pickerView: the picker view that changed
     - parameter row: the row which is now current
     - parameter component: the component that changed (0 = sound font; 1 = patch)
     */
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 {
            soundFontIndex = row
            pickerView.reloadComponent(1)
            patchIndex = 0
            pickerView.selectRow(0, inComponent: 1, animated: false)
        }
        else {
            patchIndex = row
        }

        let soundFont = SoundFont.getByIndex(soundFontIndex)
        precondition(patchIndex >= 0 && patchIndex < soundFont.patches.count)
        let patch = soundFont.patches[patchIndex]
        instrument?.patch = patch
    }

    /**
     Obtain the number of components in the picker.
     
     - parameter pickerView: the picker view asking for data
     
     - returns: 2
     */
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 2
    }

    @IBAction func donePressed(sender: UIButton) {
        if let instrument = self.instrument {
            if instrument.pan != originalPan ||
                instrument.volume != originalVolume ||
                instrument.patch != originalPatch {
                instrument.saveSetup()
            }
            self.instrument = nil
        }
        delegate?.patchSelectDismissed(instrumentRow, reason: .Done)
    }

    @IBAction func cancelPressed(sender: UIButton) {
        precondition(originalPatch != nil)
        restoreInstrument()
        delegate?.patchSelectDismissed(instrumentRow, reason: .Cancel)
    }

    @IBAction func changeOctave(sender: UIStepper) {
        octaveLabel.text = "Octave \(Int(sender.value))"
        instrument?.octave = Int(sender.value)
    }

    @IBAction func changeVolume(sender: UISlider) {
        instrument?.volume = sender.value / 100.0
    }

    @IBAction func changePan(sender: UISlider) {
        instrument?.pan = sender.value
    }
    
    @IBAction func soloInstrument(sender: UISwitch) {
        precondition(instrument != nil)
        var userInfo: [NSObject:AnyObject] = [:]
        if sender.on {
            userInfo["instrument"] = instrument!
        }
        NSNotificationCenter.defaultCenter().postNotificationName(kSoloInstrumentNotificationKey, object: self,
                                                                  userInfo: userInfo)
    }

    func stopSolo() {
        let userInfo: [NSObject:AnyObject] = [:]
        NSNotificationCenter.defaultCenter().postNotificationName(kSoloInstrumentNotificationKey, object: self,
                                                                  userInfo: userInfo)
    }
}
