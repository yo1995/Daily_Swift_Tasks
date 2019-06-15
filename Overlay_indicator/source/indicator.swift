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
        let spinnerView = UIView.init(frame: onWindow.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        
        // the simple version without text
        //        let ai = UIActivityIndicatorView.init(style: .whiteLarge)
        //        ai.startAnimating()
        //        ai.center = spinnerView.center
        
        // the view with blurry background and text
        let progressHUD = ProgressHUD(text: text)
        progressHUD.center = spinnerView.center
        
        DispatchQueue.main.async {
            spinnerView.addSubview(progressHUD)
            onWindow.addSubview(spinnerView)
        }
        vSpinner = spinnerView
    }
    
    func removeSpinner() {
        vSpinner?.removeFromSuperview()
        vSpinner = nil
    }
    
    func showSpinner(onView: UIView, text: String) {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        
        // the simple version without text
        //        let ai = UIActivityIndicatorView.init(style: .whiteLarge)
        //        ai.startAnimating()
        //        ai.center = spinnerView.center
        
        // the view with blurry background and text
        let progressHUD = ProgressHUD(text: text)
        progressHUD.center = spinnerView.center
        
        DispatchQueue.main.async {
            spinnerView.addSubview(progressHUD)
            onView.addSubview(spinnerView)
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
        activityIndictor.startAnimating()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if let superview = self.superview {
            // MARK: - this is a bad design! Should not fix the dimensions in code. Instead use dimension constant in a separate file is a better practice.
            let width = superview.frame.size.width / 2 > 200 ? 200 : superview.frame.size.width / 2
            let height: CGFloat = 50.0
            self.frame = CGRect(x: superview.frame.width / 2 - width / 2,
                                y: superview.frame.height / 2 - height / 2,
                                width: width,
                                height: height)
            vibrancyView.frame = self.bounds
            
            let activityIndicatorSize: CGFloat = 40
            activityIndictor.frame = CGRect(x: 5,
                                            y: height / 2 - activityIndicatorSize / 2,
                                            width: activityIndicatorSize,
                                            height: activityIndicatorSize)
            
            layer.cornerRadius = 8.0
            layer.masksToBounds = true
            label.text = text
            label.textAlignment = NSTextAlignment.center
            label.frame = CGRect(x: activityIndicatorSize + 5,
                                 y: 0,
                                 width: width - activityIndicatorSize - 15,
                                 height: height)
            label.textColor = UIColor.gray
            label.font = UIFont.boldSystemFont(ofSize: 16)
        }
    }
    
    func show() {
        self.isHidden = false
    }
    
    func hide() {
        self.isHidden = true
    }
}
