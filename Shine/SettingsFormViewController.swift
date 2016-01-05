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

    private lazy var timerDurationFormatter: NSDateComponentsFormatter = {
        let formatter = NSDateComponentsFormatter()
        formatter.unitsStyle = .Abbreviated

        return formatter
    }()

    private var timerDurationLabelRow: LabelRowFormer<FormLabelCell>!

    // MARK: Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let createHeader: (String -> ViewFormer) = { text in
            return LabelViewFormer<FormLabelHeaderView>().configure {
                $0.text = text.uppercaseString
                $0.viewHeight = 42.0
            }
        }

        // -------------------------
        // Light color
        // -------------------------

        let colorSelectionRow = CustomRowFormer<ColorSelectionCell>(instantiateType: .Nib(nibName: "ColorSelectionCell")) {
            $0.collectionView.dataSource = self
            $0.collectionView.delegate = self
        }.configure {
            $0.rowHeight = 54.0
        }

        let colorSection = SectionFormer(rowFormer: colorSelectionRow).set(headerViewFormer: createHeader(NSLocalizedString("Light color", comment: "")))

        // -------------------------
        // General
        // -------------------------

        let doubleTapSwitchRow = SwitchRowFormer<FormSwitchCell>() {
            $0.titleLabel.text = NSLocalizedString("Turn off with a double tap", comment: "")
        }.configure {
            $0.switched = Settings.doubleTap
        }.onSwitchChanged { switched in
            Settings.doubleTap = switched
        }

        let timerEnableSwitchRow = SwitchRowFormer<FormSwitchCell>() {
            $0.titleLabel.text = NSLocalizedString("Enable timer", comment: "")
            }.configure {
                $0.switched = Settings.timerEnable
        }

        timerDurationLabelRow = LabelRowFormer<FormLabelCell>().configure {
            $0.text = NSLocalizedString("Turn off after", comment: "")

            let comps = NSDateComponents()
            let timerDuration = Settings.timerDuration
            comps.hour = Int(timerDuration) / 3600
            comps.minute = (Int(timerDuration) % 3600) / 60
            $0.subText = timerDurationFormatter.stringFromDateComponents(comps)
        }

        let timerDurationPickerRow = CustomRowFormer<CountDownCell>(instantiateType: .Nib(nibName: "CountDownCell")) { row in
            // Workaround to a bug in UIDatePicker implementaion.
            // http://stackoverflow.com/questions/20181980/uidatepicker-bug-uicontroleventvaluechanged-after-hitting-minimum-internal
            dispatch_async(dispatch_get_main_queue(), {
                row.countDownPicker.countDownDuration = Settings.timerDuration
            })
            row.countDownPicker.addTarget(self, action: "updateTimerDuration:", forControlEvents: .ValueChanged)
            }.configure {
                $0.rowHeight = 217.0
        }

        // TODO: Change text to 'Turn off'.
        let generalRowFormers = Settings.timerEnable ? [doubleTapSwitchRow, timerEnableSwitchRow, timerDurationLabelRow] : [doubleTapSwitchRow, timerEnableSwitchRow]
        let generalSection = SectionFormer(rowFormers: generalRowFormers).set(headerViewFormer: createHeader(NSLocalizedString("General", comment: "")))

        timerEnableSwitchRow.onSwitchChanged { [unowned self] switched in
            Settings.timerEnable = switched

            if switched {
                self.former.insertUpdate(rowFormer: self.timerDurationLabelRow, toIndexPath: NSIndexPath(forItem: 2, inSection: 1), rowAnimation: .Automatic)

                self.delegate?.startTimer()

                self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 1), atScrollPosition: .Bottom, animated: true)
            } else {
                self.former.removeUpdate(rowFormers: [self.timerDurationLabelRow, timerDurationPickerRow], rowAnimation: .Automatic)

                self.delegate?.removeTimer()
            }
        }

        var pickerVisible = false
        timerDurationLabelRow.onSelected { [unowned self] row in
            if !pickerVisible {
                self.former.deselect(true)
                self.former.insertUpdate(rowFormer: timerDurationPickerRow, below: row, rowAnimation: .Automatic)

                pickerVisible = true

                self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 3, inSection: 1), atScrollPosition: .Bottom, animated: true)
            } else {
                self.former.deselect(true)
                self.former.removeUpdate(rowFormer: timerDurationPickerRow, rowAnimation: .Automatic)

                pickerVisible = false
            }
        }

        former.append(sectionFormer: colorSection, generalSection)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: Actions

    func updateTimerDuration(sender: UIDatePicker) {
        Settings.timerDuration = sender.countDownDuration

        timerDurationLabelRow.update { row in
            let comps = NSDateComponents()
            let timerDuration = sender.countDownDuration
            comps.hour = Int(timerDuration) / 3600
            comps.minute = (Int(timerDuration) % 3600) / 60
            row.subText = timerDurationFormatter.stringFromDateComponents(comps)
        }

        delegate?.updateTimer()
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
    func startTimer()
    func removeTimer()
    func updateTimer()

}
