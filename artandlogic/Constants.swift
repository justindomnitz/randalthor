//
//  Constants.swift
//  artandlogic
//
//  Created by Justin Domnitz on 2/13/18.
//  Copyright (c) 2018 Art & Logic, Inc. All Rights Reserved.
//

struct Constants {

    static let AppName = "artandlogic"
    
    static let ErrorMessage = "ERROR"
 
    //Boundaries
    static let UpperLimit:Int =  8191
    static let LowerLimit:Int = -8192

    //String manipulation
    static let NewLine = ";\n"
    static let Space   = " "
    static let Up      = "UP"
    static let Down    = "DOWN"
    
    //Command code
    static let ClearCode = "F0"
    static let PenCode   = "80"
    static let ColorCode = "A0"
    static let MoveCode  = "C0"
    
    //Command text
    static let ClearText   = "CLR"
    static let PenText     = "PEN"
    static let ColorText   = "CO"
    static let MoveText    = "MV"
    static let UnknownText = "UNRECOGNIZED COMMAND"
}
