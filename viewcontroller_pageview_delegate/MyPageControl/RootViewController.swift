//
//  RootViewController.swift
//  MyPageControl
//
//  Created by Ric Telford on 9/2/17.
//  Copyright © 2017 ece564. All rights reserved.
//

import UIKit

class RootViewController: UIPageViewController {
    
    var firstPage = PageOne()
    var secondPage = PageTwo()
    
    var dataSharedfrom1To2: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // originally by Ric
//        let pvc = UIPageViewController(transitionStyle: .pageCurl, navigationOrientation: .horizontal)
//        pvc.dataSource = self
//        self.addChild(pvc)
//        self.view.addSubview(pvc.view)
//        pvc.view.frame = self.view.bounds
//        pvc.didMove(toParent: self)
//        pvc.setViewControllers([firstPage], direction: .forward, animated: false)
        
        self.dataSource = self
        self.setViewControllers([firstPage], direction: .forward, animated: false)
        
        // 2. pass by delegate
        self.firstPage.delegate = self
    }
}


// default delegate for Root
extension RootViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if viewController === firstPage {  // class comparison
            // 1. strong coupling
            secondPage.data2 = firstPage.data1
            
            // 2. pass by delegate method and root
//            print("just a demo here: you can pass data from child to parent")
//            print(self.dataSharedfrom1To2)
            
            // 3. pass by KVO - omitted, more used for 2-way data binding. now we have `Combine`
            
            return secondPage
        }
        else {
            return firstPage
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if viewController === firstPage {  // class comparison
            // 1. strong coupling
            secondPage.data2 = firstPage.data1
            
            // 2. pass by delegate method and root
            print("just a demo here: you can pass data from child to parent")
            print(self.dataSharedfrom1To2)
            // 3. pass by KVO - omitted
            
            return secondPage
        }
        else {
            return firstPage
        }
    }
}


extension RootViewController: PageOnePassValueDelegate {
    func passTextFieldValue(_ string: String) {
        print("value received from Page One delegate: \(string)")
        self.dataSharedfrom1To2 = string
    }
}
