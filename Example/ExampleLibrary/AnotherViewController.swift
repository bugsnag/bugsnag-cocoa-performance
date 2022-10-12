//
//  AnotherViewController.swift
//  ExampleLibrary
//
//  Created by Nick Dowell on 11/10/2022.
//

import UIKit

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
