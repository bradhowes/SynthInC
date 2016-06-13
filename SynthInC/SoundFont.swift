// SoundFonts.swift
// SynthInC
//
// Created by Brad Howes
// Copyright (c) 2016 Brad Howes. All rights reserved.

import Foundation

/**
 Representation of a sound font library. NOTE: all sound font files must have 'sf2' extension.
 */
class SoundFont {

    /**
     Mapping of registered sound fonts. Add additional sound font entries here to make them available to the
     SoundFont code.
     */
    static let library: [String:SoundFont] = [
// -BEGIN-
FluidR3GMSoundFont.name: FluidR3GMSoundFont,
FreeFontGMVer32SoundFont.name: FreeFontGMVer32SoundFont,
GeneralUserGSMuseScoreversion1442SoundFont.name: GeneralUserGSMuseScoreversion1442SoundFont,
RolandNicePiano.name: RolandNicePiano,
// -END-
    ]

    /**
     Array of registered sound font names sorted in alphabetical order. Generated from `library` entries.
     */
    static let keys: [String] = library.keys.sort()
    static let patchCount: Int = library.reduce(0) { $0 + $1.1.patches.count }

    /**
     Obtain a random patch from all registered sound fonts.
     - returns: radom Patch object
     */
    static func randomPatch() -> Patch {
        var pos = RandomUniform.sharedInstance.uniform(0, upper: patchCount)
        let soundFont = library.filter {
            (k, sf) -> Bool in
            let result = (pos >= 0 && pos < sf.patches.count)
            if pos >= 0 { pos -= sf.patches.count }
            return result
        }.last!.1

        let index = pos + soundFont.patches.count
        precondition(index >= 0 && index < soundFont.patches.count)
        return soundFont.patches[index]
    }

    /**
     Obtain a SoundFont using an index into the `keys` name array. If the index is out-of-bounds this will return the
     FreeFont sound font.
     - parameter index: the key to use
     - returns: found SoundFont object
     */
    static func getByIndex(index: Int) -> SoundFont {
        guard index >= 0 && index < keys.count else { return SoundFont.library[SoundFont.keys[0]]! }
        let key = keys[index]
        return library[key]!
    }

    /**
     Obtain the index in `keys` for the given sound font name. If not found, return 0
     - parameter name: the name to look for
     - returns: found index or zero
     */
    static func indexForName(name: String) -> Int {
        return keys.indexOf(name) ?? 0
    }

    let soundFontExtension = "sf2"

    /// Presentation name of the sound font
    let name: String

    /// The file name of the sound font (sans extension)
    let fileName: String

    ///  The resolved URL for the sound font
    let fileURL: NSURL

    /// The collection of Patches found in the sound font
    var patches: [Patch]

    let dbGain: Float32

    /**
     Initialize new SoundFont instance.
     
     - parameter name: the display name for the sound font
     - parameter fileName: the file name of the sound font in the application bundle
     - parameter patches: the array of Patch objects for the sound font
     */
    init(_ name: String, fileName: String, _ patches: [Patch], _ dbGain: Float32 = 0.0 ) {
        self.name = name
        self.fileName = fileName
        self.fileURL = NSBundle.mainBundle().URLForResource(fileName, withExtension: soundFontExtension)!
        self.patches = patches
        self.dbGain = dbGain
        patches.forEach { $0.soundFont = self }
    }

    /**
     Locate a patch in the SoundFont using a display name.

     - parameter name: the display name to search for

     - returns: found Patch or nil
     */
    func findPatch(name: String) -> Patch? {
        guard let found = findPatchIndex(name) else { return nil }
        return patches[found]
    }

    /**
     Obtain the index to a Patch with a given name.
     
     - parameter name: the display name to search for
     
     - returns: index of found object or nil if not found
     */
    func findPatchIndex(name: String) -> Int? {
        return patches.indexOf({ return $0.name == name })
    }
}

/**
 Representation of a patch in a sound font.
 */
class Patch {
    
    /// Display name for the patch
    let name: String
    /// Bank number where the patch resides in the sound font
    let bank: Int
    /// Program patch number where the patch resides in the sound font
    let patch: Int
    /// Reference to the SoundFont parent
    weak var soundFont: SoundFont?

    /**
     Initialize Patch instance.
     
     - parameter name: the diplay name for the patch
     - parameter bank: the bank where the patch resides
     - parameter patch: the program ID of the patch in the sound font
     */
    init(_ name: String, _ bank: Int, _ patch: Int) {
        self.name = name
        self.bank = bank
        self.patch = patch
        self.soundFont = nil
    }
}
