//
//  String+AddText.swift
//  MyLocations
//
//  Created by Nikita Kalyuzhniy on 2/26/20.
//  Copyright © 2020 Nikita Kalyuzhniy. All rights reserved.
//

extension String {
    mutating func add(text: String?, separatedBy separator: String = "") {
        if let text = text {
            if !isEmpty {
                self += separator
            }
            self += text
        }
    }
}
