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

    // MARK: Properties

    @IBOutlet weak var overlayView: UIView!

    var brightnessLabel: UILabel!
    var timerButton: UIButton!

    var brightness: CGFloat = 0.0
    var lightOn: Bool = false   // TODO: Create a light state variable.

    var panLocation: CGPoint = CGPointZero

    private lazy var brightnessFormatter: NSNumberFormatter = {
        var formatter = NSNumberFormatter()
        formatter.numberStyle = .PercentStyle
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0

        return formatter
    }()

    private lazy var timerFormatter: NSDateComponentsFormatter = {
        var formatter = NSDateComponentsFormatter()
        formatter.unitsStyle = .Positional
        formatter.allowedUnits = [.Hour, .Minute]
        formatter.maximumUnitCount = 2
        formatter.zeroFormattingBehavior = .None

        return formatter
    }()

    private var timer: NSTimer?

    private var timerActive: Bool {
        return Settings.timerEnable && (Settings.timerDuration > 0)
    }

    // MARK: Constants

    private let brightnessThreshold: CGFloat = 0.25

    // MARK: Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupBrightness()
        setupBackground()
        setupSubviews()
        setupConstraints()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "resetBrightness", name: UIApplicationDidBecomeActiveNotification, object: nil)

        // Trigger timer.
        let duration = Settings.timerDuration
        if timerActive {
            timer = NSTimer.scheduledTimerWithTimeInterval(duration, target: self, selector: "turnOff", userInfo: nil, repeats: false)
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        lightOn = true

        brightnessLabel.text = brightnessFormatter.stringFromNumber(brightness)

        // Fade label in/out.
        UIView.animateKeyframesWithDuration(2.0, delay: 0.0, options: UIViewKeyframeAnimationOptions(rawValue: 0), animations: {
            UIView.addKeyframeWithRelativeStartTime(0.0, relativeDuration: 0.5, animations: { [unowned self] in
                self.brightnessLabel.alpha = 1.0
            })

            UIView.addKeyframeWithRelativeStartTime(0.5, relativeDuration: 0.5, animations: { [unowned self] in
                self.brightnessLabel.alpha = 0.0
            })
        }, completion: nil)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)

        timer?.invalidate()
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowSettingsSegue" {
            let presentationSegue = segue as! MZFormSheetPresentationViewControllerSegue
            presentationSegue.formSheetPresentationController.contentViewControllerTransitionStyle = .Fade
            presentationSegue.formSheetPresentationController.presentationController?.contentViewSize = CGSize(width: 300.0, height: 300.0)
            presentationSegue.formSheetPresentationController.presentationController?.shouldCenterVertically = true
            presentationSegue.formSheetPresentationController.presentationController?.shouldDismissOnBackgroundViewTap = true

            let settingsNavController = segue.destinationViewController as! UINavigationController
            let settingsViewController = settingsNavController.topViewController as! SettingsFormViewController
            settingsViewController.delegate = self
        }
    }

    // MARK: Actions

    @IBAction func adjustBrightness(sender: UIPanGestureRecognizer) {
        if lightOn {
            switch sender.state {
            case .Began:
                panLocation = sender.locationInView(overlayView)

                brightnessLabel.alpha = 1.0
                brightnessLabel.frame = CGRect(origin: locationForLabel(fromLocation: panLocation), size: brightnessLabel.frame.size)
                brightnessLabel.text = brightnessFormatter.stringFromNumber(brightness)

                updateColors()

            case .Changed:
                // Calculate pan.
                let actPanLocation = sender.locationInView(overlayView)
                let panTranslation = panLocation.y - actPanLocation.y
                panLocation = actPanLocation

                // Calculate brightness.
                brightness += panTranslation / (overlayView.bounds.height * 0.75)
                brightness = max(min(brightness, 1.0), 0.0)

                adjustLight()

                brightnessLabel.frame = CGRect(origin: locationForLabel(fromLocation: actPanLocation), size: brightnessLabel.frame.size)
                brightnessLabel.text = brightnessFormatter.stringFromNumber(brightness)

                updateColors()

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
    }

    @IBAction func switchOffLight(sender: UITapGestureRecognizer) {
        if Settings.doubleTap && (sender.state == .Ended) {
            if lightOn {
                turnOff()

                lightOn = false
            } else {
                resetBrightness()

                lightOn = true
            }
        }
    }

    func turnOff() {
        brightness = 0.0
        adjustLight()
    }

    @IBAction func showSettings(sender: UILongPressGestureRecognizer) {
        if sender.state == .Began {
            performSegueWithIdentifier("ShowSettingsSegue", sender: self)
        }
    }

    @IBAction func unwindToScreenViewController(segue: UIStoryboardSegue) {
        if !Settings.doubleTap && !lightOn {
            lightOn = true

            resetBrightness()
        }
    }

    // MARK: Notifications handlers

    // TODO: is this function necessary?
    func resetBrightness() {
        brightness = CGFloat(Settings.brightness)

        adjustLight()
    }

    // MARK: Setup

    private func setupBrightness() {
        brightness = CGFloat(Settings.brightness)
    }

    private func setupBackground() {
        if let lightColor = LightColor(rawValue: Settings.lightColor) {
            view.backgroundColor = lightColor.color
        } else {
            view.backgroundColor = LightColor.White.color
        }
    }

    private func setupSubviews() {
        brightnessLabel = UILabel(frame: CGRect(x: view.bounds.midX - 50.0, y: view.bounds.midY - 32.0, width: 100.0, height: 64.0))
        brightnessLabel.font = UIFont.systemFontOfSize(36.0)
        brightnessLabel.textAlignment = .Center
        brightnessLabel.alpha = 0.0

        timerButton = UIButton()
        timerButton.setImage(UIImage(named: "Timer"), forState: .Normal)
        timerButton.translatesAutoresizingMaskIntoConstraints = false
        timerButton.titleEdgeInsets = UIEdgeInsets(top: 0.0, left: 12.0, bottom: 0.0, right: 0.0)
        if timerActive {
            timerButton.setTitle(timerFormatter.stringFromDateComponents(timerComponents(fromDuration: Settings.timerDuration)), forState: .Normal)
            timerButton.alpha = 1.0
        } else {
            timerButton.alpha = 0.0
        }

        updateColors()

        view.addSubview(brightnessLabel)
        view.addSubview(timerButton)
    }

    private func setupConstraints() {
        let viewsDict = [
            "button": timerButton
        ]

        let horzConstraint = NSLayoutConstraint.constraintsWithVisualFormat("H:|-12-[button]-12-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDict)
        view.addConstraints(horzConstraint)

        let vertConstraint = NSLayoutConstraint.constraintsWithVisualFormat("V:[button(40)]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDict)
        view.addConstraints(vertConstraint)
    }

    // MARK: Helper functions

    private func adjustLight() {
        // Adjust screen brightness.
        let screenBrightness = (brightness - brightnessThreshold) / 0.75
        UIScreen.mainScreen().brightness = screenBrightness

        // Darken screen background.
        overlayView.alpha = 1.0 - min(brightness / brightnessThreshold, 1.0)
    }

    private func updateColors() {
        var frontColor: UIColor
        if brightness > brightnessThreshold {
            frontColor = UIColor(white: 0.0, alpha: 0.25)
        } else {
            frontColor = LightColor(rawValue: Settings.lightColor)?.color ?? LightColor.White.color
        }

        brightnessLabel.textColor = frontColor

        if timerActive {
            timerButton.tintColor = frontColor
            timerButton.setTitleColor(frontColor, forState: .Normal)
        }
    }

    private func locationForLabel(fromLocation location: CGPoint) -> CGPoint {
        var newLocation = CGPoint()

        // Calculate horizontal position.
        let horzPadding: CGFloat = 40.0
        if location.x < overlayView.bounds.midX {
            newLocation.x = location.x + horzPadding
        } else {
             newLocation.x = location.x - horzPadding - brightnessLabel.frame.width
        }

        // Calculate vertical position.
        let vertPadding: CGFloat = 4.0
        let bottomLimit: CGFloat = timerActive ? (timerButton.frame.height + vertPadding) : vertPadding

        newLocation.y = location.y - brightnessLabel.frame.height / 2.0
        if newLocation.y < vertPadding {
            newLocation.y = vertPadding
        } else if newLocation.y > overlayView.frame.height - brightnessLabel.frame.height - bottomLimit {
            newLocation.y = overlayView.frame.height - brightnessLabel.frame.height - bottomLimit
        }

        return newLocation
    }

    private func timerComponents(fromDuration duration: NSTimeInterval) -> NSDateComponents {
        let components = NSDateComponents()
        components.hour = Int(duration) / 3600
        components.minute = (Int(duration) % 3600) / 60

        return components
    }

}

// MARK: - Settings view controller delegate

extension ScreenViewController: SettingsFormViewDelegate {

    func updateLightColor() {
        UIView.animateWithDuration(1.0, animations: {
            self.view.backgroundColor = LightColor(rawValue: Settings.lightColor)?.color ?? LightColor.White.color
        })
    }

    func startTimer() {
        timer = NSTimer.scheduledTimerWithTimeInterval(Settings.timerDuration, target: self, selector: "turnOff", userInfo: nil, repeats: false)

        updateColors()

        timerButton.setTitle(timerFormatter.stringFromDateComponents(timerComponents(fromDuration: Settings.timerDuration)), forState: .Normal)
        timerButton.alpha = 1.0
    }

    func removeTimer() {
        timer?.invalidate()

        timerButton.alpha = 0.0
    }

    func updateTimer() {
        timer?.invalidate()
        timer = NSTimer.scheduledTimerWithTimeInterval(Settings.timerDuration, target: self, selector: "turnOff", userInfo: nil, repeats: false)

        timerButton.setTitle(timerFormatter.stringFromDateComponents(timerComponents(fromDuration: Settings.timerDuration)), forState: .Normal)
    }

}
