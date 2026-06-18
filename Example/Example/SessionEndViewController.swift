//
//  SessionEndViewController.swift
//  Example
//
//  Manual test for Session Span Feature - End Screen
//

import UIKit
import BugsnagPerformance

class SessionEndViewController: UIViewController {
    
    var statusLabel: UILabel!
    var endButton: UIButton!
    var metricsLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Session Test - End"
        view.backgroundColor = .systemBackground
        
        // Setup UI
        statusLabel = UILabel()
        statusLabel.text = "Screen 2: Ready to End Session"
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center
        statusLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        view.addSubview(statusLabel)
        
        metricsLabel = UILabel()
        metricsLabel.text = "Wait a few seconds, then click 'End Session' or click the back button to end the session and return to the main screen."
        metricsLabel.numberOfLines = 0
        metricsLabel.textAlignment = .center
        metricsLabel.font = .systemFont(ofSize: 14)
        metricsLabel.textColor = .secondaryLabel
        view.addSubview(metricsLabel)
        
        endButton = UIButton(type: .system)
        endButton.setTitle("End Session", for: .normal)
        endButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        endButton.backgroundColor = .systemRed
        endButton.setTitleColor(.white, for: .normal)
        endButton.layer.cornerRadius = 8
        endButton.addTarget(self, action: #selector(endButtonTapped), for: .touchUpInside)
        view.addSubview(endButton)
        
        // Layout
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        metricsLabel.translatesAutoresizingMaskIntoConstraints = false
        endButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            metricsLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 30),
            metricsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            metricsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            endButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            endButton.topAnchor.constraint(equalTo: metricsLabel.bottomAnchor, constant: 50),
            endButton.widthAnchor.constraint(equalToConstant: 150),
            endButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            endSession()
        }
    }
    
    func endSession() {
        guard let span = globalSessionSpan else {
            return
        }
        
        // End the session span
        span.end()
        
        // Clear global reference
        globalSessionSpan = nil
    }
    
    
    @objc func endButtonTapped() {
        // Back to main screen
        navigationController?.popViewController(animated: true)
    }
}
