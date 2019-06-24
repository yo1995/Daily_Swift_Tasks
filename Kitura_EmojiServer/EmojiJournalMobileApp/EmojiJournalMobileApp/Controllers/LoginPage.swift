//
//  LoginPage.swift
//  EmojiJournalMobileApp
//
//  Created by ECE564 on 6/23/19.
//  Copyright © 2019 Razeware. All rights reserved.
//

import UIKit
import SafariServices

class LoginPage: UIViewController {
    
    var username: String?
    var password: String?
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        
        let alert = UIAlertController(title: "Please login first", message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Login", style: .default, handler: { [weak self] action in
            guard let strongSelf = self else {
                return
            }
            let utf = alert.textFields![0]
            let ptf = alert.textFields![1]
            strongSelf.username = utf.text
            strongSelf.password = ptf.text
            if utf.text != "" && ptf.text != "" {
                strongSelf.performSegue(withIdentifier: "loginSegue", sender: nil)
            }
            return
        })
        let anonymAction = UIAlertAction(title: "Anonym", style: .default, handler: { [weak self] action in
            guard let strongSelf = self else {
                return
            }
            strongSelf.username = ""
            strongSelf.password = ""
            strongSelf.performSegue(withIdentifier: "loginSegue", sender: nil)
        })
        alert.addAction(okAction)
        alert.addAction(anonymAction)
        alert.addTextField { textField in
            textField.placeholder = "username"
            
        }
        alert.addTextField { textField in
            textField.placeholder = "password"
        }
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func actionButtonTapped(_ sender: Any) {
        let urlString = "http://rt113-dt01.egr.duke.edu/client"
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            let safariViewController = SFSafariViewController(url: url)
            safariViewController.preferredBarTintColor = .darkText
            self.present(safariViewController, animated: true)
        }
    }
    
    @IBAction func rightCornerButtonTapped(_ sender: Any) {
        self.loginButtonTapped(sender)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "loginSegue" {
            // need to deal with table view too
            guard let journalTableView = segue.destination as? JournalTableViewController else {
                return
            }
            // pass query through segue
            journalTableView.username = self.username ?? ""
            journalTableView.password = self.password ?? ""  // default value for anonym user
            
        }
    }
    
}
