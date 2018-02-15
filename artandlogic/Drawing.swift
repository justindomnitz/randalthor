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
        var dx_orig: Int
        var dy_orig: Int
        var dx: Int
        var dy: Int
        var dx_adj: Int
        var dy_adj: Int
        
        func adjString() -> String {
            return "(" + String(dx_adj) + ", " + String(dy_adj) + ")"
        }
        
        func outOfBounds() -> Bool {
            return dx > Constants.UpperLimit ||
                   dx < Constants.LowerLimit ||
                   dy > Constants.UpperLimit ||
                   dy < Constants.LowerLimit
        }
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
                element = Constants.Up
                penUp = true
            } else {
                element = Constants.Down
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
    
    static func movePen(command:String, inputDataElements: [String], penUp: inout Bool, outputString: inout String, outerIndex: inout Int, inputOutputlastPair: inout Drawing.Pair?) {
        
        //Add the MV command.
        outputString += command + Constants.Space
        outerIndex += 1
        
        //Build a list of our x and y points.
        var coordinates = [Int]()
        while outerIndex + 1 < inputDataElements.count,
            Drawing.command(input: inputDataElements[outerIndex]) == nil {
                coordinates.append(Model.artandlogicDecode(from: inputDataElements[outerIndex] + inputDataElements[outerIndex + 1]) ?? 0)
                outerIndex += 2
        }
        
        //Make pairs.
        var pairs = [Drawing.Pair]()
        for (index, _) in coordinates.enumerated() {
            if (index + 1) % 2 == 0 { //Complete pair.
                
                //Set our last pair from the passed in parameter or from the previous pair if there is one.
                let lastPair = (pairs.count > 0 ? pairs[pairs.count - 1] : nil) ?? inputOutputlastPair
                
                pairs.append(Drawing.Pair(dx_orig: coordinates[index - 1]                     ,
                                          dy_orig: coordinates[index]                         ,
                                          dx:      coordinates[index - 1] + (lastPair?.dx ?? 0),
                                          dy:      coordinates[index]     + (lastPair?.dy ?? 0),
                                          dx_adj:  coordinates[index - 1] + (lastPair?.dx ?? 0),
                                          dy_adj:  coordinates[index]     + (lastPair?.dy ?? 0)))
                
                let currentIndex = pairs.count - 1
                
                //Adjust our pair if we've gone out of bounds.
                if pairs[currentIndex].outOfBounds() {
                    if let lastPair = lastPair  {
                        if pairs[currentIndex].dx == lastPair.dx {
                            pairs[currentIndex].dx_adj = min(Constants.UpperLimit, pairs[currentIndex].dx_adj)
                            pairs[currentIndex].dx_adj = max(Constants.LowerLimit, pairs[currentIndex].dx_adj)
                        } else {
                            let distanceFromRightSide:Float = Float(Constants.UpperLimit - lastPair.dy)
                            let distanceFromRightSideRatio:Float = distanceFromRightSide / Float(lastPair.dy == 0 ? 1 : lastPair.dy)
                            let newHeight:Float = distanceFromRightSideRatio * Float(lastPair.dx - pairs[currentIndex].dx)
                            let touchHeight:Float = Float(lastPair.dx) - newHeight
                            pairs[currentIndex].dx_adj = Int(touchHeight.rounded())
                        }
                        
                        if pairs[currentIndex].dy == lastPair.dy {
                            pairs[currentIndex].dy_adj = min(Constants.UpperLimit, pairs[currentIndex].dy_adj)
                            pairs[currentIndex].dy_adj = max(Constants.LowerLimit, pairs[currentIndex].dy_adj)
                        } else {
                            let distanceFromRightSide:Float = Float(Constants.UpperLimit - lastPair.dx)
                            let distanceFromRightSideRatio:Float = distanceFromRightSide / Float(lastPair.dx == 0 ? 1 : lastPair.dx)
                            let newHeight:Float = distanceFromRightSideRatio * Float(lastPair.dy - pairs[currentIndex].dy)
                            let touchHeight:Float = Float(lastPair.dy) - newHeight
                            pairs[currentIndex].dy_adj = Int(touchHeight.rounded())
                        }
                    }
                }
                
                //Out of bounds.
                if pairs[currentIndex].outOfBounds() && !penUp {
                    //Current point is out of bounds and the pen is down.
                    
                    //Move to our adjusted location.
                    outputString += pairs[currentIndex].adjString() + Constants.NewLine
                    
                    //Lift the pen.
                    penUp = true
                    outputString += Constants.PenText + Constants.Space + Constants.Up + Constants.NewLine
                }
                
                //Out of bounds.
                if pairs[currentIndex].outOfBounds() && !penUp {
                    //Current point is out of bounds and the pen is down.
                    
                    //Invalid.  Should not be any way of getting here.
                    print(Constants.ErrorMessage)
                }
                
                //In bounds.
                if !pairs[currentIndex].outOfBounds() {
                    //Current point is in bounds.

                    if let lastPair = lastPair, lastPair.outOfBounds(), penUp {
                        //Last point was out of bounds and we are now in bounds and the pen is up.
                        
                        //Move to the point where we enter the bounds...

                        var reentryPair = pairs[currentIndex]
                        
                        if pairs[currentIndex].dy == lastPair.dy {
                            reentryPair.dy_adj = min(Constants.UpperLimit, pairs[currentIndex].dy_adj)
                            reentryPair.dy_adj = max(Constants.LowerLimit, pairs[currentIndex].dy_adj)
                        } else {
                            let distanceFromRightSide:Float = Float(Constants.UpperLimit - pairs[currentIndex].dy)
                            let distanceFromRightSideRatio:Float = distanceFromRightSide / Float(pairs[currentIndex].dy == 0 ? 1 : pairs[currentIndex].dy)
                            let newHeight:Float = distanceFromRightSideRatio * Float(lastPair.dx - pairs[currentIndex].dx)
                            let touchHeight:Float = newHeight - Float(pairs[currentIndex].dx)
                            reentryPair.dy_adj = Constants.UpperLimit
                            reentryPair.dx_adj = Int(touchHeight.rounded())
                        }
                        
                        if pairs[currentIndex].dx == lastPair.dx {
                            reentryPair.dx_adj = min(Constants.UpperLimit, pairs[currentIndex].dx_adj)
                            reentryPair.dx_adj = max(Constants.LowerLimit, pairs[currentIndex].dx_adj)
                        } else {
                            let distanceFromRightSide:Float = Float(Constants.UpperLimit - pairs[currentIndex].dx)
                            let distanceFromRightSideRatio:Float = distanceFromRightSide / Float(pairs[currentIndex].dx == 0 ? 1 : pairs[currentIndex].dx)
                            let newHeight:Float = distanceFromRightSideRatio * Float(lastPair.dy - pairs[currentIndex].dy)
                            let touchHeight:Float = newHeight - Float(pairs[currentIndex].dy)
                            reentryPair.dx_adj = Constants.UpperLimit
                            reentryPair.dy_adj = Int(touchHeight.rounded())
                        }
                        
                        outputString += Constants.MoveText + Constants.Space + reentryPair.adjString() + Constants.NewLine
                        
                        //...Then, put pen down.
                        penUp = false
                        outputString += Constants.PenText + Constants.Space + Constants.Down + Constants.NewLine + Constants.MoveText + Constants.Space
                    } else {
                        //Last point was in bounds.
                        
                        //Do nothing.
                    }
                    
                    //Move to our adjusted location.
                    outputString += pairs[currentIndex].adjString() + Constants.Space
                }
                
            } //if isEven
        }

        //Remove any extra white space and add a cariage return before exiting.
        outputString = outputString.trimmingCharacters(in: .whitespaces) + Constants.NewLine
 
        //Set our last pair before exiting.
        inputOutputlastPair = pairs.count > 0 ? pairs[pairs.count - 1] : nil
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
