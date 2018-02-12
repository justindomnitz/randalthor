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
}
