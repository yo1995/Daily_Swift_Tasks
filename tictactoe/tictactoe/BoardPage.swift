//
//  BoardPage.swift
//  tictactoe
//
//  Created by ECE564 on 7/6/19.
//  Copyright © 2019 mobilecenter. All rights reserved.
//

import UIKit

class BoardPage: UIViewController {
    
    /// record dict for win draw lose
    var records: [Piece: Int] = [.X: 0, .E: 0, .O: 0]
    
    /// round information display area
    @IBOutlet weak var boardPageLabel: UILabel!
    
    /// game mode, can be 1: one player vs AI or 2: two player
    var gameMode: Int!
    
    /// difficulty, AI strategy
    var difficultyLevel: difficultyLevels!
    
    /// 1P is first move flag
    var isFirstMove: Bool = true
    
    /// an array to keep track of all the programmatically created buttons
    var boardButtonArray: [UIButton] = []
    
    /// the tic tac toe game board
    var board: Board!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "This is \(String(gameMode)) Player(s)"
        
        if !self.initButtons() {
            // just impossible right now, but anything can happen
            self.navigationController?.popViewController(animated: true)
            return
        }
        
        // init a board with level
        self.board = Board(level: self.difficultyLevel)
        
        // 1P AI first
        if gameMode == 1 && !isFirstMove {
            self.aiMove()
        }
        
        self.boardPageLabel.text = "Player \(self.board.turn)'s turn"
    }
    
    func describeRecords(_ records: [Piece: Int]) -> String {
        let s = "❌ wins: \(records[.X] ?? -1), ⭕️ wins: \(records[.O] ?? -1), Draws: \(records[.E] ?? -1)"
        return s
    }
    
    /// initialize buttons as board blocks
    func initButtons() -> Bool {
        
        let totalWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        if screenHeight < totalWidth {
            debugAlert(VC: self, title: "Impossible!", msg: "Screen width is larger than screen height.\nNot able to draw the board. Abort.")
            return false
        }
        
        let boardButtonWidth = (totalWidth / 3).rounded(.towardZero)
        let x = totalWidth / 2 - 1.5 * boardButtonWidth
        let y = screenHeight / 2 - 1.5 * boardButtonWidth
        
        // init 9 buttons as the board blocks
        for i in 0..<9 {
            let row = i % 3
            let col = i / 3
            let X = CGFloat(row) * boardButtonWidth + x
            let Y = CGFloat(col) * boardButtonWidth + y
            
            let boardButtonFrame = CGRect(x: X, y: Y, width: boardButtonWidth, height: boardButtonWidth)
            let button = UIButton(frame: boardButtonFrame)
            button.tag = i
            button.backgroundColor = UIColor(valueRGB: i % 2 == 0 ? 0x666666 : 0xCCCCCC, alpha: 1)
            button.layer.cornerRadius = 5
            button.titleLabel?.frame = CGRect(x: CGFloat.zero, y: CGFloat.zero, width: boardButtonWidth, height: boardButtonWidth)
            button.titleLabel?.font = .systemFont(ofSize: boardButtonWidth / 2)
            button.setTitle(Piece.E.rawValue, for: .normal)
            button.showsTouchWhenHighlighted = true
            button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
            self.boardButtonArray.append(button)
            self.view.addSubview(button)
        }
        return true
    }
}

extension BoardPage {

    /// The action when a board block is tapped.
    ///
    /// - Parameter sender: the button entity
    @objc func buttonTapped(sender: UIButton) {
        sender.isEnabled = false  // cannot be clicked after done
        self.view.isUserInteractionEnabled = false  // disable all event until the calculation is done
        
        self.board = self.board.move(sender.tag)
        self.boardButtonArray[sender.tag].setTitle(self.board.position[sender.tag].rawValue, for: .normal)
        self.boardPageLabel.text = "Player \(self.board.turn)'s turn"
        
        let complete = {
            for b in self.boardButtonArray {
                b.removeFromSuperview()  // remove the original buttons
            }
            self.boardButtonArray.removeAll()
            self.board = Board(level: self.difficultyLevel)
            self.view.isUserInteractionEnabled = true  // reset to allow interaction
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.5, animations: {
                    let _ = self.initButtons()
                    self.boardPageLabel.text = "Player \(self.board.turn)'s turn"
                    if self.gameMode == 1 && !self.isFirstMove {
                        self.aiMove()
                    }
                })
            }
        }
        if self.board.isWin {
            debugAlertCompletion(VC: self, title: "Win", msg: "\(self.board.turn.opposite.rawValue) win the game!", completion: complete)
            records[self.board.turn.opposite]! += 1
            self.boardPageLabel.text = self.describeRecords(self.records)
        }
        else if self.board.isDraw {
            debugAlertCompletion(VC: self, title: "Draw", msg: "Round Draw!", completion: complete)
            records[.E]! += 1
            self.boardPageLabel.text = self.describeRecords(self.records)
        }
        else {  // continue the game
            if self.gameMode > 1 {  // player 2 or ai make the move
                self.view.isUserInteractionEnabled = true  // reset to allow interaction
            }
            else {
                self.aiMove()
            }
        }
    }
    
    /// AI move in 1 player mode
    func aiMove() {
        guard let pos = self.board.aiMovePosition() else {
            // no more steps, just return
            return
        }
        self.boardButtonArray[pos].isEnabled = false
        self.board = self.board.move(pos)
        self.boardButtonArray[pos].setTitle(self.board.position[pos].rawValue, for: .normal)
        self.boardPageLabel.text = "Player \(self.board.turn)'s turn"
        
        let complete = {
            for b in self.boardButtonArray {
                b.removeFromSuperview()  // remove the original buttons
            }
            self.boardButtonArray.removeAll()
            self.board = Board(level: self.difficultyLevel)
            self.view.isUserInteractionEnabled = true  // reset to allow interaction
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.5, animations: {
                    let _ = self.initButtons()
                    self.boardPageLabel.text = "Player \(self.board.turn)'s turn"
                    if self.gameMode == 1 && !self.isFirstMove {
                        self.aiMove()
                    }
                })
            }
        }
        if self.board.isWin {
            debugAlertCompletion(VC: self, title: "Win", msg: "\(self.board.turn.opposite.rawValue) win the game!", completion: complete)
            records[self.board.turn.opposite]! += 1
            self.boardPageLabel.text = self.describeRecords(self.records)
        }
        if self.board.isDraw {
            debugAlertCompletion(VC: self, title: "Draw", msg: "Round Draw!", completion: complete)
            records[.E]! += 1
            self.boardPageLabel.text = self.describeRecords(self.records)
        }
        self.view.isUserInteractionEnabled = true  // reset to allow interaction
    }
    
}
