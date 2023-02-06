//
//  SoundAnalyzer.swift
//  BasicMusicVisualizer
//
//  Created by Adam Behrman on 8/26/2022.
//  Copyright © 2022 Adam Behrman. All rights reserved.
//

import UIKit
import AVFoundation
import Accelerate

struct SoundAnalyzer {
    
    /// Returns the effective power of the sound by converting the sample data to VU Meter level
    /// - This function first computes the RMS (Root-Square-Mean). The RMS is the area under the curve -> The effective value of the sound.
    /// - Parameter channelDataValuesArray: [Float] containing the raw data.
    /// - Parameter frameCount:Float containing buffer's frame count.
    /// - Returns: Float representing the average power of the sample (160.0 - 0.0 but would be NaN when rms is negative).
    static func getAveragePower(data channelDataValuesArray:[Float], frames frameCount:Float) -> Float {
        let tempVal = channelDataValuesArray.map{ $0 * $0 }.reduce(0, +)
        let rms = sqrt(tempVal / frameCount)
        return 20 * log10(rms)
    }
    
    /// Returns VU Meter level (value between 0.0-1.0) and converts edge cases of power.
    /// - This value can be adjusted by modifying the minDb variable.
    /// - Parameter power: Average value of the input sound.
    /// - Parameter minDb: Float representing the minimum db to be registered by the VU Meter.
    /// - Returns: Float representing the adjusted VU Meter power.
    static func getVUMeter(power: Float, minDb: Float) -> Float {
        guard power.isFinite else { return 0.0 }
        
        if power < minDb {
            return 0.0
        } else if power >= 1.0 {
            return 1.0
        } else {
            return (abs(minDb) - abs(power)) / abs(minDb)
        }
    }
    
    /// Returns the result of an in-place FFT and squared magnitudes transform.
    /// - This function normalizes for magnitude in addition to the pure Fast Fourier transform.
    /// - Uses a variety of methods from the vDSP (Video Digital Signal Processing) framework in Accelerate.
    /// - Parameter pcmData: The PCM data to be transformed.
    /// - Returns: [Float] containing the magnitudes of the frequencies.
    static func performFFT(_ pcmData: [Float]) -> [Float] {
        var real = [Float](pcmData)
        var imag = [Float](repeating: 0.0, count: pcmData.count)
        
        // DSPSplitComplex can manage both real and imaginary parts.
        var splitComplex = DSPSplitComplex(realp: &real, imagp: &imag)
        
        // vDSP_Length is necessary for the Fourier Transform, which requires "the base 2 exponent of the number of elements to process." - Apple Documentation
        let length = vDSP_Length(floor(log2(Float(pcmData.count))))
        
        let radix = FFTRadix(kFFTRadix2)
        
        // A structure to hold the result of the vDSP_fft.
        let weights = vDSP_create_fftsetup(length, radix)
        
        // The actual Fast Fourier Transform. The results of this are stored in @param weights.
        vDSP_fft_zip(weights!, &splitComplex, 1, length, FFTDirection(FFT_FORWARD))
        
        // A structure to hold the result of the vDSP_zvmags.
        var magnitudes = [Float](repeating: 0.0, count: pcmData.count)
        
        // Computes the squared megnitudes of the frequencies. The results of this are stored in @param magnitudes.
        vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(pcmData.count))
        
        // A structure to hold the result of xDSP_vsmul.
        var normalizedMagnitudes = [Float](repeating: 0.0, count: pcmData.count)
        
        // Computes a vector-scalar multiplication. Input is the square-root of @param magnitudes, output is @param normalizedMagnitudes.
        vDSP_vsmul(SoundAnalyzer.sqrtVal(magnitudes), 1, [2.0 / Float(pcmData.count)], &normalizedMagnitudes, 1, vDSP_Length(pcmData.count))
        
        // Must destroy the fft setup.
        vDSP_destroy_fftsetup(weights)
        
        return normalizedMagnitudes
    }
    
    /// Computes the square root using Accelerates vvsqrtf function.
    /// - Parameter values: A [Float] containing vlaues from which to compute the square root of.
    /// - Returns: A [Float] containing the square root of the values.
    private static func sqrtVal(_ values: [Float]) -> [Float] {
        // A structure to hold the square root of the values in @param values
        var results = [Float](repeating: 0.0, count: values.count)
        
        // Computes the square root in-place of each value in values
        vvsqrtf(&results, values, [Int32(values.count)])
        return results
    }
    
    /// Seperates frequencies into 'bins' and computes the largest magnitudes in each bin.
    /// - Parameter fftValues: A [Float] containing magnitudes at indices.
    /// - Parameter frequencyInterval: A Float representing the frequency interval.
    /// - Parameter threshold: A Float representing the minimum magnitude to include in bins.
    /// - Parameter percentage: A Float representing the minimun percentage of magnitudes of frequencies of interest to gather.
    /// - Parameter notes: An Int representing the maximum number of notes to keep.
    /// - Parameter minBinSize: An Int representing the minimun amount of frequencies needed to constitute a bin.
    /// - Parameter lowFrequency: A Float representing the lowest frequency to be included in the range.
    /// - Parameter highFrequency: A Float representing the highest frequency to be included in the range.
    /// - Returns: A [Note] representing the best guesses.
    static func getNotes(fftValues: [Float], frequencyInterval: Float, threshold: Float, percentage: Float, notes: Int, minBinSize: Int, lowFrequency: Float, highFrequency: Float) -> [Note] {
        
        let bins = setupFrequencyBins(fftValues: fftValues, frequencyInterval: frequencyInterval, threshold: threshold, lowFrequency: lowFrequency, highFrequency: highFrequency)
//        print("count of bins:", bins.count)
//        print(bins)
//        print()
        
       let binGuesses = makeGuessesBetweenNotes(bins: bins, minBinSize: minBinSize)
//        print("count of bin guesses:", binGuesses.count)
//        print((Array(binGuesses).sorted {$0.1 > $1.1}))
//        print()
        
        let guesses = removeDuplicateGuesses(binGuesses: binGuesses, percentage: percentage, notes: notes)
        return guesses
    }
    
    /// Adjusts the frequencies based on linear regression equation from this:
    /**
     freqiuency n -> frequency out
     220 (A) -> 187.7 (32.3)
     233 (Bb) -> 198.8
     247 (B) -> 210.6
     262 (C) -> 223.2
     294 (D) -> 250.5
     440 (A) -> 375.5
     659 (E) -> 562.5
     880 (A) -> 751.2
     
     frequency * 1.17088 + 0.42245 - simple linear reg
     */
    private static func correctFreq(frequency: Float) -> Float {
        return frequency * 1.17088 + 0.42245
    }
    
    /// Sets up the bins for initial reduction of complexity.
    /// - Parameter fftValues: A [Float] containing magnitudes at indices.
    /// - Parameter frequencyInterval: A Float representing the frequency interval.
    /// - Parameter threshold: A Float representing the minimum magnitude to include in bins.
    /// - Parameter lowFreq: A Float representing the lowest frequency to be included in the range.
    /// - Parameter highFreq: A Float representing the highest frequency to be included in the range.
    /// - Returns: A [[Note]] containing 'bins' of similar note information.
    static func setupFrequencyBins(fftValues: [Float], frequencyInterval: Float, threshold: Float, lowFrequency: Float, highFrequency: Float) -> [[Note]] {
        var bins:[[Note]] = []
        var isAdding = false
        for i in Int(lowFrequency)...Int(highFrequency) {
            let magnitude = fftValues[i]
            if magnitude < threshold && isAdding { // stop adding to the current bin
                isAdding = false
            } else {
                let frequency = correctFreq(frequency: Float(i) * frequencyInterval)
                if isAdding { // continue adding to current frequency bin
                    bins[bins.count-1].append(Note(name: "temp", frequency: frequency, magnitude: magnitude, color: .white))
                } else { // start of new frequency bin
                    bins.append([])
                    isAdding = true
                }
            }
        }
        return bins
    }
    
    /// Goes through each bin and makes a guess between two notes in a row (frequency-wise)
    /// - Parameter bins: A [[Float:Float]] containing 'bins' of similar note information.
    /// - Parameter minBinSize: The minimum amount of frequencies in a bin to run this function on.
    /// - Returns: A [Note] containing frequencies and magnitudes of middle-ground guesses.
    static func makeGuessesBetweenNotes(bins: [[Note]], minBinSize: Int) -> [Note] {
        var binGuesses:[Note] = []
        for bin in bins {
            if bin.count < minBinSize || bin.count <= 1 {
                continue
            }
            
            for i in 0...bin.count-1 {
                if i < bin.count-2 {
                    let magA = bin[i].magnitude
                    let magB = bin[i+1].magnitude
                    let combinedMag = magA + magB
                    
                    let avgFreq = (bin[i].frequency * (magA / combinedMag)) + (bin[i+1].frequency * (magB / combinedMag))
                    let avgMag = hypot(magA, magB)
                    binGuesses.append(Note(name: "temp", frequency: avgFreq, magnitude: avgMag, color: .white))
                }
            }
        }
        return binGuesses
    }
    
    /// Remove duplicate frequencies based on root values and get total magnitude.
    /// - Parameter binGuesses: A [Note] containing frequencies and magnitudes of middle-ground guesses.
    /// - Parameter percentage: A Float representing the minimun percentage of magnitudes of frequencies of interest to gather.
    /// - Parameter notes: An Int representing the maximum number of notes to keep.
    /// - Returns: A [Note] containing the guesses.
    static func removeDuplicateGuesses(binGuesses: [Note], percentage: Float, notes: Int) -> [Note] {
        var totalMag:Float = 0.0
        var guesses:[Note] = []
        
        for guessNote in binGuesses.sorted(by: { $0.magnitude > $1.magnitude }) {
            let note = calculateNote(note: guessNote)
            
            if note != nil && !guesses.contains(where: { $0.frequency == note!.frequency }) {
                guesses.append(note!)
                totalMag += note!.magnitude
            }
        }
                        
        var magKept:Float = 0.0
        var keptGuesses:[Note] = []
        for note in guesses {
            if (notes == 0 || keptGuesses.count < notes) && magKept/totalMag < percentage {
                keptGuesses.append(note)
                magKept += note.magnitude
            }
        }
        return keptGuesses
    }
    
    /// Compares the frequency of interest to the base frequencies and the next 8 octaves to find the closest note.
    /// - Parameter note: A Note representing the guess note to check against root frequency values.
    /// - Returns: A Note? equivalent of the note closest to the frequency or nil.
    private static func calculateNote(note: Note) -> Note? {
        let maxBaseNoteFreq = NoteManager.defaultColors[NoteManager.defaultColors.count-1].frequency
        let baseNoteFreq = getBaseNoteFreq(f: note.frequency, stop: maxBaseNoteFreq)
        let baseNoteDepth = getDepth(f: note.frequency, stop: maxBaseNoteFreq)
        
        let i:Int = findBoundingFrequencies(baseNoteFreq: baseNoteFreq, notes: NoteManager.defaultColors)
        
        if i == -1 {
            return nil
        }
        
        let l:Note = NoteManager.defaultColors[i-1].copy() as! Note
        let u:Note = NoteManager.defaultColors[i].copy() as! Note
        
        let upperpercent = abs(u.frequency - baseNoteFreq) / baseNoteFreq
        let lowerpercent = abs(baseNoteFreq - l.frequency) / baseNoteFreq
        let percentDissimilar:Float = 0.01

        if min(lowerpercent, upperpercent) < percentDissimilar {
            if abs(u.frequency - baseNoteFreq) > abs(baseNoteFreq - l.frequency) {
                return Note(name: l.name, frequency: getPow(depth: baseNoteDepth, val: l.frequency), magnitude: note.magnitude, color: l.color)
            } else {
                return Note(name: u.name, frequency: getPow(depth: baseNoteDepth, val: u.frequency), magnitude: note.magnitude, color: u.color)
            }
        }
        return nil
    }
    
    private static func findBoundingFrequencies(baseNoteFreq:Float, notes:[Note]) -> Int {
        var lowerBound = 1
        var upperBound = notes.count
        
        while lowerBound < upperBound {
            let midIndex = lowerBound + (upperBound - lowerBound) / 2
            if baseNoteFreq < notes[midIndex].frequency {
                if baseNoteFreq > notes[midIndex-1].frequency {
                    return midIndex
                } else {
                    upperBound = midIndex
                }
            } else {
                lowerBound = midIndex + 1
            }
        }
        return -1
    }
    
    private static func getDepth(f: Float, stop: Float) -> Int {
        if f < stop {
            return 0
        }
        return getDepth(f: f / 2, stop: stop) + 1
    }
    
    private static func getBaseNoteFreq(f: Float, stop: Float) -> Float {
        if f < stop {
            return f
        }
        return getBaseNoteFreq(f: f / 2, stop: stop)
    }
    
    private static func getPow(depth: Int, val: Float) -> Float {
        if depth == 0 {
            return val
        }
        return getPow(depth: depth-1, val: val) * 2
    }

}
