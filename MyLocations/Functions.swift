//
//  Functions.swift
//  MyLocations
//
//  Created by Nikita Kalyuzhniy on 2/23/20.
//  Copyright © 2020 Nikita Kalyuzhniy. All rights reserved.
//

import Foundation
import Dispatch

func afterDelay(_ seconds: Double, closure: @escaping () -> ()) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: closure)
}
