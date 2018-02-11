//
//  ViewController.swift
//  artandlogic
//
//  Created by Justin Domnitz on 1/1/18.
//  Copyright © 2018 Lowyoyo, LLC. All rights reserved.
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
                self.encodedValue.text = Model.artandlogicEncode(from: intToEncode) ?? "ERROR"
            }
        }
    }
    
    @IBAction func decodeEnteredValue(_ sender: UITextField) {
        if let textToDecode = sender.text {
            DispatchQueue.main.async {
                if let decodedInt = Model.artandlogicDecode(from: textToDecode) {
                    self.decodedValue.text = String(decodedInt)
                } else {
                    self.decodedValue.text = "ERROR"
                }
            }
        }
    }
    
    @IBAction func inputDataenteredValue(_ sender: UITextField) {
        var outputString = ""
        if let inputData = sender.text?.trimmingCharacters(in: .whitespaces) {
            let inputDataElements = Model.split(inputData, 2)
            var outerIndex = 0
            while outerIndex < inputDataElements.count {
                if let command = Drawing.command(input: inputDataElements[outerIndex]) {
                    outputString += command
                    var elements = [Int]()
                    switch command {
                    case "CLR":
                        Drawing.clear()
                        outputString +=  ";\n"
                        outerIndex += 1
                    case "PEN":
                        Drawing.penUpDown(up: 0)
                        outerIndex += 1
                        let element1 = Model.artandlogicDecode(from: inputDataElements[outerIndex] + inputDataElements[outerIndex + 1]) == 0 ? "UP" : "DOWN"
                        outputString += " " + element1 + ";\n"
                        outerIndex += 2
                    case "CO":
                        Drawing.setColor(red: 0, green: 0, blue: 0, alpha: 0)
                        outerIndex += 1
                        for _ in 1...4 {
                            elements.append(Model.artandlogicDecode(from: inputDataElements[outerIndex] + inputDataElements[outerIndex + 1]) ?? 0)
                            outerIndex += 2
                        }
                        outputString += " "
                        let _ = elements.map { outputString += String($0) + " " }
                        outputString += ";\n"
                    case "MV":
                        Drawing.movePen(pairs: [Drawing.Pair]())
                        outerIndex += 1
                        while outerIndex < inputDataElements.count,
                            Drawing.command(input: inputDataElements[outerIndex]) == nil {
                            elements.append(Model.artandlogicDecode(from: inputDataElements[outerIndex] + inputDataElements[outerIndex + 1]) ?? 0)
                            outerIndex += 2
                        }
                        outputString += " "
                        let _ = elements.enumerated().map { index, element in
                            let isEven = (index + 1) % 2 == 0
                            outputString += (isEven ? ", " : "(") + String(element) + (isEven ? ") " : " ")
                        }
                        outputString += ";\n"
                    default:
                        outerIndex += 1
                    }
                } else {
                    print("Invalid command: \(inputDataElements[outerIndex])")
                    outerIndex += 1
                }
            }
        }
        outputData.text = outputString
    }

}

