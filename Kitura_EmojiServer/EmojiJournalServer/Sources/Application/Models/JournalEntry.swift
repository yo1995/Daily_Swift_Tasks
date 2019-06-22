/// Copyright (c) 2019 Razeware LLC
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

import Foundation
import KituraContracts
import SwiftKueryORM

struct JournalEntry: Model {
  var id: String?
  var emoji: String
  var date: Date
  
  init(_ entry: UserJournalEntry) {
    self.id = entry.id
    self.emoji = entry.emoji
    self.date = entry.date
  }
  
  func save(for user: UserAuth, _ completion: @escaping (JournalEntry?, RequestError?) -> Void) -> Void {
    let complete =  { (entry: UserJournalEntry?, error: RequestError?) -> Void in
      guard let entry = entry else {
        return completion(nil, error)
      }
      completion(JournalEntry(entry), error)
    }
    UserJournalEntry(self, for: user).save(using: Database.default, complete)
  }
  
  static func findAll(matching: JournalEntryParams?, for user: UserAuth, _ completion: @escaping ([JournalEntry]?, RequestError?) -> Void) -> Void {
    let complete =  { (entries: [UserJournalEntry]?, error: RequestError?) -> Void in
      guard let entries = entries else {
        return completion(nil, error)
      }
      var journalEntries = [JournalEntry]()
      for entry in entries {
        journalEntries.append(JournalEntry(entry))
      }
      completion(journalEntries, error)
    }
    UserJournalEntry.findAll(using: Database.default, matching: UserJournalEntryParams(matching, for: user), complete)
  }
  
  static func delete(id: String, for user: UserAuth, _ completion: @escaping (RequestError?) -> Void) -> Void {
    let complete = { (entry: UserJournalEntry?, error: RequestError?) -> Void in
      guard let entry = entry else {
        return completion(error)
      }
      if entry.user != user.id {
        return completion(RequestError.forbidden)
      }
      UserJournalEntry.delete(id: id, completion)
    }
    UserJournalEntry.find(id: id, complete)
  }
  
  func update(id: String, for user: UserAuth, _ completion: @escaping (JournalEntry?, RequestError?) -> Void) -> Void {
    let findComplete = { (entry: UserJournalEntry?, error: RequestError?) -> Void in
      guard let entry = entry else {
        return completion(nil, error)
      }
      if entry.user != user.id {
        return completion(nil, RequestError.forbidden)
      }
      let updateComplete =  { (entry: UserJournalEntry?, error: RequestError?) -> Void in
        guard let entry = entry else {
          return completion(nil, error)
        }
        completion(JournalEntry(entry), error)
      }
      UserJournalEntry(self, for: user).update(id: id, updateComplete)
    }
    UserJournalEntry.find(id: id, findComplete)
  }
  
  static func find(id: String, for user: UserAuth, _ completion: @escaping (JournalEntry?, RequestError?) -> Void) -> Void {
    let complete = { (entry: UserJournalEntry?, error: RequestError?) -> Void in
      guard let entry = entry else {
        return completion(nil, error)
      }
      if entry.user != user.id {
        return completion(nil, RequestError.forbidden)
      }
      return completion(JournalEntry(entry), nil)
    }
    UserJournalEntry.find(id: id, complete)
  }
  
  static func deleteAll(for user: UserAuth, _ completion: @escaping (RequestError?) -> Void) -> Void {
    UserJournalEntry.deleteAll(using: Database.default, matching: UserQuery(user), completion)
  }
}

struct JournalEntryParams: QueryParams {
  var emoji: String?
}

struct UserJournalEntry: Model {
  var id: String?
  var emoji: String
  var date: Date
  var user: String
  
  init(_ journalEntry: JournalEntry, for user: UserAuth) {
    self.id = journalEntry.id
    self.emoji = journalEntry.emoji
    self.date = journalEntry.date
    self.user = user.id
  }
}

struct UserQuery: QueryParams {
  let user: String
  
  init(_ user: UserAuth) {
    self.user = user.id
  }
}

struct UserJournalEntryParams: QueryParams {
  let user: String
  let emoji: String?
  
  init(_ query: JournalEntryParams?, for user: UserAuth) {
    self.user = user.id
    self.emoji = query?.emoji
  }
}
