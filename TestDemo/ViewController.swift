//
//  ViewController.swift
//  TestDemo
//
//  Created by 董安东 on 2017/9/8.
//  Copyright © 2017年 Adam. All rights reserved.
//

import UIKit
import NSLogger

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let deviceInfo = USB360ManagerWrapper.shared().requestDeviceInfo() ?? ""
        Log(.App,.Info," [viewController] deviceInfo = \(deviceInfo)")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

