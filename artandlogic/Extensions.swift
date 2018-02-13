//
//  Extensions.swift
//  artandlogic
//
//  Created by Justin Domnitz on 2/13/18.
//  Copyright (c) 2018 Art & Logic, Inc. All Rights Reserved.
//

extension String {
    func removingWhitespacesAndNewlines() -> String {
        return components(separatedBy: .whitespacesAndNewlines).joined()
    }
}
