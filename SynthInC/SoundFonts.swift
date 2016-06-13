// SoundFonts.swift
// SynthInC
//
// Created by Brad Howes
// Copyright (c) 2016 Brad Howes. All rights reserved.

import Foundation

/**
 Representation of a sound font library. NOTE: all sound font files must have 'sf2' extension.
 */
class SoundFont: NSObject {

    /**
     Mapping of registered sound fonts. Add additional sound font entries here to make them available to the
     SoundFont code.
     */
    static let library: [String:SoundFont] = [
    // -INSERT_HERE-
        FreeFont.name: FreeFont.register(),
        GeneralUser.name: GeneralUser.register(),
        RolandPiano.name: RolandPiano.register(),
        FluidR3.name:FluidR3.register()
    ]

    /**
     Array of registered sound font names sorted in alphabetical order. Generated from `library` entries.
     */
    static var keys = library.keys.sort()
    static var patchCount = library.reduce(0) { $0 + $1.1.patches.count }

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
        guard index >= 0 && index < keys.count else { return FreeFont }
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

    /**
     Initialize new SoundFont instance.
     
     - parameter name: the display name for the sound font
     - parameter fileName: the file name of the sound font in the application bundle
     - parameter patches: the array of Patch objects for the sound font
     */
    init(_ name: String, fileName: String, _ patches:[Patch]) {
        self.name = name
        self.fileName = fileName
        self.patches = patches
        self.fileURL = NSBundle.mainBundle().URLForResource(fileName, withExtension: soundFontExtension)!
    }

    /**
     Link a SoundFont instance with its patches.

     - returns: self
     */
    func register() -> SoundFont {
        patches.forEach { $0.soundFont = self }
        return self
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
class Patch: NSObject {
    
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

/// Definition of the FreeFont sound font
let FreeFont = SoundFont("FreeFont", fileName: "FreeFont", [
    Patch("Piano 1", 0, 0),
    Patch("Piano 2", 0, 1),
    Patch("Piano 3", 0, 2),
    Patch("Honky-tonk", 0, 3),
    Patch("E.Piano 1", 0, 4),
    Patch("E.Piano 2", 0, 5),
    Patch("Harpsichord", 0, 6),
    Patch("Clav.", 0, 7),
    Patch("Celesta", 0, 8),
    Patch("Glockenspiel", 0, 9),
    Patch("Music Box", 0, 10),
    Patch("Vibraphone", 0, 11),
    Patch("Marimba", 0, 12),
    Patch("Xylophone", 0, 13),
    Patch("Tubular-bell", 0, 14),
    Patch("Santur", 0, 15),
    Patch("Organ 1", 0, 16),
    Patch("Organ 2", 0, 17),
    Patch("Organ 3", 0, 18),
    Patch("Church Org.1", 0, 19),
    Patch("Reed Organ", 0, 20),
    Patch("Accordion Fr", 0, 21),
    Patch("Harmonica", 0, 22),
    Patch("Bandoneon", 0, 23),
    Patch("Nylon-str.Gt", 0, 24),
    Patch("Steel-str.Gt", 0, 25),
    Patch("Jazz Gt.", 0, 26),
    Patch("Clean Gt.", 0, 27),
    Patch("Muted Gt.", 0, 28),
    Patch("Overdrive Gt", 0, 29),
    Patch("DistortionGt", 0, 30),
    Patch("Gt.Harmonics", 0, 31),
    Patch("Acoustic Bs.", 0, 32),
    Patch("Fingered Bs.", 0, 33),
    Patch("Picked Bs.", 0, 34),
    Patch("Fretless Bs.", 0, 35),
    Patch("Slap Bass 1", 0, 36),
    Patch("Slap Bass 2", 0, 37),
    Patch("Synth Bass 1", 0, 38),
    Patch("Synth Bass 2", 0, 39),
    Patch("Violin", 0, 40),
    Patch("Viola", 0, 41),
    Patch("Cello", 0, 42),
    Patch("Contrabass", 0, 43),
    Patch("Tremolo Str", 0, 44),
    Patch("PizzicatoStr", 0, 45),
    Patch("Harp", 0, 46),
    Patch("Timpani", 0, 47),
    Patch("Strings", 0, 48),
    Patch("Slow Strings", 0, 49),
    Patch("Syn.Strings1", 0, 50),
    Patch("Syn.Strings2", 0, 51),
    Patch("Choir Aahs", 0, 52),
    Patch("Voice Oohs", 0, 53),
    Patch("SynVox", 0, 54),
    Patch("OrchestraHit", 0, 55),
    Patch("Trumpet", 0, 56),
    Patch("Trombone", 0, 57),
    Patch("Tuba", 0, 58),
    Patch("MutedTrumpet", 0, 59),
    Patch("French Horns", 0, 60),
    Patch("Brass 1", 0, 61),
    Patch("Synth Brass1", 0, 62),
    Patch("Synth Brass2", 0, 63),
    Patch("Soprano Sax", 0, 64),
    Patch("Alto Sax", 0, 65),
    Patch("Tenor Sax", 0, 66),
    Patch("Baritone Sax", 0, 67),
    Patch("Oboe", 0, 68),
    Patch("English Horn", 0, 69),
    Patch("Bassoon", 0, 70),
    Patch("Clarinet", 0, 71),
    Patch("Piccolo", 0, 72),
    Patch("Flute", 0, 73),
    Patch("Recorder", 0, 74),
    Patch("Pan Flute", 0, 75),
    Patch("Bottle Blow", 0, 76),
    Patch("Shakuhachi", 0, 77),
    Patch("Whistle", 0, 78),
    Patch("Ocarina", 0, 79),
    Patch("Square Wave", 0, 80),
    Patch("Saw Wave", 0, 81),
    Patch("Syn.Calliope", 0, 82),
    Patch("Chiffer Lead", 0, 83),
    Patch("Charang", 0, 84),
    Patch("Solo Vox", 0, 85),
    Patch("5th Saw Wave", 0, 86),
    Patch("Bass & Lead", 0, 87),
    Patch("Fantasia", 0, 88),
    Patch("Warm Pad", 0, 89),
    Patch("Polysynth", 0, 90),
    Patch("Space Voice", 0, 91),
    Patch("Bowed Glass", 0, 92),
    Patch("Metal Pad", 0, 93),
    Patch("Halo Pad", 0, 94),
    Patch("Sweep Pad", 0, 95),
    Patch("Ice Rain", 0, 96),
    Patch("Soundtrack", 0, 97),
    Patch("Crystal", 0, 98),
    Patch("Atmosphere", 0, 99),
    Patch("Brightness", 0, 100),
    Patch("Goblin", 0, 101),
    Patch("Echo Drops", 0, 102),
    Patch("Star Theme", 0, 103),
    Patch("Sitar", 0, 104),
    Patch("Banjo", 0, 105),
    Patch("Shamisen", 0, 106),
    Patch("Koto", 0, 107),
    Patch("Kalimba", 0, 108),
    Patch("Bagpipe", 0, 109),
    Patch("Fiddle", 0, 110),
    Patch("Shanai", 0, 111),
    Patch("Tinkle Bell", 0, 112),
    Patch("Agogo", 0, 113),
    Patch("Steel Drums", 0, 114),
    Patch("Woodblock", 0, 115),
    Patch("Taiko", 0, 116),
    Patch("Melo. Tom 1", 0, 117),
    Patch("Synth Drum", 0, 118),
    Patch("Reverse Cym.", 0, 119),
    Patch("Gt.FretNoise", 0, 120),
    Patch("Breath Noise", 0, 121),
    Patch("Seashore", 0, 122),
    Patch("Bird", 0, 123),
    Patch("Telephone 1", 0, 124),
    Patch("Helicopter", 0, 125),
    Patch("Applause", 0, 126),
    Patch("Gun Shot", 0, 127),
    Patch("SynthBass101", 1, 38),
    Patch("Trombone 2", 1, 57),
    Patch("Fr.Horn 2", 1, 60),
    Patch("Square", 1, 80),
    Patch("Saw", 1, 81),
    Patch("Syn Mallet", 1, 98),
    Patch("Echo Bell", 1, 102),
    Patch("Sitar 2", 1, 104),
    Patch("Gt.Cut Noise", 1, 120),
    Patch("Fl.Key Click", 1, 121),
    Patch("Rain", 1, 122),
    Patch("Dog", 1, 123),
    Patch("Telephone 2", 1, 124),
    Patch("Car-Engine", 1, 125),
    Patch("Laughing", 1, 126),
    Patch("Machine Gun", 1, 127),
    Patch("Echo Pan", 2, 102),
    Patch("String Slap", 2, 120),
    Patch("Thunder", 2, 122),
    Patch("Horse-Gallop", 2, 123),
    Patch("DoorCreaking", 2, 124),
    Patch("Car-Stop", 2, 125),
    Patch("Screaming", 2, 126),
    Patch("Lasergun", 2, 127),
    Patch("Wind", 3, 122),
    Patch("Bird 2", 3, 123),
    Patch("Door", 3, 124),
    Patch("Car-Pass", 3, 125),
    Patch("Punch", 3, 126),
    Patch("Explosion", 3, 127),
    Patch("Stream", 4, 122),
    Patch("Scratch", 4, 124),
    Patch("Car-Crash", 4, 125),
    Patch("Heart Beat", 4, 126),
    Patch("Bubble", 5, 122),
    Patch("Wind Chimes", 5, 124),
    Patch("Siren", 5, 125),
    Patch("Footsteps", 5, 126),
    Patch("Train", 6, 125),
    Patch("Jetplane", 7, 125),
    Patch("Piano 1", 8, 0),
    Patch("Piano 2", 8, 1),
    Patch("Piano 3", 8, 2),
    Patch("Honky-tonk", 8, 3),
    Patch("Detuned EP 1", 8, 4),
    Patch("Detuned EP 2", 8, 5),
    Patch("Coupled Hps.", 8, 6),
    Patch("Vibraphone", 8, 11),
    Patch("Marimba", 8, 12),
    Patch("Church Bell", 8, 14),
    Patch("Detuned Or.1", 8, 16),
    Patch("Detuned Or.2", 8, 17),
    Patch("Church Org.2", 8, 19),
    Patch("Accordion It", 8, 21),
    Patch("Ukulele", 8, 24),
    Patch("12-str.Gt", 8, 25),
    Patch("Hawaiian Gt.", 8, 26),
    Patch("Chorus Gt.", 8, 27),
    Patch("Funk Gt.", 8, 28),
    Patch("Feedback Gt.", 8, 30),
    Patch("Gt. Feedback", 8, 31),
    Patch("Synth Bass 3", 8, 38),
    Patch("Synth Bass 4", 8, 39),
    Patch("Slow Violin", 8, 40),
    Patch("Orchestra", 8, 48),
    Patch("Syn.Strings3", 8, 50),
    Patch("Brass 2", 8, 61),
    Patch("Synth Brass3", 8, 62),
    Patch("Synth Brass4", 8, 63),
    Patch("Sine Wave", 8, 80),
    Patch("Doctor Solo", 8, 81),
    Patch("Taisho Koto", 8, 107),
    Patch("Castanets", 8, 115),
    Patch("Concert BD", 8, 116),
    Patch("Melo. Tom 2", 8, 117),
    Patch("808 Tom", 8, 118),
    Patch("Starship", 8, 125),
    Patch("Carillon", 9, 14),
    Patch("Elec Perc.", 9, 118),
    Patch("Burst Noise", 9, 125),
    Patch("Piano 1d", 16, 0),
    Patch("E.Piano 1v", 16, 4),
    Patch("E.Piano 2v", 16, 5),
    Patch("Harpsichord", 16, 6),
    Patch("60's Organ 1", 16, 16),
    Patch("Church Org.3", 16, 19),
    Patch("Nylon Gt.o", 16, 24),
    Patch("Mandolin", 16, 25),
    Patch("Funk Gt.2", 16, 28),
    Patch("Rubber Bass", 16, 39),
    Patch("AnalogBrass1", 16, 62),
    Patch("AnalogBrass2", 16, 63),
    Patch("60's E.Piano", 24, 4),
    Patch("Harpsi.o", 24, 6),
    Patch("Organ 4", 32, 16),
    Patch("Organ 5", 32, 17),
    Patch("Nylon Gt.2", 32, 24),
    Patch("Choir Aahs 2", 32, 52),
    Patch("Standard", 128, 0),
    Patch("Room", 128, 8),
    Patch("Power", 128, 16),
    Patch("Electronic", 128, 24),
    Patch("TR-808", 128, 25),
    Patch("Jazz", 128, 32),
    Patch("Brush", 128, 40),
    Patch("Orchestra", 128, 48),
    Patch("SFX", 128, 56)])

/// Definition of the GeneralUser GS MuseScore sound font
let GeneralUser = SoundFont("GeneralUser", fileName: "GeneralUser GS MuseScore v1.442", [
    Patch("Acoustic Grand Piano", 0, 0),
    Patch("Bright Acoustic Piano", 0, 1),
    Patch("Electric Grand Piano", 0, 2),
    Patch("Honky-tonk Piano", 0, 3),
    Patch("Electric Piano 1", 0, 4),
    Patch("Electric Piano 2", 0, 5),
    Patch("Harpsichord", 0, 6),
    Patch("Clavi", 0, 7),
    Patch("Celesta", 0, 8),
    Patch("Glockenspiel", 0, 9),
    Patch("Music Box", 0, 10),
    Patch("Vibraphone", 0, 11),
    Patch("Marimba", 0, 12),
    Patch("Xylophone", 0, 13),
    Patch("Tubular Bells", 0, 14),
    Patch("Dulcimer", 0, 15),
    Patch("Drawbar Organ", 0, 16),
    Patch("Percussive Organ", 0, 17),
    Patch("Rock Organ", 0, 18),
    Patch("ChurchPipe", 0, 19),
    Patch("Positive", 0, 20),
    Patch("Accordion", 0, 21),
    Patch("Harmonica", 0, 22),
    Patch("Tango Accordion", 0, 23),
    Patch("Classic Guitar", 0, 24),
    Patch("Acoustic Guitar", 0, 25),
    Patch("Jazz Guitar", 0, 26),
    Patch("Clean Guitar", 0, 27),
    Patch("Muted Guitar", 0, 28),
    Patch("Overdriven Guitar", 0, 29),
    Patch("Distortion Guitar", 0, 30),
    Patch("Guitar harmonics", 0, 31),
    Patch("JazzBass", 0, 32),
    Patch("DeepBass", 0, 33),
    Patch("PickBass", 0, 34),
    Patch("FretLess", 0, 35),
    Patch("SlapBass1", 0, 36),
    Patch("SlapBass2", 0, 37),
    Patch("SynthBass1", 0, 38),
    Patch("SynthBass2", 0, 39),
    Patch("Violin", 0, 40),
    Patch("Viola", 0, 41),
    Patch("Cello", 0, 42),
    Patch("ContraBass", 0, 43),
    Patch("TremoloStr", 0, 44),
    Patch("Pizzicato", 0, 45),
    Patch("Harp", 0, 46),
    Patch("Timpani", 0, 47),
    Patch("String Ensemble 1", 0, 48),
    Patch("String Ensemble 2", 0, 49),
    Patch("SynthStrings 1", 0, 50),
    Patch("SynthStrings 2", 0, 51),
    Patch("Choir", 0, 52),
    Patch("DooVoice", 0, 53),
    Patch("Voices", 0, 54),
    Patch("OrchHit", 0, 55),
    Patch("Trumpet", 0, 56),
    Patch("Trombone", 0, 57),
    Patch("Tuba", 0, 58),
    Patch("MutedTrumpet", 0, 59),
    Patch("FrenchHorn", 0, 60),
    Patch("Brass", 0, 61),
    Patch("SynBrass1", 0, 62),
    Patch("SynBrass2", 0, 63),
    Patch("SopranoSax", 0, 64),
    Patch("AltoSax", 0, 65),
    Patch("TenorSax", 0, 66),
    Patch("BariSax", 0, 67),
    Patch("Oboe", 0, 68),
    Patch("EnglishHorn", 0, 69),
    Patch("Bassoon", 0, 70),
    Patch("Clarinet", 0, 71),
    Patch("Piccolo", 0, 72),
    Patch("Flute", 0, 73),
    Patch("Recorder", 0, 74),
    Patch("PanFlute", 0, 75),
    Patch("Bottle", 0, 76),
    Patch("Shakuhachi", 0, 77),
    Patch("Whistle", 0, 78),
    Patch("Ocarina", 0, 79),
    Patch("SquareWave", 0, 80),
    Patch("SawWave", 0, 81),
    Patch("Calliope", 0, 82),
    Patch("SynChiff", 0, 83),
    Patch("Charang", 0, 84),
    Patch("AirChorus", 0, 85),
    Patch("fifths", 0, 86),
    Patch("BassLead", 0, 87),
    Patch("New Age", 0, 88),
    Patch("WarmPad", 0, 89),
    Patch("PolyPad", 0, 90),
    Patch("GhostPad", 0, 91),
    Patch("BowedGlas", 0, 92),
    Patch("MetalPad", 0, 93),
    Patch("HaloPad", 0, 94),
    Patch("Sweep", 0, 95),
    Patch("IceRain", 0, 96),
    Patch("SoundTrack", 0, 97),
    Patch("Crystal", 0, 98),
    Patch("Atmosphere", 0, 99),
    Patch("Brightness", 0, 100),
    Patch("Goblin", 0, 101),
    Patch("EchoDrop", 0, 102),
    Patch("SciFi effect", 0, 103),
    Patch("Sitar", 0, 104),
    Patch("Banjo", 0, 105),
    Patch("Shamisen", 0, 106),
    Patch("Koto", 0, 107),
    Patch("Kalimba", 0, 108),
    Patch("Scotland", 0, 109),
    Patch("Fiddle", 0, 110),
    Patch("Shanai", 0, 111),
    Patch("MetalBell", 0, 112),
    Patch("Agogo", 0, 113),
    Patch("SteelDrums", 0, 114),
    Patch("Woodblock", 0, 115),
    Patch("Taiko", 0, 116),
    Patch("Tom", 0, 117),
    Patch("SynthTom", 0, 118),
    Patch("RevCymbal", 0, 119),
    Patch("FretNoise", 0, 120),
    Patch("NoiseChiff", 0, 121),
    Patch("Seashore", 0, 122),
    Patch("Birds", 0, 123),
    Patch("Telephone", 0, 124),
    Patch("Helicopter", 0, 125),
    Patch("Stadium", 0, 126),
    Patch("GunShot", 0, 127)
    ])

/// Definition of the RolandNicePiano sound font
let RolandPiano = SoundFont("Roland", fileName: "RolandNicePiano", [
    Patch("Piano", 0, 1)
    ])

/// Definition of the FluidR3 sound font
let FluidR3 = SoundFont("FluidR3", fileName: "FluidR3_GM", [
    Patch("Yamaha Grand Piano", 0, 0),
    Patch("Bright Yamaha Grand", 0, 1),
    Patch("Electric Piano", 0, 2),
    Patch("Honky Tonk", 0, 3),
    Patch("Rhodes EP", 0, 4),
    Patch("Legend EP 2", 0, 5),
    Patch("Harpsichord", 0, 6),
    Patch("Clavinet", 0, 7),
    Patch("Celesta", 0, 8),
    Patch("Glockenspiel", 0, 9),
    Patch("Music Box", 0, 10),
    Patch("Vibraphone", 0, 11),
    Patch("Marimba", 0, 12),
    Patch("Xylophone", 0, 13),
    Patch("Tubular Bells", 0, 14),
    Patch("Dulcimer", 0, 15),
    Patch("DrawbarOrgan", 0, 16),
    Patch("Percussive Organ", 0, 17),
    Patch("Rock Organ", 0, 18),
    Patch("Church Organ", 0, 19),
    Patch("Reed Organ", 0, 20),
    Patch("Accordian", 0, 21),
    Patch("Harmonica", 0, 22),
    Patch("Bandoneon", 0, 23),
    Patch("Nylon String Guitar", 0, 24),
    Patch("Steel String Guitar", 0, 25),
    Patch("Jazz Guitar", 0, 26),
    Patch("Clean Guitar", 0, 27),
    Patch("Palm Muted Guitar", 0, 28),
    Patch("Overdrive Guitar", 0, 29),
    Patch("Distortion Guitar", 0, 30),
    Patch("Guitar Harmonics", 0, 31),
    Patch("Acoustic Bass", 0, 32),
    Patch("Fingered Bass", 0, 33),
    Patch("Picked Bass", 0, 34),
    Patch("Fretless Bass", 0, 35),
    Patch("Slap Bass", 0, 36),
    Patch("Pop Bass", 0, 37),
    Patch("Synth Bass 1", 0, 38),
    Patch("Synth Bass 2", 0, 39),
    Patch("Violin", 0, 40),
    Patch("Viola", 0, 41),
    Patch("Cello", 0, 42),
    Patch("Contrabass", 0, 43),
    Patch("Tremolo", 0, 44),
    Patch("Pizzicato Section", 0, 45),
    Patch("Harp", 0, 46),
    Patch("Timpani", 0, 47),
    Patch("Strings", 0, 48),
    Patch("Slow Strings", 0, 49),
    Patch("Synth Strings 1", 0, 50),
    Patch("Synth Strings 2", 0, 51),
    Patch("Ahh Choir", 0, 52),
    Patch("Ohh Voices", 0, 53),
    Patch("Synth Voice", 0, 54),
    Patch("Orchestra Hit", 0, 55),
    Patch("Trumpet", 0, 56),
    Patch("Trombone", 0, 57),
    Patch("Tuba", 0, 58),
    Patch("Muted Trumpet", 0, 59),
    Patch("French Horns", 0, 60),
    Patch("Brass Section", 0, 61),
    Patch("Synth Brass 1", 0, 62),
    Patch("Synth Brass 2", 0, 63),
    Patch("Soprano Sax", 0, 64),
    Patch("Alto Sax", 0, 65),
    Patch("Tenor Sax", 0, 66),
    Patch("Baritone Sax", 0, 67),
    Patch("Oboe", 0, 68),
    Patch("English Horn", 0, 69),
    Patch("Bassoon", 0, 70),
    Patch("Clarinet", 0, 71),
    Patch("Piccolo", 0, 72),
    Patch("Flute", 0, 73),
    Patch("Recorder", 0, 74),
    Patch("Pan Flute", 0, 75),
    Patch("Bottle Chiff", 0, 76),
    Patch("Shakuhachi", 0, 77),
    Patch("Whistle", 0, 78),
    Patch("Ocarina", 0, 79),
    Patch("Square Lead", 0, 80),
    Patch("Saw Wave", 0, 81),
    Patch("Calliope Lead", 0, 82),
    Patch("Chiffer Lead", 0, 83),
    Patch("Charang", 0, 84),
    Patch("Solo Vox", 0, 85),
    Patch("Fifth Sawtooth Wave", 0, 86),
    Patch("Bass & Lead", 0, 87),
    Patch("Fantasia", 0, 88),
    Patch("Warm Pad", 0, 89),
    Patch("Polysynth", 0, 90),
    Patch("Space Voice", 0, 91),
    Patch("Bowed Glass", 0, 92),
    Patch("Metal Pad", 0, 93),
    Patch("Halo Pad", 0, 94),
    Patch("Sweep Pad", 0, 95),
    Patch("Ice Rain", 0, 96),
    Patch("Soundtrack", 0, 97),
    Patch("Crystal", 0, 98),
    Patch("Atmosphere", 0, 99),
    Patch("Brightness", 0, 100),
    Patch("Goblin", 0, 101),
    Patch("Echo Drops", 0, 102),
    Patch("Star Theme", 0, 103),
    Patch("Sitar", 0, 104),
    Patch("Banjo", 0, 105),
    Patch("Shamisen", 0, 106),
    Patch("Koto", 0, 107),
    Patch("Kalimba", 0, 108),
    Patch("BagPipe", 0, 109),
    Patch("Fiddle", 0, 110),
    Patch("Shenai", 0, 111),
    Patch("Tinker Bell", 0, 112),
    Patch("Agogo", 0, 113),
    Patch("Steel Drums", 0, 114),
    Patch("Woodblock", 0, 115),
    Patch("Taiko Drum", 0, 116),
    Patch("Melodic Tom", 0, 117),
    Patch("Synth Drum", 0, 118),
    Patch("Reverse Cymbal", 0, 119),
    Patch("Fret Noise", 0, 120),
    Patch("Breath Noise", 0, 121),
    Patch("Sea Shore", 0, 122),
    Patch("Bird Tweet", 0, 123),
    Patch("Telephone", 0, 124),
    Patch("Helicopter", 0, 125),
    Patch("Applause", 0, 126),
    Patch("Gun Shot", 0, 127),
    Patch("Detuned EP 1", 8, 4),
    Patch("Detuned EP 2", 8, 5),
    Patch("Coupled Harpsichord", 8, 6),
    Patch("Church Bell", 8, 14),
    Patch("Detuned Organ 1", 8, 16),
    Patch("Detuned Organ 2", 8, 17),
    Patch("Church Organ 2", 8, 19),
    Patch("Italian Accordion", 8, 21),
    Patch("Ukulele", 8, 24),
    Patch("12 String Guitar", 8, 25),
    Patch("Hawaiian Guitar", 8, 26),
    Patch("Funk Guitar", 8, 28),
    Patch("Feedback Guitar", 8, 30),
    Patch("Guitar Feedback", 8, 31),
    Patch("Synth Bass 3", 8, 38),
    Patch("Synth Bass 4", 8, 39),
    Patch("Slow Violin", 8, 40),
    Patch("Orchestral Pad", 8, 48),
    Patch("Synth Strings 3", 8, 50),
    Patch("Brass 2", 8, 61),
    Patch("Synth Brass 3", 8, 62),
    Patch("Synth Brass 4", 8, 63),
    Patch("Sine Wave", 8, 80),
    Patch("Taisho Koto", 8, 107),
    Patch("Castanets", 8, 115),
    Patch("Concert Bass Drum", 8, 116),
    Patch("Melo Tom 2", 8, 117),
    Patch("808 Tom", 8, 118),
    Patch("Burst Noise", 9, 125),
    Patch("Mandolin", 16, 25),
    Patch("Standard", 128, 0),
    Patch("Standard 1", 128, 1),
    Patch("Standard 2", 128, 2),
    Patch("Standard 3", 128, 3),
    Patch("Standard 4", 128, 4),
    Patch("Standard 5", 128, 5),
    Patch("Standard 6", 128, 6),
    Patch("Standard 7", 128, 7),
    Patch("Room", 128, 8),
    Patch("Room 1", 128, 9),
    Patch("Room 2", 128, 10),
    Patch("Room 3", 128, 11),
    Patch("Room 4", 128, 12),
    Patch("Room 5", 128, 13),
    Patch("Room 6", 128, 14),
    Patch("Room 7", 128, 15),
    Patch("Power", 128, 16),
    Patch("Power 1", 128, 17),
    Patch("Power 2", 128, 18),
    Patch("Power 3", 128, 19),
    Patch("Electronic", 128, 24),
    Patch("TR-808", 128, 25),
    Patch("Jazz", 128, 32),
    Patch("Jazz 1", 128, 33),
    Patch("Jazz 2", 128, 34),
    Patch("Jazz 3", 128, 35),
    Patch("Jazz 4", 128, 36),
    Patch("Brush", 128, 40),
    Patch("Brush 1", 128, 41),
    Patch("Brush 2", 128, 42),
    Patch("Orchestra Kit", 128, 48),
    ])
