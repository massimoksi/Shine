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

class ScreenView: UIView {

    // MARK: Properties

    var brightness: CGFloat = 1.0 {
        didSet {
            overlayLayer.backgroundColor = UIColor(white: 0.0, alpha: 1.0 - brightness / brightnessThreshold).CGColor
        }
    }

    private var overlayLayer = CALayer()

    // MARK: Constants

    private let brightnessThreshold: CGFloat = 0.25

    // MARK: Life cycle

    override func awakeFromNib() {
        super.awakeFromNib()

        overlayLayer.frame = bounds
        overlayLayer.backgroundColor = UIColor(white: 0.0, alpha: 0.0).CGColor
        layer.insertSublayer(overlayLayer, atIndex: 0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        overlayLayer.frame = bounds
    }

}
