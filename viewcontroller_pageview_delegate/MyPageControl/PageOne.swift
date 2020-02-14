//
//  PageOne.swift
//  MyPageControl
//
//  Created by Ric Telford on 9/2/17.
//  Copyright © 2017 ece564. All rights reserved.
//

import UIKit

protocol PageOnePassValueDelegate: class {
    
    /// pass value delegate method demo
    /// - Parameter string: the string from the text field
    func passTextFieldValue(_ string: String)
    
}


class PageOne: UIViewController {
    
    var data1: String = ""
    var tf: UITextField!
    
    weak var delegate: PageOnePassValueDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tf = UITextField(frame: CGRect(x: 50, y: 250, width: 240, height: 50))
        tf.backgroundColor = .orange
        tf.delegate = self
        self.view.addSubview(tf)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("we are on page 1 - data below")
        print(data1)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.tf.resignFirstResponder()
    }
    
}

extension PageOne: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.data1 = self.tf.text ?? "nil (no value)"
        print("textfield on page one end editing, save the text to data1: \(data1)")
        // only when the delegate is set
        self.delegate?.passTextFieldValue(self.data1)
        print("delegate method called")
    }
}

