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
import Former

final class SettingsFormViewController: FormViewController {

    // MARK: Properties

    weak var delegate: SettingsFormViewDelegate?

    // MARK: Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.scrollEnabled = false

        let colorSelectionRow = CustomRowFormer<ColorSelectionCell>(instantiateType: .Nib(nibName: "ColorSelectionCell")) {
            $0.collectionView.dataSource = self
            $0.collectionView.delegate = self
        }.configure {
            $0.rowHeight = 54.0
        }

        let doubleTapSwitchRow = SwitchRowFormer<FormSwitchCell>() {
            $0.titleLabel.text = NSLocalizedString("Turn off with a double tap", comment: "")
        }.configure {
            $0.switched = Settings.doubleTap
        }.onSwitchChanged { switched in
            Settings.doubleTap = switched
        }

        let createHeader: (String -> ViewFormer) = { text in
            return LabelViewFormer<FormLabelHeaderView>().configure {
                $0.text = text.uppercaseString
                $0.viewHeight = 42.0
            }
        }

        let colorSection = SectionFormer(rowFormer: colorSelectionRow).set(headerViewFormer: createHeader(NSLocalizedString("Light color", comment: "")))
        let generalSection = SectionFormer(rowFormer: doubleTapSwitchRow).set(headerViewFormer: createHeader(NSLocalizedString("General", comment: "")))

        former.append(sectionFormer: colorSection)
        former.append(sectionFormer: generalSection)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

// MARK: - Collection view data source

extension SettingsFormViewController: UICollectionViewDataSource {

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return LightColor.allColors.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ColorSelectionCheckbox", forIndexPath: indexPath) as! ColorSelectionCheckbox
        cell.tintColor = LightColor.allColors[indexPath.row]
        cell.on = Settings.lightColor == indexPath.row

        return cell
    }

}

// MARK: - Collection view delegate

extension SettingsFormViewController: UICollectionViewDelegate {

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let oldSelectedIndexPath = NSIndexPath(forItem: Settings.lightColor, inSection: 0)

        if indexPath != oldSelectedIndexPath {
            let oldSelectedCell = collectionView.cellForItemAtIndexPath(oldSelectedIndexPath) as! ColorSelectionCheckbox
            oldSelectedCell.on = false

            let cell = collectionView.cellForItemAtIndexPath(indexPath) as! ColorSelectionCheckbox
            cell.on = true

            Settings.lightColor = indexPath.item

            delegate?.updateLightColor()
        }
    }

}

// MARK: - Protocols

protocol SettingsFormViewDelegate: class {

    func updateLightColor()

}
