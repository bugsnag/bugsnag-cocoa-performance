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

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fixture.start()
    }
}
