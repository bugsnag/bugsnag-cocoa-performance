//
//  ViewController.swift
//  Fixture
//
//  Created by Nick Dowell on 26/09/2022.
//

import UIKit

class ViewController: UIViewController {
    var fixture: Fixture = Fixture()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fixture.start()
    }
}
