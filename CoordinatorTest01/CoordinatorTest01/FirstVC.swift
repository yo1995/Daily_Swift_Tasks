//
//  FirstVC.swift
//  CoordinatorTest01
//
//  Created by Ting Chen on 3/6/20.
//  Copyright © 2020 Ting Chen. All rights reserved.
//

import UIKit

class FirstVC: UIViewController, Storyboarded {
    
    weak var coordinator: MainCoordinator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.title = "FirstVC"
    }
    
}
