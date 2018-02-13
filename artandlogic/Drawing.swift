//
//  Drawing.swift
//  artandlogic
//
//  Created by Justin Domnitz on 2/9/18.
//  Copyright (c) 2018 Art & Logic, Inc. All Rights Reserved.
//

import UIKit

class Drawing: NSObject {

    struct Pair {
        var dx: Int
        var dx_adj: Int
        var dy: Int
        var dy_adj: Int
        var outOfBounds: Bool
    }

    /**
     * Clear
     *
     * Command
     * CLR
     * Opcode
     * F0
     * Parameters
     * (none)
     * Output
     * CLR;\n
     *
     * Cause the drawing to reset itself, including:
     * setting the pen state to up
     * setting the pen position back to (0,0)
     * setting the current color to (0, 0, 0, 255) (black)
     * clearing any output on the screen (not shown in our example output here)
     */
    
    static func clear(command:String, outputString: inout String, outerIndex: inout Int) {
        outputString += command
        outputString += Constants.NewLine
        outerIndex += 1
    }
    
    /**
     * Pen Up/Down
     *
     * Command
     * PEN
     * Opcode
     * 80
     * Parameters
     * 0 = pen up
     * any other value = pen down
     * Output
     * either PEN UP;\n or PEN DOWN;\n
     *
     * Change the state of the pen object to either up or down. When a pen is up, moving it leaves no trace on the drawing. When the pen is down and moves, it draws a line in the current color.
     */
    
    static func penUpDown(command:String, inputDataElements: [String], penUp: inout Bool, outputString: inout String, outerIndex: inout Int) {
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
            outputString += Constants.Space + element + Constants.NewLine
        }
        outerIndex += 2
    }
    
    /**
     * Set Color
     *
     * Command
     * CO
     * Opcode
     * A0
     * Parameters
     * RGBA
     * Red, Green, Blue, Alpha values, each in the range 0..255. All four values are required.
     * Output
     * CO {r} {g} {b} {a};\n (where each of the r/g/b/a values are formatted as integers 0..255
     *
     * Change the current color (including alpha) of the pen. The color change takes effect the next time the pen is moved. After clearing a drawing with the CLR; command, the current color is reset to black (0,0,0,255).
     */
    
    static func setColor(command:String, inputDataElements: [String], outputString: inout String, outerIndex: inout Int) {
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
        let _ = elements.map { outputString += String($0) + Constants.Space }
        outputString = outputString.trimmingCharacters(in: .whitespaces) + Constants.NewLine
    }
    
    /**
     * Move Pen
     *
     * Command
     * MV
     * Opcode
     * C0
     * Parameters
     * dx0 dy0 [dx1 dy1 .. dxn dyn] Any number of (dx,dy) pairs.
     * Output
     *
     * if pen is up, move the pen to the final coordinate position
     * If pen is down: MV (xo, y0) (x1, y1) [... (xn, yn)];\n
     * Change the location of the pen relative to its current location. If the pen is down, draw in the current color. If multiple (x, y) points are provided as parameters, each point moved to becomes the new current location in turn.
     * Also note that the values used in your output should be absolute coordinates in the drawing space, not the relative coordinates used in the encoded movement commands.
     * For example, after clearing a drawing, the current location is the origin at (0, 0). If the pen is moved (10, 10) and then (5, -5), the last location of the pen will be at (15, 5). For the purposes of this exercise, the string output would be
     *
     * MV (10, 10) (15, 5);
     *
     * if the pen is down, but just
     *
     * MV (15, 5);
     *
     * if the pen is up.
     *
     * If the specified motion takes the pen outside the allowed bounds of (-8192, -8192) .. (8191, 8191), the pen should move until it crosses that boundary and then lift. When additional movement commands bring the pen back into the valid coordinate space, the pen should be placed down at the boundary and draw to the next position in the data file.
     */
    
    static func movePen(command:String, inputDataElements: [String], penUp: inout Bool, outputString: inout String, outerIndex: inout Int, lastPair: inout Drawing.Pair?) {
        outputString += command + Constants.Space
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
                    //Absolute coordinates.
                    pairs.append(Drawing.Pair(dx:     elements[index - 1] + lastPair.dx,
                                              dx_adj: elements[index - 1] + lastPair.dx,
                                              dy:     element + lastPair.dy,
                                              dy_adj: element + lastPair.dy,
                                              outOfBounds: false))
                    let currentIndex = pairs.count - 1
                    if pairs[currentIndex].dx >  8191 ||
                        pairs[currentIndex].dx < -8192 ||
                        pairs[currentIndex].dy >  8191 ||
                        pairs[currentIndex].dy < -8192 {
                        
                        /*
                         let distanceFromRightSide:Float = 8191 - Float(lastPair.dx)
                         let distanceFromRightSideRatio:Float = distanceFromRightSide / Float(lastPair.dx)
                         let newHeight:Float = distanceFromRightSideRatio * Float(lastPair.dy - pairs[currentIndex].dy)
                         let touchHeight:Float = Float(lastPair.dy) - newHeight
                         pairs[currentIndex].dy_adj = Int(touchHeight.rounded())
                         */
                        
                        pairs[currentIndex].dx_adj = min( 8191, pairs[currentIndex].dx_adj)
                        pairs[currentIndex].dx_adj = max(-8192, pairs[currentIndex].dx_adj)
                        
                        //TO DO: Why did lastPair work here for the basic drawing off screen example?
                        pairs[currentIndex].dy_adj = min( 8191, pairs[currentIndex].dy_adj)
                        pairs[currentIndex].dy_adj = max(-8192, pairs[currentIndex].dy_adj)
                        
                        pairs[currentIndex].outOfBounds = true
                    }
                    if pairs[currentIndex].outOfBounds {
                        //Current point is out of bounds.
                        if !penUp {
                            penUp = true
                            outputString += "(" + String(pairs[currentIndex].dx_adj) + ", " + String(pairs[currentIndex].dy_adj) + ");\nPEN UP;\n"
                        }
                    } else {
                        if penUp {
                            penUp = false
                            if lastPair.outOfBounds {
                                //Previous point was out of bounds, but now we're back in bounds.
                                //Put the pen down where we reenter...
                                
                                /*
                                 let distanceFromRightSide:Float = 8191 - Float(pairs[currentIndex].dx)
                                 let distanceFromRightSideRatio:Float = distanceFromRightSide / Float(pairs[currentIndex].dx)
                                 let newHeight:Float = distanceFromRightSideRatio * Float(lastPair.dy - pairs[currentIndex].dy)
                                 let touchHeight:Float = newHeight - Float(pairs[currentIndex].dy)
                                 pairs[currentIndex].dy_adj = Int(touchHeight.rounded())
                                 */
                                
                                //TO DO: Why did lastPair work here for the basic drawing off screen example?
                                outputString = outputString.trimmingCharacters(in: .whitespaces) + "MV (" + String(lastPair.dx_adj) + ", " + String(lastPair.dy_adj) + ");\nPEN DOWN;\n"
                                
                                //outputString = outputString.trimmingCharacters(in: .whitespaces) + "MV (" + String(pairs[currentIndex].dx_adj) + ", " + String(pairs[currentIndex].dy_adj) + ");\nPEN DOWN;\n"
                            }
                            outputString = outputString.trimmingCharacters(in: .whitespaces) + "MV (" + String(pairs[currentIndex].dx) + ", " + String(pairs[currentIndex].dy) + ")"
                        } else {
                            outputString += "(" + String(pairs[currentIndex].dx) + ", " + String(pairs[currentIndex].dy) + ") "
                        }
                    }
                } else { //f let lastPair = lastPair
                    pairs.append(Drawing.Pair(dx:     elements[index - 1],
                                              dx_adj: elements[index - 1],
                                              dy:     element,
                                              dy_adj: element,
                                              outOfBounds: false))
                    let currentIndex = pairs.count - 1
                    outputString += "(" + String(pairs[currentIndex].dx) + ", " + String(pairs[currentIndex].dy) + ") "
                }
                //Set last pair.
                lastPair = pairs[pairs.count - 1]
            } //if isEven
        }
        outputString = outputString.trimmingCharacters(in: .whitespaces) + ";\n"
    }
    
    /**
     * In this system, commands are represented in the data stream by a single (un-encoded) opcode byte that can be identified by always having its most significant bit set, followed by zero or more bytes containing encoded data values. Any unrecognized commands encountered in an input stream should be ignored.
     */
    
    static func command(input: String) -> String? {
        
        guard let decimalInput = UInt8(input, radix: 16), decimalInput & 0b1000_0000 != 0 else {
            return nil
        }
        
        switch input {
        case Constants.ClearCode:
            return Constants.ClearText
        case Constants.PenCode:
            return Constants.PenText
        case Constants.ColorCode:
            return Constants.ColorText
        case Constants.MoveCode:
            return Constants.MoveText
        default:
            return Constants.UnknownText
        }
    }
}
