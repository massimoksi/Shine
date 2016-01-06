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

enum LightState {

    case Off
    case On

    mutating func toggle() {
        switch self {
        case Off:
            self = On

        case On:
            self = Off
        }
    }

}

enum LightColor: Int {

    case White
    case Yellow
    case Pink
    case LightBlue
    case Red

    var color: UIColor {
        switch self {
        case White:
            return UIColor.whiteColor()

        case Yellow:
            return UIColor(red: 255.0/255.0, green: 245.0/255.0, blue: 157.0/255.0, alpha: 1.0)

        case Pink:
            return UIColor(red: 244.0/255.0, green: 143.0/255.0, blue: 177.0/255.0, alpha: 1.0)

        case LightBlue:
            return UIColor(red: 179.0/255.0, green: 229.0/255.0, blue: 252.0/255.0, alpha: 1.0)

        case Red:
            return UIColor(red: 239.0/255.0, green: 83.0/255.0, blue: 80.0/255.0, alpha: 1.0)
        }
    }

    static var allColors: [UIColor] {
        return [White.color, Yellow.color, Pink.color, LightBlue.color, Red.color]
    }

}
