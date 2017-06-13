//
//  UIControl+.swift
//  VirtualTourist
//
//  Created by Dustin Howell on 6/13/17.
//  Copyright © 2017 Dustin Howell. All rights reserved.
//

import UIKit

extension UIControl {
    func add(for controlEvents: UIControlEvents, _ closure: @escaping () -> ()) {
        let sleeve = ClosureSleeve(closure)
        addTarget(sleeve, action: #selector(ClosureSleeve.invoke), for: controlEvents)
        objc_setAssociatedObject(self, "\(arc4random())", sleeve, .OBJC_ASSOCIATION_RETAIN)
    }
}

class ClosureSleeve {
    let closure: () -> ()
    
    init(_ closure: @escaping () -> () ) {
        self.closure = closure
    }
    
    @objc func invoke() {
        closure()
    }
}
