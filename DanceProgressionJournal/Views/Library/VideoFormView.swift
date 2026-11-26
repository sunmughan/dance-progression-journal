import SwiftUI
import SwiftData

// MARK: - Add Video and Upload Video
//
// Import from the device library or record a new video, and tag it with
// date and type. The form below the choice buttons stays disabled until
// a video is picked. Recording needs a device camera: on a simulator,
// where no camera exists, the Record button is hidden and a note says
// so plainly instead of a button that goes nowhere.

struct VideoFormView: View {
    let videoId: UUID?
    var onSaved: (UUID) -> Void

    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Dance.displayOrder) private var dances: [Dance]
    @Query(sort: \Drill.name) private var drills: [Drill]
    @Query private var videos: [Video]

    @State private var viewModel: VideoFormViewModel?
    @State private var showingLibraryPicker = false
    @State private var showingRecorder = false
    @State private var importFailed = false

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    init(videoId: UUID?, onSaved: @escaping (UUID) -> Void = { _ in }) {
        self.videoId = videoId
        self.onSaved = onSaved
        let lookupId = videoId ?? UUID()
        _videos = Query(filter: #Predicate<Video> { $0.id == lookupId })
    }

    var body: some View {
        Group {
            if let viewModel {
                formContent(viewModel)
            } else {
                ProgressView("Loading")
                    .tint(DesignTokens.Color.accent)
            }
        }
        .task {
            let model = VideoFormViewModel(
                repository: dependencies.videos,
                fileService: dependencies.videoFiles
            )
            let limit = (try? dependencies.profile.fetchSettings())?.perVideoSizeLimitMB ?? 500
            model.load(
                video: videos.first,
                dances: dances,
                drills: drills,
                sizeLimitMB: limit
            )
            viewModel = model
        }
        .navigationTitle(viewModel?.isEditing == true ? "Edit video" : "Add video")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingLibraryPicker) {
            VideoLibraryPicker(
                onPicked: { url in
                    showingLibraryPicker = false
                    importFailed = false
                    viewModel?.pickedVideoURL = url
                    Task { await viewModel?.inspectPickedVideo() }
                },
                onFailed: {
                    showingLibraryPicker = false
                    importFailed = true
                },
                onCancelled: {
                    showingLibraryPicker = false
                }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showingRecorder) {
            VideoRecorder(
                onRecorded: { url in
                    showingRecorder = false
                    viewModel?.pickedVideoURL = url
                    Task { await viewModel?.inspectPickedVideo() }
                },
                onCancelled: {
                    showingRecorder = false
                }
            )
            .ignoresSafeArea()
        }
    }

    private func formContent(_ viewModel: VideoFormViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Space.space4) {
                if !viewModel.isEditing {
                    HStack(spacing: DesignTokens.Space.space2) {
                        SecondaryButton(title: "Choose from Library") {
                            showingLibraryPicker = true
                        }
                        if cameraAvailable {
                            SecondaryButton(title: "Record Video") {
                                showingRecorder = true
                            }
                        }
                    }
                    if !cameraAvailable {
                        Text("Recording needs a device camera. Choose from Library on this device.")
                            .font(DesignTokens.Font.footnote)
                            .foregroundStyle(DesignTokens.Color.textSecondary)
                    }
                }

                if let pickedURL = viewModel.pickedVideoURL {
                    AppCard {
                        HStack(spacing: DesignTokens.Space.space2) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(DesignTokens.Color.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(pickedURL.lastPathComponent)
                                    .font(DesignTokens.Font.subheadline)
                                    .foregroundStyle(DesignTokens.Color.textPrimary)
                                    .lineLimit(1)
                                Text("\(viewModel.pickedSizeLabel) · limit \(viewModel.sizeLimitMB) MB per video")
                                    .font(DesignTokens.Font.footnote)
                                    .foregroundStyle(DesignTokens.Color.textSecondary)
                            }
                            Spacer()
                            Button("Remove") {
                                viewModel.pickedVideoURL = nil
                                viewModel.pickedDurationSeconds = 0
                                viewModel.pickedFileSizeBytes = 0
                            }
                            .font(DesignTokens.Font.subheadline)
                            .foregroundStyle(DesignTokens.Color.danger)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                if importFailed {
                    ErrorBanner(message: "This video could not be imported. Try a shorter video or check storage.")
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Title")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    TextField("Video title", text: $viewModel.title)
                        .font(DesignTokens.Font.body)
                        .padding(DesignTokens.Space.space3)
                        .frame(height: 52)
                        .background(DesignTokens.Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                        .autocorrectionDisabled()
                        .disabled(viewModel.isEditing == false && viewModel.pickedVideoURL == nil)
                    if viewModel.title.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text("Enter a title to save.")
                            .font(DesignTokens.Font.footnote)
                            .foregroundStyle(DesignTokens.Color.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Date")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    DatePicker("Recorded date", selection: $viewModel.recordedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .disabled(viewModel.isEditing == false && viewModel.pickedVideoURL == nil)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Dance")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    Picker("Dance", selection: $viewModel.selectedDance) {
                        ForEach(viewModel.dances) { dance in
                            Text(dance.name).tag(Optional(dance))
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(viewModel.isEditing == false && viewModel.pickedVideoURL == nil)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Type")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    Picker("Type", selection: $viewModel.videoType) {
                        ForEach(VideoType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(viewModel.isEditing == false && viewModel.pickedVideoURL == nil)
                }

                if viewModel.videoType == .choreography {
                    VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                        Text("Choreography name")
                            .font(DesignTokens.Font.headline)
                            .foregroundStyle(DesignTokens.Color.textPrimary)
                        TextField("Choreography name", text: $viewModel.choreographyName)
                            .font(DesignTokens.Font.body)
                            .padding(DesignTokens.Space.space3)
                            .frame(height: 52)
                            .background(DesignTokens.Color.backgroundSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                            .autocorrectionDisabled()
                            .disabled(viewModel.isEditing == false && viewModel.pickedVideoURL == nil)
                    }
                }

                if viewModel.videoType == .drill {
                    VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                        Text("Drill")
                            .font(DesignTokens.Font.headline)
                            .foregroundStyle(DesignTokens.Color.textPrimary)
                        Picker("Drill", selection: $viewModel.selectedDrillId) {
                            Text("No drill").tag(Optional<UUID>(nil))
                            ForEach(viewModel.drills) { drill in
                                Text(drill.name).tag(Optional(drill.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .disabled(viewModel.isEditing == false && viewModel.pickedVideoURL == nil)
                    }
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Notes")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    TextEditor(text: $viewModel.notes)
                        .font(DesignTokens.Font.body)
                        .padding(DesignTokens.Space.space2)
                        .frame(minHeight: 120)
                        .background(DesignTokens.Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                        .disabled(viewModel.isEditing == false && viewModel.pickedVideoURL == nil)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.space2) {
                    Text("Instagram link")
                        .font(DesignTokens.Font.headline)
                        .foregroundStyle(DesignTokens.Color.textPrimary)
                    TextField("https://instagram.com/...", text: $viewModel.instagramLink)
                        .font(DesignTokens.Font.body)
                        .padding(DesignTokens.Space.space3)
                        .frame(height: 52)
                        .background(DesignTokens.Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .disabled(viewModel.isEditing == false && viewModel.pickedVideoURL == nil)
                }

                if let errorMessage = viewModel.errorMessage {
                    ErrorBanner(message: errorMessage)
                }

                if let reason = viewModel.saveDisabledReason {
                    Text(reason)
                        .font(DesignTokens.Font.footnote)
                        .foregroundStyle(DesignTokens.Color.textSecondary)
                }
            }
            .padding(DesignTokens.Space.screenMargin)
        }
        .background(DesignTokens.Color.backgroundPrimary)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if let savedId = viewModel.save() {
                        FirebaseService.shared.logEvent("video_saved")
                        dismiss()
                        onSaved(savedId)
                        Task { await dependencies.storageBackup.backupVideo(id: savedId) }
                    }
                }
                .disabled(!viewModel.canSave || viewModel.isSaving)
            }
        }
    }
}
