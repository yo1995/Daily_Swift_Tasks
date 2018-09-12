//
//  NewItemViewController.swift
//  todo_list
//
//  Created by admin on 2018/9/12.
//  Copyright © 2018年 admin. All rights reserved.
//

import UIKit

class NewItemViewController: UIViewController {
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    @IBOutlet weak var textField: UITextField!
    
    var toDoItem = ToDoItem()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if ((sender as! UIBarButtonItem) != self.saveButton) {
            return
        }
        if ((self.textField.text) != nil) {
            self.toDoItem.itemName = self.textField.text!
            self.toDoItem.completed = false
        }
    }
    

}
