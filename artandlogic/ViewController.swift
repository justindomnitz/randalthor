//
//  ViewController.swift
//  artandlogic
//
//  Created by Justin Domnitz on 1/1/18.
//  Copyright (c) 2018 Art & Logic, Inc. All Rights Reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var decodedValue: UITextField!
    @IBOutlet weak var encodedValue: UITextField!
    @IBOutlet weak var inputData: UITextField!
    @IBOutlet weak var outputData: UITextView!
    
    @IBAction func encodeEnteredValue(_ sender: UITextField) {
        if let textToEncode = sender.text,
            let intToEncode = Int(textToEncode) {
            DispatchQueue.main.async {
                self.encodedValue.text = Model.artandlogicEncode(from: intToEncode) ?? Constants.ErrorMessage
            }
        }
    }
    
    @IBAction func decodeEnteredValue(_ sender: UITextField) {
        if let textToDecode = sender.text {
            DispatchQueue.main.async {
                if let decodedInt = Model.artandlogicDecode(from: textToDecode) {
                    self.decodedValue.text = String(decodedInt)
                } else {
                    self.decodedValue.text = Constants.ErrorMessage
                }
            }
        }
    }
    
    @IBAction func inputDataenteredValue(_ sender: UITextField) {
        var outputString = ""
        var lastPair: Drawing.Pair?
        if let inputData = sender.text?.removingWhitespacesAndNewlines() {
            let inputDataElements = Model.split(inputData, 2)
            var outerIndex = 0
            var penUp = true
            while outerIndex < inputDataElements.count {
                if let command = Drawing.command(input: inputDataElements[outerIndex]) {
                    switch command {
                    case Constants.ClearText:
                        Drawing.clear(command: command, outputString: &outputString, outerIndex: &outerIndex)
                    case Constants.PenText:
                        Drawing.penUpDown(command: command, inputDataElements: inputDataElements, penUp: &penUp, outputString: &outputString, outerIndex: &outerIndex)
                    case Constants.ColorText:
                        Drawing.setColor(command: command, inputDataElements: inputDataElements, outputString: &outputString, outerIndex: &outerIndex)
                    case Constants.MoveText:
                        Drawing.movePen(command: command, inputDataElements: inputDataElements, penUp: &penUp, outputString: &outputString, outerIndex: &outerIndex, lastPair: &lastPair)
                    default:
                        print("Unrecognized command: \(inputDataElements[outerIndex]) \(command)")
                        outerIndex += 1
                    }
                } else {
                    print("Invalid command: \(inputDataElements[outerIndex])")
                    outerIndex += 1
                }
            }
        }
        DispatchQueue.main.async {
            self.outputData.text = outputString
        }
    }

}


