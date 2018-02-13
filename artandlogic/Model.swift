//
//  Model.swift
//  artandlogic
//
//  Created by Justin Domnitz on 1/1/18.
//  Copyright (c) 2018 Art & Logic, Inc. All Rights Reserved.
//

import UIKit

class Model: NSObject {

    static let adjustment = 8192
    
    struct DataPacket {
        var dataSets = [UInt8](repeating: 0, count: 8)
        
        func encodedRepresentation() -> [UInt8] {
            var packet = [UInt8](repeating: 0, count: 8)
            
            var carryOver = false
            
            //Loop through each byte.
            for (byteIndex, dataSet) in dataSets.enumerated() {
                
                //print("Examining byte \(byteIndex) decimal value \(dataSet).")
                
                //Set the value.
                packet[byteIndex] = dataSet
                
                //Only shift the second byte.
                if byteIndex == 1 {
                    packet[byteIndex] = packet[byteIndex] << 1
                }
                
                if carryOver {
                    //Carry over the value.
                    packet[byteIndex] |= 0b0000_0001
                    carryOver = false
                } else {
                    //Find the most significant bit.
                    let bitmask:UInt8 = 1 << 7
                    if dataSet & bitmask > 0 {
                        //print("The current significant digit of byte \(byteIndex) is 7.")
                        if byteIndex == 0 { //Carry over from the first byte.
                            packet[byteIndex] &= ~bitmask //Clear the most significant bit.
                            carryOver = true
                        }
                    }
                }
                
            }
            
            return packet
        }
        
        func decodedRepresentation() -> [UInt8] {
            var packet = [UInt8](repeating: 0, count: 8)
            
            var carryOver = false
            
            //Loop through each byte in reverse order.
            var byteIndex = dataSets.count - 1
            for dataSet in dataSets {
                
                //print("Examining byte \(byteIndex) decimal value \(dataSet).")
                
                //Set the value.
                packet[byteIndex] = dataSet
                
                //Only shift the second byte.
                if byteIndex == 1 {
                    packet[byteIndex] = packet[byteIndex] >> 1
                }
                
                if carryOver {
                    //Carry over the value.
                    packet[byteIndex] |= 0b1000_0000
                    carryOver = false
                } else {
                    let bitmask:UInt8 = 1
                    if dataSet & bitmask > 0 {
                        //print("The least significant digit of byte \(byteIndex) is 0.")
                        if byteIndex == 1 { //Carry over from the last byte.
                            carryOver = true
                        }
                    }
                }
                
                byteIndex -= 1
            }
            
            return packet
        }

    }
    
    //This function needs to accept a signed integer in the 14-bit range [-8192..+8191] and return a 4 character string.
    static func artandlogicEncode(from: Int) -> String? {
        
        guard from >= -8192 && from <= 8191 else {
            return nil
        }
        
        //1 - Add 8192 to the raw value, so its range is translated to [0..16383].
        let intermediateDecimalValue = from + adjustment
        print("intermediateDecimalValue: \(intermediateDecimalValue)")
        
        //2 - Pack that value into two bytes such that the most significant bit of each is cleared.
        //    Unencoded intermediate value (as a 16-bit integer): 00HHHHHH HLLLLLLL
        //    Encoded value: 0HHHHHHH 0LLLLLLL
        var dataPacket = DataPacket()
        dataPacket.dataSets = toByteArray(intermediateDecimalValue)

        //3 - Format the two bytes as a single 4-character hexadecimal string and return it.
        let packet = dataPacket.encodedRepresentation()
        let encodedHexValue = String(format:"%02X%02X", packet[1], packet[0])

        return encodedHexValue
    }
    
    //Your decoding function should accept two bytes on input, both in the range [0x00..0x7F] and recombine them to return the corresponding integer between [-8192..+8191]
    static func artandlogicDecode(from: String) -> Int? {
        
        //0 - Check to make sure we have exactly four characters.
        guard from.count == 4 else {
            return nil
        }
        
        //1 - Convert the 4-character hexadecimal string to two bytes.
        guard let dataSets = stringToBytes(from) else {
            return nil
        }
        
        //2 - Unpack that value into two bytes such that the most significant bit of each is set.
        var dataPacket = DataPacket()
        dataPacket.dataSets = dataSets
        
        //3 - Subtract 8192 to the raw value, its range is translated to [-8192..+8191]. //TO DO!
        let intermediateDecimalValue = fromByteArray(dataPacket.decodedRepresentation(), Int.self) - adjustment

        return intermediateDecimalValue
    }
    
    //MARK: - Helper Methods
    
    static func stringToBytes(_ string: String) -> [UInt8]? {
        let length = string.count
        if length & 1 != 0 {
            return nil
        }
        var bytes = [UInt8]()
        bytes.reserveCapacity(length/2)
        var index = string.startIndex
        for _ in 0..<length/2 {
            let nextIndex = string.index(index, offsetBy: 2)
            if let b = UInt8(string[index..<nextIndex], radix: 16) {
                bytes.append(b)
            } else {
                return nil
            }
            index = nextIndex
        }
        return bytes
    }
    
    static func toByteArray<T>(_ value: T) -> [UInt8] {
        var value = value
        return withUnsafeBytes(of: &value) { Array($0) }
    }
    
    static func fromByteArray<T>(_ value: [UInt8], _: T.Type) -> T {
        return value.withUnsafeBytes {
            $0.baseAddress!.load(as: T.self)
        }
    }
    
    static func split(_ str: String, _ count: Int) -> [String] {
        return stride(from: 0, to: str.count, by: count).map { i -> String in
            let startIndex = str.index(str.startIndex, offsetBy: i)
            let endIndex   = str.index(startIndex, offsetBy: count, limitedBy: str.endIndex) ?? str.endIndex
            return String(str[startIndex..<endIndex])
        }
    }
    
}
