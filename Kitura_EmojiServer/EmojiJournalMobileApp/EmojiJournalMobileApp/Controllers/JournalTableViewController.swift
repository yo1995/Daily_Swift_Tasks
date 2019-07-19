/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.


import UIKit
import ISEmojiView
import KituraKit

class JournalTableViewController: UITableViewController {
    private var journalEntries: [JournalEntry] = []
    private var deleteEntryIndexPath: IndexPath?
    fileprivate var emojiSearchTextField: UITextField?
    fileprivate var idSearchTextField: UITextField?
    private var anonymMappings: [String: String] = Dictionary()
    
    var username: String?
    var password: String?
    var isAnonym: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.addSubview(self.refresherControl)
        if self.username == "" {
            self.isAnonym = true
        }
        else {
            self.isAnonym = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        EmojiClient.credentials = HTTPBasic(username: self.username!, password: self.password!)
        loadJournalEntries(with: nil)
        if self.isAnonym {
            self.navigationItem.title = "All Posts"
            self.navigationItem.rightBarButtonItem?.isEnabled = false
            self.navigationItem.leftBarButtonItems![1].isEnabled = false  // the search button
        }
        else {
            self.navigationItem.title = "Posts by \(self.username!)"
        }
    }
    
    
    lazy var refresherControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh(_:)), for: UIControl.Event.valueChanged)
        return refreshControl
    }()

    
    @objc func pullToRefresh(_ refreshControl: UIRefreshControl) {
        loadJournalEntries(with: nil)
    }
    
    @IBAction func refresh() {
        loadJournalEntries(with: nil)
    }
    
    @IBAction func search() {
        promptQueryChoices()
    }
    
    @IBAction func close() {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addNewEmojiSegue" {
            guard let addController = segue.destination as? AddEmojiViewController else {
                return
            }
            addController.delegate = self
        }
        else if segue.identifier == "updateEmojiSegue" {
            guard let existingEntry = sender as? JournalEntry else {
                return
            }
            guard let updateController = segue.destination as? AddEmojiViewController else {
                return
            }
            updateController.delegate = self
            updateController.existingEntry = existingEntry
        }
    }
    
    private func loadJournalEntry(id: String) {
        EmojiClient.get(id: id) { [weak self] entry, error in
            guard let strongSelf = self else {
                return
            }
            if let error = error {
                strongSelf.handleError(error)
            }
            else {
                strongSelf.journalEntries = [entry!]
                strongSelf.tableView.reloadData()
            }
        }
    }
    
    private func loadJournalEntries(with emoji: String?) {
        if self.isAnonym {
            
            let e = EmojiClient(urlString: "http://rt113-dt01.egr.duke.edu",
                                username: nil,
                                password: nil)
            
            e.previewAll { [weak self] entries, error in
                guard let strongSelf = self else {
                    return
                }
                if let error = error {
                    strongSelf.handleError(error)
                } else {
                    var webToEntries: [JournalEntry] = []
                    for e in entries! {
                        webToEntries.append(JournalEntry(id: e.id, emoji: e.emoji, date: e.date)!)
                        strongSelf.anonymMappings[e.id ?? ""] = e.user
                    }
                    strongSelf.journalEntries = webToEntries
                    strongSelf.tableView.reloadData()
                    strongSelf.refresherControl.endRefreshing()
                }
            }
            return
        }
        else if let emoji = emoji {
            EmojiClient.get(emoji: emoji) { [weak self] entries, error in
                guard let strongSelf = self else {
                    return
                }
                if let error = error {
                    strongSelf.handleError(error)
                } else {
                    strongSelf.journalEntries = entries!
                    strongSelf.tableView.reloadData()
                    strongSelf.refresherControl.endRefreshing()
                }
            }
        }
        else {
            EmojiClient.getAll { [weak self] entries, error in
                guard let strongSelf = self else {
                    return
                }
                if let error = error {
                    strongSelf.handleError(error)
                } else {
                    strongSelf.journalEntries = entries!
                    strongSelf.tableView.reloadData()
                    strongSelf.refresherControl.endRefreshing()
                }
            }
        }
    }
    
    fileprivate func handleError(_ error: EmojiClientError) {
        
        let failAction: () -> Void = {
            self.navigationController?.popViewController(animated: true)
            return
        }
        
        switch error {
        case .couldNotAdd(let entry):
            UIAlertController.showError(with: "Could not add entry: \(entry.emoji)", on: self, then: nil)
        case .couldNotDelete(let entry):
            UIAlertController.showError(with: "Could not delete entry: \(entry.emoji)", on: self, then: nil)
        case .couldNotLoadEntries:
            UIAlertController.showError(with: "Could not access entries on server.\nCheck your credentials.", on: self, then: failAction)
        case .couldNotLoadEntry(let id):
            UIAlertController.showError(with: "Could not access entry with id: \(id)", on: self, then: nil)
        case .couldNotCreateClient:
            UIAlertController.showError(with: "Could not create client for server transmission", on: self, then: failAction)
        case .couldNotUpdate(let entry):
            UIAlertController.showError(with: "Could not update entry: \(entry.emoji)", on: self, then: nil)
        }
    }
}

//MARK: - UIAlertController showerror
extension UIAlertController {
    static func showError(with message: String, on controller: UIViewController, then finish: (() -> Void)?) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .destructive, handler: { _ in
            if let done = finish {
                done()
            }
        })
        alert.addAction(action)
        controller.present(alert, animated: true, completion: nil)
    }
}

// MARK: - Table view data source
extension JournalTableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return journalEntries.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: JournalTableViewCell.cellIdentifier, for: indexPath) as! JournalTableViewCell
        let entry = journalEntries[indexPath.row]
        cell.emojiLabel.text = entry.emoji
        cell.dateLabel.text = entry.date.displayDate.uppercased()
        cell.timeLabel.text = entry.date.displayTime
        
        if self.isAnonym {
            cell.dateLabel.text = entry.date.displayDate.uppercased() + " - " + self.anonymMappings[entry.id ?? ""]!
        }
        
        cell.backgroundColor = entry.backgroundColor
        return cell
    }
}


// MARK - Search Functionality
extension JournalTableViewController {
    func promptQueryChoices() {
        let alert = UIAlertController(title: "How would you like to search?", message: nil, preferredStyle: .alert)
        let idAction = UIAlertAction(title: "ID", style: .default) { action in
            self.promptIDAction()
        }
        let emojiAction = UIAlertAction(title: "Emoji", style: .default) { action in
            self.promptEmojiAction()
        }
        alert.addAction(idAction)
        alert.addAction(emojiAction)
        present(alert, animated: true, completion: nil)
    }
    
    func promptIDAction() {
        let alert = UIAlertController(title: "Enter ID to search for", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] action in
            guard let strongSelf = self else {
                return
            }
            guard let idSearch = strongSelf.idSearchTextField?.text else {
                return
            }
            strongSelf.idSearchTextField = nil
            strongSelf.loadJournalEntry(id: idSearch)
        }))
        alert.addTextField { [weak self] textField in
            guard let strongSelf = self else {
                return
            }
            strongSelf.idSearchTextField = textField
        }
        present(alert, animated: true, completion: nil)
    }
    
    func promptEmojiAction() {
        let alert = UIAlertController(title: "Enter emoji to search for", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] action in
            guard let strongSelf = self else {
                return
            }
            guard let emojiSearch = strongSelf.emojiSearchTextField?.text else {
                return
            }
            strongSelf.emojiSearchTextField = nil
            strongSelf.loadJournalEntries(with: emojiSearch)
        }))
        alert.addTextField { [weak self] textField in
            guard let strongSelf = self else {
                return
            }
            strongSelf.emojiSearchTextField = textField
            let keyboardSettings = KeyboardSettings(bottomType: .categories)
            let emojiView = EmojiView(keyboardSettings: keyboardSettings)
            emojiView.translatesAutoresizingMaskIntoConstraints = false
            emojiView.delegate = self
            textField.inputView = emojiView
            textField.becomeFirstResponder()
        }
        present(alert, animated: true, completion: nil)
    }
}

// MARK - Search Functionality Emoji Delegate
extension JournalTableViewController: EmojiViewDelegate {
    func emojiViewDidSelectEmoji(_ emoji: String, emojiView: EmojiView) {
        if let textField = emojiSearchTextField {
            textField.text = emoji
        }
    }
    
    func emojiViewDidPressDeleteButton(emojiView: EmojiView) {
        if let textField = emojiSearchTextField {
            textField.text = ""
        }
    }
}

// MARK: - Add Emoji Delegate functions
extension JournalTableViewController: AddEmojiDelegate {
    func didAdd(entry: JournalEntry, from controller: AddEmojiViewController) {
        EmojiClient.add(entry: entry) { [weak self] (savedEntry: JournalEntry?, error: EmojiClientError?) in
            guard let strongSelf = self else {
                return
            }
            if let error = error {
                strongSelf.handleError(error)
            }
            else {
                strongSelf.navigationController?.popToViewController(strongSelf, animated: true)
                // avoid animating to top of empty table view, causing crash
                if strongSelf.tableView.numberOfRows(inSection: 0) > 0 {
                    let path = IndexPath(row: 0, section: 0)
                    strongSelf.tableView.scrollToRow(at: path, at: UITableViewScrollPosition.top, animated: true)
                }
            }
        }
    }
    
    func didUpdate(entry: JournalEntry, from controller: AddEmojiViewController) {
        EmojiClient.update(entry: entry) { [weak self] updatedEntry, error in
            guard let strongSelf = self else {
                return
            }
            if let error = error {
                strongSelf.handleError(error)
            }
            else {
                strongSelf.navigationController?.popToViewController(strongSelf, animated: true)
                strongSelf.loadJournalEntries(with: nil)
            }
        }
    }
}

// MARK: - Table view delegate
extension JournalTableViewController {
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if self.isAnonym {
            return []
        }
        let updateAction = UITableViewRowAction(style: .normal, title: "Update", handler: { [weak self] action, indexpath in
            guard let strongSelf = self else {
                return
            }
            strongSelf.performSegue(withIdentifier: "updateEmojiSegue", sender: strongSelf.journalEntries[indexPath.row])
        })
        updateAction.backgroundColor = .purple
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete", handler: { [weak self] action, indexpath in
            guard let strongSelf = self else {
                return
            }
            strongSelf.deleteEntryIndexPath = indexPath
            let entry = strongSelf.journalEntries[indexPath.row]
            strongSelf.confirmDelete(entry: entry)
        })
        return [updateAction, deleteAction];
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteEntryIndexPath = indexPath
            let entry = journalEntries[indexPath.row]
            confirmDelete(entry: entry)
        }
    }
    
    func confirmDelete(entry: JournalEntry) {
        let alert = UIAlertController(title: "Delete Journal Entry", message: "Are you sure you want to delete \(entry.emoji) from your journal?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: deleteEntryHandler))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { [weak self] action in
            guard let strongSelf = self else {
                return
            }
            strongSelf.deleteEntryIndexPath = nil
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func deleteEntryHandler(action: UIAlertAction) {
        guard let indexPath = deleteEntryIndexPath else {
            deleteEntryIndexPath = nil
            return
        }
        EmojiClient.delete(entry: journalEntries[indexPath.row]) { [weak self] (error: EmojiClientError?) in
            guard let strongSelf = self else {
                return
            }
            if let error = error {
                strongSelf.handleError(error)
            }
            else {
                strongSelf.tableView.beginUpdates()
                strongSelf.journalEntries.remove(at: indexPath.row)
                strongSelf.tableView.deleteRows(at: [indexPath], with: .automatic)
                strongSelf.deleteEntryIndexPath = nil
                strongSelf.tableView.endUpdates()
            }
        }
    }
}

// MARK: - JournalEntry backgroundColor
extension JournalEntry {
    var backgroundColor: UIColor {
        guard let substring = id?.suffix(6).uppercased() else {
            return UIColor(hexString: "000000")
        }
        return UIColor(hexString: substring)
    }
}

// MARK: - UIColor hexString
extension UIColor {
    convenience init(hexString: String, alpha: CGFloat = 1.0) {
        let hexString: String = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let scanner = Scanner(string: hexString)
        if hexString.hasPrefix("#") {
            scanner.scanLocation = 1
        }
        var color: UInt32 = 0
        scanner.scanHexInt32(&color)
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        let red = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue = CGFloat(b) / 255.0
        self.init(red: red,
                  green: green,
                  blue: blue,
                  alpha: alpha)
    }
    
    func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb: Int = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255) << 0
        return String(format:"#%06x", rgb)
    }
}
