//
//  BaseViewController.swift
//  Presented View Controller
//
//  Created by Ric Telford on 9/20/17.
//  Copyright © 2017 rictelford. All rights reserved.
//

import UIKit

var whichTransition = 0
var whichPresentation = 0

class BaseViewController: UIViewController, PresentedViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func presentVC(_ sender: Any) {
        let pvc = PresentedViewController(nibName: "PresentedViewController", bundle: nil)
        pvc.data = "Incoming Data Packet" as AnyObject?
        pvc.delegate = self
        
        switch whichTransition {
        case 0: break // showing that .CoverVertical is the default
        case 1: pvc.modalTransitionStyle = .coverVertical
        case 2: pvc.modalTransitionStyle = .crossDissolve
        case 3: pvc.modalTransitionStyle = .partialCurl
        case 4:
            pvc.modalTransitionStyle = .flipHorizontal
            self.view.window!.backgroundColor = UIColor.green
        default: break
        }
        
        switch whichPresentation {
        case 0: break // showing that .FullScreen is the default
        case 1: pvc.modalPresentationStyle = .popover
        case 2: pvc.modalPresentationStyle = .pageSheet
        case 3: pvc.modalPresentationStyle = .formSheet
        case 4:
            pvc.modalPresentationStyle = .overFullScreen
            pvc.view.alpha = 0.5 // just to prove that it's working
        default: break
        }

            self.present(pvc, animated:true, completion:nil)
    }

    @IBAction func showVC(_ sender: Any) {
        let svc = ShowedViewController(nibName: "ShowedViewController", bundle: nil)
        self.show(svc, sender: self)
    }
    
    func acceptData(_ data:AnyObject!){
        print("From BaseViewController - data received:")
        print(data)
    }
    
    @IBAction func changedTransition(_ sender: UISegmentedControl) {
        whichTransition = sender.selectedSegmentIndex
    }
    
    @IBAction func changedPresentation(_ sender: UISegmentedControl) {
        whichPresentation = sender.selectedSegmentIndex
    }

}
