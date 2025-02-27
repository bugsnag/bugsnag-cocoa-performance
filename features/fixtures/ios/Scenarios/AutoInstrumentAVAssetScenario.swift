//
//  AutoInstrumentAVAssetScenario.swift
//  Fixture
//
//  Created by Karl Stenerud on 06.06.24.
//

import Foundation
import AVFoundation

@objcMembers
class AutoInstrumentAVAssetScenario: Scenario, AVAssetDownloadDelegate {

    override func setInitialBugsnagConfiguration() {
        super.setInitialBugsnagConfiguration()
        bugsnagPerfConfig.autoInstrumentNetworkRequests = true
    }

    func query(string: String) {
        let url = URL(string: string, relativeTo: fixtureConfig.reflectURL)!
        let currentFileName = "the-file"
        let configuration = URLSessionConfiguration.background(withIdentifier: currentFileName)

        let downloadSession = AVAssetDownloadURLSession(configuration: configuration,
                                                        assetDownloadDelegate: self,
                                  delegateQueue: OperationQueue.main)
        let asset = AVURLAsset(url: url)
        let downloadTask = downloadSession.makeAssetDownloadTask(asset: asset,
                                                                 assetTitle: currentFileName,
                                                                 assetArtworkData: nil,
                                                                 options: nil)
        downloadTask!.resume()
    }

    override func run() {
        // Force the automatic spans to be sent in a separate trace that we will discard
        waitForCurrentBatch()
        let span = BugsnagPerformance.startSpan(name: "parentSpan")
        span.end();
        query(string: "?status=200")
    }
}
