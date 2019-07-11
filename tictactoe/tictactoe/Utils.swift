//
//  Utils.swift
//  tictactoe
//
//  Created by ECE564 on 7/6/19.
//  Copyright © 2019 mobilecenter. All rights reserved.
//

import UIKit

func debugAlert(VC: UIViewController, title: String, msg: String) {
    DispatchQueue.main.async {  // Make sure you're on the main thread here, so no warnings and exceptions will be thrown
        let alert = UIAlertController(title: title, message: msg, preferredStyle: UIAlertController.Style.alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        VC.present(alert, animated: true, completion: nil)
        return
    }
}

/// debug alert box with completion closure
///
/// - Parameters:
///   - VC: the ViewController to present on
///   - title: alert title
///   - msg: alert message
///   - completion: alert completion handler
func debugAlertCompletion(VC: UIViewController, title: String, msg: String, completion: @escaping () -> Void) {
    DispatchQueue.main.async {  // Make sure you're on the main thread here, so no warnings and exceptions will be thrown
        let alert = UIAlertController(title: title, message: msg, preferredStyle: UIAlertController.Style.alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { _ in
            completion()
        })
        alert.addAction(okAction)
        VC.present(alert, animated: true, completion: nil)
        return
    }
}

extension UIColor {
    convenience init(valueRGB: UInt, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((valueRGB & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((valueRGB & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(valueRGB & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
}
