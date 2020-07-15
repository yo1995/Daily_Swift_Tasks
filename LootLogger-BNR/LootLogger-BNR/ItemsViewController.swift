//
//  ItemsViewController.swift
//  LootLogger-BNR
//
//  Created by Ting Chen on 7/14/20.
//  Copyright © 2020 DukeMobileDevCenter. All rights reserved.
//

import UIKit

class ItemsViewController: UITableViewController {
    var itemStore: ItemStore!
    
    @IBAction func addNewItem(_ sender: UIBarButtonItem) {
        // Create a new item and add it to the store
        let newItem = itemStore.createItem()
        // Figure out where that item is in the array
        if let index = itemStore.allItems.firstIndex(where: { $0 == newItem }) {
            let indexPath = IndexPath(row: index, section: 0)
            // Insert this new row into the table
            tableView.insertRows(at: [indexPath], with: .automatic)
        }
    }
    
    @IBAction func toggleEditingMode(_ sender: UIBarButtonItem) {
        if isEditing {
            // Change text of button to inform user of state
            sender.title = "Edit"
            // Turn off editing mode
            setEditing(false, animated: true)
        } else {
            // Change text of button to inform user of state
            sender.title = "Done"
            // Enter editing mode
            setEditing(true, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 85
    }
}

// MARK: - Data source
extension ItemsViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemStore.allItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath) as! ItemCell
        let item = itemStore.allItems[indexPath.row]
        // Configure the cell with the Item
        cell.nameLabel.text = item.name
        cell.serialNumberLabel.text = item.serialNumber
        cell.valueLabel.text = "$\(item.valueInDollars)"
        cell.backgroundColor = item.valueInDollars > 50 ? .systemTeal : .systemRed
        cell.accessoryType = item.isFavorite ? .checkmark : .none
        return cell
    }
}

// MARK: - Edit and actions
extension ItemsViewController {
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // Update the model
        itemStore.moveItem(from: sourceIndexPath.row, to: destinationIndexPath.row)
    }
    
    func contextualFavoriteAction(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
        let item = itemStore.allItems[indexPath.row]
        let title = item.isFavorite ? "Un-fav" : "Fav"
        let action = UIContextualAction(style: .normal, title: title) { [weak self] (contextAction: UIContextualAction, sourceView: UIView, completionHandler: (Bool) -> Void) in
            guard let self = self else { return }
            // Remove the item from the store
            item.isFavorite.toggle()
            self.tableView.reloadRows(at: [indexPath], with: .none)
            completionHandler(true)
        }
        action.backgroundColor = item.isFavorite ? .systemGray : .systemOrange
        return action
    }
    
    func contextualDeleteAction(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
        let item = itemStore.allItems[indexPath.row]
        let action = UIContextualAction(style: .destructive, title: "Delete") { (contextAction: UIContextualAction, sourceView: UIView, completionHandler: (Bool) -> Void) in
            // Remove the item from the store
            self.itemStore.removeItem(item)
            // Also remove that row from the table view with an animation
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        return action
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = contextualDeleteAction(forRowAtIndexPath: indexPath)
        let favAction = contextualFavoriteAction(forRowAtIndexPath: indexPath)
        let swipeConfig = UISwipeActionsConfiguration(actions: [deleteAction, favAction])
        swipeConfig.performsFirstActionWithFullSwipe = false
        return swipeConfig
    }
}
