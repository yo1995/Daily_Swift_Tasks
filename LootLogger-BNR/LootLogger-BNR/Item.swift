//
//  Item.swift
//  LootLogger-BNR
//
//  Created by Ting Chen on 7/14/20.
//  Copyright © 2020 DukeMobileDevCenter. All rights reserved.
//

import UIKit

class Item {
    var name: String
    var valueInDollars: Int
    var serialNumber: String?
    var isFavorite: Bool
    let dateCreated: Date
    
    static func ==(lhs: Item, rhs: Item) -> Bool {
        return lhs.name == rhs.name
            && lhs.serialNumber == rhs.serialNumber
            && lhs.valueInDollars == rhs.valueInDollars
            && lhs.dateCreated == rhs.dateCreated
    }
    
    init(name: String, serialNumber: String?, valueInDollars: Int) {
        self.name = name
        self.valueInDollars = valueInDollars
        self.serialNumber = serialNumber
        self.isFavorite = false
        self.dateCreated = Date()
    }
    
    // Randomly generate a piece of item.
    convenience init(random: Bool = false) {
        if random {
            let randomAdjective = ["Fluffy", "Rusty", "Shiny", "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz"].randomElement()!
            let randomNoun = ["Bear", "Spork", "Mac"].randomElement()!
            let randomName = "\(randomAdjective) \(randomNoun)"
            let randomValue = Int.random(in: 0..<100)
            let randomSerialNumber =
                UUID().uuidString.components(separatedBy: "-").first!
            self.init(name: randomName, serialNumber: randomSerialNumber, valueInDollars: randomValue)
        } else {
            self.init(name: "", serialNumber: nil, valueInDollars: 0)
        }
    }
}
