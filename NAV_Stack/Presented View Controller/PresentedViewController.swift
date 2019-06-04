//
//  PresentedViewController.swift
//  Presented View Controller
//
//  Created by Ric Telford on 9/20/17.
//  Copyright © 2017 rictelford. All rights reserved.
//

import UIKit

protocol PresentedViewControllerDelegate : class {
    func acceptData(_ data:AnyObject!)
}

class PresentedViewController: UIViewController {

    var data : AnyObject?
    weak var delegate : PresentedViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func returnToBase(_ sender: Any) {
                self.presentingViewController!.dismiss(animated: true, completion: nil)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // prove you've got data
        print("From PresentedViewController - data received: \(self.data!)")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isBeingDismissed {
            self.delegate?.acceptData("Outgoing Data Packet" as AnyObject?)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        print("new size coming: \(size)")
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
