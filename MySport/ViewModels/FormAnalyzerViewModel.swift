import AVFoundation
import Vision
import Observation

// Pre-processed joint map: Vision y already flipped (0 = top, 1 = bottom).
// CGPoint is Sendable; dictionary is conditionally Sendable — safe to pass across actors.
typealias JointPoints = [VNHumanBodyPoseObservation.JointName: CGPoint]

// MARK: - ExerciseType

enum ExerciseType: String, CaseIterable, Identifiable {
    case squat         = "Присід"
    case pushup        = "Віджимання"
    case plank         = "Планка"
    case lunge         = "Випад"
    case shoulderPress = "Жим плечима"

    var id: Self { self }

    var localizedName: String {
        switch self {
        case .squat:         return t(.exerciseSquat)
        case .pushup:        return t(.exercisePushup)
        case .plank:         return t(.exercisePlank)
        case .lunge:         return t(.exerciseLunge)
        case .shoulderPress: return t(.exerciseShoulderPress)
        }
    }

    var systemImage: String {
        switch self {
        case .squat:         return "figure.squat"
        case .pushup:        return "figure.pushup"
        case .plank:         return "figure.core.training"
        case .lunge:         return "figure.step.training"
        case .shoulderPress: return "figure.arms.open"
        }
    }
}

// MARK: - DetectedJoint

struct DetectedJoint {
    /// Normalised position — origin top-left (Vision y already flipped).
    let position: CGPoint
    let confidence: Float
}

// MARK: - FormAnalyzerViewModel

@Observable
final class FormAnalyzerViewModel: NSObject {

    // MARK: - Observed state

    var selectedExercise: ExerciseType = .squat
    var repCount:         Int    = 0
    var feedbackText:     String = t(.standInFront)
    var elapsedSeconds:   Int    = 0
    var showPermissionAlert = false

    /// All detected joints — used by the skeleton canvas to draw.
    var joints: [VNHumanBodyPoseObservation.JointName: DetectedJoint] = [:]

    /// Native portrait dimensions of the Vision-processed image.
    /// Used by the canvas for accurate aspect-fill coordinate mapping.
    private(set) var videoSize: CGSize = CGSize(width: 720, height: 1280)

    // MARK: - Session (exposed so UIViewRepresentable can bind the preview layer)

    let captureSession = AVCaptureSession()

    // MARK: - Private

    private let videoOutput    = AVCaptureVideoDataOutput()
    private let processingQueue = DispatchQueue(label: "com.mysport.poseQueue", qos: .userInteractive)
    private var wasInDownPosition = false
    private var plankTimer: Timer?

    // MARK: - Lifecycle

    func start() {
        Task { [weak self] in await self?.requestPermission() }
    }

    func stop() {
        processingQueue.async { [weak self] in self?.captureSession.stopRunning() }
        stopPlankTimer()
    }

    // MARK: - Exercise selection

    func selectExercise(_ exercise: ExerciseType) {
        guard exercise != selectedExercise else { return }
        selectedExercise  = exercise
        repCount          = 0
        elapsedSeconds    = 0
        wasInDownPosition = false
        feedbackText      = t(.standInFront)
        stopPlankTimer()
    }

    // MARK: - Public counter display

    var counterDisplay: String {
        if selectedExercise == .plank {
            return String(format: "%d:%02d", elapsedSeconds / 60, elapsedSeconds % 60)
        }
        return "\(repCount) \(t(.reps))"
    }

    // MARK: - Angle calculation (exact formula from spec)

    private func angle(at joint: CGPoint, from pointA: CGPoint, to pointB: CGPoint) -> Double {
        let vectorA = CGVector(dx: pointA.x - joint.x, dy: pointA.y - joint.y)
        let vectorB = CGVector(dx: pointB.x - joint.x, dy: pointB.y - joint.y)
        let dot  = vectorA.dx * vectorB.dx + vectorA.dy * vectorB.dy
        let magA = sqrt(vectorA.dx * vectorA.dx + vectorA.dy * vectorA.dy)
        let magB = sqrt(vectorB.dx * vectorB.dx + vectorB.dy * vectorB.dy)
        guard magA > 0, magB > 0 else { return 0 }
        return acos(max(-1, min(1, dot / (magA * magB)))) * 180 / .pi
    }

    private func pt(_ name: VNHumanBodyPoseObservation.JointName,
                    in pts: JointPoints) -> CGPoint? { pts[name] }

    // MARK: - Exercise analyzers (all called on main thread)

    func processPose(_ pts: JointPoints) {
        switch selectedExercise {
        case .squat:         analyzeSquat(pts)
        case .pushup:        analyzePushup(pts)
        case .plank:         analyzePlank(pts)
        case .lunge:         analyzeLunge(pts)
        case .shoulderPress: analyzeShoulderPress(pts)
        }
    }

    func noPersonDetected() {
        feedbackText = t(.personNotFound)
        if selectedExercise == .plank { stopPlankTimer() }
    }

    // ── Squat ──────────────────────────────────────────────────────────────
    // Left knee angle: hip → knee → ankle
    // angle < 100° AND was > 140° → count rep
    private func analyzeSquat(_ pts: JointPoints) {
        guard let hip   = pt(.leftHip,   in: pts),
              let knee  = pt(.leftKnee,  in: pts),
              let ankle = pt(.leftAnkle, in: pts) else {
            feedbackText = t(.cantSeeLegs)
            return
        }
        let a = angle(at: knee, from: hip, to: ankle)
        if a < 100 {
            feedbackText = t(.deepSquat)
            wasInDownPosition = true
        } else if a <= 140 {
            feedbackText = t(.goDeeper)
        } else {
            feedbackText = t(.getReady)
            if wasInDownPosition {
                repCount += 1
                wasInDownPosition = false
            }
        }
    }

    // ── Push-up ────────────────────────────────────────────────────────────
    // Left elbow angle: shoulder → elbow → wrist
    // angle < 100° AND was > 150° → count rep
    private func analyzePushup(_ pts: JointPoints) {
        guard let shoulder = pt(.leftShoulder, in: pts),
              let elbow    = pt(.leftElbow,    in: pts),
              let wrist    = pt(.leftWrist,    in: pts) else {
            feedbackText = t(.cantSeeArms)
            return
        }
        let a = angle(at: elbow, from: shoulder, to: wrist)
        if a < 100 {
            feedbackText = t(.greatForm)
            wasInDownPosition = true
        } else if a <= 150 {
            feedbackText = t(.goLower)
        } else {
            feedbackText = t(.startPos)
            if wasInDownPosition {
                repCount += 1
                wasInDownPosition = false
            }
        }
    }

    // ── Plank ──────────────────────────────────────────────────────────────
    // Hip angle: shoulder → hip → ankle. No rep counting; shows elapsed timer.
    private func analyzePlank(_ pts: JointPoints) {
        guard let shoulder = pt(.leftShoulder, in: pts),
              let hip      = pt(.leftHip,      in: pts),
              let ankle    = pt(.leftAnkle,    in: pts) else {
            feedbackText = t(.cantSeeBody)
            stopPlankTimer()
            return
        }
        let a = angle(at: hip, from: shoulder, to: ankle)
        if a > 160 {
            feedbackText = t(.perfectPlank)
            startPlankTimerIfNeeded()
        } else if a >= 140 {
            feedbackText = t(.raiseHips)
            stopPlankTimer()
        } else {
            feedbackText = t(.hipsTooLow)
            stopPlankTimer()
        }
    }

    // ── Lunge ──────────────────────────────────────────────────────────────
    // Front (left) knee angle: hip → knee → ankle
    // angle < 100° AND was > 140° → count rep
    private func analyzeLunge(_ pts: JointPoints) {
        guard let hip   = pt(.leftHip,   in: pts),
              let knee  = pt(.leftKnee,  in: pts),
              let ankle = pt(.leftAnkle, in: pts) else {
            feedbackText = t(.cantSeeLegs)
            return
        }
        let a = angle(at: knee, from: hip, to: ankle)
        if a < 100 {
            feedbackText = t(.deepLunge)
            wasInDownPosition = true
        } else {
            feedbackText = t(.goLower)
            if wasInDownPosition {
                repCount += 1
                wasInDownPosition = false
            }
        }
    }

    // ── Shoulder Press ─────────────────────────────────────────────────────
    // Left elbow angle: shoulder → elbow → wrist
    // angle > 160° AND was < 120° → count rep
    private func analyzeShoulderPress(_ pts: JointPoints) {
        guard let shoulder = pt(.leftShoulder, in: pts),
              let elbow    = pt(.leftElbow,    in: pts),
              let wrist    = pt(.leftWrist,    in: pts) else {
            feedbackText = t(.cantSeeArmsFront)
            return
        }
        let a = angle(at: elbow, from: shoulder, to: wrist)
        if a > 160 {
            feedbackText = t(.fullExtension)
            if wasInDownPosition {
                repCount += 1
                wasInDownPosition = false
            }
        } else {
            feedbackText = t(.higherUp)
            if a < 120 { wasInDownPosition = true }
        }
    }

    // MARK: - Plank Timer

    private func startPlankTimerIfNeeded() {
        guard plankTimer == nil else { return }
        plankTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.elapsedSeconds += 1
        }
    }

    private func stopPlankTimer() {
        plankTimer?.invalidate()
        plankTimer = nil
    }

    // MARK: - Camera permissions & configuration

    private func requestPermission() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureCaptureSession()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted { configureCaptureSession() }
            else { await MainActor.run { showPermissionAlert = true } }
        default:
            await MainActor.run { showPermissionAlert = true }
        }
    }

    private func configureCaptureSession() {
        guard !captureSession.isRunning else { return }
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input  = try? AVCaptureDeviceInput(device: device) else { return }

        captureSession.beginConfiguration()
        captureSession.sessionPreset = .hd1280x720

        if captureSession.canAddInput(input) { captureSession.addInput(input) }

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
        if captureSession.canAddOutput(videoOutput) { captureSession.addOutput(videoOutput) }

        captureSession.commitConfiguration()
        processingQueue.async { [weak self] in self?.captureSession.startRunning() }
    }

    deinit { plankTimer?.invalidate() }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension FormAnalyzerViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {

    /// Runs on `processingQueue`. Performs Vision inference, then hops to the main actor for state updates.
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Raw buffer is landscape (1280×720). `.right` rotates Vision space to portrait (720×1280).
        let bufW = CVPixelBufferGetWidth(pixelBuffer)
        let bufH = CVPixelBufferGetHeight(pixelBuffer)
        let portraitSize = CGSize(width: CGFloat(bufH), height: CGFloat(bufW))

        let request = VNDetectHumanBodyPoseRequest()
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
            .perform([request])

        guard let observation = request.results?.first,
              let rawPoints   = try? observation.recognizedPoints(.all) else {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.videoSize = portraitSize
                self.joints    = [:]
                self.noPersonDetected()
            }
            return
        }

        // Build both data structures on background before hopping to main.
        var detected = [VNHumanBodyPoseObservation.JointName: DetectedJoint]()
        var jointPts = JointPoints()
        for (name, point) in rawPoints where point.confidence > 0.3 {
            let pos = CGPoint(x: point.x, y: 1 - point.y) // flip y: 0 = top
            detected[name] = DetectedJoint(position: pos, confidence: point.confidence)
            jointPts[name] = pos
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.videoSize = portraitSize
            self.joints    = detected
            self.processPose(jointPts)
        }
    }
}
