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
import KituraStencil
import Kitura
import SwiftKueryORM

fileprivate extension UserJournalEntry {
  var displayDate: String {
    get {
      let formatter = DateFormatter()
      formatter.dateStyle = .long
      return formatter.string(from: self.date)
    }
  }
  
  var displayTime: String {
    get {
      let formatter = DateFormatter()
      formatter.timeStyle = .long
      return formatter.string(from: self.date)
    }
  }
  
  var backgroundColorCode: String {
    get {
      guard let substring = id?.suffix(6).uppercased() else {
        return "000000"
      }
      return substring
    }
  }
}

struct JournalEntryWeb: Codable {
  var id: String?
  var emoji: String
  var date: Date
  var displayDate: String
  var displayTime: String
  var backgroundColorCode: String
  var user: String
}

func initializeWebClientRoutes(app: App) {
  app.router.setDefault(templateEngine: StencilTemplateEngine())
  app.router.all(middleware: StaticFileServer(path: "./public"))
  app.router.get("/client", handler: showClient)
  Log.info("Web client routes created")
}

func showClient(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) {
  UserJournalEntry.findAll(using: Database.default) { entries, error in
    guard let entries = entries else {
      response.status(.serviceUnavailable).send(json: ["Message": "Service unavailable: \(String(describing: error?.localizedDescription))"])
      return
    }
    let sortedEntries = entries.sorted(by: {
      $0.date.timeIntervalSince1970 > $1.date.timeIntervalSince1970
    })
    var webEntries = [JournalEntryWeb]()
    for entry in sortedEntries {
      webEntries.append(JournalEntryWeb(id: entry.id,
                                        emoji: entry.emoji,
                                        date: entry.date,
                                        displayDate: entry.displayDate,
                                        displayTime: entry.displayTime,
                                        backgroundColorCode: entry.backgroundColorCode,
                                        user: entry.user))
    }
    do {
      try response.render("home.stencil", with: webEntries, forKey: "entries")
    } catch let error {
      response.status(.internalServerError).send(error.localizedDescription)
    }
  }
}
