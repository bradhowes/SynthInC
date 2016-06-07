//
//  MergeSort.swift
//  SynthInC
//
//  Created by Brad Howes on 6/5/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

public extension Array where Element: Comparable {
    private mutating func merge(min min: Int, mid: Int, max: Int) -> [Element] {
        var left = Array(self[min...mid])      // self[min...mid].map{$0}
        var right = Array(self[mid+1...max])    // self[mid+1...max].map{$0}
        
        var leftIndex = 0
        var rightIndex = 0
        
        for k in min...max {
            if leftIndex == left.count {
                for index in rightIndex..<right.count {
                    self[k + index - rightIndex] = right[x]
                }
                return self
            }

            if rightIndex == right.count {
                for index in leftIndex..<left.count {
                    self[k + index - leftIndex] = left[index]
                }
                return self
            }

            if left[leftIndex] <= right[rightIndex] {
                self[k] = left[leftIndex]
                leftIndex += 1
            } else {
                self[k] = right[rightIndex]
                rightIndex += 1
            }
        }
        
        return self
    }
    
    mutating func mergeSorted(min min: Int, max: Int) -> [Element] {
        if min < max {
            let mid = Int(floor(Double(min + max) / 2))
            
            self.mergeSorted(min: min, max: mid)
            self.mergeSorted(min: mid + 1, max: max)
            self.merge(min: min, mid: mid, max: max)
        }
        
        return self
    }
    
    // MergeSort Method -> Original from "CLRS"
    public func mergeSort() -> [Element] {
        var s = self
        return s.mergeSorted(min: 0, max: s.count - 1)
    }
}
