//
//  ClosureButton.swift
//  VirtualTourist
//
//  Created by Dustin Howell on 6/13/17.
//  Copyright © 2017 Dustin Howell. All rights reserved.
//

import UIKit

class ClosureButton: UIButton {
    var touchUpAction: ( () -> () )?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addTarget(self, action: #selector(touchUp), for: .touchUpInside)
    }
    
    convenience init(frame: CGRect, touchUpAction: @escaping ( () -> ())) {
        self.init(frame: frame)
        self.touchUpAction = touchUpAction
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func touchUp() {
        touchUpAction?()
    }
}
