//
//  ShowedViewController.swift
//  Presented View Controller
//
//  Created by Ric Telford on 9/20/17.
//  Copyright © 2017 rictelford. All rights reserved.
//

import UIKit

class ShowedViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func next(_ sender: Any) {
        let svc = ShowedViewController(nibName: "ShowedViewController", bundle: nil)
        self.show(svc, sender: self)
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
