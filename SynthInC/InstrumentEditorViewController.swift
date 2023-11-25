// Copyright © 2016 Brad Howes. All rights reserved.

import Foundation
import UIKit
import ASValueTrackingSlider
import SwiftMIDI

/**
 Dismissed reason

 - Done: user pressed the Done button
 - Cancel: user pressed the Cancel button
 */
enum InstrumentEditorDismissedReason {
  case cancel, done
}

/**
 @brief Delegate protocol for the InstrumentEditorViewController.
 */
protocol InstrumentEditorViewControllerDelegate : NSObjectProtocol {

  /**
   Notify the delegate when the patch select view is dismissed.

   - parameter row: the UITableView row associated with the edit
   - parameter reason: the `PatchSelectDismissedReason` value
   */
  func instrumentEditorDismissed(_ row: Int, reason: InstrumentEditorDismissedReason)
  func instrumentEditorPatchChanged(_ row: Int)
  func instrumentEditorVolumeChanged(_ row: Int)
  func instrumentEditorPanChanged(_ row: Int)
  func instrumentEditorMuteChanged(_ row: Int)
  func instrumentEditorOctaveChanged(_ row: Int)
  func instrumentEditorSoloChanged(_ row: Int, soloing: Bool)
}

/// View controller for the instrument editing view.
final class InstrumentEditorViewController: UIViewController {

  @IBOutlet weak var doneButton: UIBarButtonItem!
  @IBOutlet weak var cancelButton: UIBarButtonItem!
  @IBOutlet weak var picker: UIPickerView!
  @IBOutlet weak var panSlider: ASValueTrackingSlider!
  @IBOutlet weak var volumeSlider: ASValueTrackingSlider!
  @IBOutlet weak var octaveChange: UIStepper!
  @IBOutlet weak var octaveLabel: UILabel!
  @IBOutlet weak var soloButton: UIButton!
  @IBOutlet weak var muteButton: UIButton!

  weak var delegate: InstrumentEditorViewControllerDelegate?
  var instrument: Instrument? {
    didSet {
      guard let instrument = self.instrument else { return }
      self.instrumentConfig = instrument.encodeConfiguration()
      self.soundFontIndex = SoundFont.indexForName(instrument.patch.soundFont.name)
      self.patchIndex = instrument.patch.soundFont.findPatchIndex(instrument.patch.name) ?? 0
    }
  }
  var instrumentRow: Int = -1
  var instrumentConfig: Data!

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

    octaveChange.minimumValue = -2.0
    octaveChange.maximumValue =  2.0
    octaveChange.stepValue = 1.0
    octaveChange.value = 0.0

    volumeSlider.minimumValue = 0.0
    volumeSlider.maximumValue = 100.0

    let thumb = UIImage(named: "Slider")
    volumeSlider.setThumbImage(thumb, for: UIControl.State())
    volumeSlider.setThumbImage(thumb, for: .selected)
    volumeSlider.setThumbImage(thumb, for: .highlighted)
    volumeSlider.popUpViewColor = UIColor.init(red: 12/255.0, green: 102/255.0, blue: 223/255.0, alpha: 1.0)

    panSlider.minimumValue = -1.0
    panSlider.maximumValue = 1.0
    panSlider.setThumbImage(thumb, for: UIControl.State())
    panSlider.setThumbImage(thumb, for: .selected)
    panSlider.setThumbImage(thumb, for: .highlighted)
    panSlider.popUpViewColor = UIColor.init(red: 12/255.0, green: 102/255.0, blue: 223/255.0, alpha: 1.0)

    muteButton.setImage(UIImage(named: "Mute On"), for: .highlighted)
    soloButton.setImage(UIImage(named: "Solo On"), for: .highlighted)

    let maxNameWidth = SoundFont.maxNameWidth * 2.0 + 40.0 // Gah! Why this?!
    preferredContentSize.width = min(UIApplication.shared.windows.first!.frame.width, maxNameWidth)

    super.viewDidLoad()
  }

  /**
   Tell the OS that we have a dark background

   - returns: UIStatusBarStyle.LigthContent
   */
  override var preferredStatusBarStyle : UIStatusBarStyle {
    return .lightContent
  }
}

// MARK: - View Management
extension InstrumentEditorViewController {

  /**
   Update view with current Instrument settings just before view is shown to user.

   - parameter animated: true if the view is being animated while it is shown
   */
  override func viewWillAppear(_ animated: Bool) {
    precondition(instrument != nil)
    guard let instrument = self.instrument else { return }

    picker.selectRow(soundFontIndex, inComponent: 0, animated: false)
    picker.reloadComponent(1)
    picker.selectRow(patchIndex, inComponent: 1, animated: false)

    octaveChange.value = Double(instrument.octave)
    updateOctaveText()

    volumeSlider.value = instrument.volume * 100.0
    panSlider.value = instrument.pan

    updateSoloImage(false)
    updateMuteImage(instrument.muted)

    title = instrument.patch.name

    super.viewWillAppear(animated)
  }

  /**
   Notification that the view is being dismissed. Stop any solo activity, and if restore the original Instrument
   settings if not accepted by the user.

   - parameter animated: true if the view will disappear in animated fashion
   */
  override func viewWillDisappear(_ animated: Bool) {
    if let instrument = self.instrument {
      stopSolo()
      _ = instrument.configure(with: instrumentConfig)
      self.instrument = nil
      delegate?.instrumentEditorDismissed(instrumentRow, reason: .cancel)
    }
    super.viewWillDisappear(animated)
  }

  /**
   Update solo button based on given value.

   - parameter value: the boolean value to use
   */
  fileprivate func updateSoloImage(_ value: Bool) {
    soloButton.setImage(UIImage(named: value ? "Solo On" : "Solo Off"), for: UIControl.State())
  }

  /**
   Update mute button based on given value.

   - parameter value: the boolean value to use
   */
  fileprivate func updateMuteImage(_ value: Bool) {
    muteButton.setImage(UIImage(named: value ? "Mute On" : "Mute Off"), for: UIControl.State())
  }

  /**
   Update the octave label with the current value setting.
   */
  fileprivate func updateOctaveText() {
    guard let instrument = instrument else { return }
    let value = Int(instrument.octave)
    octaveLabel.text = "\(value > 0 ? "+" : "")\(Int(value))"
  }

  /**
   Stop any `solo` activity that was in place.
   */
  fileprivate func stopSolo() {
    if instrument?.solo == true {
      delegate?.instrumentEditorSoloChanged(instrumentRow, soloing: false)
    }
  }
}

// MARK: - Instrument Editing
extension InstrumentEditorViewController {

  /**
   Set the instrument that will be edited.

   - parameter instrument: Instrument instance to modify
   - parameter row: the row index in the instruments table view in the main view
   */
  func editInstrument(_ instrument: Instrument, row: Int) {
    print("editing instrument \(row)")
    self.instrument = instrument
    self.instrumentRow = row
    self.instrumentConfig = instrument.encodeConfiguration()
  }
}

// MARK: - UIPickerView Support
extension InstrumentEditorViewController: UIPickerViewDelegate, UIPickerViewDataSource {

  /**
   Provide patch picker view with number of elements in a component. The first component is the sound font list, and
   the second is the list of patches available in the sound font.

   - parameter pickerView: the view asking for data
   - parameter component: the component in the view being asked about

   - returns: number of elements in the component
   */
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return component == 0 ? SoundFont.keys.count : SoundFont.getByIndex(soundFontIndex).patches.count
  }

  /**
   Provide patch picker with the item text to show. The first component is the sound font list, and the second is the
   list of patches availabe in the selected sound font.

   - parameter pickerView: the view asking for data
   - parameter row: the row of the item to return
   - parameter component: the component of the item to return

   - returns: text of the item
   */
  func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int)
  -> NSAttributedString? {
    var text: String
    if component == 0 {
      text = SoundFont.keys[row]
    }
    else {
      let soundFont = SoundFont.getByIndex(soundFontIndex)
      precondition(row < soundFont.patches.count)
      text = soundFont.patches[row].name
    }

    return NSAttributedString(string: text, attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
  }

  /**
   Notification that the user picked an element of a component. If a new sound font was picked, load the patches into
   the second component. Otherwise, apply the patch to the edited instrument.

   - parameter pickerView: the picker view that changed
   - parameter row: the row which is now current
   - parameter component: the component that changed (0 = sound font; 1 = patch)
   */
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
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

    delegate?.instrumentEditorPatchChanged(instrumentRow)
  }

  /**
   Obtain the number of components in the picker.

   - parameter pickerView: the picker view asking for data

   - returns: 2
   */
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 2
  }

  //    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
  //        if component == 0 {
  //            return SoundFont.maxWidth
  //        }
  //        else {
  //            return SoundFont.getByIndex(soundFontIndex).maxPatchWidth
  //        }
  //    }
}

// MARK: - Control Activity
extension InstrumentEditorViewController {

  /**
   Handle "Done" button activity. Save the instrument's configuration and announce the dismissal.

   - parameter sender: the button
   */
  @IBAction func donePressed(_ sender: UIBarButtonItem) {
    stopSolo()
    self.instrument = nil
    delegate?.instrumentEditorDismissed(instrumentRow, reason: .done)
  }

  /**
   Handle "Cancel" button activity. Restore the instrument's configuration and announce the dismissal.

   - parameter sender: the button
   */
  @IBAction func cancelPressed(_ sender: UIBarButtonItem) {
    stopSolo()
    _ = instrument?.configure(with: instrumentConfig)
    self.instrument = nil
    delegate?.instrumentEditorDismissed(instrumentRow, reason: .cancel)
  }

  /**
   Handle changes to the instrument octave shift value.

   - parameter sender: the stepper with the current octave shift value
   */
  @IBAction func changeOctave(_ sender: UIStepper) {
    instrument?.octave = Int(sender.value)
    updateOctaveText()
    delegate?.instrumentEditorOctaveChanged(instrumentRow)
  }

  /**
   Handle volume changes. Update the instrument's volume setting.

   - parameter sender: the volume slider
   */
  @IBAction func changeVolume(_ sender: UISlider) {
    instrument?.volume = sender.value / 100.0
    delegate?.instrumentEditorVolumeChanged(instrumentRow)
  }

  /**
   Handle pan changes. Update the instrument's pan setting.

   - parameter sender: the pan slider
   */
  @IBAction func changePan(_ sender: UISlider) {
    instrument?.pan = sender.value
    delegate?.instrumentEditorPanChanged(instrumentRow)
  }

  /**
   Handle "Solo" button toggle

   - parameter sender: the button
   */
  @IBAction func soloInstrument(_ sender: UIButton) {
    guard let instrument = instrument else { return }
    if !instrument.solo && instrument.muted {
      muteInstrument(sender)
    }
    updateSoloImage(!instrument.solo)
    delegate?.instrumentEditorSoloChanged(instrumentRow, soloing: !instrument.solo)
  }

  /**
   Handle the "Mute" button toggle. Update the instrument's mute setting.

   - parameter sender: the button
   */
  @IBAction func muteInstrument(_ sender: UIButton) {
    guard let instrument = instrument else { return }
    instrument.muted = !instrument.muted
    updateMuteImage(instrument.muted)
    delegate?.instrumentEditorMuteChanged(instrumentRow)
  }
}
