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
    
    var defreq:Float        // Frequency from slider
    var counter:Int         // Counter for configuring the base lines
    var baselines:[Float]
    var fftData:[Float]
    var samplingFreq:Float
    var currstatus:String   // Current output about gesturing
    var lastFreq:Float      // Last frequency before changed from the slider
    var needChange:Bool     // Whether we need to configure the baselines
    var N:Int
    var df:Float
    
    
    init (audioFftData: Array<Float>){
        fftData = audioFftData
        samplingFreq = 48000
        N = 0
        df = 0.0
        currstatus = "Initializing Doppler shifts"
        baselines = [Float(1),Float(1)]
        defreq = Float(5000)
        lastFreq = Float(0)
        needChange = false
        counter = 0
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
    
    
    func getDopplerShift() -> String {

        
        var windowSize = 15/(Int(self.df))*2-1      // Set the window size
        
        if (windowSize % 2 == 0) {
            windowSize = windowSize - 1
        }
        
        
        
        let highindex = getIndexByFrequency(wfreq: (defreq+200))    // Upper bound for selected frequency
        let lowindex = getIndexByFrequency(wfreq: (defreq-200))     // Lower bound for selected frequency
        let newfftdata = self.fftData[lowindex...highindex] // Get fft data between the bounds
        
        
        // perfrom sliding window to find two peak
        
        // add padding to cover if peak happens on edges
        let paddingSize = windowSize/2
        let paddingArr: [Float] = [Float](repeating: 0.0, count: paddingSize)
        let fullData2: [Float] = paddingArr + newfftdata + paddingArr
        
        var peakIndexes:[Int] = []
        for i in 0...fullData2.count - windowSize {
            let window = fullData2[i...i+windowSize-1]
            var max:Float = 0.0
            var index:UInt = 0
            vDSP_maxvi(Array(window), vDSP_Stride(1), &max, &index, vDSP_Length(windowSize))
            if (index == windowSize/2) {
                peakIndexes.append(i+lowindex)      // Need +lowindex to get the index in fftdata
            }
        }

        let sortedPeaks = sortHelper(peakIndexes: peakIndexes)  // Get peeks
        let thepeak = sortedPeaks[1].m2         // Get the peak magnitude
        let peakindex = sortedPeaks[1].index    // Get the index of the peak
        
        
        var leftdif = Float(0)
        var rightdif = Float(0)
        var curi = 0;
    
        // Find the average magnitude at the left and right of the peak
        if(peakindex < 50){
            for i in 1...(peakindex - 1){
                leftdif = leftdif + self.fftData[peakindex-i]
                rightdif = rightdif + self.fftData[peakindex+i]
                curi = curi + 1
            }
        }
        else{
            for i in 1...50 {
                leftdif = leftdif + self.fftData[peakindex-i]
                rightdif = rightdif + self.fftData[peakindex+i]
                curi = curi + 1
            }
        }

        
        leftdif = leftdif/Float(curi)
        rightdif = rightdif/Float(curi)
        
        
        // Need +100 to make sure both dif and peak are positive, and get the percentage of the left average and right average to the peak.
        let leftperc = (leftdif + 100)/(thepeak + 100) * 100
        let rightperc = (rightdif + 100)/(thepeak + 100) * 100
        
        
        
        if(defreq != lastFreq && needChange == false){
            needChange = true           // Need to reset the baselines
            counter = 0             // Reset the counter
            self.currstatus = "Initializing Doppler shifts"
        }
        else if (needChange == true){   // If it is changeing
            if(counter < 500){          // Loop 500 times
                if(baselines[0] == 0){
                    baselines[0] = leftperc
                }
                else{
                    baselines[0] = (leftperc + baselines[0]) / 2 // Take the average
                }
                if(baselines[1] == 0){
                    baselines[1] = rightperc
                }
                else{
                    baselines[1] = (rightperc + baselines[1]) / 2 // Take the average
                }
                counter = counter + 1
            }
            else{
                lastFreq = defreq;
                needChange = false      // Change finished
                self.currstatus = "Not gesturing"
            }
        }
        else{
            
            // The difference between baselines and current magnitudes
            let leftcheck = leftperc-baselines[0]
            let rightcheck = rightperc-baselines[1]
            
            if(abs(rightcheck) > 20 && rightcheck > leftcheck){
                self.currstatus = "Gesturing toward"
                print("==========Toward")
            }
            else if(abs(rightcheck) > 20 && rightcheck < leftcheck){
                self.currstatus = "Gesturing Away"
                print("==========Away")
            }
            else{
                self.currstatus = "Not gesturing"
                print("==========Not gesturing")
            }
            
        }
    
        return currstatus
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
        return sortedPeaks
    }
    
    private func getFrequencyByIndex(index: Int) -> Float {
        return Float(index)*self.samplingFreq/Float(self.fftData.count*2)
    }
    
    
    private func getIndexByFrequency(wfreq:Float) -> Int{
        let floatIndex = wfreq/self.df          // Capture the index
        
        if floatIndex < 0 {
            return 0
        }
        if floatIndex > Float(fftData.count*2) {
            return fftData.count*2 - 1
        }
        return Int(floatIndex.rounded(.down))
    }
    
    
    private func interpolation(p: Peak) -> Float {
        return p.f2 + (p.m1-p.m3)*self.df*2/(p.m3-2*p.m2+p.m1)/2
    }
    
    
}
