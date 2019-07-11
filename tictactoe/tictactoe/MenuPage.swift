//
//  MenuPage.swift
//  tictactoe
//
//  Created by ECE564 on 7/6/19.
//  Copyright © 2019 mobilecenter. All rights reserved.
//

import UIKit

class MenuPage: UIViewController {
    
    @IBOutlet weak var firstMoveSwitch: UISwitch!
    
    var difficultyLevel: difficultyLevels = .easy  // default to easy level
    
    @IBAction func DifficultyButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Please choose difficulty level", message: "", preferredStyle: UIAlertController.Style.actionSheet)
        let random = UIAlertAction(title: "Easy (Smart Random)", style: .default, handler: { _ in
            self.difficultyLevel = .easy
            self.navigationItem.title = self.difficultyLevel.rawValue
        })
        let greed = UIAlertAction(title: "Medium (Greed)", style: .default, handler: { _ in
            self.difficultyLevel = .medium
            self.navigationItem.title = self.difficultyLevel.rawValue
        })
        let minmax = UIAlertAction(title: "Hard (Minmax)", style: .default, handler: { _ in
            self.difficultyLevel = .hard
            self.navigationItem.title = self.difficultyLevel.rawValue
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(random)
        alert.addAction(greed)
        alert.addAction(minmax)
        alert.addAction(cancel)
        alert.popoverPresentationController?.sourceView = sender  // for iPad only
        self.present(alert, animated: true, completion: nil)
        return
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.navigationItem.title = self.difficultyLevel.rawValue
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "1PSegue" {
            let BoardPageVC = segue.destination as! BoardPage
            // pass parameters through segue
            BoardPageVC.gameMode = 1
            BoardPageVC.difficultyLevel = self.difficultyLevel
            BoardPageVC.isFirstMove = self.firstMoveSwitch.isOn
        }
        if segue.identifier == "2PSegue" {
            let BoardPageVC = segue.destination as! BoardPage
            // pass parameters through segue
            BoardPageVC.gameMode = 2
            BoardPageVC.difficultyLevel = self.difficultyLevel
        }
    }
}

