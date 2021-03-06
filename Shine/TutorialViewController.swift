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
import Ticker

class TutorialViewController: UIViewController {

    // MARK: - Properties

    weak var delegate: TutorialViewControllerDelegate?

    @IBOutlet weak var panGestureImageView: UIImageView!
    @IBOutlet weak var doubleTapGestureImageView: UIImageView!
    @IBOutlet weak var longPressGestureImageView: UIImageView!

    @IBOutlet weak var captionLabel: UILabel!

    @IBOutlet weak var panGestureCenterYConstraint: NSLayoutConstraint!
    @IBOutlet weak var doubleTapGestureWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var longPressGestureWidthConstraint: NSLayoutConstraint!

    private var step = 0 {
        didSet {
            switch step {
            case 1:
                showPanGesture()

            case 2:
                showDoubleTapGesture()

            case 3:
                showLongPressGesture()

            default:
                panGestureImageView.hidden = true
                doubleTapGestureImageView.hidden = true
                longPressGestureImageView.hidden = true
                captionLabel.hidden = true

                delegate?.tutorialDidFinish()
            }
        }
    }

    // MARK: - Constants

    private let fadeInDuration: NSTimeInterval = 1.0
    private let animationDuration: NSTimeInterval = 2.0
    private let animationDelay: NSTimeInterval = 0.5

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        panGestureImageView.hidden = true
        doubleTapGestureImageView.hidden = true
        longPressGestureImageView.hidden = true
        captionLabel.hidden = true

        panGestureImageView.tintColor = UIColor(white: 0.0, alpha: 0.25)
        doubleTapGestureImageView.tintColor = UIColor(white: 0.0, alpha: 0.25)
        longPressGestureImageView.tintColor = UIColor(white: 0.0, alpha: 0.25)
        captionLabel.textColor = UIColor(white: 0.0, alpha: 0.25)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        step = 1
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Actions

    @IBAction func handleTap(sender: UITapGestureRecognizer) {
        Ticker.debug("Tapped")

        step += 1
    }

    // MARK: - Helper functions

    private func showPanGesture() {
        doubleTapGestureImageView.hidden = true
        longPressGestureImageView.hidden = true

        panGestureImageView.alpha = 0.0
        panGestureImageView.hidden = false

        captionLabel.alpha = 0.0
        captionLabel.text = NSLocalizedString("TUTORIAL_PAN_GESTURE", comment: "")
        captionLabel.hidden = false

        UIView.animateWithDuration(fadeInDuration, animations: {
            self.panGestureImageView.alpha = 1.0
            self.captionLabel.alpha = 1.0
            }, completion: { _ in
                UIView.animateKeyframesWithDuration(self.animationDuration, delay: self.animationDelay, options: [.Autoreverse, .Repeat], animations: {
                    UIView.addKeyframeWithRelativeStartTime(0.0, relativeDuration: 1.0, animations: {
                        self.panGestureCenterYConstraint.constant = 16.0

                        self.view.layoutIfNeeded()
                    })
                }, completion: nil)
        })
    }

    private func showDoubleTapGesture() {
        panGestureImageView.hidden = true
        longPressGestureImageView.hidden = true

        doubleTapGestureImageView.alpha = 0.0
        doubleTapGestureImageView.hidden = false

        captionLabel.alpha = 0.0
        captionLabel.text = NSLocalizedString("TUTORIAL_DOUBLE_TAP_GESTURE", comment: "")
        captionLabel.hidden = false

        UIView.animateWithDuration(fadeInDuration, animations: {
            self.doubleTapGestureImageView.alpha = 1.0
            self.captionLabel.alpha = 1.0
            }, completion: { _ in
                UIView.animateKeyframesWithDuration(self.animationDuration, delay: self.animationDelay, options: .Repeat, animations: {
                    UIView.addKeyframeWithRelativeStartTime(0.0, relativeDuration: 0.2, animations: {
                        self.doubleTapGestureWidthConstraint.constant = 55.0

                        self.view.layoutIfNeeded()
                    })
                    UIView.addKeyframeWithRelativeStartTime(0.2, relativeDuration: 0.2, animations: {
                        self.doubleTapGestureWidthConstraint.constant = 60.0

                        self.view.layoutIfNeeded()
                    })
                    UIView.addKeyframeWithRelativeStartTime(0.4, relativeDuration: 0.2, animations: {
                        self.doubleTapGestureWidthConstraint.constant = 55.0

                        self.view.layoutIfNeeded()
                    })
                    UIView.addKeyframeWithRelativeStartTime(0.6, relativeDuration: 0.2, animations: {
                        self.doubleTapGestureWidthConstraint.constant = 60.0

                        self.view.layoutIfNeeded()
                    })
                }, completion: nil)
        })
    }

    private func showLongPressGesture() {
        panGestureImageView.hidden = true
        doubleTapGestureImageView.hidden = true

        longPressGestureImageView.alpha = 0.0
        longPressGestureImageView.hidden = false

        captionLabel.alpha = 0.0
        captionLabel.text = NSLocalizedString("TUTORIAL_LONG_PRESS_GESTURE", comment: "")
        captionLabel.hidden = false

        UIView.animateWithDuration(fadeInDuration, animations: {
            self.longPressGestureImageView.alpha = 1.0
            self.captionLabel.alpha = 1.0
            }, completion: { _ in
                UIView.animateKeyframesWithDuration(self.animationDuration, delay: self.animationDelay, options: .Repeat, animations: {
                    UIView.addKeyframeWithRelativeStartTime(0.0, relativeDuration: 0.2, animations: {
                        self.longPressGestureWidthConstraint.constant = 55.0

                        self.view.layoutIfNeeded()
                    })
                    UIView.addKeyframeWithRelativeStartTime(0.8, relativeDuration: 0.2, animations: {
                        self.longPressGestureWidthConstraint.constant = 60.0

                        self.view.layoutIfNeeded()
                    })
                }, completion: nil)
        })
    }

}

// MARK: - Protocols

protocol TutorialViewControllerDelegate: class {

    func tutorialDidFinish()

}
