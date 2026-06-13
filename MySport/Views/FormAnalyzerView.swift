import SwiftUI
import AVFoundation
import Vision

// MARK: - FormAnalyzerView

struct FormAnalyzerView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var viewModel = FormAnalyzerViewModel()

    var body: some View {
        ZStack {
            // ── Camera preview ──────────────────────────────────────────────
            CameraPreviewView(session: viewModel.captureSession)
                .ignoresSafeArea()

            // ── Skeleton overlay (accurate aspect-fill transform) ───────────
            SkeletonCanvas(
                joints: viewModel.joints,
                videoSize: viewModel.videoSize
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // ── HUD ─────────────────────────────────────────────────────────
            VStack(spacing: 0) {
                // Top bar: counter (left) + close button (right)
                HStack(alignment: .top) {
                    RepCounterView(text: viewModel.counterDisplay,
                                   isPlank: viewModel.selectedExercise == .plank)
                    Spacer()
                    Button {
                        viewModel.stop()
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Spacer()

                // Feedback text
                Text(viewModel.feedbackText)
                    .font(.title2).fontWeight(.bold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(.black.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.bottom, 12)

                // Exercise selector
                ExerciseSelectorView(
                    selected: viewModel.selectedExercise,
                    onSelect: viewModel.selectExercise
                )
                .padding(.bottom, 34)
            }
        }
        .onAppear  { viewModel.start() }
        .onDisappear { viewModel.stop() }
        .alert(t(.cameraRequired),
               isPresented: $viewModel.showPermissionAlert) {
            Button(t(.openSettings)) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button(t(.cancel), role: .cancel) {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text(t(.cameraPermMsg))
        }
    }
}

// MARK: - RepCounterView

struct RepCounterView: View {
    let text: String
    let isPlank: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isPlank ? "timer" : "repeat")
                .font(.system(size: 14, weight: .bold))
            Text(text)
                .font(.system(size: 26, weight: .black, design: .rounded))
                .monospacedDigit()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(.black.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - ExerciseSelectorView

struct ExerciseSelectorView: View {
    let selected: ExerciseType
    let onSelect: (ExerciseType) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ExerciseType.allCases) { exercise in
                    Button { onSelect(exercise) } label: {
                        HStack(spacing: 6) {
                            Image(systemName: exercise.systemImage)
                                .font(.system(size: 13, weight: .bold))
                            Text(exercise.localizedName)
                                .font(.system(size: 13, weight: .bold))
                        }
                        .padding(.horizontal, 14).padding(.vertical, 9)
                        .background(selected == exercise
                            ? Color.fitnessPrimary
                            : Color.white.opacity(0.18))
                        .foregroundStyle(selected == exercise
                            ? Color.fitnessDarkBg
                            : Color.white)
                        .clipShape(Capsule())
                        .animation(.easeInOut(duration: 0.15), value: selected)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - CameraPreviewView

/// Wraps a plain `UIView` whose `layerClass` is `AVCaptureVideoPreviewLayer`.
/// This is the correct pattern for preview — no sublayer juggling.
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewLayerView {
        let view = PreviewLayerView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewLayerView, context: Context) {
        if uiView.previewLayer.session !== session {
            uiView.previewLayer.session = session
        }
    }
}

final class PreviewLayerView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

// MARK: - SkeletonCanvas

/// Draws skeleton bones and joints using SwiftUI Canvas with accurate aspect-fill transform.
struct SkeletonCanvas: View {
    let joints: [VNHumanBodyPoseObservation.JointName: DetectedJoint]
    let videoSize: CGSize

    private let connections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        // Left arm
        (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
        // Right arm
        (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
        // Left leg
        (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
        // Right leg
        (.rightHip, .rightKnee), (.rightKnee, .rightAnkle),
        // Torso
        (.leftShoulder, .rightShoulder),
        (.leftHip, .rightHip),
        (.leftShoulder, .leftHip),
        (.rightShoulder, .rightHip)
    ]

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let transform = aspectFillTransform(videoSize: videoSize, viewSize: size)

                // ── Bones ──────────────────────────────────────────────────
                for (nameA, nameB) in connections {
                    guard let a = joints[nameA], let b = joints[nameB] else { continue }
                    let ptA = transform(a.position)
                    let ptB = transform(b.position)
                    var path = Path()
                    path.move(to: ptA)
                    path.addLine(to: ptB)
                    ctx.stroke(path,
                               with: .color(.green.opacity(0.75)),
                               style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                }

                // ── Joints ─────────────────────────────────────────────────
                for (_, joint) in joints {
                    let pt  = transform(joint.position)
                    let r   = CGFloat(joint.confidence > 0.7 ? 6.0 : 4.0)
                    let dot = CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)
                    ctx.fill(Path(ellipseIn: dot), with: .color(.green))
                }
            }
        }
    }

    /// Returns a closure that maps a normalised Vision point [0,1]×[0,1] to screen coordinates,
    /// matching the exact transform that `AVCaptureVideoPreviewLayer` applies with `.resizeAspectFill`.
    private func aspectFillTransform(videoSize: CGSize, viewSize: CGSize) -> (CGPoint) -> CGPoint {
        let videoAspect = videoSize.width / videoSize.height
        let viewAspect  = viewSize.width  / viewSize.height

        let scale: CGFloat
        let offsetX: CGFloat
        let offsetY: CGFloat

        if viewAspect > videoAspect {
            // View is wider than video: fill by scaling to width, crop top/bottom.
            scale   = viewSize.width / videoSize.width
            offsetX = 0
            offsetY = -(videoSize.height * scale - viewSize.height) / 2
        } else {
            // View is taller than video: fill by scaling to height, crop left/right.
            scale   = viewSize.height / videoSize.height
            offsetX = -(videoSize.width * scale - viewSize.width) / 2
            offsetY = 0
        }

        return { pt in
            CGPoint(
                x: pt.x * videoSize.width  * scale + offsetX,
                y: pt.y * videoSize.height * scale + offsetY
            )
        }
    }
}

#Preview {
    FormAnalyzerView()
}
