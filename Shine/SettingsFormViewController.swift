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
        // Light
        // -------------------------

        let colorSelectionRow = CustomRowFormer<ColorSelectionCell>(instantiateType: .Nib(nibName: "ColorSelectionCell")) {
            $0.collectionView.dataSource = self
            $0.collectionView.delegate = self
        }.configure {
            $0.rowHeight = 54.0
        }

        let colorSection = SectionFormer(rowFormer: colorSelectionRow).set(headerViewFormer: createHeader(NSLocalizedString("SETTINGS_SEC_LIGHT", comment: "")))

        // -------------------------
        // Turn off
        // -------------------------

        let doubleTapSwitchRow = SwitchRowFormer<FormSwitchCell>() {
            $0.titleLabel.text = NSLocalizedString("SETTINGS_ROW_DOUBLE_TAP", comment: "")
        }.configure {
            $0.switched = Settings.doubleTap
        }

        let timerEnableSwitchRow = SwitchRowFormer<FormSwitchCell>() {
            $0.titleLabel.text = NSLocalizedString("SETTINGS_ROW_TIMER_ENABLE", comment: "")
        }.configure {
            $0.switched = Settings.timerEnable
        }

        timerDurationLabelRow = LabelRowFormer<FormLabelCell>().configure {
            $0.text = NSLocalizedString("SETTINGS_ROW_TIMER_DURATION", comment: "")

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
            row.countDownPicker.addTarget(self, action: #selector(SettingsFormViewController.updateTimerDuration(_:)), forControlEvents: .ValueChanged)
        }.configure {
            $0.rowHeight = 217.0
        }

        let lockScreenSwitchRow = SwitchRowFormer<FormSwitchCell>() {
            $0.titleLabel.text = NSLocalizedString("SETTINGS_ROW_LOCK_SCREEN", comment: "")
        }.configure {
            $0.switched = Settings.lockScreen
        }.onSwitchChanged { switched in
            Settings.lockScreen = switched
        }

        let monitorBatterySwitchRow = SwitchRowFormer<FormSwitchCell>() {
            $0.titleLabel.text = NSLocalizedString("SETTINGS_ROW_MONITOR_BATTERY", comment: "")
            }.configure {
                $0.switched = Settings.monitorBattery
            }.onSwitchChanged { switched in
                Settings.monitorBattery = switched
        }

        var turnOffRows: [RowFormer]
        if Settings.timerEnable {
            turnOffRows = [doubleTapSwitchRow, timerEnableSwitchRow, timerDurationLabelRow, lockScreenSwitchRow, monitorBatterySwitchRow]
        } else if Settings.doubleTap {
            turnOffRows = [doubleTapSwitchRow, timerEnableSwitchRow, lockScreenSwitchRow, monitorBatterySwitchRow]
        } else {
            turnOffRows = [doubleTapSwitchRow, timerEnableSwitchRow, monitorBatterySwitchRow]
        }
        let turnOffSection = SectionFormer(rowFormers: turnOffRows).set(headerViewFormer: createHeader(NSLocalizedString("SETTINGS_SEC_TURN_OFF", comment: "")))

        doubleTapSwitchRow.onSwitchChanged { [unowned self] switched in
            Settings.doubleTap = switched

            if switched {
                // Insert lock screen row if not yet visible.
                if !Settings.timerEnable {
                    self.former.insertUpdate(rowFormer: lockScreenSwitchRow, below: timerEnableSwitchRow, rowAnimation: .Automatic)
                }
            } else {
                // Remove lock screen row only if timer is not enabled.
                if !Settings.timerEnable {
                    self.former.removeUpdate(rowFormer: lockScreenSwitchRow, rowAnimation: .Automatic)
                }
            }
        }

        timerEnableSwitchRow.onSwitchChanged { [unowned self] switched in
            Settings.timerEnable = switched

            if switched {
                self.former.insertUpdate(rowFormer: self.timerDurationLabelRow, toIndexPath: NSIndexPath(forItem: 2, inSection: 1), rowAnimation: .Automatic)

                self.delegate?.timerWasEnabled()

                self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 1), atScrollPosition: .Bottom, animated: true)

                // Insert lock screen row if not yet visible.
                if !Settings.doubleTap {
                    self.former.insertUpdate(rowFormer: lockScreenSwitchRow, below: self.timerDurationLabelRow, rowAnimation: .Automatic)
                }
            } else {
                // Remove lock screen row only if double tap is disabled.
                let rowFormersToBeRemoved = Settings.doubleTap ? [self.timerDurationLabelRow, timerDurationPickerRow] : [self.timerDurationLabelRow, timerDurationPickerRow, lockScreenSwitchRow]
                self.former.removeUpdate(rowFormers: rowFormersToBeRemoved, rowAnimation: .Automatic)

                self.delegate?.timerWasDisabled()
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

        former.append(sectionFormer: colorSection, turnOffSection)
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

        delegate?.timerDidChange()
    }

}

// MARK: - Collection view data source

extension SettingsFormViewController: UICollectionViewDataSource {

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return LightColor.allColors.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ColorSelectionCheckbox", forIndexPath: indexPath) as! ColorSelectionCheckbox
        cell.tintColor = LightColor.allColors[indexPath.item]
        cell.on = Settings.lightColor == indexPath.item

        return cell
    }

}

// MARK: - Collection view delegate

extension SettingsFormViewController: UICollectionViewDelegate {

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let selectedColor = indexPath.item
        if selectedColor != Settings.lightColor {
            let oldCell = collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: Settings.lightColor, inSection: 0)) as! ColorSelectionCheckbox
            oldCell.on = false

            Settings.lightColor = selectedColor
            let cell = collectionView.cellForItemAtIndexPath(indexPath) as! ColorSelectionCheckbox
            cell.on = true

            delegate?.colorDidChange()
        }
    }

}

// MARK: - Protocols

protocol SettingsFormViewDelegate: class {

    func colorDidChange()
    func timerWasEnabled()
    func timerWasDisabled()
    func timerDidChange()

}
