//
//  UIUtil.swift
//  OnTheMap
//
//  Created by Dustin Howell on 3/29/17.
//  Copyright © 2017 Dustin Howell. All rights reserved.
//

import UIKit

func executeOnMain(withDelayInSeconds delay: Double? = nil, _ updates: @escaping () -> Void) {
    if let delay = delay {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: updates)
    } else {
        DispatchQueue.main.async {
            updates()
        }
    }
}

func showAlertController(hostController: UIViewController, title: String, msg: String) {
    executeOnMain {
        let alertController = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        hostController.present(alertController, animated: true, completion: nil)
    }
}
