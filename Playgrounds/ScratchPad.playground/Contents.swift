//: Playground - noun: a place where people can play

import UIKit
import AudioToolbox
import CoreAudio
import AVFoundation
import SwiftMIDI

var graph: AUGraph? = nil
NewAUGraph(&graph)

var desc = AudioComponentDescription(componentType: OSType(kAudioUnitType_Mixer),
                                     componentSubType: OSType(kAudioUnitSubType_MultiChannelMixer),
                                     componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
                                     componentFlags: 0, componentFlagsMask: 0)
var mixerNode: AUNode = 0
AUGraphAddNode(graph!, &desc, &mixerNode)


desc = AudioComponentDescription(componentType: OSType(kAudioUnitType_Output),
                                 componentSubType: OSType(kAudioUnitSubType_RemoteIO),
                                 componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
                                 componentFlags: 0, componentFlagsMask: 0)
var outputNode: AUNode = 0
AUGraphAddNode(graph!, &desc, &outputNode)
AUGraphOpen(graph!)

var mixerUnit: AudioUnit? = nil
AUGraphNodeInfo(graph!, mixerNode, nil, &mixerUnit)

var busCount = UInt32(1);
AudioUnitSetProperty(mixerUnit!, kAudioUnitProperty_ElementCount,
                     kAudioUnitScope_Input, 0, &busCount,
                     UInt32(MemoryLayout.size(ofValue: busCount)))
var sampleRate: Float64 = 44100.0;
AudioUnitSetProperty(mixerUnit!, kAudioUnitProperty_SampleRate,
                     kAudioUnitScope_Output, 0, &sampleRate,
                     UInt32(MemoryLayout.size(ofValue: sampleRate)))
AUGraphConnectNodeInput(graph!, mixerNode, 0, outputNode, 0)


var samplerNode: AUNode = 0
var samplerUnit: AudioUnit!

desc = AudioComponentDescription(
    componentType: OSType(kAudioUnitType_MusicDevice),
    componentSubType: OSType(kAudioUnitSubType_Sampler),
    componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
    componentFlags: 0, componentFlagsMask: 0)
AUGraphAddNode(graph!, &desc, &samplerNode)

AUGraphNodeInfo(graph!, samplerNode, nil, &samplerUnit)

AudioUnitSetProperty(samplerUnit!, kAudioUnitProperty_SampleRate,
                     kAudioUnitScope_Output, 0, &sampleRate,
                     UInt32(MemoryLayout.size(ofValue: sampleRate)))
let index = 0
AUGraphConnectNodeInput(graph!, samplerNode, 0, mixerNode, UInt32(index))

let bankMSB = UInt8(kAUSampler_DefaultMelodicBankMSB)
let bankLSB = UInt8(kAUSampler_DefaultBankLSB)
let patch = 1
let presetID = UInt8(patch)

let soundFont = SoundFont.library["Fluid R3 GM"]!
var data = AUSamplerInstrumentData(fileURL: Unmanaged.passUnretained(soundFont.fileURL as CFURL),
                                   instrumentType: UInt8(kInstrumentType_SF2Preset),
                                   bankMSB: bankMSB,
                                   bankLSB: bankLSB,
                                   presetID: presetID)
AudioUnitSetProperty(samplerUnit, kAUSamplerProperty_LoadInstrument,
                     kAudioUnitScope_Global, 0, &data, UInt32(MemoryLayout.size(ofValue: data)))
