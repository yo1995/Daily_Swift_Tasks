//
//  ViewController.swift
//  indicator
//
//  Created by ECE564 on 6/15/19.
//  Copyright © 2019 mobilecenter. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    
    @IBOutlet weak var button: UIButton!
    
    let colorArray: [UIColor] = [
        .orange,
        .green,
        .blue,
        .purple,
        .cyan,
        .clear,
        .red,
        .magenta,
        .yellow,
        .lightGray
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }
    

    @IBAction func buttonTapped(_ sender: Any) {
        
        self.view.backgroundColor = self.colorArray.randomElement()
        
        self.showSpinner(onWindow: UIApplication.shared.keyWindow!, text: "Loading..")
        // self.showSpinner(onView: self.view, text: "Loading..")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.removeSpinner()
        }
    }
    
}

