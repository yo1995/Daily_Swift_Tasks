//
//  Models.swift
//  tictactoe
//
//  Created by ECE564 on 7/6/19.
//  Copyright © 2019 mobilecenter. All rights reserved.
//

import Foundation

enum difficultyLevels: String {
    case easy = "Easy (Smart Random)"
    case medium = "Medium (Greed)"
    case hard = "Hard (Minmax)"
}


enum Piece: String {
    case X = "❌"
    case O = "⭕️"
    case E = "  "
    var opposite: Piece {
        switch self {
        case .X:
            return .O
        case .O:
            return .X
        case .E:
            return .E
        }
    }
}


struct Board {
    
    let position: [Piece]
    let turn: Piece
    let lastMove: Int
    let level: difficultyLevels
    
    init(position: [Piece] = [.E, .E, .E, .E, .E, .E, .E, .E, .E], turn: Piece = .X, lastMove: Int = -1, level: difficultyLevels = .easy) {
        self.position = position
        self.turn = turn
        self.lastMove = lastMove
        self.level = level
    }
    
    init(level: difficultyLevels) {
        self.position = [.E, .E, .E, .E, .E, .E, .E, .E, .E]
        self.turn = .X
        self.lastMove = -1
        self.level = level
    }
    
    func move(_ location: Int) -> Board {
        var tempPosition = position
        tempPosition[location] = turn
        return Board(position: tempPosition, turn: turn.opposite, lastMove: location, level: self.level)
    }
    
    func aiMovePosition() -> Int?  {
        if self.legalMoves.count < 1 {
            return nil
        }
        if self.level == .medium {
            return self.mediumMove()
        }
        if self.level == .hard {
            return self.hardMove()
        }
        if self.level == .easy {
            return self.easyMove()
        }
        return nil
    }
    
    // smarter random guess, super easy to defeat
    private func easyMove() -> Int? {
        var bests: [Int] = []
        for combo in winningCombos {
            if position[combo[0]] == position[combo[1]] && position[combo[0]] != .E && position[combo[2]] == .E {
                if position[combo[0]] == self.turn {
                    return combo[2]
                }
                else {
                    bests.append(combo[2])
                }
            }
            if position[combo[0]] == position[combo[2]] && position[combo[0]] != .E && position[combo[1]] == .E {
                if position[combo[0]] == self.turn {
                    return combo[1]
                }
                else {
                    bests.append(combo[1])
                }
            }
            if position[combo[1]] == position[combo[2]] && position[combo[1]] != .E && position[combo[0]] == .E {
                if position[combo[1]] == self.turn {
                    return combo[0]
                }
                else {
                    bests.append(combo[0])
                }
            }
        }
        if !bests.isEmpty {
            return bests.randomElement()
        }
        return self.legalMoves.randomElement()
    }
    
    private func mediumMove() -> Int? {
        // first try to stop opponent from winning
        var bests: [Int] = []
        for combo in winningCombos {
            if position[combo[0]] == position[combo[1]] && position[combo[0]] != .E && position[combo[2]] == .E {
                if position[combo[0]] == self.turn {
                    return combo[2]
                }
                else {
                    bests.append(combo[2])
                }
            }
            if position[combo[0]] == position[combo[2]] && position[combo[0]] != .E && position[combo[1]] == .E {
                if position[combo[0]] == self.turn {
                    return combo[1]
                }
                else {
                    bests.append(combo[1])
                }
            }
            if position[combo[1]] == position[combo[2]] && position[combo[1]] != .E && position[combo[0]] == .E {
                if position[combo[1]] == self.turn {
                    return combo[0]
                }
                else {
                    bests.append(combo[0])
                }
            }
        }
        if !bests.isEmpty {
            return bests.randomElement()
        }
        // take center will have better chance to tie
        if position[4] == .E {
            return 4
        }
        // then corners
        let corners = [0, 2, 6, 8]
        for p in corners {
            if position[p] == .E {
                return p
            }
        }
        // should not come to this case unless already tied, maybe design early termination later
        return self.legalMoves.randomElement()
    }
    
    private func hardMove() -> Int? {
        // first, second step optimization, to avoid huge recursive stack.
        let corners = [0, 2, 6, 8]
        if self.legalMoves.count > 8 {
            return corners.randomElement()  // corner is the best first step strategy
        }
        if self.legalMoves.count == 8 {
            if self.position[4] != .E {
                return corners.randomElement()  // corner is the best strategy
            }
            for c in corners {
                if self.position[c] != .E {
                    return 4  // must go center to ensure tie
                }
            }
            return (self.legalMoves.reduce(0, +) - 4) % 8  // this is magic ;-)
        }
        // then run minmax algorithm
        var bestEval = Int.min
        var bestMove: Int? = nil
        for move in self.legalMoves {
            let result = minimax(self.move(move), maximizing: false, originalPlayer: self.turn)
            if result > bestEval {
                bestEval = result
                bestMove = move
            }
        }
        return bestMove
    }
    
    // Find the best possible outcome for originalPlayer
    private func minimax(_ board: Board, maximizing: Bool, originalPlayer: Piece) -> Int {
        // Base case — evaluate the position if it is a win or a draw
        if board.isWin && originalPlayer == board.turn.opposite { return 1 } // win
        else if board.isWin && originalPlayer != board.turn.opposite { return -1 } // loss
        else if board.isDraw { return 0 } // draw
        
        // Recursive case — maximize your gains or minimize the opponent's gains
        if maximizing {
            var bestEval = Int.min
            for move in board.legalMoves { // find the move with the highest evaluation
                let result = minimax(board.move(move), maximizing: false, originalPlayer: originalPlayer)
                bestEval = max(result, bestEval)
            }
            return bestEval
        }
        else { // minimizing
            var worstEval = Int.max
            for move in board.legalMoves {
                let result = minimax(board.move(move), maximizing: true, originalPlayer: originalPlayer)
                worstEval = min(result, worstEval)
            }
            return worstEval
        }
    }
    
    private var winningCombos: [[Int]] {
        /*
         0 | 1 | 2
         ---------
         3 | 4 | 5
         ---------
         6 | 7 | 8
         */
        return [
            [0,1,2],[3,4,5],[6,7,8], /* horizontals */
            [0,3,6],[1,4,7],[2,5,8], /* veritcals */
            [0,4,8],[2,4,6]          /* diagonals */
        ]
    }
    
    var legalMoves: [Int] {
        return position.indices.filter { position[$0] == .E }
    }
    
    var isWin: Bool {
        for combo in winningCombos {
            if position[combo[0]] == position[combo[1]] && position[combo[0]] == position[combo[2]] && position[combo[0]] != .E {
                return true
            }
        }
        return false
    }
    
    var isDraw: Bool {
        return !isWin && legalMoves.count == 0
    }
    
}
