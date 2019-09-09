//
//  indicator.swift
//  indicator
//
//  Created by Ting on 6/15/19.
//  Copyright © 2019 mobilecenter. All rights reserved.
//

import UIKit

var vSpinner : UIView?

extension UIViewController {
    
    func showSpinner(onWindow: UIWindow, text: String) {
        let spinnerView = UIView()
        spinnerView.translatesAutoresizingMaskIntoConstraints = false
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        
        // the view with blurry background and text
        let progressHUD = ProgressHUD(text: text)
        progressHUD.translatesAutoresizingMaskIntoConstraints = false
        
        DispatchQueue.main.async {
            onWindow.addSubview(spinnerView)
            NSLayoutConstraint.activate([
                spinnerView.topAnchor.constraint(equalTo: onWindow.topAnchor, constant: 0),
                spinnerView.leftAnchor.constraint(equalTo: onWindow.leftAnchor, constant: 0),
                spinnerView.rightAnchor.constraint(equalTo: onWindow.rightAnchor, constant: 0),
                spinnerView.bottomAnchor.constraint(equalTo: onWindow.bottomAnchor, constant: 0),
                spinnerView.widthAnchor.constraint(equalTo: onWindow.widthAnchor),
                spinnerView.heightAnchor.constraint(equalTo: onWindow.heightAnchor)
                ])
            spinnerView.addSubview(progressHUD)
            NSLayoutConstraint.activate([
                progressHUD.widthAnchor.constraint(lessThanOrEqualToConstant: 200.0),
                progressHUD.heightAnchor.constraint(equalToConstant: 50.0),
                progressHUD.centerXAnchor.constraint(equalTo: onWindow.centerXAnchor),
                progressHUD.centerYAnchor.constraint(equalTo: onWindow.centerYAnchor)
                ])
            // don't be too wide
            let widthConstraint = progressHUD.widthAnchor.constraint(greaterThanOrEqualTo: onWindow.widthAnchor, multiplier: 0.5)
            widthConstraint.priority = UILayoutPriority(rawValue: 500)
            widthConstraint.isActive = true
        }
        vSpinner = spinnerView
    }
    
    func removeSpinner() {
        vSpinner?.removeFromSuperview()
        vSpinner = nil
    }
    
    func showSpinner(onView: UIView, text: String) {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.translatesAutoresizingMaskIntoConstraints = false
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        
        // the view with blurry background and text
        let progressHUD = ProgressHUD(text: text)
        progressHUD.center = onView.center
        
        DispatchQueue.main.async {
            onView.addSubview(spinnerView)
            NSLayoutConstraint.activate([
                spinnerView.topAnchor.constraint(equalTo: onView.topAnchor, constant: 0),
                spinnerView.leftAnchor.constraint(equalTo: onView.leftAnchor, constant: 0),
                spinnerView.rightAnchor.constraint(equalTo: onView.rightAnchor, constant: 0),
                spinnerView.bottomAnchor.constraint(equalTo: onView.bottomAnchor, constant: 0)
                ])
            spinnerView.addSubview(progressHUD)
            
            NSLayoutConstraint.activate([
                progressHUD.widthAnchor.constraint(lessThanOrEqualToConstant: 200.0),
                progressHUD.heightAnchor.constraint(equalToConstant: 50.0),
                progressHUD.centerXAnchor.constraint(equalTo: onView.centerXAnchor),
                progressHUD.centerYAnchor.constraint(equalTo: onView.centerYAnchor)
                ])
            // don't be too wide
            let widthConstraint = progressHUD.widthAnchor.constraint(greaterThanOrEqualTo: onView.widthAnchor, multiplier: 0.5)
            widthConstraint.priority = UILayoutPriority(rawValue: 500)
            widthConstraint.isActive = true
        }
        vSpinner = spinnerView
    }
}


/// A view to display an indicator together with a text
class ProgressHUD: UIVisualEffectView {
    
    var text: String? {
        didSet {
            label.text = text
        }
    }
    
    let activityIndictor: UIActivityIndicatorView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
    let label: UILabel = UILabel()
    let blurEffect = UIBlurEffect(style: .light)
    let vibrancyView: UIVisualEffectView
    
    init(text: String) {
        self.text = text
        self.vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: blurEffect))
        super.init(effect: blurEffect)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.text = ""
        self.vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: blurEffect))
        super.init(coder: aDecoder)
        self.setup()
    }
    
    func setup() {
        contentView.addSubview(vibrancyView)
        contentView.addSubview(activityIndictor)
        contentView.addSubview(label)
        vibrancyView.translatesAutoresizingMaskIntoConstraints = false
        activityIndictor.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        activityIndictor.startAnimating()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if let _ = self.superview {
            let activityIndicatorSize: CGFloat = 40
            layer.cornerRadius = 8.0
            layer.masksToBounds = true
            label.text = text
            label.textAlignment = NSTextAlignment.center
            label.textColor = UIColor.darkText
            label.font = UIFont.boldSystemFont(ofSize: 16)
            
            NSLayoutConstraint.activate([
                vibrancyView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
                vibrancyView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 0),
                vibrancyView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 0),
                vibrancyView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0),
                
                activityIndictor.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 5),
                activityIndictor.topAnchor.constraint(equalTo: self.centerYAnchor, constant: -activityIndicatorSize / 2),
                activityIndictor.widthAnchor.constraint(equalToConstant: activityIndicatorSize),
                activityIndictor.heightAnchor.constraint(equalToConstant: activityIndicatorSize),
                
                label.leftAnchor.constraint(equalTo: activityIndictor.rightAnchor, constant: 5),
                label.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
                label.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -5),
                label.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0)
                ])
        }
    }
    
    func show() {
        self.isHidden = false
    }
    
    func hide() {
        self.isHidden = true
    }
}
