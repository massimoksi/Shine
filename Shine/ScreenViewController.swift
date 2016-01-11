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
        }
    }

    var state: LightState = .Off

    @IBOutlet weak var overlayView: UIView!

    var brightnessLabel: UILabel!
    var timerButton: UIButton!

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

                timerButton.setTitle(timerFormatter.stringFromDateComponents(timerComponents()), forState: .Normal)
            } else {
                // Stop timers.
                turnOffTimer?.invalidate()
                refreshTimer?.invalidate()

                turnOffTimer = nil
                refreshTimer = nil

                timerButton.setTitle(timerFormatter.stringFromDateComponents(timerComponents()), forState: .Normal)
            }
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

        timerButton = UIButton()
        timerButton.setImage(UIImage(named: "Timer"), forState: .Normal)
        timerButton.translatesAutoresizingMaskIntoConstraints = false
        timerButton.titleEdgeInsets = UIEdgeInsets(top: 0.0, left: 12.0, bottom: 0.0, right: 0.0)
        view.addSubview(timerButton)

        setupForegroundColor()
        setupConstraints()

        // Trigger timers.
        if timerActive {
            timerRunning = true

            timerButton.hidden = false
        } else {
            timerButton.hidden = true
        }
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

        state = .On

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

        turnOffTimer?.invalidate()
        refreshTimer?.invalidate()

        turnOffTimer = nil
        refreshTimer = nil
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowSettingsSegue" {
            let presentationSegue = segue as! MZFormSheetPresentationViewControllerSegue
            presentationSegue.formSheetPresentationController.contentViewControllerTransitionStyle = .Fade
            presentationSegue.formSheetPresentationController.presentationController?.contentViewSize = CGSize(width: 300.0, height: 300.0)
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

                panLocation = sender.locationInView(overlayView)

                brightnessLabel.alpha = 1.0
                brightnessLabel.frame = CGRect(origin: locationForLabel(fromLocation: panLocation), size: brightnessLabel.frame.size)
                brightnessLabel.text = brightnessFormatter.stringFromNumber(brightness)

                setupForegroundColor()

            case .Changed:
                // Calculate pan.
                let actPanLocation = sender.locationInView(overlayView)
                let panTranslation = panLocation.y - actPanLocation.y
                panLocation = actPanLocation

                // Calculate brightness.
                brightness += panTranslation / (overlayView.bounds.height * 0.75)

                adjustLight()

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
                resetBrightness()

                brightnessLabel.alpha = 0.0

                if timerActive {
                    timerRunning = true
                }

            default:
                resetBrightness()

                brightnessLabel.alpha = 0.0

                if timerActive {
                    timerRunning = true
                }
            }
        }
    }

    @IBAction func switchOffLight(sender: UITapGestureRecognizer) {
        if Settings.doubleTap && (sender.state == .Ended) {
            switch state {
            case .Off:
                if timerActive {
                    timerRunning = true
                }

                resetBrightness()

            case .On:
                if timerActive {
                    timerRunning = false
                }

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
            resetBrightness()

            state.toggle()
        }
    }

    // MARK: Timers

    func turnOff() {
        brightness = 0.0
        adjustLight()
    }

    func refresh() {
        let timerDuration = timerFormatter.stringFromDateComponents(timerComponents())

        timerButton.setTitle(refreshBlinker ? timerDuration?.stringByReplacingOccurrencesOfString(":", withString: " ") : timerDuration, forState: .Normal)
        refreshBlinker = !refreshBlinker
    }

    // TODO: is this function necessary?
    func resetBrightness() {
        brightness = CGFloat(Settings.brightness)

        adjustLight()
    }

    // MARK: Setup

    private func setupBrightness() {
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
