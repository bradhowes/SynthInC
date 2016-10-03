// RandomGenerators.swift
// SynthInC
//
// Created by Brad Howes
// Copyright (c) 2016 Brad Howes. All rights reserved.

import Foundation
import GameKit

/// Uniform random number generator. Provides methods for generating numbers in ranges.
class RandomUniform {

    /// Random number source
    fileprivate(set) var randomSource: GKARC4RandomSource
    
    /// Seed value for the generator
    fileprivate let seedData: Data

    /// Singleton instance
    static let sharedInstance = RandomUniform(Parameters.randomSeed)

    /**
     Intialize random number generator using given seed value. This should guarantee that random values from the
     generator will always follow the same sequence when using the same seed value.

     - parameter seed: the seed value to use to initialize the generator
     */
    init(_ seed: Int) {
        var randomSeed = seed
        seedData = NSMutableData(bytes:&randomSeed, length: MemoryLayout.size(ofValue: randomSeed)) as Data
        randomSource = GKARC4RandomSource(seed: self.seedData)
        randomSource.dropValues(1000)
    }

    /// Get the next random value from the generator. (read-only)
    var value: Int { return randomSource.nextInt() }

    /**
     Reset the generator so that it starts emitting the same sequence of numbers as when it was first created.
     */
    func reset() {
        randomSource = GKARC4RandomSource(seed: self.seedData)
        randomSource.dropValues(1000)
    }

    /**
     Return a random `Int` value that is within a given range, the probability of each number in the range being
     uniform.
     
     - parameter lower: lower bound of the range (inclusive)
     - parameter upper: upper bound of the range (inclusive)
     
     - returns: new `Int` value
     */
    func uniform(_ lower: Int, upper: Int) -> Int {
        return Int(randomSource.nextUniform() * Float(upper - lower)) + lower
    }

    /**
     Return a random `Double` value that is withing a given range, the probability of each number in the range being
     uniform.

     - parameter lower: lower bound of the range (inclusive)
     - parameter upper: upper bound of the range (inclusive)
     
     - returns: new `Double` value
     */
    func uniform(_ lower: Double, upper: Double) -> Double {
        return Double(randomSource.nextUniform()) * (upper - lower) + lower
    }

    /**
     Return a random `Float` value that is withing a given range, the probability of each number in the range being
     uniform.
     
     - parameter lower: lower bound of the range (inclusive)
     - parameter upper: upper bound of the range (inclusive)
     
     - returns: new `Float` value
     */
    func uniform(_ lower: Float, upper: Float) -> Float {
        return randomSource.nextUniform() * (upper - lower) + lower
    }
}

/// Random numbers pulled from a Gaussian (normal) probability distribution model. Values will be centered around the
/// mean, with lower probabilities as one moves away from the mean. See [GKGaussianDistribution](xcdoc://?url=developer.apple.com/library/etc/redirect/xcode/ios/1151/documentation/GameplayKit/Reference/GKGaussianDistribution_Class/index.html) for additional details. This is nothing
/// more than a wrapper around that class.
class RandomGaussian {
    
    /// Actual provider of random values
    fileprivate let randomSource: GKGaussianDistribution

    /**
     Initialize random number generator using bounds to describe the model.
     
     - parameter lowestValue: lower bound of the distribution
     - parameter highestValue: upper bound of the distribution
     - parameter randomSource: a source of uniform random values to use
     */
    init(lowestValue: Int, highestValue: Int,
         randomSource: GKRandomSource = RandomUniform.sharedInstance.randomSource) {
        self.randomSource = GKGaussianDistribution(randomSource: randomSource,
                                                   lowestValue: lowestValue,
                                                   highestValue: highestValue)
    }

    /// Get the next random value from the generator. (read-only)
    var value: Int {
        return randomSource.nextInt()
    }
}
