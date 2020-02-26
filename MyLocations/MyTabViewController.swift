//
//  MyTabViewController.swift
//  MyLocations
//
//  Created by Nikita Kalyuzhniy on 2/26/20.
//  Copyright © 2020 Nikita Kalyuzhniy. All rights reserved.
//

import UIKit

class MyTabViewController: UITabBarController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override var childForStatusBarStyle: UIViewController? {
        return nil
    }
}
