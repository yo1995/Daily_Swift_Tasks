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
import LoggerAPI
import Kitura

var entries: [JournalEntry] = []

func initializeEntryRoutes(app: App) {
  app.router.get("/entries", handler: getEntries)
  app.router.post("/entries", handler: addEntry)
  app.router.delete("/entries", handler: deleteEntry)
  app.router.put("/entries", handler: modifyEntry)
  app.router.get("/entries", handler: getOneEntry)
  Log.info("Journal entry routes created")
}

func addEntry(user: UserAuth, entry: JournalEntry, completion: @escaping (JournalEntry?, RequestError?) -> Void) {
  var savedEntry = entry
  savedEntry.id = UUID().uuidString
  savedEntry.save(for: user, completion)
}

func getEntries(user: UserAuth, query: JournalEntryParams?, completion: @escaping ([JournalEntry]?, RequestError?) -> Void) -> Void {
  JournalEntry.findAll(matching: query, for: user, completion)
}

func deleteEntry(user: UserAuth, id: String, completion: @escaping (RequestError?) -> Void) {
  JournalEntry.delete(id: id, for: user, completion)
}

func modifyEntry(user: UserAuth, id: String, entry: JournalEntry, completion: @escaping (JournalEntry?, RequestError?) -> Void) {
  entry.update(id: id, for: user, completion)
}

func getOneEntry(user: UserAuth, id: String, completion: @escaping (JournalEntry?, RequestError?) -> Void) {
  JournalEntry.find(id: id, for: user, completion)
}


