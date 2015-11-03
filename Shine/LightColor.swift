//
//  LightColor.swift
//  Shine
//
//  Created by Massimo Peri on 28/10/15.
//  Copyright © 2015 Massimo Peri. All rights reserved.
//

import UIKit

enum LightColor: Int {
    case White
    case Yellow
    case Red
    
    var color: UIColor {
        switch self {
        case .White:
            return UIColor.whiteColor()
            
        case .Yellow:
            return UIColor.yellowColor()

        case .Red:
            return UIColor.redColor()
        }
    }
    
    static var allColors: [UIColor] {
        return [White.color, Yellow.color, Red.color]
    }
}
