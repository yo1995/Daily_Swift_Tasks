//
//  ViewController.swift
//  SakaiWebLogin
//
//  Created by ECE564 on 6/14/19.
//  Copyright © 2019 mobilecenter. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    #warning("do we need to store the cookies in user defaults or serialize it for next launch? should we let user decide when to log out, and what is the timeout for shib auth session?")
    
    @IBOutlet weak var debugTextView: UITextView!
    
    @IBAction func presentTapped(_ sender: Any) {
        let vc = loginPage()
        self.debugTextView.text = "No results before loading."
        vc.modalPresentationStyle = .formSheet
        
        self.present(vc, animated: true, completion: {
            self.showSpinner(onView: self.view, text: "Loading...")
            print("spinner shown")
        })
        
        vc.onCancel = { _ in
            print("❕ debug info: user canceled")
            DispatchQueue.main.async {
                self.removeSpinner()
                print("spinner removed")
            }
        }
        
        vc.onDoneSubmit = { _ in
            print("✅ debug info: submit is done")
            
        }
        
        vc.onDoneLogin = { _ in  // might be changed to entity
            print("✅ debug info: the results. the original implementation is global variable, which is bad.")
            DispatchQueue.main.async {
                // must update UI on main thread
                self.debugTextView.text = courses.description
                UIView.transition(with: self.view, duration: 0.5, options: .transitionCrossDissolve, animations: {
                    self.removeSpinner()
                }, completion: nil)
                print("spinner removed")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.debugTextView.text = "No results before loading."
        
    }


}

