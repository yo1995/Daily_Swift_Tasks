//
//  EntryVC.swift
//  CoordinatorTest01
//
//  Created by Ting Chen on 3/6/20.
//  Copyright © 2020 Ting Chen. All rights reserved.
//

import UIKit

class EntryVC: UIViewController, Storyboarded {
    
    weak var coordinator: MainCoordinator?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.title = "Entry"
        // self.navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    /// Tap this button to goto FirstVC
    /// - Parameter sender: a reference to the UIButton tapped
    @IBAction func goFirstTapped(_ sender: UIButton) {
        coordinator?.goFirst()
    }
    
    /// Tap this button to goto SecondVC
    /// - Parameter sender: a reference to the UIButton tapped
    @IBAction func goSecondTapped(_ sender: UIButton) {
        coordinator?.goSecond()
    }
}

