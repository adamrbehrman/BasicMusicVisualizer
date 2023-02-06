//  FileManager.swift
//  BasicMusicVisualizer
//
//  Created by Adam Behrman on 8/26/2022.
//  Copyright © 2022 Adam Behrman. All rights reserved.
//

import Foundation
import AVFoundation
import GameplayKit

class NoteManager {
    
    static let FLAT_CHAR = "b"
    
    static let defaultColors:[Note] = [
        Note(name: "C", frequency: 16.35, magnitude: 0.0, color: UIColor.red),
        Note(name: "Db", frequency: 17.32, magnitude: 0.0, color: UIColor(red: 0.5, green: 0.0, blue:0.0, alpha: 1.0)),
        Note(name: "D", frequency: 18.35, magnitude: 0.0, color: UIColor(red: 0.01, green: 0.01, blue:0.01, alpha: 1.0)),
        Note(name: "Eb", frequency: 19.45, magnitude: 0.0, color: UIColor(red: 0.0, green: 0.0, blue: 0.3, alpha: 1.0)),
        Note(name: "E", frequency: 20.60, magnitude: 0.0, color: UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)),
        Note(name: "F", frequency: 21.83, magnitude: 0.0, color: UIColor.orange),
        Note(name: "Gb", frequency: 23.12, magnitude: 0.0, color: UIColor.green),
        Note(name: "G", frequency: 24.5, magnitude: 0.0, color: UIColor.blue),
        Note(name: "Ab", frequency: 25.96, magnitude: 0.0, color: UIColor.blue),
        Note(name: "A", frequency: 27.5, magnitude: 0.0, color: UIColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0)),
        Note(name: "Bb", frequency: 29.14, magnitude: 0.0, color: UIColor(red: 1.0, green: 0.7, blue: 1.0, alpha: 0.3)),
        Note(name: "B", frequency: 30.87, magnitude: 0.0, color: UIColor.purple),
        Note(name: "C", frequency: 32.7, magnitude: 0.0, color: UIColor.red)
    ]
    
}

class Note: Identifiable, CustomStringConvertible, NSCopying {
    
    var id:String { String(frequency) }
    var name:String
    var frequency:Float
    var magnitude:Float
    var color:UIColor
    
    init() {
        self.frequency = 0.0
        self.magnitude = 0.0
        self.name = ""
        self.color = .white
    }
    
    init(name: String, frequency: Float, magnitude: Float, color: UIColor) {
        self.name = name
        self.frequency = frequency
        self.magnitude = magnitude
        self.color = color
    }
    
    public var description: String {
        return "Note: [name: \(name), frequency: \(frequency), mmgnitude: \(magnitude), color: \(color)]"
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Note(name: name, frequency: frequency, magnitude: magnitude, color: color)
        return copy
    }
}

//    private static let filePaths:[String] = [
//        "0_c.wav",
//        "0_cs.wav",
//        "0_d.wav",
//        "0_ds.wav",
//        "0_e.wav",
//        "0_f.wav",
//        "0_fs.wav",
//        "0_g.wav",
//        "0_gs.wav",
//        "0_a.wav",
//        "0_as.wav",
//        "0_b.wav"
//    ]
//
//    private static var noteKeys:[String] = []
//
//    /// Stores all note information
//    public static var notes:[[Note]] = [[]]
//
//    public static func loadNotes() {
//        let noteData = DataManager.loadJSON(filePath: noteDataFilePath)
//
//        if noteData == nil {
//            print("No data: Loading default colors.")
//            NoteManager.loadFiles()
//            DataManager.saveJSON(filePath: noteDataFilePath)
//        } else {
//            print("JSON found: Loading recently saved color data.")
//            NoteManager.notes = noteData!
//
//            var i = 0
//            for noteArr in NoteManager.notes {
//                i = 0
//                for note in noteArr {
//                    note.filePath = Bundle.main.path(forResource: NoteManager.filePaths[i], ofType: nil)
//                    i += 1
//                }
//            }
//        }
//        // Save any old data
//        guard let newSession = DataManager.FIREBASE_handleNewSession() else { return }
//
//        if newSession {
//            print("Previous session no longer valid. Starting new session.")
//            // Reset data for today's session
//            for noteArr in NoteManager.notes {
//                for note in noteArr {
//                    for colorD in note.colors {
//                        colorD.newSession()
//                    }
//                }
//            DataManager.FIREBASE_saveSessionData()
//            }
//        }
//    }
//
//    public static func getNotes() -> [Note] {
//        return notes[instrumentIndex];
//    }
//
//    /// Handles the loading of all files into individual Notes.
//    private static func loadFiles() {
//        for i in 0..<filePaths.count {
//            let filePath = filePaths[i]
//            let prefix = filePath.split(separator: ".")[0].split(separator: "_")
//            let instrument = Int(prefix[0])
//            var noteName:String = String(prefix[1])
//            if(noteName.count > 1) {
//                noteName = noteName.dropLast() + NoteManager.SHARP_CHAR
//            }
//            let note = Note(name: noteName.uppercased(), cColor: CodableColor(from: colors[i]), filePath: filePath)
//            noteKeys.append(note.key)
//            notes[instrument!].append(note)
//        }
//    }
//
//    /// Generates a random number (inclusive) between 0 and the list length - 1 returns the the note selected at that index
//    public static func getRandomNote() -> Note? {
//        return getNotes()[Int.random(in: 0...notes[instrumentIndex].count-1)]
//    }
//
//    /// Gets the color from the note with the given name
//    public static func getColorFromNote(noteName: String) -> UIColor? {
//        for note in getNotes() {
//            if noteName.lowercased() == note.name.lowercased() {
//                return note.getCurrentColor().getColor().color
//            }
//        }
//        return  nil
//    }
//
//    /// Gets the color from the note with the given name
//    public static func getNameFromNote(noteIndex: Int) -> String {
//        return getNotes()[noteIndex].name
//    }
//
//    /// Changes currentIndex to the desired instrument index
//    public static func changeInstrument(instrumentNumber: Int) {
//        instrumentIndex = instrumentNumber
//    }
//
//    public static func getInstrumentNum() -> Int {
//        return NoteManager.instrumentIndex
//    }
//}
//
//import UIKit
//class Note : NSObject, Codable {
//
//    /// Note class holds the data for notes
//    var key:String
//    var name:String
//    var colors:[colorData] = []
//    var currentColor:Int
//
//    var filePath:String?
//
//    init(name:String, cColor:CodableColor, filePath:String) {
//        self.name = name
//        colors.append(colorData(color: cColor))
//        currentColor = 0
//        self.filePath = Bundle.main.path(forResource: filePath, ofType: nil)
//
//        self.key = name + String(NoteManager.getInstrumentNum())
//    }
//
//    func addNewColor(color:UIColor){
//        colors.append(colorData(color: CodableColor(from: color)))
//        currentColor+=1
//    }
//
//    func setCurrentColor(to color:UIColor){
//        colors[currentColor].setColor(to: CodableColor(from: color))
//    }
//
//    func getCurrentColor() -> colorData{
//        return colors[currentColor]
//    }
//
//    func getColorInfo(for uiColor:UIColor) -> colorData? {
//        for color in colors {
//            if color.getColor().color == uiColor {
//                return color
//            }
//        }
//        return nil
//    }
//}
//
//public struct CodableColor:Codable {
//    private var _color: UIColor
//
//    var color: UIColor {
//      set { _color = newValue }
//      get { return _color }
//    }
//
//    public init(from color: UIColor) {
//        _color = color
//    }
//
//    public init(from decoder: Decoder) throws {
//        var container = try decoder.unkeyedContainer()
//        let decodedData = try container.decode(Data.self)
//        let nsCoder = try NSKeyedUnarchiver(forReadingFrom: decodedData)
//        _color = UIColor(coder: nsCoder)!
//    }
//
//    public func encode(to encoder: Encoder) throws {
//        let nsCoder = NSKeyedArchiver(requiringSecureCoding: true)
//        _color.encode(with: nsCoder)
//        var container = encoder.unkeyedContainer()
//        try container.encode(nsCoder.encodedData)
//    }
//
//    public mutating func decode(from decoder: Decoder, using key: String) throws {
//        var container = try decoder.unkeyedContainer()
//        let decodedData = try container.decode(Data.self)
//        let nsCoder = try NSKeyedUnarchiver(forReadingFrom: decodedData)
//        _color = UIColor(coder: nsCoder)!
//    }
//
//}
//
//public class colorData:Codable{
//    private var color:CodableColor
//
//    /// Statistics that hold all the data about guessing
//    var allGuesses:Int
//    var allGuessesCorrect:Int
//
//    /// Statistics that hold current session data about guessing
//    var currentGuesses:Int
//    var currentGuessesCorrect:Int
//
//    /// Statistics that hold current test session data about guessing
//    var displayGuesses:Int
//    var displayGuessesCorrect:Int
//
//    init(color cColor:CodableColor){
//        color = cColor
//        currentGuesses = 0
//        currentGuessesCorrect = 0
//        allGuessesCorrect = 0
//        allGuesses = 0
//        displayGuesses = 0
//        displayGuessesCorrect = 0
//    }
//
//    public func getColor()->CodableColor{
//        return color
//    }
//
//    public func setColor(to cColor:CodableColor) {
//        color = cColor
//    }
//
//    public func newSession() {
//        currentGuessesCorrect = 0
//        currentGuesses = 0
//        displayGuessesCorrect = 0
//        displayGuesses = 0
//    }
//
//    public func handleChangedColor() {
//        if allGuesses > 0 {
//            currentGuesses = 0
//            currentGuessesCorrect = 0
//            displayGuesses = 0
//            displayGuessesCorrect = 0
//        }
//    }
//
//    public func incrimentGuessesCorrect() {
//        currentGuessesCorrect += 1
//        allGuessesCorrect += 1
//        displayGuessesCorrect += 1
//    }
//
//    public func incriementTotalGuesses() {
//        currentGuesses += 1
//        allGuesses += 1
//        displayGuesses += 1
//    }
//
//    public func resetGuessesCorrect() {
//        displayGuessesCorrect = 0
//    }
//
//    public func resetTotalGuesses() {
//        displayGuesses = 0
//    }
//
//    public func toString() -> String {
//        return "For color \(toHex(color: color.color)!), you've gotten \(allGuessesCorrect) right out of \(allGuesses) questions."
//    }
//
//    /// Credit to https://cocoacasts.com/from-hex-to-uicolor-and-back-in-swift
//    public func toHex(color:UIColor, alpha: Bool = false) -> String? {
//        let cgColor = color.cgColor
//        // print(cgColor.components, cgColor.components!.count)
//        guard let components = cgColor.components, components.count >= 3 else {
//            return nil
//        }
//
//        let r = Float(components[0])
//        let g = Float(components[1])
//        let b = Float(components[2])
//        var a = Float(1.0)
//
//        if components.count >= 4 {
//            a = Float(components[3])
//        }
//
//        if alpha {
//            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
//        } else {
//            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
//        }
//    }
//}
