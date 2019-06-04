//
//  AppDelegate.swift
//  MINIMAL
//
//  Created by Ric Telford on 7/17/17.
//  Copyright © 2017 ece564. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // this is the MINIMAL amount of code required to make an app run
        self.window = UIWindow(frame: UIScreen.main.bounds)
        
//        let navController = UINavigationController(rootViewController: MainViewController())
        if let appWindow = self.window {
            appWindow.backgroundColor = UIColor.gray
            // point to VC file, even though it won't do anything (NOTE:  navController is meant to be subclassed, not used)
            appWindow.rootViewController = MainViewController()
            appWindow.makeKeyAndVisible()
        }
        return true
    }
}

//  End of Code
