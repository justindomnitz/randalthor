//
//  Drawing.swift
//  artandlogic
//
//  Created by Justin Domnitz on 2/9/18.
//  Copyright © 2018 Lowyoyo, LLC. All rights reserved.
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

    /*
     Clear
     
     Command
     CLR
     Opcode
     F0
     Parameters
     (none)
     Output
     CLR;\n
     
     Cause the drawing to reset itself, including:
     setting the pen state to up
     setting the pen position back to (0,0)
     setting the current color to (0, 0, 0, 255) (black)
     clearing any output on the screen (not shown in our example output here)
    */
    
    static func clear() {
        //TO DO
    }
    
    /*
     Pen Up/Down
     
     Command
     PEN
     Opcode
     80
     Parameters
     0 = pen up
     any other value = pen down
     Output
     either PEN UP;\n or PEN DOWN;\n
     
     Change the state of the pen object to either up or down. When a pen is up, moving it leaves no trace on the drawing. When the pen is down and moves, it draws a line in the current color.
    */
    
    static func penUpDown(up: Int) {
        //TO DO
    }
    
    /*
     Set Color

     Command
     CO
     Opcode
     A0
     Parameters
     RGBA
     Red, Green, Blue, Alpha values, each in the range 0..255. All four values are required.
     Output
     CO {r} {g} {b} {a};\n (where each of the r/g/b/a values are formatted as integers 0..255
     
     Change the current color (including alpha) of the pen. The color change takes effect the next time the pen is moved. After clearing a drawing with the CLR; command, the current color is reset to black (0,0,0,255).
    */
    
    static func setColor(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        //Swift example...
        //let _ = UIColor(red: red, green: green, blue: blue, alpha: alpha)
        //TO DO
    }
    
    /*
     Move Pen
     
     Command
     MV
     Opcode
     C0
     Parameters
     dx0 dy0 [dx1 dy1 .. dxn dyn] Any number of (dx,dy) pairs.
     Output
     
     if pen is up, move the pen to the final coordinate position
     If pen is down: MV (xo, y0) (x1, y1) [... (xn, yn)];\n
     Change the location of the pen relative to its current location. If the pen is down, draw in the current color. If multiple (x, y) points are provided as parameters, each point moved to becomes the new current location in turn.
     Also note that the values used in your output should be absolute coordinates in the drawing space, not the relative coordinates used in the encoded movement commands.
     For example, after clearing a drawing, the current location is the origin at (0, 0). If the pen is moved (10, 10) and then (5, -5), the last location of the pen will be at (15, 5). For the purposes of this exercise, the string output would be
     
     MV (10, 10) (15, 5);
     
     if the pen is down, but just
     
     MV (15, 5);
     
     if the pen is up.
     
     If the specified motion takes the pen outside the allowed bounds of (-8192, -8192) .. (8191, 8191), the pen should move until it crosses that boundary and then lift. When additional movement commands bring the pen back into the valid coordinate space, the pen should be placed down at the boundary and draw to the next position in the data file.
    */
    
    static func movePen(pairs: [Pair]) {
        //TO DO
    }
    
    /*
     In this system, commands are represented in the data stream by a single (un-encoded) opcode byte that can be identified by always having its most significant bit set, followed by zero or more bytes containing encoded data values. Any unrecognized commands encountered in an input stream should be ignored.
    */
    
    static func command(input: String) -> String? {
        
        guard let decimalInput = UInt8(input, radix: 16), decimalInput & 0b1000_0000 != 0 else {
            return nil
        }
        
        switch input {
        case "F0":
            return "CLR"
        case "80":
            return "PEN"
        case "A0":
            return "CO"
        case "C0":
            return "MV"
        default:
            return "UNRECOGNIZED COMMAND"
        }
    }
    
    static func radialIntersectionWithDegrees(_ inputDegrees: Double, frame: CGRect) -> CGPoint {
        let radians = inputDegrees * Double.pi / 180
        return radialIntersectionWithRadians(radians, frame: frame)
    }
    
    static func radialIntersectionWithRadians(_ inputRadians: Double, frame: CGRect) -> CGPoint  {
        var radians = inputRadians
        radians = Double(fmodf(Float(radians), Float(2 * Double.pi)))
        if (radians < 0) {
            radians += 2 * Double.pi
        }
        return radialIntersectionWithConstrainedRadians(radians, frame: frame)
    }
    
    // This method requires 0 <= radians < 2 * π.
    static func radialIntersectionWithConstrainedRadians(_ radians: Double, frame: CGRect) -> CGPoint {
    
        let xRadius:Double = Double(frame.size.width / 2)
        let yRadius:Double = Double(frame.size.height / 2)
        
        let pointRelativeToCenter:CGPoint;
        let tangent:Double = Double(tanf(Float(radians)));
        let y:Double = xRadius * tangent;
        
        // An infinite line passing through the center at angle `radians`
        // intersects the right edge at Y coordinate `y` and the left edge
        // at Y coordinate `-y`.
        
        if (fabsf(Float(y)) <= Float(yRadius)) {
            // The line intersects the left and right edges before it intersects
            // the top and bottom edges.
            if ((radians < Double.pi/2) || (radians > (Double.pi + Double.pi/2))) {
                // The ray at angle `radians` intersects the right edge.
                pointRelativeToCenter = CGPoint(x: xRadius, y: -y);
            } else {
                // The ray intersects the left edge.
                pointRelativeToCenter = CGPoint(x: -xRadius, y: y);
            }
        } else {
            // The line intersects the top and bottom edges before it intersects
            // the left and right edges.
            let x:Double  = yRadius / tangent;
            if (radians < Double.pi) {
                // The ray at angle `radians` intersects the bottom edge.
                pointRelativeToCenter = CGPoint(x: x, y: -yRadius);
            } else {
                // The ray intersects the top edge.
                pointRelativeToCenter = CGPoint(x: -x, y: yRadius);
            }
        }
    
        return CGPoint(x: pointRelativeToCenter.x,
                       y: pointRelativeToCenter.y);
//        return CGPoint(x: pointRelativeToCenter.x,
//                       y: pointRelativeToCenter.y);
    }
}
