//
//  AddEmojiViewController.swift
//  EmojiJournalMobileApp
//
//  Created by David Okun IBM on 1/26/18.
//  Copyright © 2018 Razeware. All rights reserved.
//

import UIKit
import ISEmojiView

protocol AddEmojiDelegate: class {
    func didAdd(entry: JournalEntry, from controller: AddEmojiViewController)
    func didUpdate(entry: JournalEntry, from controller: AddEmojiViewController)
}

class AddEmojiViewController: UIViewController {
    @IBOutlet weak var emojiTextField: UITextField!
    weak var delegate: AddEmojiDelegate?
    var existingEntry: JournalEntry?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let keyboardSettings = KeyboardSettings(bottomType: .categories)
        let emojiView = EmojiView(keyboardSettings: keyboardSettings)
        emojiView.translatesAutoresizingMaskIntoConstraints = false
        emojiView.delegate = self
        emojiTextField.inputView = emojiView
        if let existingEntry = existingEntry {
            emojiTextField.text = existingEntry.emoji
        }
        emojiTextField.becomeFirstResponder()
    }
}

// MARK: - AddEmojiViewController EmojiViewDelegate
extension AddEmojiViewController: EmojiViewDelegate {
    func emojiViewDidSelectEmoji(_ emoji: String, emojiView: EmojiView) {
        emojiTextField.text = emoji
        emojiTextField.resignFirstResponder()
    }
    
    func emojiViewDidPressDeleteButton(emojiView: EmojiView) {
        emojiTextField.text = ""
    }
}

// MARK: - AddEmojiViewController saveEmoji, displayError
extension AddEmojiViewController {
    @IBAction func saveEmoji() {
        guard let emoji = emojiTextField.text else {
            displayError(with: "Need to enter an emoji")
            return
        }
        if let existingEntry = existingEntry {
            guard let updatedEntry = JournalEntry(id: existingEntry.id, emoji: emoji, date: Date()) else {
                displayError(with: "Could not update entry")
                return
            }
            delegate?.didUpdate(entry: updatedEntry, from: self)
        } else {
            guard let newEntry = JournalEntry(id: nil, emoji: emoji, date: Date()) else {
                displayError(with: "Could not create new entry")
                return
            }
            delegate?.didAdd(entry: newEntry, from: self)
        }
    }
    
    private func displayError(with message: String) {
        let alert = UIAlertController(title: "Error", message: "We could not save this emoji - please try again! Reason: \(message)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

