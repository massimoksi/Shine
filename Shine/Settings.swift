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

import Foundation
import Ticker

struct Settings {

    static var brightness: Float {
        get {
            return NSUserDefaults.standardUserDefaults().floatForKey(Key.Brightness.rawValue)
        }

        set {
            // TODO: is it really necessary to condition here?
            NSUserDefaults.standardUserDefaults().setFloat(max(min(newValue, 1.0), 0.0), forKey: Key.Brightness.rawValue)

            Ticker.debug("+++> \(Key.Brightness.rawValue): \(newValue)")
        }
    }

    static var lightColor: Int {
        get {
            return NSUserDefaults.standardUserDefaults().integerForKey(Key.LightColor.rawValue)
        }

        set {
            NSUserDefaults.standardUserDefaults().setInteger(newValue, forKey: Key.LightColor.rawValue)

            Ticker.debug("+++> \(Key.LightColor.rawValue): \(newValue)")
        }
    }

    static var bundleVersion: String {
        get {
            guard let version = NSUserDefaults.standardUserDefaults().stringForKey(Key.BundleVersion.rawValue) else {
                return "0.0.0"
            }

            return version
        }

        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: Key.BundleVersion.rawValue)

            Ticker.debug("+++> \(Key.BundleVersion.rawValue): \(newValue)")
        }
    }

    static var doubleTap: Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey(Key.DoubleTap.rawValue)
        }

        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: Key.DoubleTap.rawValue)

            Ticker.debug("+++> \(Key.DoubleTap.rawValue): \(newValue)")
        }
    }

    static var timerEnable: Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey(Key.TimerEnable.rawValue)
        }

        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: Key.TimerEnable.rawValue)

            Ticker.debug("+++> \(Key.TimerEnable.rawValue): \(newValue)")
        }
    }

    static var timerDuration: Double {
        get {
            return NSUserDefaults.standardUserDefaults().doubleForKey(Key.TimerDuration.rawValue)
        }

        set {
            NSUserDefaults.standardUserDefaults().setDouble(newValue, forKey: Key.TimerDuration.rawValue)

            Ticker.debug("+++> \(Key.TimerDuration.rawValue): \(newValue)")
        }
    }

    static var lockScreen: Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey(Key.LockScreen.rawValue)
        }

        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: Key.LockScreen.rawValue)

            Ticker.debug("+++> \(Key.LockScreen.rawValue): \(newValue)")
        }
    }

    static func registerDefaults() {
        NSUserDefaults.standardUserDefaults().registerDefaults([
            Key.Brightness.rawValue: Float(1.0),
            Key.LightColor.rawValue: 0,
            Key.BundleVersion.rawValue: "0.0.0",
            Key.DoubleTap.rawValue: true,
            Key.TimerEnable.rawValue: false,
            Key.TimerDuration.rawValue: 600.0,
            Key.LockScreen.rawValue: false
        ])
    }

    // MARK: - Keys

    private enum Key: String {
        case Brightness
        case LightColor
        case BundleVersion
        case DoubleTap
        case TimerEnable
        case TimerDuration
        case LockScreen
    }

}
