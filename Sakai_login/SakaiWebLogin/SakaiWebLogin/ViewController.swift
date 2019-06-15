//
//  ViewController.swift
//  SakaiWebLogin
//
//  Created by ECE564 on 6/14/19.
//  Copyright © 2019 mobilecenter. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    
    @IBOutlet weak var debugTextView: UITextView!
    
    @IBAction func presentTapped(_ sender: Any) {
        let vc = loginPage()
        self.debugTextView.text = "No results before loading."
        
        self.present(vc, animated: true, completion: nil)
        
        vc.onDoneLogin = { _ in  // might be changed to entity
            print("✅ debug info: this is the results. the original implementation is global variable, which is bad.")
            DispatchQueue.main.async {
                // must update UI on main thread
                self.debugTextView.text = courses.description
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.debugTextView.text = "No results before loading."
    }


}

