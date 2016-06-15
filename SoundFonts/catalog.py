#!/bin/env python

import glob, os, string, sys
from sf2utils.sf2parse import Sf2File

def run(filePaths):

    registrations = ''

    for filePath in filePaths:
        with open(filePath, 'rb') as sf2File:

            sf2 = Sf2File(sf2File)
            presets = [(getattr(z, 'bank', None), getattr(z, 'preset', None), getattr(z, 'name', None))
                       for z in sf2.presets]
            if presets[-1][0] == None:
                del presets[-1]
            presets.sort()

            filePath = os.path.basename(os.path.splitext(filePath)[0])
            valid = string.letters + string.digits + '_'
            name = filter(lambda a: a in valid, sf2.info.bank_name)

            registrations += '{}SoundFont.name: {}SoundFont,\n'.format(name, name)

            with open('./' + filePath + '.swift', 'w') as swiftFile:
                swiftFile.write('''//
// SynthInC
//
// Created by Brad Howes
// Copyright (c) 2016 Brad Howes. All rights reserved.

let {}SoundFont = SoundFont("{}", fileName: "{}", [
'''.format(name, sf2.info.bank_name, filePath))
                for each in presets:
                    swiftFile.write('    Patch({:30} {:3d}, {:3d}),\n'.format('"' + each[2] + '",', each[0],
                                                                              each[1]))
                swiftFile.write('])\n')

    with open('../SynthInC/SoundFont.swift', 'r') as sf:
        contents = sf.read()

    begin = contents.find('// -BEGIN-')
    if begin == -1: raise "*** missing '// -BEGIN-' token in SoundFont.swift file"
    end = contents.find('// -END-')
    if end == -1: raise "*** missing '// -END-' token in SoundFont.swift file"
    contents = contents[:begin] + '// -BEGIN-\n' + registrations + contents[end:]

    with open('../SynthInC/SoundFont.swift', 'w') as sf:
        sf.write(contents)

if __name__ == '__main__':
    run(glob.glob('./*.sf2'))
