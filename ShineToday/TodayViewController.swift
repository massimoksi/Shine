//
//  TodayViewController.swift
//  ShineToday
//
//  Created by Massimo Peri on 08/10/15.
//  Copyright © 2015 Massimo Peri. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
        
    @IBOutlet weak var openButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        
        preferredContentSize = CGSize(width: 0, height: 48.0)
        
        openButton.layer.borderColor = UIColor.lightTextColor().CGColor
        openButton.layer.borderWidth = 1.0
        openButton.layer.cornerRadius = 8.0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        completionHandler(NCUpdateResult.NewData)
    }

    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets(
            top: defaultMarginInsets.top,
            left: defaultMarginInsets.left - 30.0,
            bottom: 10.0,
            right: defaultMarginInsets.right
        )
    }
    
    // MARK: - Actions
    
    @IBAction func openContainingApp(sender: UIButton) {
        let appURL = NSURL(string: "shine://")
        extensionContext?.openURL(appURL!, completionHandler: nil);
    }
    
}
