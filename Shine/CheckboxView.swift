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

@IBDesignable class CheckboxView: UIView {

    @IBInspectable var on: Bool = false {
        didSet {
            // Show/hide checkmark.
            checkmarkLayer.hidden = !on
        }
    }
    
    @IBInspectable var lineWidth: CGFloat = 2.0 {
        didSet {
            layer.borderWidth = lineWidth
            checkmarkLayer.lineWidth = lineWidth
        }
    }
    
    @IBInspectable var contrast: CGFloat = 0.25 {
        didSet {
            layer.borderColor = UIColor(white: 0.0, alpha: contrast).CGColor
            checkmarkLayer.strokeColor = UIColor(white: 0.0, alpha: contrast).CGColor
        }
    }
    
    private let checkmarkLayer = CAShapeLayer()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        translatesAutoresizingMaskIntoConstraints = false
        
        layer.addSublayer(checkmarkLayer)
    }
    
    override func intrinsicContentSize() -> CGSize {
        let minSize = 44.0
        
        return CGSize(width: minSize, height: minSize)
    }
    
    override class func requiresConstraintBasedLayout() -> Bool {
        return true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.backgroundColor = tintColor.CGColor
        layer.cornerRadius = frame.height/2
        layer.borderColor = UIColor(white: 0.0, alpha: contrast).CGColor
        layer.borderWidth = lineWidth
        
        checkmarkLayer.frame = bounds
        checkmarkLayer.fillColor = UIColor.clearColor().CGColor
        checkmarkLayer.strokeColor = UIColor(white: 0.0, alpha: contrast).CGColor
        checkmarkLayer.lineCap = kCALineCapRound
        checkmarkLayer.lineWidth = lineWidth
        checkmarkLayer.path = checkmarkPath().CGPath
        checkmarkLayer.hidden = !on
    }
    
    // MARK: - Private methods
    
    private func checkmarkPath() -> UIBezierPath {
        let w = frame.width
        let h = frame.height
        
        let path = UIBezierPath()
        path.moveToPoint(CGPoint(x: w/3.1578, y: h/2))
        path.addLineToPoint(CGPoint(x: w/2.0618, y: h/1.57894))
        path.addLineToPoint(CGPoint(x: w/1.3953, y: h/2.7272))
        
        return path
    }
    
}
