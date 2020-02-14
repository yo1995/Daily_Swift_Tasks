//
//  PageTwo.swift
//  MyPageControl
//
//  Created by Ric Telford on 9/2/17.
//  Copyright © 2017 ece564. All rights reserved.
//

import UIKit

class PageTwo: UIViewController {
    
    var data2: String = ""
    var tf: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        tf = UILabel(frame: CGRect(x: 50, y: 250, width: 240, height: 50))
        tf.backgroundColor = .gray
        self.view.addSubview(tf)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("we are on page 2 - data below")
        print(data2)
        self.tf.text = data2
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
