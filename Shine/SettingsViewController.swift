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

class SettingsViewController: UIViewController {
    
    var delegate: SettingsViewControllerDelegate?
    
}

// MARK: - Collection view data source

extension SettingsViewController: UICollectionViewDataSource {

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return LightColor.allColors.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("LightColorCell", forIndexPath: indexPath) as! ColorCollectionViewCell
        cell.checkbox.tintColor = LightColor.allColors[indexPath.row]
        cell.checkbox.on = Settings.lightColor.rawValue == indexPath.row
        
        return cell
    }

}

// MARK: - Collection view delegate

extension SettingsViewController: UICollectionViewDelegate {

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let oldSelectedIndexPath = NSIndexPath(forItem: Settings.lightColor.rawValue, inSection: 0)
        
        if (indexPath != oldSelectedIndexPath) {
            let oldSelectedCell = collectionView.cellForItemAtIndexPath(oldSelectedIndexPath) as! ColorCollectionViewCell
            oldSelectedCell.checkbox.on = false
            
            let cell = collectionView.cellForItemAtIndexPath(indexPath) as! ColorCollectionViewCell
            cell.checkbox.on = true
            
            Settings.lightColor = LightColor(rawValue: indexPath.item)!
            
            delegate?.updateLightColor()
        }
    }
    
}

// MARK: - Protocols

protocol SettingsViewControllerDelegate {
    
    func updateLightColor()
    
}
