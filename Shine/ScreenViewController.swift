// Copyright (c) 2015 Massimo Peri (@massimoksi)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit
import MZFormSheetPresentationController

class ScreenViewController: UIViewController {

    var brightness: CGFloat = 0.0
    
    var panLocation: CGPoint!
    
    @IBOutlet weak var overlayView: UIView!

    var brightnessLabel: UILabel!
    
    private lazy var brightnessFormatter: NSNumberFormatter = {
        var formatter = NSNumberFormatter()
        formatter.numberStyle = .PercentStyle
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let lightColor = LightColor(rawValue: Settings.lightColor) {
            view.backgroundColor = lightColor.color
        }
        else {
            view.backgroundColor = LightColor.White.color
        }
        
        brightnessLabel = UILabel(frame: CGRect(x: view.bounds.midX - 50.0, y: view.bounds.midY - 32.0, width: 100.0, height: 64.0))
        brightnessLabel.font = UIFont.systemFontOfSize(36.0)
        brightnessLabel.textAlignment = .Center
        brightnessLabel.textColor = UIColor(white: 0.65, alpha: 1.0)
        brightnessLabel.alpha = 0.0
        view.addSubview(brightnessLabel)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "resetBrightness", name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        brightnessLabel.text = brightnessFormatter.stringFromNumber(brightness)
        
        UIView.animateKeyframesWithDuration(2.0, delay: 0.0, options: UIViewKeyframeAnimationOptions(rawValue: 0), animations: {
            // Fade in.
            UIView.addKeyframeWithRelativeStartTime(0.0, relativeDuration: 0.5, animations: { [unowned self] in
                self.brightnessLabel.alpha = 1.0
            })
            
            // Fade out.
            UIView.addKeyframeWithRelativeStartTime(0.5, relativeDuration: 0.5, animations: { [unowned self] in
                self.brightnessLabel.alpha = 0.0
            })
        }, completion: nil)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
    }

    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "ShowSettingsSegue") {
            let presentationSegue = segue as! MZFormSheetPresentationViewControllerSegue
            presentationSegue.formSheetPresentationController.contentViewControllerTransitionStyle = .Fade
            presentationSegue.formSheetPresentationController.presentationController?.contentViewSize = CGSize(width: 300.0, height: 116.0)
            presentationSegue.formSheetPresentationController.presentationController?.shouldCenterVertically = true
            
            let settingsViewController = segue.destinationViewController as! SettingsViewController
            settingsViewController.delegate = self
        }
    }

    // MARK: - Actions
    
    @IBAction func adjustBrightness(sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .Began:
            panLocation = sender.locationInView(overlayView)

            brightnessLabel.frame = CGRect(origin: locationForLabelFromLocation(panLocation), size: brightnessLabel.frame.size)
            brightnessLabel.text = brightnessFormatter.stringFromNumber(brightness)
            brightnessLabel.alpha = 1.0
            
        case .Changed:
            // Calculate pan.
            let actPanLocation = sender.locationInView(overlayView)
            let panTranslation = panLocation.y - actPanLocation.y
            panLocation = actPanLocation

            // Calculate brightness.
            brightness += panTranslation / (overlayView.bounds.height * 0.75)
            brightness = max(min(brightness, 1.0), 0.0)

            brightnessLabel.frame = CGRect(origin: locationForLabelFromLocation(actPanLocation), size: brightnessLabel.frame.size)
            brightnessLabel.text = brightnessFormatter.stringFromNumber(brightness)
            
            // Calculate screen brightness.
            let screenBrightness = (brightness - 0.25) / 0.75
            UIScreen.mainScreen().brightness = screenBrightness

            softDimBrightness()
            
        case .Ended:
            // Store final screen brightness into user defaults.
            Settings.brightness = Float(brightness)
            
            UIView.animateWithDuration(1.0, animations: { [unowned self] in
                self.brightnessLabel.alpha = 0.0
            })
            
        case .Cancelled, .Failed:
            resetBrightness()

            brightnessLabel.alpha = 0.0
            
        default:
            resetBrightness()
            
            brightnessLabel.alpha = 0.0
        }
    }
    
    @IBAction func showSettings(sender: UILongPressGestureRecognizer) {
        if sender.state == .Began {
            performSegueWithIdentifier("ShowSettingsSegue", sender: self)
        }
    }

    @IBAction func unwindToScreenViewController(segue: UIStoryboardSegue) {
        // Nothing to do.
    }
    
    // MARK: - Notifications handlers
    
    func resetBrightness() {
        brightness = CGFloat(Settings.brightness)
        
        UIScreen.mainScreen().brightness = brightness
        
        softDimBrightness()
    }

    // MARK: - Private methods
    
    private func softDimBrightness() {
        // Darken screen background.
        overlayView.alpha = 1.0 - min(brightness / 0.25, 1.0)
    }
    
    private func locationForLabelFromLocation(location: CGPoint) -> CGPoint {
        var newLocation = CGPoint()

        // Calculate horizontal position.
        if (location.x < overlayView.bounds.midX) {
            newLocation.x = location.x + 8.0
        }
        else {
             newLocation.x = location.x - 8.0 - brightnessLabel.frame.width
        }
        
        // Calculate vertical position.
        newLocation.y = location.y - brightnessLabel.frame.height / 2.0
        if (newLocation.y < 4.0) {
            newLocation.y = 4.0
        }
        else if (newLocation.y > overlayView.frame.height - brightnessLabel.frame.height - 4.0) {
            newLocation.y = overlayView.frame.height - brightnessLabel.frame.height - 4.0
        }
        
        return newLocation
    }
    
}

// MARK: - Settings view controller delegate

extension ScreenViewController: SettingsViewControllerDelegate {
    
    func updateLightColor() {
        UIView.animateWithDuration(1.0, animations: {
            if let lightColor = LightColor(rawValue: Settings.lightColor) {
                self.view.backgroundColor = lightColor.color
            }
            else {
                self.view.backgroundColor = LightColor.White.color
            }
        })
    }
    
}
