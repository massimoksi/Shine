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

    private enum State {
        case Idle
        case Running
        case Stopped
        case Paused
    }

    // MARK: Properties

    private var state: State = .Idle {
        didSet {
            switch state {
            case .Idle:
                // Stop timers.
                if timerActive {
                    timerRunning = false
                }

                // Enable automatic lock.
                UIApplication.sharedApplication().idleTimerDisabled = false

            case .Running:
                // Set brightness from user defaults.
                brightness = CGFloat(Settings.brightness)

                // Setup timers.
                if timerActive {
                    timerRunning = true

                    timerButton.hidden = false
                } else {
                    timerButton.hidden = true
                }

                // Fade brightness label in/out.
                if oldValue != .Paused {
                    brightnessLabel.center = view.center
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

                // Disable automatic lock.
                UIApplication.sharedApplication().idleTimerDisabled = true

            case .Stopped:
                // Turn the screen off.
                brightness = 0.0

                // Stop timers.
                if timerActive {
                    timerRunning = false
                }

                // Enable automatic lock.
                if Settings.lockScreen {
                    UIApplication.sharedApplication().idleTimerDisabled = false
                }

            case .Paused:
                // Stop timers.
                if timerActive {
                    timerRunning = false
                }
            }
        }
    }

    var brightness: CGFloat = 0.0 {
        didSet {
            // Condition brightness.
            brightness = max(min(brightness, 1.0), 0.0)

            // Update brightness label percentage.
            brightnessLabel.text = brightnessFormatter.stringFromNumber(brightness)

            // Adjust screen brightness.
            UIScreen.mainScreen().brightness = (brightness - brightnessThreshold) / 0.75

            // Darken screen background.
            let screenView = view as! ScreenView
            screenView.brightness = brightness

            // Adjust foreground color.
            adjustForegroundColor()

            // TODO: stop timers when brightness is 0%.
        }
    }

    let brightnessLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: 100.0, height: 64.0))
        label.font = UIFont.systemFontOfSize(36.0)
        label.textAlignment = .Center
        label.alpha = 0.0

        return label
    }()

    @IBOutlet weak var timerButton: UIButton! {
        didSet {
            // Use monospaced numbers (http://stackoverflow.com/questions/30854690/how-to-get-monospaced-numbers-in-uilabel-on-ios-9).
            timerButton.titleLabel?.font = timerButton.titleLabel?.font.monospacedDigitFont
        }
    }

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
        formatter.allowedUnits = [.Hour, .Minute, .Second]  // TODO: adjust depending on timer duration.
        formatter.zeroFormattingBehavior = .None

        return formatter
    }()

    private var panLocation = CGPoint()

    private var turnOffTimer: NSTimer?
    private var refreshTimer: NSTimer?

    private var timerRunning = false {
        didSet {
            if timerRunning {
                // Start timers.
                turnOffTimer = NSTimer.scheduledTimerWithTimeInterval(Settings.timerDuration, target: self, selector: "turnOffTimerDidFire:", userInfo: nil, repeats: false)
                refreshTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "refreshTimerDidFire:", userInfo: nil, repeats: true)
            } else {
                // Stop timers.
                turnOffTimer?.invalidate()
                refreshTimer?.invalidate()

                turnOffTimer = nil
                refreshTimer = nil
            }

            timerButton.setTitle(timerFormatter.stringFromTimeInterval(Settings.timerDuration), forState: .Normal)
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

        if let lightColor = LightColor(rawValue: Settings.lightColor) {
            view.backgroundColor = lightColor.color
        } else {
            view.backgroundColor = LightColor.White.color
        }

        view.addSubview(brightnessLabel)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationDidBecomeActive:", name: UIApplicationDidBecomeActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillResignActive:", name: UIApplicationWillResignActiveNotification, object: nil)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillResignActiveNotification, object: nil)
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
                self.state = .Paused
            }
            presentationSegue.formSheetPresentationController.didDismissContentViewControllerHandler = { [unowned self] _ in
                self.state = .Running
            }

            let settingsNavController = segue.destinationViewController as! UINavigationController
            let settingsViewController = settingsNavController.topViewController as! SettingsFormViewController
            settingsViewController.delegate = self
        }
    }

    @IBAction func unwindToScreenViewController(segue: UIStoryboardSegue) {
        // Do nothing.
    }

    // MARK: Actions

    @IBAction func handlePan(sender: UIPanGestureRecognizer) {
        if state == .Running {
            switch sender.state {
            case .Began:
                // Pause timers.
                if timerActive {
                    timerRunning = false
                }

                panLocation = sender.locationInView(view)

            case .Changed:
                // Calculate new brightness.
                let actPanLocation = sender.locationInView(view)
                let panTranslation = panLocation.y - actPanLocation.y
                brightness += panTranslation / (view.bounds.height * 0.75)
                panLocation = actPanLocation

                // Move brightness label.
                brightnessLabel.frame = CGRect(origin: locationForLabel(fromLocation: actPanLocation), size: brightnessLabel.frame.size)
                brightnessLabel.alpha = 1.0

            case .Ended:
                // Store final screen brightness into user defaults.
                Settings.brightness = Float(brightness)

                // Fade brightness label out.
                UIView.animateWithDuration(1.0, animations: { [unowned self] in
                    self.brightnessLabel.alpha = 0.0
                })

                // Restart timers.
                if timerActive {
                    timerRunning = true
                }

            case .Cancelled, .Failed:
                // Restore original brightness.
                brightness = CGFloat(Settings.brightness)

                // Hide brightness label.
                brightnessLabel.alpha = 0.0

                // Restart timers.
                if timerActive {
                    timerRunning = true
                }

            default:
                // Restore original brightness.
                brightness = CGFloat(Settings.brightness)

                // Hide brightness label.
                brightnessLabel.alpha = 0.0

                // Restart timers.
                if timerActive {
                    timerRunning = true
                }
            }
        }
    }

    @IBAction func handleDoubleTap(sender: UITapGestureRecognizer) {
        if sender.state == .Ended {
            switch state {
            case .Running:
                if Settings.doubleTap {
                    state = .Stopped
                }

            case .Stopped:
                state = .Running

            default: break
            }
        }
    }

    @IBAction func handleLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .Began {
            performSegueWithIdentifier("ShowSettingsSegue", sender: self)
        }
    }

    // MARK: Notification handlers

    func applicationDidBecomeActive(notification: NSNotification) {
        state = .Running
    }

    func applicationWillResignActive(notification: NSNotification) {
        state = .Idle
    }

    // MARK: Timers

    func turnOffTimerDidFire(timer: NSTimer) {
        state = .Stopped
    }

    func refreshTimerDidFire(timer: NSTimer) {
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!   // TODO: import Gaston.
        let components = calendar.components([.Hour, .Minute, .Second], fromDate: NSDate().dateByAddingTimeInterval(-1.0), toDate: (turnOffTimer?.fireDate)!, options: NSCalendarOptions(rawValue: 0))

        timerButton.setTitle(timerFormatter.stringFromDateComponents(components), forState: .Normal)
    }

    // MARK: Helper functions

    private func adjustForegroundColor() {
        let frontColor = (brightness > brightnessThreshold) ? UIColor(white: 0.0, alpha: 0.25) : LightColor(rawValue: Settings.lightColor)?.color ?? LightColor.White.color

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

}

// MARK: - Settings form view delegate

extension ScreenViewController: SettingsFormViewDelegate {

    func colorDidChange() {
        UIView.animateWithDuration(1.0, animations: {
            self.view.backgroundColor = LightColor(rawValue: Settings.lightColor)?.color ?? LightColor.White.color
        })
    }

    func timerWasEnabled() {
        adjustForegroundColor()

        timerButton.setTitle(timerFormatter.stringFromTimeInterval(Settings.timerDuration), forState: .Normal)
        timerButton.hidden = false
    }

    func timerWasDisabled() {
        timerButton.hidden = true
    }

    func timerDidChange() {
        timerButton.setTitle(timerFormatter.stringFromTimeInterval(Settings.timerDuration), forState: .Normal)
    }

}
