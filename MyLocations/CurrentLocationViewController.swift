//
//  FirstViewController.swift
//  MyLocations
//
//  Created by Nikita Kalyuzhniy on 2/19/20.
//  Copyright © 2020 Nikita Kalyuzhniy. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData
import QuartzCore
import AudioToolbox

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate, CAAnimationDelegate
{
    let locationManager = CLLocationManager()
    var location: CLLocation?
    var updatingLocation = false
    var lastLocationError: Error?
    
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    var performingReverseGeocoding = false
    var lastGeocoddingError: Error?
    
    var timer: Timer?
    
    var managedObjectContext: NSManagedObjectContext!
    var soundID: SystemSoundID = 0
    
    // MARK: - Sound Effect
    
    func loadSoundEffect(_ name: String) {
        if let path = Bundle.main.path(forResource: name, ofType: nil) {
            let fileURL = URL(fileURLWithPath: path, isDirectory: false)
            let error = AudioServicesCreateSystemSoundID(fileURL as CFURL, &soundID)
            if error != kAudioServicesNoError {
                print("Error code \(error) loading sound at path: \(path)")
            }
        }
    }
    
    func unloadSoundEffect() {
        AudioServicesDisposeSystemSoundID(soundID)
        soundID = 0
    }
    
    func playSoundEffect() {
        AudioServicesPlaySystemSound(soundID)
    }
    
    //MARK:- Animation
    
    var logoVisible = false
    
    lazy var logoButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setBackgroundImage(UIImage(named: "Logo"), for: .normal)
        button.sizeToFit()
        button.addTarget(self, action: #selector(getLocation),
                               for: .touchUpInside)
        button.center.x = self.view.bounds.midX
        button.center.y = 220
        return button
    }()
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    @IBOutlet weak var latitudeTextLabel: UILabel!
    @IBOutlet weak var longitudeTextLabel: UILabel!
    @IBOutlet weak var containerView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadSoundEffect("Sound.caf")
        updateLabels()
        configureGetButton()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TagLocation" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! LocationDetailsViewController
            
            controller.coordinate = location!.coordinate
            controller.placemark = placemark
            controller.managedObjectContext = managedObjectContext
        }
    }
    
    //MARK:- Logo View
    
    func showLogoView() {
        if !logoVisible {
            logoVisible = true
            containerView.isHidden = true
            view.addSubview(logoButton)
        }
    }
    
    func hideLogoView() {
        
        if !logoVisible { return }
        
        logoVisible = false
        containerView.isHidden = false
        containerView.center.x = view.bounds.size.width * 2
        containerView.center.y = 40 + containerView.bounds.size.height / 2
        
        let centerX = view.bounds.midX
        
        let panelMover = CABasicAnimation(keyPath: "position")
        panelMover.isRemovedOnCompletion = false
        panelMover.fillMode = CAMediaTimingFillMode.forwards
        panelMover.duration = 0.6
        panelMover.fromValue = NSValue(cgPoint: containerView.center)
        panelMover.toValue = NSValue(cgPoint:
            CGPoint(x: centerX, y: containerView.center.y))
        panelMover.timingFunction = CAMediaTimingFunction(
            name: CAMediaTimingFunctionName.easeOut)
        panelMover.delegate = self
        containerView.layer.add(panelMover, forKey: "panelMover")
        
        let logoMover = CABasicAnimation(keyPath: "position")
        logoMover.isRemovedOnCompletion = false
        logoMover.fillMode = CAMediaTimingFillMode.forwards
        logoMover.duration = 0.5
        logoMover.fromValue = NSValue(cgPoint: logoButton.center)
        logoMover.toValue = NSValue(cgPoint:
            CGPoint(x: -centerX, y: logoButton.center.y))
        logoMover.timingFunction = CAMediaTimingFunction(
            name: CAMediaTimingFunctionName.easeIn)
        logoButton.layer.add(logoMover, forKey: "logoMover")
        
        let logoRotator = CABasicAnimation(keyPath: "transform.rotation.z")
        logoRotator.isRemovedOnCompletion = false
        logoRotator.fillMode = CAMediaTimingFillMode.forwards
        logoRotator.duration = 0.5
        logoRotator.fromValue = 0.0
        logoRotator.toValue = -2 * Double.pi
        logoRotator.timingFunction = CAMediaTimingFunction(
            name: CAMediaTimingFunctionName.easeIn)
        logoButton.layer.add(logoRotator, forKey: "logoRotator")
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        containerView.layer.removeAllAnimations()
        containerView.center.x = view.bounds.size.width / 2
        containerView.center.y = 40 + containerView.bounds.size.height / 2
        logoButton.layer.removeAllAnimations()
        logoButton.removeFromSuperview()
    }
    
    func showLocationServisesDeniedAlert() {
        let alert = UIAlertController(title: "Location servises disabled", message: "Please enable location sevices for this app in Settings", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alert.addAction(okAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    //FIXME: - UPDATELABEL NOT UPDATING
    
    func updateLabels() {
        if let location = location {
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            latitudeTextLabel.isHidden = false
            longitudeTextLabel.isHidden = false
            
            tagButton.isHidden = false
            messageLabel.text = ""
        } else {
            
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            addressLabel.text = ""
            tagButton.isHidden = true
            
            latitudeTextLabel.isHidden = true
            longitudeTextLabel.isHidden = true
            
            let statusMessage: String
            
            if let error = lastLocationError as NSError? {
                if error.domain == kCLErrorDomain && error.code == CLError.denied.rawValue {
                    statusMessage = "Location Services Disabled"
                } else {
                    statusMessage = "Error Getting Location"
                }
            } else if !CLLocationManager.locationServicesEnabled() {
                statusMessage = "Location Services Disabled"
            } else if updatingLocation {
                statusMessage = "Searching..."
            } else {
                statusMessage = ""
                showLogoView()
            }
            
            //FIXME: - placemark != placemark at first
            
            if let placemark = placemark {
                addressLabel.text = string(from: placemark)
            } else if performingReverseGeocoding {
                addressLabel.text = "Searching for Address..."
            } else if lastGeocoddingError != nil {
                addressLabel.text = "Error Finding Address"
            } else {
                addressLabel.text = "No Address Found"
            }
            
            messageLabel.text = statusMessage
        }
    }
    
    func string(from placemark: CLPlacemark) -> String {
        
        var line1 = ""
        
        line1 = add(text: placemark.subThoroughfare, toLine: line1, separatedBy: " ")
        line1 = add(text: placemark.thoroughfare, toLine: line1, separatedBy: " ")
        
        var line2 = " "
        
        line2 = add(text: placemark.locality, toLine: line2, separatedBy: "")
        line2 = add(text: placemark.administrativeArea, toLine: line2, separatedBy: " ")
        line2 = add(text: placemark.postalCode, toLine: line2, separatedBy: " ")
        line1.add(text: line2, separatedBy: "\n")
        return line1
    }
    
    func stopLocationManager() {
        if updatingLocation {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
            if let timer = timer {
                timer.invalidate()
            }
        }
    }
    
    func startLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
            
            timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(didTimeOut), userInfo: nil, repeats: false)
        }
    }
    
    func configureGetButton() {
        let spinnerTag = 1000
        
        if updatingLocation {
            getButton.setTitle("Stop", for: .normal)
            
            if view.viewWithTag(spinnerTag) == nil {
                let spinner = UIActivityIndicatorView(style: .white)
                spinner.center = messageLabel.center
                spinner.center.y += spinner.bounds.size.height/2 + 15
                spinner.startAnimating()
                spinner.tag = spinnerTag
                containerView.addSubview(spinner)
            }
        } else {
            getButton.setTitle("Get My Location", for: .normal)
            
            if let spinner = view.viewWithTag(spinnerTag) {
                spinner.removeFromSuperview()
            }
        }
    }
    
    func add(text: String?, toLine line: String, separatedBy separator: String) -> String {
        var result = line
        if let text = text {
            if !line.isEmpty {
                result += separator
            }
            result += text
        }
        return result
    }
    
    @objc func didTimeOut() {
        print("*** Time Out")
        
        if location == nil {
            stopLocationManager()
            lastGeocoddingError = NSError(domain: "MyLocationsErrorDomain", code: 1, userInfo: nil)
            
            updateLabels()
            configureGetButton()
        }
    }
    
    //MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError \(error)")
        
        
        
        if (error as NSError).code == CLError.locationUnknown.rawValue {
            return
        }
        lastLocationError = error
        
        stopLocationManager()
        configureGetButton()
        updateLabels()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let newLocation = locations.last!
        print("didUpdateLocations\(newLocation)")
        
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        
        var distance = CLLocationDistance(DBL_MAX)
        
        if let location = location {
            distance = newLocation.distance(from: location)
        }
        
        if location == nil ||
            location!.horizontalAccuracy > newLocation.horizontalAccuracy {
            
            location = newLocation
            lastLocationError = nil
            updateLabels()
            
            if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
                print("*** We're done!")
                stopLocationManager()
                updateLabels()
                configureGetButton()
                
                if distance > 0 {
                    performingReverseGeocoding = false
                }
            }
            
            if !performingReverseGeocoding {
                print("*** Going to geocode")
                
                performingReverseGeocoding = true
                
                geocoder.reverseGeocodeLocation(newLocation, completionHandler: {
                    placemarks, error in
                    
                    print("*** Found placemarks: \(String(describing: placemarks)), error: \(String(describing: error))")
                    
                    self.lastLocationError = error
                    if error == nil, let p = placemarks, !p.isEmpty {
                        
                        if self.placemark == nil {             // add this if block
                            print("FIRST TIME!")
                            self.playSoundEffect()
                        }
                        
                        self.placemark = p.last!
                    } else {
                        self.placemark = nil
                    }
                    
                    self.performingReverseGeocoding = false
                    self.updateLabels()
                })
            }
        } else if distance < 1 {
            let timeInterval = newLocation.timestamp.timeIntervalSince(location!.timestamp)
            if timeInterval > 10 {
                print("Force done")
                stopLocationManager()
                updateLabels()
                configureGetButton()
            }
        }
    }
    
    //MARK: - Actions
    
    @IBAction func getLocation() {
        
        let authStatus = CLLocationManager.authorizationStatus()
        
        if authStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        
        if authStatus == .denied || authStatus == .restricted {
            showLocationServisesDeniedAlert()
            return
        }
        
        if logoVisible {
            hideLogoView()
        }
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
    
        if updatingLocation {
            stopLocationManager()
        } else {
            location = nil
            lastLocationError = nil
            startLocationManager()
        }
        
        updateLabels()
        configureGetButton()
        updateLabels()
    }
}
