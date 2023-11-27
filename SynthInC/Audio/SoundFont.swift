// Copyright © 2016 Brad Howes. All rights reserved.

import UIKit

let systemFontAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.systemFontSize)]

/**
 Representation of a sound font library. NOTE: all sound font files must have 'sf2' extension.
 */
final class SoundFont {

  /**
   Mapping of registered sound fonts. Add additional sound font entries here to make them available to the
   SoundFont code. NOTE: the value of this mapping is manipulated by the Python script `catalog.py` found in
   the `Extras` folder. In particular, it expects to find the -BEGIN- and -END- comments.
   */
  static let library: [String:SoundFont] = [
    // -BEGIN-
    FreeFontGMVer32SoundFont.name: FreeFontGMVer32SoundFont,
    GeneralUserGSMuseScoreversion1442SoundFont.name: GeneralUserGSMuseScoreversion1442SoundFont,
    FluidR3GMSoundFont.name: FluidR3GMSoundFont,
    UserBankSoundFont.name: UserBankSoundFont,
    // -END-
  ]

  /**
   Array of registered sound font names sorted in alphabetical order. Generated from `library` entries.
   */
  static let keys: [String] = library.keys.sorted()

  /**
   Maximium width of all library names.
   */
  static let maxNameWidth: CGFloat = library.values.map { $0.nameWidth }.max() ?? 100.0
  static let patchCount: Int = library.reduce(0) { $0 + $1.1.patches.count }

  /**
   Obtain a random patch from all registered sound fonts.
   - returns: radom Patch object
   */
  static func randomPatch(randomSource: Rando) -> Patch {
    let namePos = randomSource.pick(from: 0...keys.count)
    let soundFont = getByIndex(namePos)
    let patchPos = randomSource.pick(from: 0...soundFont.patches.count)
    return soundFont.patches[patchPos]
  }

  /**
   Obtain a SoundFont using an index into the `keys` name array. If the index is out-of-bounds this will return the
   FreeFont sound font.
   - parameter index: the key to use
   - returns: found SoundFont object
   */
  static func getByIndex(_ index: Int) -> SoundFont {
    guard index >= 0 && index < keys.count else { return SoundFont.library[SoundFont.keys[0]]! }
    let key = keys[index]
    return library[key]!
  }

  /**
   Obtain the index in `keys` for the given sound font name. If not found, return 0
   - parameter name: the name to look for
   - returns: found index or zero
   */
  static func indexForName(_ name: String) -> Int {
    return keys.firstIndex(of: name) ?? 0
  }

  let soundFontExtension = "sf2"

  /// Presentation name of the sound font
  let name: String
  /// Width of the sound font name
  lazy var nameWidth = { (name as NSString).size(withAttributes: systemFontAttributes).width }()
  /// The file name of the sound font (sans extension)
  let fileName: String
  ///  The resolved URL for the sound font
  let fileURL: URL

  /// The collection of Patches found in the sound font
  let patches: [Patch]
  /// The max width of all of the patch names in the sound font
  lazy var maxPatchNameWidth = { patches.map { $0.nameWidth }.max() ?? 100.0 }()
  /// The gain to apply to a patch in the sound font
  let dbGain: Float32

  /**
   Initialize new SoundFont instance.

   - parameter name: the display name for the sound font
   - parameter fileName: the file name of the sound font in the application bundle
   - parameter patches: the array of Patch objects for the sound font
   - parameter dbGain: AudioUnit attenuation to apply to patches from this sound font [-90, +12]
   */
  init(_ name: String, fileName: String, _ patches: [Patch], _ dbGain: Float32 = 0.0 ) {
    self.name = name
    self.fileName = fileName
    self.fileURL = Bundle(for: SoundFont.self).url(forResource: fileName, withExtension: soundFontExtension)!
    self.patches = patches
    self.dbGain = min(max(dbGain, -90.0), 12.0)
    patches.forEach { $0.soundFont = self }
  }

  /**
   Locate a patch in the SoundFont using a display name.

   - parameter name: the display name to search for

   - returns: found Patch or nil
   */
  func findPatch(_ name: String) -> Patch? {
    guard let found = findPatchIndex(name) else { return nil }
    return patches[found]
  }

  /**
   Obtain the index to a Patch with a given name.

   - parameter name: the display name to search for

   - returns: index of found object or nil if not found
   */
  func findPatchIndex(_ name: String) -> Int? {
    patches.firstIndex(where: { return $0.name == name })
  }
}

/**
 Representation of a patch in a sound font.
 */
final class Patch {

  /// Display name for the patch
  let name: String
  /// Width of the name in the system font
  lazy var nameWidth: CGFloat = { (name as NSString).size(withAttributes: systemFontAttributes).width }()

  /// Bank number where the patch resides in the sound font
  let bank: Int
  /// Program patch number where the patch resides in the sound font
  let patch: Int
  /// Reference to the SoundFont parent (set by the SoundFont itself)
  weak var soundFont: SoundFont! = nil

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
  }
}

let FavoriteSoundFont = SoundFont.getByIndex(0)
let FavoritePatches = [
  FavoriteSoundFont.patches[0],
  FavoriteSoundFont.patches[7],
  FavoriteSoundFont.patches[2],
  FavoriteSoundFont.patches[12],
  FavoriteSoundFont.patches[24],
  FavoriteSoundFont.patches[42],
  FavoriteSoundFont.patches[32],
  FavoriteSoundFont.patches[40],
  FavoriteSoundFont.patches[46],
  FavoriteSoundFont.patches[52],
  FavoriteSoundFont.patches[53],
  FavoriteSoundFont.patches[54],
  FavoriteSoundFont.patches[64],
  FavoriteSoundFont.patches[73],
  FavoriteSoundFont.patches[74],
  FavoriteSoundFont.patches[79],
  FavoriteSoundFont.patches[108],
]
