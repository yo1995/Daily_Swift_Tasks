//
//  Controllers.swift
//  tictactoe
//
//  Created by ECE564 on 7/6/19.
//  Copyright © 2019 mobilecenter. All rights reserved.
//

import UIKit

class BoardButton : UIButton {
    var id: Int
    
    init(frame: CGRect, id: Int) {
        self.id = id
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
