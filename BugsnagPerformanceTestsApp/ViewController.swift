//
//  ViewController.swift
//  BugsnagPerformanceTestsApp
//
//  Created by Robert B on 12/04/2023.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var counter = 0
    @IBOutlet var textField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textField.text = "\(counter)"
        // Do any additional setup after loading the view.
    }
    
    @IBAction func increment() {
        counter += 1
        textField.text = "\(counter)"
    }
}

