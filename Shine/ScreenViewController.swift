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

    var brightness: CGFloat = 0.0 {
        didSet {
            brightness = max(min(brightness, 1.0), 0.0)

            // Adjust screen brightness.
            UIScreen.mainScreen().brightness = (brightness - brightnessThreshold) / 0.75

            // Darken screen background.
            let screenView = view as! ScreenView
            screenView.brightness = brightness
        }
    }

    var state: LightState = .On

    var brightnessLabel: UILabel!
    @IBOutlet weak var timerButton: UIButton!

    private lazy var brightnessFormatter: NSNumberFormatter = {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .PercentStyle
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0

        return formatter
    }()

    private lazy var timerFormatter: NSDateComponentsFormatter = {
        let formatter = NSDateComponentsFormatter()
        formatter.unitsStyle = .Positional
        formatter.allowedUnits = [.Hour, .Minute]
        formatter.maximumUnitCount = 2
        formatter.zeroFormattingBehavior = .None

        return formatter
    }()

    private var panLocation = CGPoint()

    private var refreshBlinker = false

    private var turnOffTimer: NSTimer?
    private var refreshTimer: NSTimer?

    private var timerRunning = false {
        didSet {
            if timerRunning {
                // Start timers.
                turnOffTimer = NSTimer.scheduledTimerWithTimeInterval(Settings.timerDuration, target: self, selector: "turnOff", userInfo: nil, repeats: false)
                refreshTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "refresh", userInfo: nil, repeats: true)
            } else {
                // Stop timers.
                turnOffTimer?.invalidate()
                refreshTimer?.invalidate()

                turnOffTimer = nil
                refreshTimer = nil
            }

            timerButton.setTitle(timerFormatter.stringFromDateComponents(timerComponents()), forState: .Normal)
        }
    }

    private var timerActive: Bool {
        return Settings.timerEnable && (Settings.timerDuration > 0)
    }

    // MARK: Constants

    private let brightnessThreshold: CGFloat = 0.25

    // MARK: Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupBrightness()
        setupBackgroundColor()

        brightnessLabel = UILabel(frame: CGRect(x: view.bounds.midX - 50.0, y: view.bounds.midY - 32.0, width: 100.0, height: 64.0))
        brightnessLabel.font = UIFont.systemFontOfSize(36.0)
        brightnessLabel.textAlignment = .Center
        brightnessLabel.alpha = 0.0
        view.addSubview(brightnessLabel)

        setupForegroundColor()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "start", name: UIApplicationDidBecomeActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "stop", name: UIApplicationWillResignActiveNotification, object: nil)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillResignActiveNotification, object: nil)

        stop()
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowSettingsSegue" {
            let presentationSegue = segue as! MZFormSheetPresentationViewControllerSegue
            presentationSegue.formSheetPresentationController.contentViewControllerTransitionStyle = .Fade
            if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
                presentationSegue.formSheetPresentationController.presentationController?.contentViewSize = CGSize(width: view.bounds.width - 16.0, height: 360.0)
            } else {
                presentationSegue.formSheetPresentationController.presentationController?.contentViewSize = CGSize(width: 320.0, height: 480.0)
            }
            presentationSegue.formSheetPresentationController.presentationController?.shouldCenterVertically = true
            presentationSegue.formSheetPresentationController.presentationController?.shouldDismissOnBackgroundViewTap = true
            presentationSegue.formSheetPresentationController.willPresentContentViewControllerHandler = { [unowned self] _ in
                if self.timerActive {
                    self.timerRunning = false
                }
            }
            presentationSegue.formSheetPresentationController.didDismissContentViewControllerHandler = { [unowned self] _ in
                if self.timerActive {
                    self.timerRunning = true
                }
            }

            let settingsNavController = segue.destinationViewController as! UINavigationController
            let settingsViewController = settingsNavController.topViewController as! SettingsFormViewController
            settingsViewController.delegate = self
        }
    }

    // MARK: Actions

    @IBAction func adjustBrightness(sender: UIPanGestureRecognizer) {
        if state == .On {
            switch sender.state {
            case .Began:
                if timerActive {
                    timerRunning = false
                }

                panLocation = sender.locationInView(view)

                brightnessLabel.alpha = 1.0
                brightnessLabel.frame = CGRect(origin: locationForLabel(fromLocation: panLocation), size: brightnessLabel.frame.size)
                brightnessLabel.text = brightnessFormatter.stringFromNumber(brightness)

                setupForegroundColor()

            case .Changed:
                // Calculate pan.
                let actPanLocation = sender.locationInView(view)
                let panTranslation = panLocation.y - actPanLocation.y
                panLocation = actPanLocation

                // Calculate brightness.
                brightness += panTranslation / (view.bounds.height * 0.75)

                brightnessLabel.frame = CGRect(origin: locationForLabel(fromLocation: actPanLocation), size: brightnessLabel.frame.size)
                brightnessLabel.text = brightnessFormatter.stringFromNumber(brightness)

                setupForegroundColor()

            case .Ended:
                // Store final screen brightness into user defaults.
                Settings.brightness = Float(brightness)

                UIView.animateWithDuration(1.0, animations: { [unowned self] in
                    self.brightnessLabel.alpha = 0.0
                })

                if timerActive {
                    timerRunning = true
                }

            case .Cancelled, .Failed:
                setupBrightness()

                brightnessLabel.alpha = 0.0

                if timerActive {
                    timerRunning = true
                }

            default:
                setupBrightness()

                brightnessLabel.alpha = 0.0

                if timerActive {
                    timerRunning = true
                }
            }
        }
    }

    @IBAction func toggleLight(sender: UITapGestureRecognizer) {
        if Settings.doubleTap && (sender.state == .Ended) {
            switch state {
            case .Off:
                start()

                // If the screen is not yet automatically locked, when switching the light back on, I need to disable automatic lock.
                if Settings.lockScreen {
                    UIApplication.sharedApplication().idleTimerDisabled = true
                }

            case .On:
                stop()

                turnOff()
            }

            state.toggle()
        }
    }

    @IBAction func showSettings(sender: UILongPressGestureRecognizer) {
        if sender.state == .Began {
            performSegueWithIdentifier("ShowSettingsSegue", sender: self)
        }
    }

    @IBAction func unwindToScreenViewController(segue: UIStoryboardSegue) {
        if !Settings.doubleTap && (state == .Off) {
            setupBrightness()

            state.toggle()
        }
    }

    // MARK: Notification handlers

    func start() {
        setupBrightness()

        if timerActive {
            timerRunning = true

            timerButton.hidden = false
        } else {
            timerButton.hidden = true
        }

        brightnessLabel.text = brightnessFormatter.stringFromNumber(brightness)

        // Fade label in/out.
        brightnessLabel.center = view.center
        UIView.animateKeyframesWithDuration(2.0, delay: 0.0, options: UIViewKeyframeAnimationOptions(rawValue: 0), animations: {
            UIView.addKeyframeWithRelativeStartTime(0.0, relativeDuration: 0.5, animations: { [unowned self] in
                self.brightnessLabel.alpha = 1.0
                })

            UIView.addKeyframeWithRelativeStartTime(0.5, relativeDuration: 0.5, animations: { [unowned self] in
                self.brightnessLabel.alpha = 0.0
                })
            }, completion: nil)
    }

    func stop() {
        if timerActive {
            timerRunning = false
        }
    }

    // MARK: Timers

    func turnOff() {
        brightness = 0.0

        if Settings.lockScreen {
            UIApplication.sharedApplication().idleTimerDisabled = false
        }
    }

    func refresh() {
        let timerDuration = timerFormatter.stringFromDateComponents(timerComponents())

        timerButton.setTitle(refreshBlinker ? timerDuration?.stringByReplacingOccurrencesOfString(":", withString: " ") : timerDuration, forState: .Normal)
        refreshBlinker = !refreshBlinker
    }

    // MARK: Setup

    func setupBrightness() {
        brightness = CGFloat(Settings.brightness)
    }

    private func setupBackgroundColor() {
        if let lightColor = LightColor(rawValue: Settings.lightColor) {
            view.backgroundColor = lightColor.color
        } else {
            view.backgroundColor = LightColor.White.color
        }
    }

    private func setupForegroundColor() {
        let frontColor = (brightness > brightnessThreshold) ? UIColor(white: 0.0, alpha: 0.25) : LightColor(rawValue: Settings.lightColor)?.color ?? LightColor.White.color

        brightnessLabel.textColor = frontColor

        if timerActive {
            timerButton.tintColor = frontColor
            timerButton.setTitleColor(frontColor, forState: .Normal)
        }
    }

    // MARK: Helper functions

    private func locationForLabel(fromLocation location: CGPoint) -> CGPoint {
        var newLocation = CGPoint()

        // Calculate horizontal position.
        let horzPadding: CGFloat = 40.0
        if location.x < view.bounds.midX {
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
        } else if newLocation.y > view.frame.height - brightnessLabel.frame.height - bottomLimit {
            newLocation.y = view.frame.height - brightnessLabel.frame.height - bottomLimit
        }

        return newLocation
    }

    private func timerComponents() -> NSDateComponents {
        guard let timer = turnOffTimer else {
            let duration = Settings.timerDuration
            let components = NSDateComponents()
            components.hour = Int(duration) / 3600
            components.minute = (Int(duration) % 3600) / 60

            return components
        }

        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        let components = calendar.components([.Hour, .Minute], fromDate: NSDate().dateByAddingTimeInterval(-60.0), toDate: timer.fireDate, options: NSCalendarOptions(rawValue: 0))

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
        setupForegroundColor()

        timerButton.setTitle(timerFormatter.stringFromDateComponents(timerComponents()), forState: .Normal)
        timerButton.hidden = false
    }

    func removeTimer() {
        timerButton.hidden = true
    }

    func updateTimer() {
        timerButton.setTitle(timerFormatter.stringFromDateComponents(timerComponents()), forState: .Normal)
    }

}
