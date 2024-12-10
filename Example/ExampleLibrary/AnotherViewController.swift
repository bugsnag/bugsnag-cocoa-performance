//
//  AnotherViewController.swift
//  ExampleLibrary
//
//  Created by Nick Dowell on 11/10/2022.
//

import UIKit
import BugsnagPerformance

class AnotherViewController: UIViewController {
    
    override func loadView() {
        print("AnotherViewController", #function)
        super.loadView()
    }

    override func viewDidLoad() {
        print("AnotherViewController", #function)
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        print("AnotherViewController", #function)
        super.viewDidAppear(animated)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

class GenericViewController<T>: UIViewController {
    var value: T?

    init() {
        super.init(nibName: nil, bundle: nil)
        value = nil
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        value = nil
    }

    override func loadView() {
        print("GenericViewController", #function)
        super.loadView()
    }

    override func viewDidLoad() {
        print("GenericViewController", #function)
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        print("GenericViewController", #function)
        super.viewDidAppear(animated)
    }
}
