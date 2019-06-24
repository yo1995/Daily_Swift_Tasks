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
import KituraKit
import KituraContracts

struct Configuration {
    let baseURL: String = "http://rt113-dt01.egr.duke.edu"
    var username: String = "tori"
    var password: String = "fitnessfinder"
}

enum EmojiClientError: Error {
    case couldNotLoadEntries
    case couldNotLoadEntry(String)
    case couldNotAdd(JournalEntry)
    case couldNotDelete(JournalEntry)
    case couldNotUpdate(JournalEntry)
    case couldNotCreateClient
}

// MARK: - UIApplication isDebugMode
extension UIApplication {
    var isDebugMode: Bool {
        let dictionary = ProcessInfo.processInfo.environment
        return dictionary["DEBUGMODE"] != nil
    }
}

public struct JournalEntryParams: QueryParams {
    let emoji: String?
}

class EmojiClient {
    static var baseURL: String {
        return "http://rt113-dt01.egr.duke.edu" // "http://localhost:8080"
    }
    
    var changeURL: String!
    var username: String?
    var password: String?
    
    init(urlString: String, username: String?, password: String?) {
        self.changeURL = urlString
        self.username = username
        self.password = password
    }
    
    static var credentials = HTTPBasic(username: "tori", password: "fitnessfinder")  // default value
    
    // this is an instance function
    func previewAll(completion: @escaping (_ entries: [JournalEntryWeb]?, _ error: EmojiClientError?) -> Void) {
        guard let client = KituraKit(baseURL: changeURL) else {
            return completion(nil, .couldNotCreateClient)
        }
        client.get("/preview") { (entries: [JournalEntryWeb]?, error: RequestError?) in
            DispatchQueue.main.async {
                if error != nil {
                    completion(nil, .couldNotLoadEntries)
                } else {
                    completion(entries, nil)
                }
            }
        }
    }
    
    static func getAll(completion: @escaping (_ entries: [JournalEntry]?, _ error: EmojiClientError?) -> Void) {
        guard let client = KituraKit(baseURL: baseURL) else {
            return completion(nil, .couldNotCreateClient)
        }
        client.defaultCredentials = credentials
        client.get("/entries") { (entries: [JournalEntry]?, error: RequestError?) in
            DispatchQueue.main.async {
                if error != nil {
                    completion(nil, .couldNotLoadEntries)
                } else {
                    completion(entries, nil)
                }
            }
        }
    }
    
    static func get(id: String, completion: @escaping (_ entry: JournalEntry?, _ error: EmojiClientError?) -> Void) {
        guard let client = KituraKit(baseURL: baseURL) else {
            return completion(nil, .couldNotCreateClient)
        }
        client.defaultCredentials = credentials
        client.get("/entries", identifier: id) { (entry: JournalEntry?, error: RequestError?) in
            DispatchQueue.main.async {
                if error != nil {
                    completion(nil, .couldNotLoadEntry(id))
                } else {
                    completion(entry, nil)
                }
            }
        }
    }
    
    static func get(emoji: String, completion: @escaping (_ entries: [JournalEntry]?, _ error: EmojiClientError?) -> Void) {
        guard let client = KituraKit(baseURL: baseURL) else {
            return completion(nil, .couldNotCreateClient)
        }
        let query = JournalEntryParams(emoji: emoji)
        client.defaultCredentials = credentials
        client.get("/entries", query: query) { (entries: [JournalEntry]?, error: RequestError?) in
            DispatchQueue.main.async {
                if error != nil {
                    completion(nil, .couldNotLoadEntries)
                } else {
                    completion(entries, nil)
                }
            }
        }
    }
    
    static func add(entry: JournalEntry, completion: @escaping (_ entry: JournalEntry?, _ error: EmojiClientError?) -> Void) {
        guard let client = KituraKit(baseURL: baseURL) else {
            return completion(nil, .couldNotCreateClient)
        }
        client.defaultCredentials = credentials
        client.post("/entries", data: entry) { (newEntry: JournalEntry?, error: RequestError?) in
            DispatchQueue.main.async {
                if error != nil {
                    completion(nil, .couldNotAdd(entry))
                } else {
                    completion(entry, nil)
                }
            }
        }
    }
    
    static func delete(entry: JournalEntry, completion: @escaping (_ error: EmojiClientError?) -> Void) {
        guard let client = KituraKit(baseURL: baseURL) else {
            return completion(.couldNotCreateClient)
        }
        guard let identifier = entry.id else {
            return completion(.couldNotCreateClient)
        }
        client.defaultCredentials = credentials
        client.delete("/entries", identifier: identifier) { (error: RequestError?) in
            DispatchQueue.main.async {
                if error != nil {
                    completion(.couldNotDelete(entry))
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    static func update(entry: JournalEntry, completion: @escaping (_ entry: JournalEntry?, _ error: EmojiClientError?) -> Void) {
        guard let client = KituraKit(baseURL: baseURL) else {
            return completion(nil, .couldNotCreateClient)
        }
        guard let identifier = entry.id else {
            return completion(nil, .couldNotUpdate(entry))
        }
        client.defaultCredentials = credentials
        client.put("/entries", identifier: identifier, data: entry) { (updated: JournalEntry?, error: RequestError?) in
            DispatchQueue.main.async {
                if error != nil {
                    completion(nil, .couldNotUpdate(entry))
                } else {
                    completion(updated, nil)
                }
            }
        }
    }
}
