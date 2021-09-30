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
    
    var defreq:Float
    var counter:Int
    var difference:[Float]
    var fftData:[Float]
    var samplingFreq:Float
    var currstatus:String
    var setup:Bool
    var N:Int
    var df:Float
    init (audioFftData: Array<Float>){
        fftData = audioFftData
        samplingFreq = 48000
        N = 0
        df = 0.0
        currstatus = "Initializing Doppler shifts"
        difference = [Float(1),Float(1)]
        setup = false
        defreq = Float(5000)
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

        
        var windowSize = 15/(Int(self.df))*2-1
        
        if (windowSize % 2 == 0) {
            // maximum needs to be right in the middle of the window
            // window size needs to be odd
            windowSize = windowSize - 1
        }
        
        
        
        let highindex = getIndexByFrequency(wfreq: (defreq+200))
        let lowindex = getIndexByFrequency(wfreq: (defreq-200))
        let newfftdata = self.fftData[lowindex...highindex]
        
        
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
            // this helps improve the performance
            vDSP_maxvi(Array(window), vDSP_Stride(1), &max, &index, vDSP_Length(windowSize))
            if (index == windowSize/2) {
                // since we added the padding, the index of subarray is parallel with the original fftData
                peakIndexes.append(i+lowindex)
            }
        }

        let sortedPeaks = sortHelper(peakIndexes: peakIndexes)
        
        
        
    
         //print("Loudest Freq: \(loudestFreq[0]), Second Loudest Freq: \(loudestFreq[1])")
         
         // Determine motion of hand based on magnitude and frequency
        if(sortedPeaks[1].m2 > Float(-64)){
            print(sortedPeaks[1].f2)
            if(sortedPeaks[1].f2 > self.defreq+40){
                print("========= moving toward")
                self.currstatus = "Moving Toward"
             }
            else if(sortedPeaks[1].f2 < self.defreq-40){
                print("========= moving away")
                self.currstatus = "Moving Away"
            }
            else{
                self.currstatus = "No Motion"
            }
         }
         else{
            self.currstatus = "No Motion"
         }
        
//
//        var leftdif = Float(0)
//        var rightdif = Float(0)
//
//
//        if(sortedPeaks[0].index < 20){
//            for i in 1...(sortedPeaks[0].index - 1){
//                leftdif = leftdif + self.fftData[sortedPeaks[0].index-i]
//                rightdif = rightdif + self.fftData[sortedPeaks[0].index+i]
//            }
//        }
//        else{
//            for i in 1...20 {
//                leftdif = leftdif + self.fftData[sortedPeaks[0].index-i]
//                rightdif = rightdif + self.fftData[sortedPeaks[0].index+i]
//            }
//        }
//        leftdif = leftdif/20
//        rightdif = rightdif/20
//
//        let leftperc = (leftdif + 100)/(thepeak + 100) * 100
//        let rightperc = (rightdif + 100)/(thepeak + 100) * 100
//
//
//        if(counter<200){
//            if(difference[0] == 0){
//                difference[0] = leftperc
//            }
//            else{
//                difference[0] = (leftperc + difference[0]) / 2
//            }
//            if(difference[1] == 0){
//                difference[1] = rightperc
//            }
//            else{
//                difference[1] = (rightperc + difference[1]) / 2
//            }
//            counter = counter + 1;
//        }
//        else{
//
//            currstatus = "Hold"
//            print(sortedPeaks[0].index)
//            print("++++++++++  \(difference[0])")
//            print("----------- \(difference[1])")
//            print("!!!!!!!!!!!!  \(leftperc)")
//            print("!!!!!!!!!!!! \(rightperc)")
//            print("@@@@@@@@@@@ \((leftperc-difference[0])/difference[0]*100) ")
//            print("@@@@@@@@@@@ \((rightperc-difference[1])/difference[1]*100 )")
//
//            if((leftperc-difference[0])/difference[0]*100 > 10
//                || (rightperc-difference[1])/difference[1]*100 < -10)
//            {
//                currstatus = "Out"
//            }
//            else if((rightperc-difference[1])/difference[1]*100 > 10
//                    || (leftperc-difference[0])/difference[0]*100 < -10)
//                    {
//                currstatus = "In"
//            }
//
//        }
        
    
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
        let floatIndex = wfreq/self.df
        
        if floatIndex < 0 {
            return 0
        }
        
        // If the index is out of bounds of the number of fft frames, return max frequency
        if floatIndex > Float(fftData.count*2) {
            return fftData.count*2 - 1
        }
        
        // Round up for high frequency, down for low frequency (to include both)
    
        return Int(floatIndex.rounded(.down))
    }
    
    
    private func interpolation(p: Peak) -> Float {
        return p.f2 + (p.m1-p.m3)*self.df*2/(p.m3-2*p.m2+p.m1)/2
    }
    
    
}
