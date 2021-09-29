//
//  ToneAnalysis.swift
//  AudioLabSwift
//
//  Created by John Zhang on 9/25/21.
//  Copyright © 2021 John Zhang. All rights reserved.
//

import Foundation
import Accelerate

class ToneAnalysis {
    
    var fftData:[Float]
    var samplingFreq:Float
    var N:Int
    var df:Float
    init (audioFftData: Array<Float>){
        fftData = audioFftData
        samplingFreq = 44100.0
        N = 0
        df = 0.0
    }
    
    struct Peak {
        var f1:Float
        var f2:Float
        var f3:Float
        var m1: Float
        var m2: Float
        var m3: Float
        var index: Int
    }
    
    func setFFTData(audioFftData: Array<Float>) {
        self.fftData = audioFftData
        self.N = audioFftData.count*2
        self.df = self.samplingFreq/Float(audioFftData.count)/2
    }
    
    func getTwoLoudestTones() -> Array<Float> {
        var twoLoudestTones: [Float] = []
        
        var windowSize = Int(50/df)*2-1
        
        if (windowSize % 2 == 0) {
            // maximum needs to be right in the middle of the window
            // window size needs to be odd
            windowSize = windowSize - 1
        }
        
        // perfrom sliding window to find two peak
        
        // add padding to cover if peak happens on edges
        let paddingSize = windowSize/2
        let paddingArr: [Float] = [Float](repeating: 0.0, count: paddingSize)
        let fullData: [Float] = paddingArr + self.fftData + paddingArr
        
        // find local maxima
        var peakIndexes:[Int] = []
        for i in 0...fullData.count - windowSize {
            let window = fullData[i...i+windowSize-1]
            var max:Float = 0.0
            var index:UInt = 0
            // this helps improve the performance
            vDSP_maxvi(Array(window), vDSP_Stride(1), &max, &index, vDSP_Length(windowSize))
            if (index == windowSize/2) {
                // since we added the padding, the index of subarray is parallel with the original fftData
                peakIndexes.append(i)
            }
        }

        let sortedPeaks = sortHelper(peakIndexes: peakIndexes)
        if sortedPeaks.count > 1 {
            twoLoudestTones.append(self.interpolation(p: sortedPeaks[0]))
            twoLoudestTones.append(self.interpolation(p: sortedPeaks[1]))
        }
        
        return twoLoudestTones
    }
    
    private func sortHelper(peakIndexes: [Int]) -> [Peak] {
        var peaks: [Peak] = []
        for index in peakIndexes {
            peaks.append(Peak(f1: self.getFrequencyByIndex(index: index-1),
                              f2: self.getFrequencyByIndex(index: index),
                              f3: self.getFrequencyByIndex(index: index+1),
                              m1: self.fftData[index-1],
                              m2: self.fftData[index],
                              m3: self.fftData[index+1],
                              index: index))
        }
        let sortedPeaks = peaks.sorted {(l, r) in return l.m2 > r.m2 }
        if (sortedPeaks.count > 1 ){
            print(sortedPeaks[0].index, sortedPeaks[0].f2)
        }
        return sortedPeaks
    }
    
    private func getFrequencyByIndex(index: Int) -> Float {
        return Float(index)*self.df
    }
    
    private func interpolation(p: Peak) -> Float {
        return p.f2 + (p.m1-p.m3)*self.df*2/(p.m3-2*p.m2+p.m1)/2
    }
    
    
}
