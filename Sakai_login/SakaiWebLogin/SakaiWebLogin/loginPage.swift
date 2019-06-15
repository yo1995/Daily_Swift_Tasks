//
//  loginPage.swift
//  SakaiWebLogin
//
//  Created by ECE564 on 6/14/19.
//  Copyright © 2019 mobilecenter. All rights reserved.
//

import UIKit
import WebKit

var task : URLSessionTask!
var userId : String = ""
var sites = [String]()
var courses:[(name: String, siteId: String, term: String,  instructor: String, lastModified: Int64)] = []

class loginPage: UIViewController, WKNavigationDelegate {
    
    let semaphore = DispatchSemaphore(value: 0)
    let semaphore1 = DispatchSemaphore(value: 0)
    
    var navBar: UINavigationBar!
    var loginWebView: WKWebView!
    
    var onDoneLogin : ((Bool) -> Void)?
    
    @IBAction func webviewRefresh(_ sender: Any) {
        let url = URL(string:"https://sakai.duke.edu")!
        self.loginWebView.load(URLRequest(url: url))
    }
    
    @IBAction func cancel() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        #warning("ℹ️ The WKWebView autolayout has conflicts for pop up keyboard. Check these threads.")
        // https://stackoverflow.com/questions/46993890/wkwebview-layoutconstraints-issue
        // https://stackoverflow.com/questions/47113661/wkwebview-constrains-issue-when-keyboard-pops-up
        self.view.backgroundColor = .lightGray
        
        self.initWebView()
        self.initNavBar()
        
        self.setLayoutConstraints()
        
        let url = URL(string: "https://sakai.duke.edu")!
        self.loginWebView.load(URLRequest(url: url))
        
        // Do any additional setup after loading the view.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyBoard))
        self.view.addGestureRecognizer(tap)
    }
    
    func setLayoutConstraints() {
        
        self.navBar.translatesAutoresizingMaskIntoConstraints = false
        let navBarConstraints = [
            self.navBar.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.navBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.navBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.navBar.heightAnchor.constraint(equalToConstant: 44)]
        NSLayoutConstraint.activate(navBarConstraints)
        
        self.loginWebView.translatesAutoresizingMaskIntoConstraints = false
        let webViewConstraints = [
            self.loginWebView.topAnchor.constraint(equalTo:self.navBar.bottomAnchor),
            self.loginWebView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.loginWebView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.loginWebView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)]
        NSLayoutConstraint.activate(webViewConstraints)
        
    }
    
    func initWebView() {
        self.loginWebView = WKWebView()
        self.loginWebView.navigationDelegate = self
        self.view.addSubview(loginWebView)
    }
    
    func initNavBar() {
        
        self.navBar = UINavigationBar()  // frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44)
        
        let navItem = UINavigationItem(title: "Login")
        let refreshItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.refresh, target: nil, action: #selector(self.webviewRefresh))
        let cancelItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.cancel, target: nil, action: #selector(self.cancel))
        navItem.rightBarButtonItem = refreshItem
        navItem.leftBarButtonItem = cancelItem
        self.navBar.setItems([navItem], animated: false)
        
        self.view.addSubview(self.navBar)
    }
    
    
    func initialCourses() {
        courses = []
        for site in sites {
            let thisurl = "https://sakai.duke.edu/direct/site/" + site + ".json?n=100&d=3000"
            let requestURL: NSURL = NSURL(string: thisurl)!
            let urlRequest: NSMutableURLRequest = NSMutableURLRequest(url: requestURL as URL)
            let session = URLSession.shared
            session.configuration.httpCookieStorage = HTTPCookieStorage.shared
            session.configuration.httpCookieAcceptPolicy = .always
            session.configuration.httpShouldSetCookies = true
            let task = session.dataTask(with: urlRequest as URLRequest) {
                (data, response, error) -> Void in
                let httpResponse = response as? HTTPURLResponse
                if (httpResponse == nil) {
                    print("Error: no response in init courses")
                    self.semaphore.signal()
                    courses = []
                    return
                }
                let statusCode = httpResponse?.statusCode
                
                if (statusCode == 200) {
                    do{
                        let json = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as! [String: AnyObject]
                        var name:String = "name"
                        var instructor:String = "instructor"
                        var lastModified:Int64 = 0
                        var term:String = "Project"
                        if let title = json["title"] as? String {
                            name = title
                        }
                        if let type = json["type"] as? String {
                            if (type != "project") {
                                if let props = json["props"]  {
                                    term = (props["term"] as? String)!
                                }
                            }
                        }
                        if let siteOwner = json["siteOwner"]  {
                            if (siteOwner["userDisplayName"] as? String) != nil {
                                instructor = (siteOwner["userDisplayName"] as? String)!
                            }
                        }
                        if let mylastModified = json["lastModified"] as? Int64{
                            lastModified = mylastModified
                        }
                        let tuple = (name, site, term, instructor, lastModified)
                        // print(tuple)
                        courses.append(tuple)
                        if courses.count == sites.count{
                            print("ℹ️ debug info: all done here")
                            self.dismiss(animated: true, completion: {
                                self.onDoneLogin!(true)  // the full process, including ui update, is done here.
                            })
                        }
                    }
                    catch {
                        print("Error with Json: \(error)")
                    }
                }
                self.semaphore.signal()
            }
            task.resume()
            _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if !((loginWebView.url?.absoluteString.hasPrefix("https://sakai.duke.edu/portal"))! ) {
            print("ℹ️ debug info: not portal page yet")
            return
        }
        else {
            print("ℹ️ debug info: portal loaded")
            loadAPIAfterLogin()
        }
    }
    
    // https://stackoverflow.com/questions/48181336/sync-wkwebview-cookie-to-nshttpcookiestorage
    // more logics can be added to this block to handle exceptions of grabbing the session data
    // for now i only deal with the success case
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Swift.Void) {
        guard let response = navigationResponse.response as? HTTPURLResponse, let url = navigationResponse.response.url
            else {
                decisionHandler(.cancel)
                return
        }
        
        print("ℹ️ debug info: set cookies here")
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies {(cookies) in
            for cookie in cookies {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
        }
        
        // for sakai login, there are 4 steps
        // 1. https://shib.oit.duke.edu/idp/profile/SAML2/POST/SSO;jsessionid=(*session_id*)?execution=e1s1&_eventId_proceed=1 , shib auth
        // 2. https://sakai.duke.edu/portal , the full page
        // 3. https://sakai.duke.edu/portal/tool/(*a_strange_token*)?panel=Main , which load the main panel
        // 4. https://sakai.duke.edu/portal/tool/(*another_strange_token*)/calendar , might be related to calendar module
        // those unknown tokens might be related with certain events or person identity, or for other purposes.
        if let headerFields = response.allHeaderFields as? [String: String] {
            print("ℹ️ debug info: check headers here")
            print(headerFields)
            print(url)
        }
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        print("ℹ️ debug info: redirect happened here")
    }
    
    
    func loadAPIAfterLogin() {
        if !((loginWebView.url?.absoluteString.hasPrefix("https://sakai.duke.edu/portal"))!){
            print("ℹ️ debug info: portal loaded falsified...")
            return
        }
        sites = [String]()
        let requestURL: NSURL = NSURL(string: "https://sakai.duke.edu/direct/membership.json?_limit=100")!
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(url: requestURL as URL)
        
        let session = URLSession.shared
        session.configuration.httpCookieStorage = HTTPCookieStorage.shared
        session.configuration.httpCookieAcceptPolicy = .always
        session.configuration.httpShouldSetCookies = true
        let targetString = "site:"
        
        let task = session.dataTask(with: urlRequest as URLRequest) {
            (data, response, error) -> Void in
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
                    print("no response in loadAPIAfterLogin")  // , \((response as? HTTPURLResponse)!.statusCode) httpResponse
                    sites = []
                    userId = ""
                    self.semaphore1.signal()
                    return
            }
           
            do{
                let json = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as! [String: AnyObject]
                if let membership_collection = json["membership_collection"] as? [[String: AnyObject]] {
                    for membership in membership_collection {
                        if let id = membership["id"] as? String {
                            let startIndex = strStr(id, targetString)
                            let mystring = id.substring(from: (startIndex + 5))
                            sites.append(mystring)
                        }
                        if let myuserId = membership["userId"] as? String {
                            userId = myuserId
                        }
                    }
                }
                else {
                    print("no such object in json")
                }
            }
            catch {
                print("Error with Json parsing: \(error)")
            }
            
            self.semaphore1.signal()
        }
        task.resume()
        _ = semaphore1.wait(timeout: DispatchTime.distantFuture)
        print("ℹ️ debug info: before init courses")
        
        initialCourses()
        print("ℹ️ debug info: after init courses")
    }
    
    @objc func dismissKeyBoard() {
        self.view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

