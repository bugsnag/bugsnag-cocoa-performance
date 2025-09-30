//
//  ViewController.swift
//  Fixture
//
//  Created by Nick Dowell on 26/09/2022.
//

import UIKit

class ViewController: UIViewController {
    var fixture: Fixture = Fixture()
//    var fixture: Fixture = PresetFixture(scenarioName: "RenderingMetricsScenario",
//                                         scenarioConfig: [
//                                            "spanStartTime": "early"
//                                         ],
//                                         bugsnagConfig: [
//                                            "renderingMetrics": "true"
//                                         ])

    func setFixture(fixture: Fixture) {
        self.fixture = fixture
        fixture.start()
    }

    override func loadView() {
        // we are creating a class property because we may have delegates
        // assign your delegates here, before view
        let customView = UIView()
        customView.backgroundColor = .white

        view = customView
    }
}
