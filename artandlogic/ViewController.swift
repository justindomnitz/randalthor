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
        var lastPair: Drawing.Pair?
        if let inputData = sender.text?.removingWhitespacesAndNewlines() {
            let inputDataElements = Model.split(inputData, 2)
            var outerIndex = 0
            var penUp = false
            var penChange = false
            while outerIndex < inputDataElements.count {
                if let command = Drawing.command(input: inputDataElements[outerIndex]) {
                    switch command {
                    case "CLR":
                        Drawing.clear()
                        outputString += command
                        outputString +=  ";\n"
                        outerIndex += 1
                    case "PEN":
                        Drawing.penUpDown(up: 0)
                        outputString += command
                        outerIndex += 1
                        if outerIndex + 1 < inputDataElements.count {
                            var element = ""
                            if Model.artandlogicDecode(from: inputDataElements[outerIndex] + inputDataElements[outerIndex + 1]) == 0 {
                                element = "UP"
                                penUp = true
                            } else {
                                element = "DOWN"
                                penUp = false
                            }
                            penChange = true
                            outputString += " " + element + ";\n"
                        }
                        outerIndex += 2
                    case "CO":
                        Drawing.setColor(red: 0, green: 0, blue: 0, alpha: 0)
                        outputString += command
                        outerIndex += 1
                        var innerIndex = 0
                        var elements = [Int]()
                        while outerIndex + 1 < inputDataElements.count, innerIndex < 4 {
                            elements.append(Model.artandlogicDecode(from: inputDataElements[outerIndex] + inputDataElements[outerIndex + 1]) ?? 0)
                            outerIndex += 2
                            innerIndex += 1
                        }
                        outputString += " "
                        let _ = elements.map { outputString += String($0) + " " }
                        outputString = outputString.trimmingCharacters(in: .whitespaces)
                        outputString += ";\n"
                    case "MV":
                        Drawing.movePen(pairs: [Drawing.Pair]())
                        outputString += command + " "
                        outerIndex += 1
                        var elements = [Int]()
                        while outerIndex + 1 < inputDataElements.count,
                            Drawing.command(input: inputDataElements[outerIndex]) == nil {
                            elements.append(Model.artandlogicDecode(from: inputDataElements[outerIndex] + inputDataElements[outerIndex + 1]) ?? 0)
                            outerIndex += 2
                        }
                        //Make pairs.
                        var pairs = [Drawing.Pair]()
                        for (index, element) in elements.enumerated() {
                            let isEven = (index + 1) % 2 == 0
                            if isEven {
                                if let lastPair = lastPair {
                                    if penChange {
                                        penChange = false
                                        if index > 1 {
                                            outputString += "MV "
                                        }
                                    }
                                    //Absolute coordinates.
                                    pairs.append(Drawing.Pair(dx: elements[index - 1] + lastPair.dx, dx_adj: elements[index - 1] + lastPair.dx, dy: element + lastPair.dy, dy_adj: element + lastPair.dy))
                                    var outOfBounds = false
                                    let currentIndex = pairs.count - 1
                                    if pairs[currentIndex].dx > 8191 {
                                        pairs[currentIndex].dx_adj = 8191
                                        //TO DO: How do I adjust dy?  Must use trigonometry to figure it out!
                                        pairs[currentIndex].dy_adj = pairs[currentIndex].dy_adj
                                        outOfBounds = true
                                    }
                                    if pairs[currentIndex].dx < -8192 {
                                        pairs[currentIndex].dx_adj = -8192
                                        outOfBounds = true
                                    }
                                    if pairs[currentIndex].dy > 8191 {
                                        pairs[currentIndex].dy_adj = 8191
                                        outOfBounds = true
                                    }
                                    if pairs[currentIndex].dy < -8192 {
                                        pairs[currentIndex].dy_adj = -8192
                                        outOfBounds = true
                                    }
                                    if outOfBounds {
                                        outputString += "(" + String(pairs[currentIndex].dx_adj) + ", " + String(pairs[currentIndex].dy_adj) + ") "
                                        if !penUp {
                                            outputString = outputString.trimmingCharacters(in: .whitespaces) + ";\nPEN UP;\n"
                                            penUp = true
                                            penChange = true
                                        }
                                    } else {
                                        if penUp {
                                            penUp = false
                                            penChange = true
                                            //TO DO: Refine the logic below which will or will not log the point at which the drawing reenters the valid grid...
                                            outputString = outputString.trimmingCharacters(in: .whitespaces) + " (" + String(lastPair.dx_adj) + ", " + String(lastPair.dy_adj) + ");\nPEN DOWN;\nMV (" + String(pairs[currentIndex].dx) + ", " + String(pairs[currentIndex].dy) + ")"
                                        } else {
                                            outputString += "(" + String(pairs[currentIndex].dx) + ", " + String(pairs[currentIndex].dy) + ") "
                                        }
                                    }
                                } else {
                                    pairs.append(Drawing.Pair(dx: elements[index - 1], dx_adj: elements[index - 1], dy: element, dy_adj: element))
                                    let currentIndex = pairs.count - 1
                                    outputString += "(" + String(pairs[currentIndex].dx) + ", " + String(pairs[currentIndex].dy) + ") "
                                }
                                //Set last pair.
                                lastPair = pairs[pairs.count - 1]
                            }
                        }
                        outputString = outputString.trimmingCharacters(in: .whitespaces) + ";\n"
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

extension String {
    func removingWhitespacesAndNewlines() -> String {
        return components(separatedBy: .whitespacesAndNewlines).joined()
    }
}

