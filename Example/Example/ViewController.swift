//
//  ViewController.swift
//  Example
//
//  Created by Nick Dowell on 21/09/2022.
//

import UIKit
import SwiftUI
import BugsnagPerformance

// Global reference to store the active session span for testing
var globalSessionSpan: BugsnagPerformanceSpan?

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        installDiskIOPSOperationsButton()
    }

    @IBAction func showGenericView(_ sender: Any) {
        let vc = GenericViewController<Int>()
        show(vc, sender:sender)
    }

    @IBAction func showSwiftUIView(_ sender: Any) {
        if #available(iOS 13.0.0, *) {
            show(UIHostingController(rootView: SomeView<Int>().bugsnagTraced()), sender: sender)
        } else {
            present(UIAlertController(
                title: "Error",
                message: "SwiftUI is not available on this version of iOS",
                preferredStyle: .alert), animated: true)
        }
    }

    @IBAction func DoNetworkRequest(_ sender: Any) {
        let url = URL(string: "https://bugsnag.com")!
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
        }
        task.resume()
    }

    @IBAction func DoManualSpan(_ sender: Any) {
        let span = BugsnagPerformance.startSpan(name: "my span")
        // Wait between 100ms and 1s
        let waitTime = arc4random() % 900000
        usleep(100000 + waitTime)
        span.end()
    }

    @IBAction func DoSessionSpan(_ sender: Any) {
        globalSessionSpan = BugsnagPerformance.startAppSessionSpan("my session span")
        // Navigate to Session Span Test Flow
        let endVC = SessionEndViewController()
        navigationController?.pushViewController(endVC, animated: true)
    }

    // MARK: - Disk IOPS Operation (TEMP: showcase code)

    private func installDiskIOPSOperationsButton() {
        // Match the visual style of the storyboard buttons ("Manual Span",
        // "Session Span", etc.): plain blue text, no background, centered.
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Disk IOPS", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17)
        button.addTarget(self, action: #selector(openDiskIOPSOperations), for: .touchUpInside)
        view.addSubview(button)

        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            // Position just above the bottom safe-area, matching the vertical
            // rhythm of the storyboard's button column.
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
        ])
    }

    @objc private func openDiskIOPSOperations() {
        let vc = DiskIOPSViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    // --- END ---
}

// =============================================================================
// MARK: - Disk IOPS Live Operation VC (TEMP: showcase code)
// =============================================================================

/// Standalone screen that continuously fires first-class spans while running
/// disk work, then shows the read / write / total IOPS values live and plots
/// a rolling chart of read (blue) vs write (orange) ops/sec.
///
/// Values shown on this screen are computed **in the app** by calling
/// `proc_pid_rusage` directly. This is identical to what the SDK does
/// internally, so the numbers you see match the SDK's captured span
/// attributes (visible in the console with the "[DiskIO] Step 4/onSpanEnd"
/// log line).
final class DiskIOPSViewController: UIViewController {

    private let readLabel   = UILabel()
    private let writeLabel  = UILabel()
    private let totalLabel  = UILabel()
    private let statusLabel = UILabel()
    private let chartView   = DiskIOPSChartView()
    private let startStopButton = UIButton(type: .system)

    // Snapshot data (matches the SDK's [DiskIO] Step 1 & Step 2 logs).
    private let snapshotHeaderLabel = UILabel()
    private let snapshotStartLabel  = UILabel()
    private let snapshotEndLabel    = UILabel()
    private let snapshotDeltaLabel  = UILabel()

    // Latest span lifecycle indicator (spanId, start ts, end ts, current phase).
    private let spanHeaderLabel = UILabel()
    private let spanIdLabel     = UILabel()
    private let spanStartLabel  = UILabel()
    private let spanEndLabel    = UILabel()
    private let spanPhaseLabel  = UILabel()
    private let spanPhaseDot    = UIView()

    // Span-type selector — lets each tick create a different span kind so the
    // Operations can showcase disk IOPS across custom, session, and non-first-class
    // spans (the last one is expected to omit disk metrics via tri-state gating).
    private enum SpanKind: Int, CaseIterable {
        case customFirstClass = 0
        case appSession       = 1
        case customNonFirstClass = 2
        var title: String {
            switch self {
            case .customFirstClass:     return "Custom"
            case .appSession:           return "Session"
            case .customNonFirstClass:  return "Non-1st"
            }
        }
        var explanation: String {
            switch self {
            case .customFirstClass:
                return "Custom first-class span. Disk metrics ATTACHED."
            case .appSession:
                return "AppSessionSpan (long-running session). Disk metrics ATTACHED."
            case .customNonFirstClass:
                return "Custom NON-first-class span. Disk metrics OMITTED " +
                       "by tri-state gating (this proves the SDK filter works)."
            }
        }
    }
    private let spanKindControl = UISegmentedControl(
        items: SpanKind.allCases.map(\.title))
    private var selectedKind: SpanKind = .customFirstClass

    // Span-duration selector — lets the user run either the "loop" mode (a new
    // span every second) or a single long-running span so the Operations can showcase
    // how disk IOPS is averaged across arbitrarily long time windows.
    private enum SpanDuration: Int, CaseIterable {
        case loop = 0
        case thirtySeconds = 1
        case oneMinute = 2
        case fiveMinutes = 3
        case twentyMinutes = 4
        case fortyMinutes = 5

        /// Longer label used inside the dropdown menu.
        var displayLabel: String {
            switch self {
            case .loop:             return "Loop (1s cycle)"
            case .thirtySeconds:    return "30 seconds"
            case .oneMinute:        return "1 minute"
            case .fiveMinutes:      return "5 minutes"
            case .twentyMinutes:    return "20 minutes"
            case .fortyMinutes:     return "40 minutes"
            }
        }

        /// Total wall-clock seconds the span should stay open. `nil` means
        /// use the legacy loop mode (open+close a span every second).
        var seconds: TimeInterval? {
            switch self {
            case .loop:             return nil
            case .thirtySeconds:    return 30
            case .oneMinute:        return 60
            case .fiveMinutes:      return 300
            case .twentyMinutes:    return 1200
            case .fortyMinutes:     return 2400
            }
        }

        /// Educational text describing what to expect in the numbers panel.
        /// Long spans do sustained per-second I/O so live IOPS is visible.
        var explanation: String {
            switch self {
            case .loop:             return "Rolling 1s spans — steady-state IOPS."
            case .thirtySeconds:    return "Single 30s span. Sustained I/O every second → live IOPS."
            case .oneMinute:        return "Single 1m span. Sustained I/O every second → live IOPS."
            case .fiveMinutes:      return "Single 5m span. Sustained I/O every second → live IOPS."
            case .twentyMinutes:    return "Single 20m span. Sustained I/O every second → live IOPS."
            case .fortyMinutes:     return "Single 40m span. Sustained I/O every second → live IOPS."
            }
        }
    }
    private let spanDurationButton = UIButton(type: .system)
    private var selectedDuration: SpanDuration = .loop

    private var timer: Timer?
    private var running = false
    private var sampleCount = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Disk IOPS Live Operations"
        view.backgroundColor = .systemBackground
        buildUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stop()
    }

    // MARK: UI

    private func buildUI() {
        let readTitle  = makeTitle("Read ops/sec",  color: .systemBlue)
        let writeTitle = makeTitle("Write ops/sec", color: .systemOrange)
        let totalTitle = makeTitle("Total ops/sec", color: .label)

        [readLabel, writeLabel, totalLabel].forEach {
            $0.font = .monospacedDigitSystemFont(ofSize: 36, weight: .semibold)
            $0.textAlignment = .center
            $0.text = "—"
        }
        readLabel.textColor  = .systemBlue
        writeLabel.textColor = .systemOrange
        totalLabel.textColor = .label

        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.text = "Tap Start to begin sampling every 1 second. " +
                           "Each sample opens+closes a first-class span, so the SDK " +
                           "captures the same values (see console '[DiskIO]' logs)."

        startStopButton.setTitle("▶ Start", for: .normal)
        startStopButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        startStopButton.setTitleColor(.white, for: .normal)
        startStopButton.backgroundColor = .systemGreen
        startStopButton.layer.cornerRadius = 10
        startStopButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        startStopButton.addTarget(self, action: #selector(toggle), for: .touchUpInside)

        let readCol  = makeColumn(title: readTitle,  value: readLabel)
        let writeCol = makeColumn(title: writeTitle, value: writeLabel)
        let totalCol = makeColumn(title: totalTitle, value: totalLabel)

        let numbersRow = UIStackView(arrangedSubviews: [readCol, writeCol, totalCol])
        numbersRow.axis = .horizontal
        numbersRow.distribution = .fillEqually
        numbersRow.spacing = 8
        numbersRow.translatesAutoresizingMaskIntoConstraints = false

        // Snapshot data card: exactly what the SDK captures at span start/end.
        snapshotHeaderLabel.text = "Snapshot data (matches SDK's Step 1 & Step 2)"
        snapshotHeaderLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        snapshotHeaderLabel.textColor = .secondaryLabel
        snapshotHeaderLabel.textAlignment = .center

        [snapshotStartLabel, snapshotEndLabel, snapshotDeltaLabel].forEach {
            $0.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
            $0.textColor = .label
            $0.numberOfLines = 2
            $0.lineBreakMode = .byWordWrapping
            $0.adjustsFontSizeToFitWidth = true
            $0.minimumScaleFactor = 0.75
        }
        snapshotStartLabel.text = "start: —"
        snapshotEndLabel.text   = "end:   —"
        snapshotDeltaLabel.text = "delta: —"

        let snapshotStack = UIStackView(arrangedSubviews: [
            snapshotHeaderLabel, snapshotStartLabel, snapshotEndLabel, snapshotDeltaLabel,
        ])
        snapshotStack.axis = .vertical
        snapshotStack.spacing = 2
        snapshotStack.alignment = .fill
        snapshotStack.translatesAutoresizingMaskIntoConstraints = false
        snapshotStack.isLayoutMarginsRelativeArrangement = true
        snapshotStack.layoutMargins = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        snapshotStack.backgroundColor = .secondarySystemBackground
        snapshotStack.layer.cornerRadius = 8
        snapshotStack.layer.borderWidth = 1
        snapshotStack.layer.borderColor = UIColor.systemGray4.cgColor

        // Latest-span lifecycle card.
        spanHeaderLabel.text = "Latest span (SDK boundaries)"
        spanHeaderLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        spanHeaderLabel.textColor = .secondaryLabel
        spanHeaderLabel.textAlignment = .center

        [spanIdLabel, spanStartLabel, spanEndLabel].forEach {
            $0.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
            $0.textColor = .label
            $0.numberOfLines = 1
        }
        spanIdLabel.text    = "id:      —"
        spanStartLabel.text = "started: —"
        spanEndLabel.text   = "ended:   —"

        spanPhaseDot.translatesAutoresizingMaskIntoConstraints = false
        spanPhaseDot.backgroundColor = .systemGray3
        spanPhaseDot.layer.cornerRadius = 6
        NSLayoutConstraint.activate([
            spanPhaseDot.widthAnchor.constraint(equalToConstant: 12),
            spanPhaseDot.heightAnchor.constraint(equalToConstant: 12),
        ])

        spanPhaseLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        spanPhaseLabel.textColor = .label
        spanPhaseLabel.text = "phase: idle"

        let phaseRow = UIStackView(arrangedSubviews: [spanPhaseDot, spanPhaseLabel])
        phaseRow.axis = .horizontal
        phaseRow.spacing = 8
        phaseRow.alignment = .center

        let spanStack = UIStackView(arrangedSubviews: [
            spanHeaderLabel, spanIdLabel, spanStartLabel, spanEndLabel, phaseRow,
        ])
        spanStack.axis = .vertical
        spanStack.spacing = 2
        spanStack.alignment = .fill
        spanStack.translatesAutoresizingMaskIntoConstraints = false
        spanStack.isLayoutMarginsRelativeArrangement = true
        spanStack.layoutMargins = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        spanStack.backgroundColor = .secondarySystemBackground
        spanStack.layer.cornerRadius = 8
        spanStack.layer.borderWidth = 1
        spanStack.layer.borderColor = UIColor.systemGray4.cgColor

        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.layer.borderWidth = 1
        chartView.layer.borderColor = UIColor.systemGray4.cgColor
        chartView.layer.cornerRadius = 8

        startStopButton.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        let legend = UILabel()
        legend.translatesAutoresizingMaskIntoConstraints = false
        legend.font = .systemFont(ofSize: 12, weight: .medium)
        legend.textAlignment = .center
        legend.attributedText = Self.legendText()

        // Configure the span-kind segmented control.
        spanKindControl.selectedSegmentIndex = 0
        spanKindControl.translatesAutoresizingMaskIntoConstraints = false
        spanKindControl.addTarget(self, action: #selector(spanKindChanged),
                                  for: .valueChanged)

        // Configure the span-duration dropdown button (UIMenu on iOS 14+,
        // action sheet fallback on iOS 13). Picking an item selects the
        // span-duration for the next Start; disk I/O runs continuously for
        // the chosen duration and Read/Write ops update live.
        spanDurationButton.translatesAutoresizingMaskIntoConstraints = false
        spanDurationButton.setTitleColor(.label, for: .normal)
        spanDurationButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        spanDurationButton.backgroundColor = .secondarySystemBackground
        spanDurationButton.layer.cornerRadius = 6
        spanDurationButton.layer.borderWidth = 1
        spanDurationButton.layer.borderColor = UIColor.systemGray4.cgColor
        spanDurationButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        updateSpanDurationButtonTitle()
        if #available(iOS 14.0, *) {
            spanDurationButton.showsMenuAsPrimaryAction = true
            spanDurationButton.menu = buildSpanDurationMenu()
        } else {
            spanDurationButton.addTarget(self,
                                         action: #selector(showSpanDurationActionSheet),
                                         for: .touchUpInside)
        }

        view.addSubview(spanKindControl)
        view.addSubview(spanDurationButton)
        view.addSubview(numbersRow)
        view.addSubview(snapshotStack)
        view.addSubview(spanStack)
        view.addSubview(chartView)
        view.addSubview(legend)
        view.addSubview(startStopButton)
        view.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            spanKindControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            spanKindControl.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            spanKindControl.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),

            spanDurationButton.topAnchor.constraint(equalTo: spanKindControl.bottomAnchor, constant: 6),
            spanDurationButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            spanDurationButton.heightAnchor.constraint(equalToConstant: 34),

            numbersRow.topAnchor.constraint(equalTo: spanDurationButton.bottomAnchor, constant: 8),
            numbersRow.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            numbersRow.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),

            snapshotStack.topAnchor.constraint(equalTo: numbersRow.bottomAnchor, constant: 8),
            snapshotStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            snapshotStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),

            spanStack.topAnchor.constraint(equalTo: snapshotStack.bottomAnchor, constant: 8),
            spanStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            spanStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),

            chartView.topAnchor.constraint(equalTo: spanStack.bottomAnchor, constant: 8),
            chartView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            chartView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            chartView.heightAnchor.constraint(equalToConstant: 130),

            legend.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 4),
            legend.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            startStopButton.topAnchor.constraint(equalTo: legend.bottomAnchor, constant: 8),
            startStopButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            statusLabel.topAnchor.constraint(equalTo: startStopButton.bottomAnchor, constant: 6),
            statusLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
        ])
    }

    /// Update the "Latest span" card to reflect the current phase. Must be
    /// called from the main thread.
    private func setSpanPhase(_ phase: String, color: UIColor) {
        spanPhaseLabel.text = "phase: \(phase)"
        spanPhaseDot.backgroundColor = color
    }

    private static let clockFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    private static func clock(_ absTime: CFAbsoluteTime) -> String {
        let date = Date(timeIntervalSinceReferenceDate: absTime)
        return clockFormatter.string(from: date)
    }

    /// Compact byte formatter — 4194304 -> "4.00 MB", 262144 -> "256 KB",
    /// 8192 -> "8192 B". Keeps the delta card readable even for GB-sized values.
    private static func humanBytes(_ value: UInt64) -> String {
        if value >= 1024 * 1024 {
            return String(format: "%.2f MB", Double(value) / (1024.0 * 1024.0))
        }
        if value >= 1024 {
            return String(format: "%.0f KB", Double(value) / 1024.0)
        }
        return "\(value) B"
    }

    private static func legendText() -> NSAttributedString {
        let out = NSMutableAttributedString()
        out.append(NSAttributedString(string: "■ ", attributes: [.foregroundColor: UIColor.systemBlue]))
        out.append(NSAttributedString(string: "read   "))
        out.append(NSAttributedString(string: "■ ", attributes: [.foregroundColor: UIColor.systemOrange]))
        out.append(NSAttributedString(string: "write"))
        return out
    }

    private func makeTitle(_ text: String, color: UIColor) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = color
        l.textAlignment = .center
        return l
    }

    private func makeColumn(title: UILabel, value: UILabel) -> UIView {
        let stack = UIStackView(arrangedSubviews: [title, value])
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .fill
        return stack
    }

    // MARK: Sampling

    @objc private func toggle() {
        running ? stop() : start()
    }

    @objc private func spanKindChanged() {
        selectedKind = SpanKind(rawValue: spanKindControl.selectedSegmentIndex) ?? .customFirstClass
        statusLabel.text = selectedKind.explanation
    }

    // MARK: Span-duration dropdown helpers

    private func updateSpanDurationButtonTitle() {
        spanDurationButton.setTitle("Span duration: \(selectedDuration.displayLabel)  ▾",
                                    for: .normal)
    }

    private func selectSpanDuration(_ d: SpanDuration) {
        selectedDuration = d
        updateSpanDurationButtonTitle()
        statusLabel.text = d.explanation
        if #available(iOS 14.0, *) {
            // Rebuild so the .on checkmark tracks the new selection.
            spanDurationButton.menu = buildSpanDurationMenu()
        }
    }

    @available(iOS 14.0, *)
    private func buildSpanDurationMenu() -> UIMenu {
        let actions = SpanDuration.allCases.map { d -> UIAction in
            UIAction(title: d.displayLabel,
                     state: (d == selectedDuration ? .on : .off)) { [weak self] _ in
                self?.selectSpanDuration(d)
            }
        }
        return UIMenu(title: "Span duration", children: actions)
    }

    @objc private func showSpanDurationActionSheet() {
        let sheet = UIAlertController(title: "Span duration",
                                       message: nil,
                                       preferredStyle: .actionSheet)
        SpanDuration.allCases.forEach { d in
            sheet.addAction(UIAlertAction(title: d.displayLabel, style: .default) { [weak self] _ in
                self?.selectSpanDuration(d)
            })
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        // iPad requires a popover source when presenting an action sheet.
        sheet.popoverPresentationController?.sourceView = spanDurationButton
        sheet.popoverPresentationController?.sourceRect = spanDurationButton.bounds
        present(sheet, animated: true)
    }

    private func start() {
        // Defensive: any leftover loop-mode timer must be killed before a
        // long-span run, otherwise its per-second tick() would keep firing
        // and overwriting the "started:" label — making it look like the
        // long span keeps re-opening.
        timer?.invalidate()
        timer = nil

        running = true
        startStopButton.setTitle("■ Stop", for: .normal)
        startStopButton.backgroundColor = .systemRed
        sampleCount = 0
        chartView.reset()

        if let longDuration = selectedDuration.seconds {
            statusLabel.text = "Running one \(selectedDuration.displayLabel) span. " +
                "Tap Stop to abort. See console '[DiskIO] Step 4' log at end."
            runLongSpan(duration: longDuration)
        } else {
            statusLabel.text = "Sampling every 1 second. Each tick fires a first-class span."
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.tick()
            }
        }
    }

    private func stop() {
        running = false
        timer?.invalidate()
        timer = nil
        startStopButton.setTitle("▶ Start", for: .normal)
        startStopButton.backgroundColor = .systemGreen
        statusLabel.text = "Stopped. Tap Start to sample again."
        setSpanPhase("idle", color: .systemGray3)
    }

    private func tick() {
        // Run everything on a background queue so the ~1s settle sleep
        // doesn't freeze the UI. Marshal results back to main for display.
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // Capture the START snapshot BEFORE opening the span so the
            // on-screen snapshot exactly matches the SDK's
            // "[DiskIO] Step 1/onSpanStart" log for this same tick.
            guard let startSnap = DiskIOSample.capture() else { return }

            // Read the currently-selected span kind on the main thread so we
            // don't touch a UIKit view from a background queue.
            var kindLocal: SpanKind = .customFirstClass
            DispatchQueue.main.sync { kindLocal = self.selectedKind }

            // Build the span based on the chosen kind.
            //   - customFirstClass:   first-class custom span (disk ATTACHED)
            //   - appSession:         long-running session span (disk ATTACHED)
            //   - customNonFirstClass: firstClass=.no + metrics.disk=.unset
            //                          (disk OMITTED via tri-state gating)
            let span: BugsnagPerformanceSpan
            let spanKindLabel: String
            switch kindLocal {
            case .customFirstClass:
                let opts = BugsnagPerformanceSpanOptions()
                opts.setFirstClass(.yes)
                opts.metricsOptions.disk = .yes
                span = BugsnagPerformance.startSpan(name: "DiskIOPSLiveTick.Custom",
                                                    options: opts)
                spanKindLabel = "Custom (1st-class)"
            case .appSession:
                span = BugsnagPerformance.startAppSessionSpan("DiskIOPSLive")
                spanKindLabel = "AppSession"
            case .customNonFirstClass:
                let opts = BugsnagPerformanceSpanOptions()
                opts.setFirstClass(.no)
                // Leaving metrics.disk = .unset so the tri-state gate falls
                // back to the firstClass check and blocks disk metrics.
                span = BugsnagPerformance.startSpan(name: "DiskIOPSLiveTick.NonFirstClass",
                                                    options: opts)
                spanKindLabel = "Custom (non-1st)"
            }

            // span.spanId is UInt64; convert to Int64 via bitPattern (no trap for high-bit values),
            // then let %llx render the 16-hex-digit form. Guards against Swift crashing on IDs > 2^63.
            let spanIdHex = String(format: "%016llx",
                                   Int64(bitPattern: UInt64(span.spanId)))
            let startWallClock = Self.clock(startSnap.timestamp)

            // Update the "Latest span" card — span has just opened.
            DispatchQueue.main.async {
                self.spanIdLabel.text    = "id:      \(spanIdHex)  [\(spanKindLabel)]"
                self.spanStartLabel.text = "started: \(startWallClock)"
                self.spanEndLabel.text   = "ended:   —"
                self.setSpanPhase("opened  (\(spanKindLabel))", color: .systemGreen)
            }

            // 4–16 MB of random bytes, chunked write with F_FULLFSYNC.
            let bytes = Int.random(in: 4...16) * 1024 * 1024
            var payload = Data(count: bytes)
            payload.withUnsafeMutableBytes { raw in
                if let base = raw.baseAddress { arc4random_buf(base, bytes) }
            }
            let path = FileManager.default.temporaryDirectory
                .appendingPathComponent("bsg-diskio-live-\(UUID().uuidString).bin")
            DispatchQueue.main.async {
                self.setSpanPhase("writing \(bytes / (1024 * 1024)) MB", color: .systemOrange)
            }

            path.withUnsafeFileSystemRepresentation { cpath in
                guard let cpath = cpath else { return }
                let fd = open(cpath, O_WRONLY | O_CREAT | O_TRUNC, 0o644)
                if fd < 0 { return }
                payload.withUnsafeBytes { raw in
                    guard let base = raw.baseAddress else { return }
                    var offset = 0
                    let total = payload.count
                    while offset < total {
                        let chunk = min(1 << 20, total - offset)
                        let written = write(fd, base.advanced(by: offset), chunk)
                        if written <= 0 { break }
                        offset += written
                    }
                }
                _ = fcntl(fd, F_FULLFSYNC)
                close(fd)
            }
            _ = try? Data(contentsOf: path)
            try? FileManager.default.removeItem(at: path)

            // Settle window so the kernel has time to attribute pending writes
            // to this process. On the simulator, ri_diskio_byteswritten updates
            // asynchronously even after F_FULLFSYNC returns.
            DispatchQueue.main.async {
                self.setSpanPhase("settling (kernel catch-up)", color: .systemYellow)
            }
            Thread.sleep(forTimeInterval: 0.9)

            guard let endSnap = DiskIOSample.capture() else {
                DispatchQueue.main.async {
                    span.end()
                    self.setSpanPhase("ended (endSnap invalid)", color: .systemRed)
                }
                return
            }
            let endWallClock = Self.clock(endSnap.timestamp)
            DispatchQueue.main.async {
                span.end()
                self.spanEndLabel.text = "ended:   \(endWallClock)"
                self.setSpanPhase("ended  (SDK Step 2 → 3 → 4 fired)", color: .systemRed)
            }

            let duration = endSnap.timestamp - startSnap.timestamp
            guard duration > 0 else { return }

            let readDelta  = endSnap.bytesRead  >= startSnap.bytesRead
                ? endSnap.bytesRead  - startSnap.bytesRead  : 0
            let writeDelta = endSnap.bytesWritten >= startSnap.bytesWritten
                ? endSnap.bytesWritten - startSnap.bytesWritten : 0

            let readOps  = Int64((Double(readDelta)  / 16384.0 / duration).rounded())
            let writeOps = Int64((Double(writeDelta) / 16384.0 / duration).rounded())
            let totalOps = readOps + writeOps

            NSLog("[DiskIO Live] tick=\(self.sampleCount + 1) " +
                  "start(R=\(startSnap.bytesRead) W=\(startSnap.bytesWritten)) " +
                  "end(R=\(endSnap.bytesRead) W=\(endSnap.bytesWritten)) " +
                  "Δt=\(String(format: "%.4f", duration))s " +
                  "read=\(readOps) write=\(writeOps) total=\(totalOps)")

            DispatchQueue.main.async {
                self.sampleCount += 1
                self.readLabel.text  = "\(readOps)"
                self.writeLabel.text = "\(writeOps)"
                self.totalLabel.text = "\(totalOps)"

                let startTs = String(format: "%.4f", startSnap.timestamp)
                let endTs   = String(format: "%.4f", endSnap.timestamp)
                let dt      = String(format: "%.4f", duration)
                self.snapshotStartLabel.text =
                    "start:  R=\(Self.humanBytes(startSnap.bytesRead))  " +
                    "W=\(Self.humanBytes(startSnap.bytesWritten))  t=\(startTs)"
                self.snapshotEndLabel.text =
                    "end:    R=\(Self.humanBytes(endSnap.bytesRead))  " +
                    "W=\(Self.humanBytes(endSnap.bytesWritten))  t=\(endTs)"
                self.snapshotDeltaLabel.text =
                    "delta:  ΔR=\(Self.humanBytes(readDelta))  " +
                    "ΔW=\(Self.humanBytes(writeDelta))  Δt=\(dt)s"

                self.chartView.appendSample(read: readOps, write: writeOps)
            }
        }
    }

    // MARK: Long-span mode
    //
    // Opens a single span, performs one 8 MB write near the start, then
    // waits for the selected duration before closing. This showcases how
    // IOPS is averaged across arbitrarily large time windows — the same
    // byte-delta divided by a larger `duration` yields smaller ops/sec,
    // and at long enough durations both counters round to 0 because the
    // metrics helper divides bytes by an assumed 16 KB block size.
    //
    // Values shown on-screen are computed locally via `proc_pid_rusage`.
    // They should match the SDK's own computation, visible at span end
    // in the console log line prefixed "[DiskIO] Step 4/onSpanEnd".
    private func runLongSpan(duration: TimeInterval) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            guard let startSnap = DiskIOSample.capture() else {
                DispatchQueue.main.async {
                    self.statusLabel.text = "Failed to capture starting snapshot."
                    self.stop()
                }
                return
            }

            var kindLocal: SpanKind = .customFirstClass
            DispatchQueue.main.sync { kindLocal = self.selectedKind }

            let span: BugsnagPerformanceSpan
            let spanKindLabel: String
            let nameSuffix = "\(Int(duration))s"
            switch kindLocal {
            case .customFirstClass:
                let opts = BugsnagPerformanceSpanOptions()
                opts.setFirstClass(.yes)
                opts.metricsOptions.disk = .yes
                span = BugsnagPerformance.startSpan(name: "DiskIOPSLong.\(nameSuffix).Custom",
                                                    options: opts)
                spanKindLabel = "Custom (1st-class)"
            case .appSession:
                span = BugsnagPerformance.startAppSessionSpan("DiskIOPSLong.\(nameSuffix)")
                spanKindLabel = "AppSession"
            case .customNonFirstClass:
                let opts = BugsnagPerformanceSpanOptions()
                opts.setFirstClass(.no)
                span = BugsnagPerformance.startSpan(name: "DiskIOPSLong.\(nameSuffix).NonFirstClass",
                                                    options: opts)
                spanKindLabel = "Custom (non-1st)"
            }

            let spanIdHex = String(format: "%016llx",
                                   Int64(bitPattern: UInt64(span.spanId)))
            let startWallClock = Self.clock(startSnap.timestamp)
            // Show the predicted end time upfront so the user can visually
            // confirm the "started → ends" gap equals the chosen duration
            // (e.g. 30s) without waiting for the span to close. The label
            // is renamed to "ended:" once the actual end fires below.
            let predictedEndWallClock = Self.clock(startSnap.timestamp + duration)

            DispatchQueue.main.async {
                self.spanIdLabel.text    = "id:      \(spanIdHex)  [\(spanKindLabel)]"
                self.spanStartLabel.text = "started: \(startWallClock)"
                self.spanEndLabel.text   = "ends:    \(predictedEndWallClock)  (in \(Int(duration))s)"
                self.setSpanPhase("SPAN OPEN — \(Int(duration))s to go",
                                  color: .systemGreen)
            }

            // Live-workload loop.
            //
            // Per tick (~1s):
            //  1. Perform one write+read+delete cycle. The byte-count
            //     ROTATES through workloadCycle so the live values
            //     visibly oscillate — a fixed size would show a flat
            //     steady-state value which is indistinguishable from a
            //     stalled UI.
            //  2. Take a fresh snapshot and compute the "1s rolling
            //     window" IOPS for the Read/Write/Total labels + chart.
            //  3. Update the cumulative ΔR/ΔW/Δt card so the user can
            //     watch the SDK's end-of-span numbers accumulate.
            //
            // Expected live values (read side, on any device):
            //   128KB → 8  ops/s   |   512KB → 32 ops/s
            //   1MB   → 64 ops/s   |   2MB   → 128 ops/s
            //
            // On the SIMULATOR the write counter (ri_diskio_byteswritten)
            // under-reports by ~99% because macOS's disk-buffer-cache
            // absorbs the write before it reaches the block layer that
            // proc_pid_rusage measures. F_NOCACHE (inside
            // performDiskWorkload) forces uncached I/O to try to bypass
            // that, but simulator behavior is still unreliable — on
            // real devices the write side tracks correctly.
            let workloadCycle: [Int] = [
                128 * 1024,   // → read=8   ops/s (min)
                512 * 1024,   // → read=32  ops/s
                1024 * 1024,  // → read=64  ops/s (max)
                512 * 1024,   // → read=32  ops/s (returning)
            ]
            let tickInterval: TimeInterval = 1.0
            let baseT = startSnap.timestamp
            var lastSampleSnap = startSnap
            var iteration = 0

            while self.running {
                let elapsed = CFAbsoluteTimeGetCurrent() - baseT
                if elapsed >= duration { break }

                let sustainedBytes = workloadCycle[iteration % workloadCycle.count]
                self.performDiskWorkload(bytes: sustainedBytes)

                guard let now = DiskIOSample.capture() else {
                    iteration += 1
                    Thread.sleep(forTimeInterval: tickInterval)
                    continue
                }

                // 1s rolling window (what the numbers panel + chart show).
                let windowDur = max(0.001, now.timestamp - lastSampleSnap.timestamp)
                let rd1s = now.bytesRead >= lastSampleSnap.bytesRead
                    ? now.bytesRead - lastSampleSnap.bytesRead : 0
                let wd1s = now.bytesWritten >= lastSampleSnap.bytesWritten
                    ? now.bytesWritten - lastSampleSnap.bytesWritten : 0
                let readOps1s  = Int64((Double(rd1s) / DiskIOSample.blockSizeBytes / windowDur).rounded())
                let writeOps1s = Int64((Double(wd1s) / DiskIOSample.blockSizeBytes / windowDur).rounded())
                let totalOps1s = readOps1s + writeOps1s

                // Cumulative delta from span start (matches SDK Step 4).
                let rdCum = now.bytesRead >= startSnap.bytesRead
                    ? now.bytesRead - startSnap.bytesRead : 0
                let wdCum = now.bytesWritten >= startSnap.bytesWritten
                    ? now.bytesWritten - startSnap.bytesWritten : 0

                lastSampleSnap = now
                let remaining = max(0, Int((duration - elapsed).rounded()))
                // First sample's window is unusually short (windowDur ≈
                // performDiskWorkload duration ≈ 50-100ms) because we
                // compare against startSnap, which was taken BEFORE the
                // workload. That inflates the first ops/s value by 10x+
                // and, once charted, ruins the Y-axis auto-scale so
                // subsequent bars look like a flat zero baseline. Skip
                // it from the chart only; labels still update.
                let isFirstSample = iteration == 0
                let tickLabel = iteration + 1

                DispatchQueue.main.async {
                    self.readLabel.text  = "\(readOps1s)"
                    self.writeLabel.text = "\(writeOps1s)"
                    self.totalLabel.text = "\(totalOps1s)"
                    self.setSpanPhase("SPAN OPEN — tick #\(tickLabel), \(remaining)s left",
                                      color: .systemBlue)
                    self.snapshotDeltaLabel.text =
                        "delta:  ΔR=\(Self.humanBytes(rdCum))  " +
                        "ΔW=\(Self.humanBytes(wdCum))  " +
                        "Δt=\(String(format: "%.1f", elapsed))s"
                    if !isFirstSample {
                        self.chartView.appendSample(read: readOps1s, write: writeOps1s)
                    }
                }

                iteration += 1
                Thread.sleep(forTimeInterval: tickInterval)
            }

            // Capture end snap, close span, publish results.
            guard let endSnap = DiskIOSample.capture() else {
                DispatchQueue.main.async {
                    span.end()
                    self.setSpanPhase("ended (endSnap invalid)", color: .systemRed)
                    self.stop()
                }
                return
            }

            let endWallClock = Self.clock(endSnap.timestamp)
            DispatchQueue.main.async {
                span.end()
                self.spanEndLabel.text = "ended:   \(endWallClock)"
                self.setSpanPhase("ended  (SDK Step 2 → 3 → 4 fired)",
                                  color: .systemRed)
            }

            let durationActual = endSnap.timestamp - startSnap.timestamp
            guard durationActual > 0 else {
                DispatchQueue.main.async { self.stop() }
                return
            }

            let readDelta  = endSnap.bytesRead  >= startSnap.bytesRead
                ? endSnap.bytesRead  - startSnap.bytesRead  : 0
            let writeDelta = endSnap.bytesWritten >= startSnap.bytesWritten
                ? endSnap.bytesWritten - startSnap.bytesWritten : 0

            let readOps  = Int64((Double(readDelta)  / DiskIOSample.blockSizeBytes / durationActual).rounded())
            let writeOps = Int64((Double(writeDelta) / DiskIOSample.blockSizeBytes / durationActual).rounded())
            let totalOps = readOps + writeOps

            NSLog("[DiskIO Live] long-span target=\(Int(duration))s " +
                  "actual=\(String(format: "%.4f", durationActual))s " +
                  "kind=\(spanKindLabel) " +
                  "start(R=\(startSnap.bytesRead) W=\(startSnap.bytesWritten)) " +
                  "end(R=\(endSnap.bytesRead) W=\(endSnap.bytesWritten)) " +
                  "ΔR=\(readDelta) ΔW=\(writeDelta) " +
                  "read=\(readOps) write=\(writeOps) total=\(totalOps)")

            DispatchQueue.main.async {
                self.sampleCount = 1
                self.readLabel.text  = "\(readOps)"
                self.writeLabel.text = "\(writeOps)"
                self.totalLabel.text = "\(totalOps)"

                let startTs = String(format: "%.4f", startSnap.timestamp)
                let endTs   = String(format: "%.4f", endSnap.timestamp)
                let dt      = String(format: "%.4f", durationActual)
                self.snapshotStartLabel.text =
                    "start:  R=\(Self.humanBytes(startSnap.bytesRead))  " +
                    "W=\(Self.humanBytes(startSnap.bytesWritten))  t=\(startTs)"
                self.snapshotEndLabel.text =
                    "end:    R=\(Self.humanBytes(endSnap.bytesRead))  " +
                    "W=\(Self.humanBytes(endSnap.bytesWritten))  t=\(endTs)"
                self.snapshotDeltaLabel.text =
                    "delta:  ΔR=\(Self.humanBytes(readDelta))  " +
                    "ΔW=\(Self.humanBytes(writeDelta))  Δt=\(dt)s"

                self.chartView.appendSample(read: readOps, write: writeOps)

                let aborted = durationActual < duration - 1.0
                self.statusLabel.text = aborted
                    ? "Aborted at \(dt)s. read=\(readOps) write=\(writeOps) " +
                      "total=\(totalOps). Compare with '[DiskIO] Step 4' in console."
                    : "Done (\(dt)s). read=\(readOps) write=\(writeOps) " +
                      "total=\(totalOps). '[DiskIO] Step 4' in console should match."
                self.stop()
            }
        }
    }

    /// Synchronous 1-file disk workload used by the long-span mode:
    /// write `bytes` random bytes uncached, F_FULLFSYNC, read them back
    /// uncached, delete. Called on a background queue; ~tens of ms.
    ///
    /// F_NOCACHE is the critical bit for the simulator — without it,
    /// macOS's disk buffer cache absorbs the write before it reaches
    /// the block layer that `proc_pid_rusage` reads, so
    /// ri_diskio_byteswritten under-reports by ~99% and the Operations shows
    /// write=0 forever. F_NOCACHE forces uncached direct I/O so the
    /// write is properly attributed to this process.
    private func performDiskWorkload(bytes: Int) {
        var payload = Data(count: bytes)
        payload.withUnsafeMutableBytes { raw in
            if let base = raw.baseAddress { arc4random_buf(base, bytes) }
        }
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("bsg-diskio-long-\(UUID().uuidString).bin")

        // Write path — uncached, then F_FULLFSYNC to guarantee it hits storage.
        path.withUnsafeFileSystemRepresentation { cpath in
            guard let cpath = cpath else { return }
            let fd = open(cpath, O_WRONLY | O_CREAT | O_TRUNC, 0o644)
            if fd < 0 { return }
            _ = fcntl(fd, F_NOCACHE, 1)
            payload.withUnsafeBytes { raw in
                guard let base = raw.baseAddress else { return }
                var offset = 0
                let total = payload.count
                while offset < total {
                    let chunk = min(1 << 20, total - offset)
                    let written = write(fd, base.advanced(by: offset), chunk)
                    if written <= 0 { break }
                    offset += written
                }
            }
            _ = fcntl(fd, F_FULLFSYNC)
            close(fd)
        }

        // Read-back — also uncached so ri_diskio_bytesread reflects a real
        // storage read, not a page-cache hit against the bytes we just wrote.
        path.withUnsafeFileSystemRepresentation { cpath in
            guard let cpath = cpath else { return }
            let fd = open(cpath, O_RDONLY, 0)
            if fd < 0 { return }
            _ = fcntl(fd, F_NOCACHE, 1)
            var buffer = [UInt8](repeating: 0, count: 1 << 20)
            buffer.withUnsafeMutableBufferPointer { bp in
                guard let base = bp.baseAddress else { return }
                var totalRead = 0
                while totalRead < bytes {
                    let want = min(bp.count, bytes - totalRead)
                    let n = read(fd, base, want)
                    if n <= 0 { break }
                    totalRead += n
                }
            }
            close(fd)
        }
        try? FileManager.default.removeItem(at: path)
    }
}

// =============================================================================
// MARK: - Rolling line chart for read + write
// =============================================================================

final class DiskIOPSChartView: UIView {

    private var readSamples:  [Int64] = []
    private var writeSamples: [Int64] = []
    private let maxSamples = 60

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .secondarySystemBackground
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .secondarySystemBackground
    }

    func reset() {
        readSamples.removeAll()
        writeSamples.removeAll()
        setNeedsDisplay()
    }

    func appendSample(read: Int64, write: Int64) {
        readSamples.append(read)
        writeSamples.append(write)
        if readSamples.count > maxSamples {
            readSamples.removeFirst(readSamples.count - maxSamples)
            writeSamples.removeFirst(writeSamples.count - maxSamples)
        }
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        // Background grid
        ctx.setStrokeColor(UIColor.systemGray4.cgColor)
        ctx.setLineWidth(0.5)
        let gridLines = 4
        for i in 0...gridLines {
            let y = rect.height * CGFloat(i) / CGFloat(gridLines)
            ctx.move(to: CGPoint(x: 0, y: y))
            ctx.addLine(to: CGPoint(x: rect.width, y: y))
        }
        ctx.strokePath()

        if readSamples.isEmpty && writeSamples.isEmpty {
            let p = NSMutableParagraphStyle(); p.alignment = .center
            let attrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.tertiaryLabel,
                .font: UIFont.systemFont(ofSize: 12),
                .paragraphStyle: p,
            ]
            let text: NSString = "no samples yet"
            let size = text.size(withAttributes: attrs)
            text.draw(in: CGRect(x: 0, y: rect.midY - size.height / 2, width: rect.width, height: size.height),
                      withAttributes: attrs)
            return
        }

        let maxValue = max(1, Int64((readSamples + writeSamples).max() ?? 1))
        drawLine(readSamples, in: rect, ctx: ctx, color: UIColor.systemBlue.cgColor, maxValue: maxValue)
        drawLine(writeSamples, in: rect, ctx: ctx, color: UIColor.systemOrange.cgColor, maxValue: maxValue)

        // Max-value label (top-right)
        let scaleText = "max ≈ \(maxValue)"
        (scaleText as NSString).draw(
            at: CGPoint(x: rect.width - 90, y: 4),
            withAttributes: [
                .foregroundColor: UIColor.secondaryLabel,
                .font: UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular),
            ])
    }

    private func drawLine(_ samples: [Int64], in rect: CGRect, ctx: CGContext,
                          color: CGColor, maxValue: Int64) {
        guard samples.count > 1 else { return }
        ctx.setStrokeColor(color)
        ctx.setLineWidth(2)
        ctx.setLineJoin(.round)
        let stepX = rect.width / CGFloat(max(1, maxSamples - 1))
        let padding: CGFloat = 8

        for (i, v) in samples.enumerated() {
            let x = CGFloat(i) * stepX
            let yFraction = 1.0 - CGFloat(v) / CGFloat(maxValue)
            let y = padding + yFraction * (rect.height - padding * 2)
            if i == 0 { ctx.move(to: CGPoint(x: x, y: y)) }
            else      { ctx.addLine(to: CGPoint(x: x, y: y)) }
        }
        ctx.strokePath()
    }
}

// =============================================================================
// MARK: - Local proc_pid_rusage helper (matches what the SDK does internally)
// =============================================================================

/// Forward-declaration for `proc_pid_rusage` — libproc.h isn't in the iOS
/// public SDK, but the symbol is available at runtime via libSystem.
@_silgen_name("proc_pid_rusage")
private func c_proc_pid_rusage(_ pid: Int32,
                               _ flavor: Int32,
                               _ buffer: UnsafeMutableRawPointer) -> Int32

struct DiskIOSample {
    let timestamp: CFAbsoluteTime
    let bytesRead: UInt64
    let bytesWritten: UInt64

    /// Reads the current process's disk byte counters. Returns nil if the
    /// platform read fails (e.g., locked down or unavailable).
    ///
    /// Offset math: `rusage_info_v4` starts with a 16-byte UUID (offset 0)
    /// followed by 17 `uint64_t` fields, then `ri_diskio_bytesread` (offset 152)
    /// and `ri_diskio_byteswritten` (offset 160). We allocate a comfortably
    /// large buffer to hold the whole struct without needing to declare it.
    static func capture() -> DiskIOSample? {
        let RUSAGE_INFO_V4: Int32 = 4
        let bufferSize = 512  // rusage_info_v4 is ~304 bytes; 512 is safe headroom
        let buffer = UnsafeMutableRawPointer.allocate(byteCount: bufferSize,
                                                       alignment: MemoryLayout<UInt64>.alignment)
        defer { buffer.deallocate() }
        buffer.initializeMemory(as: UInt8.self, repeating: 0, count: bufferSize)

        let rc = c_proc_pid_rusage(getpid(), RUSAGE_INFO_V4, buffer)
        guard rc == 0 else { return nil }

        let bytesRead    = buffer.load(fromByteOffset: 152, as: UInt64.self)
        let bytesWritten = buffer.load(fromByteOffset: 160, as: UInt64.self)
        return DiskIOSample(timestamp: CFAbsoluteTimeGetCurrent(),
                            bytesRead: bytesRead,
                            bytesWritten: bytesWritten)
    }
}
