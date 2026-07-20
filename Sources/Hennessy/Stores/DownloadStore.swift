import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class DownloadStore {
    var selectedSection: SidebarSection = .download
    var searchText = ""
    var urlText = ""
    var outputDirectory: URL
    var selectedMode: DownloadMode = .bestAudio
    var titleOverride = ""
    var artistOverride = ""
    var playlistText = "" {
        didSet {
            if oldValue != playlistText {
                playlistProgressItems = []
            }
        }
    }
    var playlistProgressItems: [PlaylistDownloadProgressItem] = []
    var creatorSearchQuery = ""
    var creatorSearchResults: [MediaSearchResult] = []
    var creatorSearchChannel: CreatorSearchCandidate?
    var selectedCreatorResultIDs: Set<String> = []
    var creatorSearchLimit = 100
    var isSearchingCreator = false
    var creatorSearchError: String?
    var allowPlaylist = false
    var logText = "准备下载。"
    var statusMessage = "等待链接"
    var errorSummary: String?
    var downloadProgress: Double?
    var progressDetail = ""
    var lastOutputURL: URL?
    var isRunning = false
    var records: [DownloadRecord] = []
    var isSearchPresented = false
    var mediaSearchQuery = ""
    var mediaSearchResults: [MediaSearchResult] = []
    var mediaSearchLimit = 80
    var isSearchingMedia = false
    var mediaSearchError: String?
    private var pendingSearchThumbnailURL: String?
    var libraryItems: [LibraryMediaItem] = LibraryPersistence.load()
    var selectedLibraryItemID: String?
    var libraryFilter: LibraryFilter = .all
    let playerController: PlayerController
    var playbackRepeatMode: PlaybackRepeatMode = .none
    var isAutoPlayEnabled = true
    var isCrossfadeEnabled = false
    var isFullPlayerPresented = false
    var playerArtworkMode: PlayerArtworkMode = .artwork
    var lyricsState: LyricsLoadState = .idle
    var editingLibraryItem: LibraryMediaItem?
    var isArtworkRefreshRunning = false

    private let service = DownloaderService()
    private let searchService = MediaSearchService()
    private let lyricsService = LyricsService()
    private let artworkService = ArtworkLookupService()
    private let maxLogCharacters = 12_000
    @ObservationIgnored private var lyricsCache: [String: LyricsLoadState] = [:]
    @ObservationIgnored private var lyricsLoadTask: Task<Void, Never>?
    @ObservationIgnored private var artworkLookupTasks: [String: Task<Void, Never>] = [:]

    init() {
        outputDirectory = DirectoryAccess.restoredOutputDirectory() ?? DirectoryAccess.defaultOutputDirectory
        playerController = PlayerController()
        playerController.onPlaybackEnded = { [weak self] in
            self?.handlePlaybackEnded()
        }
        playerController.onCrossfadeRequested = { [weak self] in
            self?.handleCrossfadeRequested()
        }
    }

    var canStartDownload: Bool {
        !isRunning && URL(string: urlText.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
    }

    var canStartPlaylistDownload: Bool {
        !isRunning && !playlistPreviewEntries.isEmpty
    }

    var canSearchCreator: Bool {
        !isSearchingCreator && !creatorSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canLoadMoreMediaResults: Bool {
        !isSearchingMedia && !mediaSearchResults.isEmpty
    }

    var canLoadMoreCreatorResults: Bool {
        !isSearchingCreator && !creatorSearchResults.isEmpty
    }

    var selectedCreatorResults: [MediaSearchResult] {
        creatorSearchResults.filter { selectedCreatorResultIDs.contains($0.id) }
    }

    var canStartCreatorDownload: Bool {
        !isRunning && !selectedCreatorResults.isEmpty
    }

    var playlistPreviewEntries: [PlaylistDownloadEntry] {
        PlaylistDownloadEntry.entries(from: playlistText)
    }

    var filteredRecords: [DownloadRecord] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return records }
        return records.filter { record in
            record.title.localizedCaseInsensitiveContains(query)
                || record.url.localizedCaseInsensitiveContains(query)
                || record.mode.title.localizedCaseInsensitiveContains(query)
        }
    }

    var visibleLibraryItems: [LibraryMediaItem] {
        let items = libraryItems.filter { item in
            libraryFilter == .all || item.isFavorite
        }
        return items.sorted { $0.addedAt > $1.addedAt }
    }

    var recentlyPlayedItems: [LibraryMediaItem] {
        libraryItems
            .filter { $0.lastPlayedAt != nil && $0.existsOnDisk }
            .sorted { ($0.lastPlayedAt ?? .distantPast) > ($1.lastPlayedAt ?? .distantPast) }
    }

    var selectedLibraryItem: LibraryMediaItem? {
        guard let selectedLibraryItemID else { return visibleLibraryItems.first }
        return libraryItems.first { $0.id == selectedLibraryItemID } ?? visibleLibraryItems.first
    }

    var hasRefreshableArtworkItems: Bool {
        libraryItems.contains { $0.isAudio }
    }

    func chooseOutputDirectory() {
        guard let url = OpenPanel.chooseDirectory(initialDirectory: outputDirectory) else { return }
        outputDirectory = url
        DirectoryAccess.saveOutputDirectory(url)
    }

    func revealLastOutput() {
        guard let lastOutputURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([lastOutputURL])
    }

    func openMediaSearch() {
        isSearchPresented = true
        if mediaSearchQuery.isEmpty, !urlText.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("http") {
            mediaSearchQuery = urlText
        }
    }

    func searchMedia(resetLimit: Bool = true) {
        let query = mediaSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, !isSearchingMedia else { return }
        if resetLimit {
            mediaSearchLimit = 80
        }
        let limit = mediaSearchLimit

        isSearchingMedia = true
        mediaSearchError = nil

        Task {
            do {
                mediaSearchResults = try await searchService.search(query: query, limit: limit)
                isSearchingMedia = false
            } catch {
                mediaSearchResults = []
                mediaSearchError = error.localizedDescription
                isSearchingMedia = false
            }
        }
    }

    func loadMoreMediaResults() {
        guard canLoadMoreMediaResults else { return }
        mediaSearchLimit += 80
        searchMedia(resetLimit: false)
    }

    func useSearchResult(_ result: MediaSearchResult) {
        urlText = result.url
        titleOverride = ""
        artistOverride = ""
        pendingSearchThumbnailURL = result.thumbnailURL?.absoluteString
        selectedSection = .download
        isSearchPresented = false
        statusMessage = "已填入搜索结果"
        errorSummary = nil
    }

    func downloadAndPlaySearchResult(_ result: MediaSearchResult, mode: DownloadMode) {
        guard !isRunning else { return }
        urlText = result.url
        titleOverride = ""
        artistOverride = ""
        pendingSearchThumbnailURL = result.thumbnailURL?.absoluteString
        selectedMode = mode
        isSearchPresented = false
        startDownload(playWhenFinished: true)
    }

    func startDownload() {
        startDownload(playWhenFinished: false)
    }

    func startPlaylistDownload() {
        let entries = playlistPreviewEntries
        guard !entries.isEmpty, !isRunning else { return }
        startBatchDownload(entries: entries, batchName: "歌单", runningStatus: "正在下载歌单")
    }

    func searchCreatorMedia(resetLimit: Bool = true) {
        let query = creatorSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, !isSearchingCreator else { return }
        if resetLimit {
            creatorSearchLimit = 100
            selectedCreatorResultIDs = []
        }
        let limit = creatorSearchLimit

        isSearchingCreator = true
        creatorSearchError = nil
        if resetLimit {
            creatorSearchResults = []
            creatorSearchChannel = nil
        }
        statusMessage = "正在搜索创作者"

        Task {
            do {
                let result = try await searchService.searchCreatorUploads(query: query, limit: limit)
                creatorSearchChannel = result.creator
                creatorSearchResults = result.items
                selectedCreatorResultIDs = selectedCreatorResultIDs.intersection(Set(result.items.map(\.id)))
                isSearchingCreator = false
                statusMessage = "已找到创作者发布列表"
                progressDetail = "\(result.items.count) 项"
            } catch {
                creatorSearchError = error.localizedDescription
                creatorSearchResults = []
                creatorSearchChannel = nil
                selectedCreatorResultIDs = []
                isSearchingCreator = false
                statusMessage = "创作者搜索失败"
            }
        }
    }

    func loadMoreCreatorResults() {
        guard canLoadMoreCreatorResults else { return }
        creatorSearchLimit += 100
        searchCreatorMedia(resetLimit: false)
    }

    func toggleCreatorResultSelection(_ result: MediaSearchResult) {
        if selectedCreatorResultIDs.contains(result.id) {
            selectedCreatorResultIDs.remove(result.id)
        } else {
            selectedCreatorResultIDs.insert(result.id)
        }
    }

    func selectAllCreatorResults() {
        selectedCreatorResultIDs = Set(creatorSearchResults.map(\.id))
    }

    func clearCreatorSelection() {
        selectedCreatorResultIDs = []
    }

    func startCreatorSelectionDownload() {
        let entries = selectedCreatorResults.map(PlaylistDownloadEntry.init(mediaResult:))
        guard !entries.isEmpty, !isRunning else { return }
        startBatchDownload(entries: entries, batchName: "创作者内容", runningStatus: "正在下载所选内容")
    }

    private func startBatchDownload(entries: [PlaylistDownloadEntry], batchName: String, runningStatus: String) {
        guard !entries.isEmpty, !isRunning else { return }

        isRunning = true
        lastOutputURL = nil
        errorSummary = nil
        downloadProgress = 0
        progressDetail = "0/\(entries.count)"
        playlistProgressItems = entries.enumerated().map { index, entry in
            PlaylistDownloadProgressItem(id: index, entry: entry, state: .pending, detail: "等待处理")
        }
        logText = ""
        statusMessage = runningStatus

        Task {
            var completed = 0
            var duplicates = 0
            var failed = 0

            for (index, entry) in entries.enumerated() {
                guard isRunning else { break }

                progressDetail = "\(index + 1)/\(entries.count)"
                downloadProgress = Double(index) / Double(entries.count)
                appendLog("\n[\(index + 1)/\(entries.count)] \(entry.displayName)\n")
                updatePlaylistProgress(index, state: entry.url == nil ? .searching : .downloading, detail: entry.url == nil ? "正在搜索最佳匹配" : "使用原始链接")

                do {
                    let resolved = try await resolvePlaylistEntry(entry)
                    if let matchTitle = resolved.matchTitle {
                        updatePlaylistProgress(index, state: .matched, detail: "匹配：\(matchTitle)")
                    }
                    let request = DownloadRequest(
                        url: resolved.url,
                        outputDirectory: outputDirectory,
                        mode: selectedMode,
                        titleOverride: entry.title ?? "",
                        artistOverride: entry.artist ?? "",
                        allowPlaylist: false,
                        thumbnailURL: resolved.thumbnailURL ?? entry.thumbnailURL
                    )
                    let startedAt = Date()

                    if let duplicate = duplicateLibraryItem(
                        sourceURL: request.url,
                        title: entry.title ?? resolved.matchTitle,
                        artist: entry.artist,
                        mode: request.mode
                    ),
                       let promoted = promoteDuplicateLibraryItem(
                        duplicate,
                        thumbnailURL: request.thumbnailURL,
                        mode: request.mode
                       ) {
                        duplicates += 1
                        completed += 1
                        lastOutputURL = promoted.fileURL
                        appendLog("已存在于资料库，跳过下载并移到播放列表顶部：\(promoted.title)\n")
                        updatePlaylistProgress(index, state: .duplicate, detail: "已移到播放列表顶部")
                        records.insert(DownloadRecord(
                            title: promoted.fileName,
                            url: request.url,
                            outputURL: promoted.fileURL,
                            mode: request.mode,
                            startedAt: startedAt,
                            succeeded: true
                        ), at: 0)
                        continue
                    }

                    updatePlaylistProgress(index, state: .downloading, detail: "正在下载")
                    let result = try await service.download(request: request) { [weak self] chunk in
                        Task { @MainActor in
                            self?.appendLog(chunk)
                        }
                    }

                    let outputURL = result.finalURL
                    lastOutputURL = outputURL
                    records.insert(DownloadRecord(
                        title: outputURL?.lastPathComponent ?? entry.displayName,
                        url: resolved.url,
                        outputURL: outputURL,
                        mode: request.mode,
                        startedAt: startedAt,
                        succeeded: result.succeeded
                    ), at: 0)

                    if result.succeeded, let outputURL {
                        completed += 1
                        updatePlaylistProgress(index, state: .done, detail: outputURL.lastPathComponent)
                        addToLibrary(
                            fileURL: outputURL,
                            sourceURL: resolved.url,
                            mode: request.mode,
                            thumbnailURL: result.thumbnailURL ?? resolved.thumbnailURL ?? entry.thumbnailURL,
                            title: result.songTitle ?? entry.title,
                            artist: result.artistName ?? entry.artist
                        )
                    } else {
                        failed += 1
                        appendLog(result.errorText)
                        updatePlaylistProgress(index, state: .failed, detail: summarizeFailure(result))
                    }
                } catch {
                    failed += 1
                    appendLog("\n\(entry.displayName)：\(error.localizedDescription)\n")
                    updatePlaylistProgress(index, state: .failed, detail: error.localizedDescription)
                }
            }

            isRunning = false
            downloadProgress = 1
            let duplicateDetail = duplicates > 0 ? "，跳过 \(duplicates) 首重复" : ""
            progressDetail = "\(completed)/\(entries.count)\(duplicateDetail)"
            statusMessage = failed == 0
                ? (duplicates > 0 ? "\(batchName)处理完成" : "\(batchName)下载完成")
                : "\(batchName)部分失败"
            errorSummary = failed == 0 ? nil : "\(failed) 首下载失败，请查看日志。"
        }
    }

    private func startDownload(playWhenFinished: Bool) {
        guard canStartDownload else { return }

        let cleanURL = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        let request = DownloadRequest(
            url: cleanURL,
            outputDirectory: outputDirectory,
            mode: selectedMode,
            titleOverride: titleOverride.trimmingCharacters(in: .whitespacesAndNewlines),
            artistOverride: artistOverride.trimmingCharacters(in: .whitespacesAndNewlines),
            allowPlaylist: allowPlaylist,
            thumbnailURL: pendingSearchThumbnailURL
        )
        pendingSearchThumbnailURL = nil

        if let duplicate = duplicateLibraryItem(
            sourceURL: request.url,
            title: request.titleOverride,
            artist: request.artistOverride,
            mode: request.mode
        ),
           let promoted = promoteDuplicateLibraryItem(
            duplicate,
            thumbnailURL: request.thumbnailURL,
            mode: request.mode
           ) {
            lastOutputURL = promoted.fileURL
            errorSummary = nil
            downloadProgress = 1
            progressDetail = "已移到播放列表顶部"
            logText = "已存在于资料库，跳过下载：\(promoted.title)\n"
            statusMessage = "已在资料库中"
            records.insert(DownloadRecord(
                title: promoted.fileName,
                url: request.url,
                outputURL: promoted.fileURL,
                mode: request.mode,
                startedAt: Date(),
                succeeded: true
            ), at: 0)
            if playWhenFinished {
                selectedSection = .player
            }
            return
        }

        isRunning = true
        lastOutputURL = nil
        errorSummary = nil
        downloadProgress = nil
        progressDetail = "准备连接"
        logText = ""
        statusMessage = "正在下载"
        let startedAt = Date()

        Task {
            do {
                let result = try await service.download(request: request) { [weak self] chunk in
                    Task { @MainActor in
                        self?.appendLog(chunk)
                    }
                }

                let outputURL = result.finalURL
                lastOutputURL = outputURL
                isRunning = false
                statusMessage = result.succeeded ? "下载完成" : "下载失败"
                downloadProgress = result.succeeded ? 1 : nil
                progressDetail = result.succeeded ? "100%" : ""
                appendLog(result.errorText)
                errorSummary = result.succeeded ? nil : summarizeFailure(result)

                records.insert(DownloadRecord(
                    title: outputURL?.lastPathComponent ?? request.url,
                    url: request.url,
                    outputURL: outputURL,
                    mode: request.mode,
                    startedAt: startedAt,
                    succeeded: result.succeeded
                ), at: 0)

                if result.succeeded, let outputURL {
                    addToLibrary(
                        fileURL: outputURL,
                        sourceURL: request.url,
                        mode: request.mode,
                        thumbnailURL: result.thumbnailURL ?? request.thumbnailURL,
                        title: result.songTitle,
                        artist: result.artistName
                    )
                    if playWhenFinished {
                        selectedSection = .player
                    }
                }
            } catch {
                isRunning = false
                statusMessage = "下载失败"
                downloadProgress = nil
                progressDetail = ""
                errorSummary = error.localizedDescription
                appendLog("\n\(error.localizedDescription)\n")
                records.insert(DownloadRecord(
                    title: request.url,
                    url: request.url,
                    outputURL: nil,
                    mode: request.mode,
                    startedAt: startedAt,
                    succeeded: false
                ), at: 0)
            }
        }
    }

    func selectLibraryItem(_ item: LibraryMediaItem) {
        selectedLibraryItemID = item.id
        selectedSection = .player
        markPlayed(item)
    }

    func playSelectedLibraryItemIfNeeded() {
        guard let item = selectedLibraryItem else { return }
        guard playerController.currentItemID != item.id else {
            markPlayed(item)
            return
        }
        playLibraryItem(item, autoplay: true)
    }

    func toggleFavorite(_ item: LibraryMediaItem) {
        guard let index = libraryItems.firstIndex(where: { $0.id == item.id }) else { return }
        libraryItems[index].isFavorite.toggle()
        LibraryPersistence.save(libraryItems)
    }

    func removeFromLibrary(_ item: LibraryMediaItem) {
        libraryItems.removeAll { $0.id == item.id }
        if selectedLibraryItemID == item.id {
            selectedLibraryItemID = visibleLibraryItems.first?.id
        }
        LibraryPersistence.save(libraryItems)
    }

    func revealLibraryItem(_ item: LibraryMediaItem) {
        NSWorkspace.shared.activateFileViewerSelecting([item.fileURL])
    }

    func beginEditingLibraryItem(_ item: LibraryMediaItem) {
        editingLibraryItem = libraryItems.first { $0.id == item.id } ?? item
    }

    func refreshArtwork(for item: LibraryMediaItem) {
        guard libraryItems.contains(where: { $0.id == item.id }) else { return }
        resetArtworkToFallback(for: item.id)
        refreshArtwork(for: item.id)
    }

    func refreshAllAlbumArtwork() {
        guard !isArtworkRefreshRunning else { return }
        let itemIDs = libraryItems.filter(\.isAudio).map(\.id)
        guard !itemIDs.isEmpty else {
            statusMessage = "没有可刷新的音频"
            return
        }

        artworkLookupTasks.values.forEach { $0.cancel() }
        artworkLookupTasks.removeAll()
        isArtworkRefreshRunning = true
        statusMessage = "正在刷新专辑封面"

        Task { [artworkService] in
            var matchedCount = 0
            var fallbackCount = 0

            for itemID in itemIDs {
                guard !Task.isCancelled else { break }
                switch await applyArtworkLookup(for: itemID, artworkService: artworkService) {
                case .matched:
                    matchedCount += 1
                case .fallback:
                    fallbackCount += 1
                case .skipped:
                    break
                }
            }

            isArtworkRefreshRunning = false
            statusMessage = "封面刷新完成"
            progressDetail = "匹配 \(matchedCount) 首，回退 \(fallbackCount) 首"
        }
    }

    func updateLibraryItemMetadata(_ item: LibraryMediaItem, title: String, artist: String) {
        guard let index = libraryItems.firstIndex(where: { $0.id == item.id }) else { return }
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanArtist = artist.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }

        libraryItems[index].title = cleanTitle
        libraryItems[index].artist = cleanArtist.isEmpty ? nil : cleanArtist
        resetArtworkToFallback(for: libraryItems[index].id)
        LibraryPersistence.save(libraryItems)
        refreshArtwork(for: libraryItems[index].id)

        lyricsCache[item.id] = nil
        if selectedLibraryItemID == item.id {
            lyricsState = .idle
            if playerArtworkMode == .lyrics {
                loadLyricsForSelectedItemIfNeeded(force: true)
            }
        }
    }

    func playRecord(_ record: DownloadRecord) {
        guard let outputURL = record.outputURL else { return }
        addToLibrary(fileURL: outputURL, sourceURL: record.url, mode: record.mode, thumbnailURL: nil, title: nil, artist: nil)
        selectedSection = .player
    }

    func setPlaybackRepeatMode(_ mode: PlaybackRepeatMode) {
        playbackRepeatMode = playbackRepeatMode == mode ? .none : mode
    }

    func toggleAutoPlay() {
        isAutoPlayEnabled.toggle()
    }

    func toggleCrossfade() {
        isCrossfadeEnabled.toggle()
        playerController.crossfadeLeadTime = isCrossfadeEnabled ? 0.9 : nil
    }

    func setPlayerArtworkMode(_ mode: PlayerArtworkMode) {
        playerArtworkMode = mode
        if mode == .lyrics {
            loadLyricsForSelectedItemIfNeeded()
        }
    }

    func loadLyricsForSelectedItemIfNeeded(force: Bool = false) {
        guard let item = selectedLibraryItem else {
            lyricsLoadTask?.cancel()
            lyricsState = .idle
            return
        }

        if !force, let cached = lyricsCache[item.id] {
            lyricsState = cached
            return
        }

        lyricsLoadTask?.cancel()
        lyricsState = .loading

        let itemID = item.id
        let duration = playerController.duration.isFinite && playerController.duration > 30
            ? playerController.duration
            : nil

        lyricsLoadTask = Task { [lyricsService] in
            do {
                let result = try await lyricsService.lookup(for: item, duration: duration)
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    guard self.selectedLibraryItem?.id == itemID else { return }
                    let state: LyricsLoadState
                    if let track = result.track {
                        state = result.isAutomaticMatch
                            ? .available(track)
                            : .lowConfidence(track, reason: result.reason)
                    } else {
                        state = .unavailable(result.reason)
                    }
                    self.lyricsState = state
                    self.lyricsCache[itemID] = state
                }
            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    guard self.selectedLibraryItem?.id == itemID else { return }
                    let state = LyricsLoadState.failed(error.localizedDescription)
                    self.lyricsState = state
                    self.lyricsCache[itemID] = state
                }
            }
        }
    }

    func reloadLyricsForSelectedItem() {
        guard let item = selectedLibraryItem else { return }
        lyricsCache[item.id] = nil
        loadLyricsForSelectedItemIfNeeded(force: true)
    }

    func acceptLowConfidenceLyrics() {
        guard let item = selectedLibraryItem else { return }
        if case .lowConfidence(let track, _) = lyricsState {
            let state = LyricsLoadState.available(track)
            lyricsState = state
            lyricsCache[item.id] = state
        }
    }

    private func handlePlaybackEnded() {
        switch playbackRepeatMode {
        case .none:
            if isAutoPlayEnabled {
                playNextLibraryItem()
            }
        case .one:
            if let item = selectedLibraryItem {
                playerController.restart(item)
            }
        case .all:
            playNextLibraryItem()
        }
    }

    private func handleCrossfadeRequested() {
        switch playbackRepeatMode {
        case .none:
            if isAutoPlayEnabled {
                playNextLibraryItem()
            }
        case .one:
            break
        case .all:
            playNextLibraryItem()
        }
    }

    func playNextLibraryItem() {
        let items = visibleLibraryItems.filter(\.existsOnDisk)
        guard !items.isEmpty else { return }
        let currentIndex = selectedLibraryItemID.flatMap { selectedID in
            items.firstIndex { $0.id == selectedID }
        }
        let nextIndex = currentIndex.map { ($0 + 1) % items.count } ?? 0
        let nextItem = items[nextIndex]
        playLibraryItem(nextItem, autoplay: true)
    }

    func playPreviousLibraryItem() {
        let items = visibleLibraryItems.filter(\.existsOnDisk)
        guard !items.isEmpty else { return }
        let currentIndex = selectedLibraryItemID.flatMap { selectedID in
            items.firstIndex { $0.id == selectedID }
        }
        let previousIndex = currentIndex.map { ($0 - 1 + items.count) % items.count } ?? 0
        let previousItem = items[previousIndex]
        playLibraryItem(previousItem, autoplay: true)
    }

    func markPlayed(_ item: LibraryMediaItem) {
        guard let index = libraryItems.firstIndex(where: { $0.id == item.id }) else { return }
        libraryItems[index].lastPlayedAt = Date()
        LibraryPersistence.save(libraryItems)
    }

    private func playLibraryItem(_ item: LibraryMediaItem, autoplay: Bool) {
        selectedLibraryItemID = item.id
        markPlayed(item)

        let shouldFade = isCrossfadeEnabled
            && autoplay
            && playerController.isPlaying
            && playerController.currentItemID != nil
            && playerController.currentItemID != item.id

        if shouldFade {
            playerController.loadWithFade(item, autoplay: autoplay)
        } else {
            playerController.load(item, autoplay: autoplay)
        }
    }

    func cancelDownload() {
        service.cancel()
        isRunning = false
        statusMessage = "已停止"
        errorSummary = nil
        downloadProgress = nil
        progressDetail = ""
        appendLog("\n已停止当前下载。\n")
    }

    private func appendLog(_ text: String) {
        guard !text.isEmpty else { return }
        updateProgress(from: text)
        if logText == "准备下载。" {
            logText = text
        } else {
            logText += text
        }
        trimLogIfNeeded()
    }

    private func trimLogIfNeeded() {
        guard logText.count > maxLogCharacters else { return }
        let suffix = logText.suffix(maxLogCharacters)
        logText = "…已省略较早日志。\n" + String(suffix)
    }

    private func duplicateLibraryItem(sourceURL: String?, title: String?, artist: String?, mode: DownloadMode) -> LibraryMediaItem? {
        DuplicateMediaMatcher.bestMatch(
            in: libraryItems.filter(\.existsOnDisk),
            lookup: DuplicateMediaLookup(
                sourceURL: sourceURL,
                title: title,
                artist: artist,
                mode: mode
            )
        )
    }

    private func promoteDuplicateLibraryItem(_ item: LibraryMediaItem, thumbnailURL: String?, mode: DownloadMode) -> LibraryMediaItem? {
        guard let index = libraryItems.firstIndex(where: { $0.id == item.id }) else { return nil }
        var promoted = libraryItems.remove(at: index)
        let resolvedSourceThumbnail = resolvedSourceThumbnailURL(
            sourceURL: promoted.sourceURL,
            providedThumbnailURL: thumbnailURL,
            existingItem: promoted
        )

        promoted.addedAt = Date()
        promoted.lastPlayedAt = playWhenAdding(mode: mode) ? Date() : promoted.lastPlayedAt
        if promoted.sourceThumbnailURL?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
            promoted.sourceThumbnailURL = resolvedSourceThumbnail
        }
        if promoted.thumbnailURL?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
            promoted.thumbnailURL = fallbackThumbnailURL(for: promoted)
        }

        libraryItems.insert(promoted, at: 0)
        selectedLibraryItemID = promoted.id
        LibraryPersistence.save(libraryItems)
        return promoted
    }

    private func addToLibrary(fileURL: URL, sourceURL: String, mode: DownloadMode, thumbnailURL: String?, title: String?, artist: String?) {
        let path = fileURL.path
        let id = path
        let existingItem = libraryItems.first { $0.id == id }
        let existingFavorite = existingItem?.isFavorite ?? false
        let existingArtist = existingItem?.artist
        let cleanTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanArtist = artist?.trimmingCharacters(in: .whitespacesAndNewlines)
        let sourceThumbnailURL = resolvedSourceThumbnailURL(
            sourceURL: sourceURL,
            providedThumbnailURL: thumbnailURL,
            existingItem: existingItem
        )
        let initialArtworkURL = sourceThumbnailURL ?? existingItem?.thumbnailURL
        libraryItems.removeAll { $0.id == id }
        let item = LibraryMediaItem(
            id: id,
            title: cleanTitle?.isEmpty == false ? cleanTitle! : fileURL.deletingPathExtension().lastPathComponent,
            artist: cleanArtist?.isEmpty == false ? cleanArtist : existingArtist,
            sourceURL: sourceURL,
            thumbnailURL: initialArtworkURL,
            sourceThumbnailURL: sourceThumbnailURL,
            filePath: path,
            modeRawValue: mode.rawValue,
            addedAt: Date(),
            lastPlayedAt: playWhenAdding(mode: mode) ? Date() : nil,
            isFavorite: existingFavorite
        )
        libraryItems.insert(item, at: 0)
        selectedLibraryItemID = item.id
        LibraryPersistence.save(libraryItems)
        refreshArtwork(for: item.id)
    }

    private func refreshArtwork(for itemID: String) {
        artworkLookupTasks[itemID]?.cancel()
        guard let item = libraryItems.first(where: { $0.id == itemID }), item.isAudio else { return }

        artworkLookupTasks[itemID] = Task { [artworkService] in
            _ = await applyArtworkLookup(for: itemID, artworkService: artworkService)
            artworkLookupTasks[itemID] = nil
        }
    }

    private func applyArtworkLookup(for itemID: String, artworkService: ArtworkLookupService) async -> ArtworkRefreshOutcome {
        guard let index = libraryItems.firstIndex(where: { $0.id == itemID }) else { return .skipped }
        let item = libraryItems[index]
        guard item.isAudio else { return .skipped }
        resetArtworkToFallback(for: itemID)

        let result = try? await artworkService.lookupArtwork(title: item.title, artist: item.artist)
        guard !Task.isCancelled, let currentIndex = libraryItems.firstIndex(where: { $0.id == itemID }) else {
            return .skipped
        }

        if let result {
            libraryItems[currentIndex].thumbnailURL = result.artworkURL.absoluteString
            LibraryPersistence.save(libraryItems)
            return .matched
        } else {
            libraryItems[currentIndex].thumbnailURL = fallbackThumbnailURL(for: libraryItems[currentIndex])
            LibraryPersistence.save(libraryItems)
            return .fallback
        }
    }

    private func resetArtworkToFallback(for itemID: String) {
        guard let index = libraryItems.firstIndex(where: { $0.id == itemID }) else { return }
        libraryItems[index].thumbnailURL = fallbackThumbnailURL(for: libraryItems[index])
    }

    private func fallbackThumbnailURL(for item: LibraryMediaItem) -> String? {
        item.sourceFallbackArtworkURL?.absoluteString ?? item.thumbnailURL
    }

    private func resolvedSourceThumbnailURL(sourceURL: String, providedThumbnailURL: String?, existingItem: LibraryMediaItem?) -> String? {
        if let providedThumbnailURL, !providedThumbnailURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return providedThumbnailURL
        }
        if let sourceThumbnailURL = existingItem?.sourceThumbnailURL, !sourceThumbnailURL.isEmpty {
            return sourceThumbnailURL
        }
        return youtubeThumbnailURL(from: sourceURL)?.absoluteString
    }

    private func youtubeThumbnailURL(from string: String) -> URL? {
        guard let components = URLComponents(string: string) else { return nil }
        let videoID: String?
        if components.host?.contains("youtu.be") == true {
            videoID = components.path.split(separator: "/").first.map(String.init)
        } else if components.host?.contains("youtube.com") == true {
            videoID = components.queryItems?.first { $0.name == "v" }?.value
        } else {
            videoID = nil
        }
        guard let videoID else { return nil }
        return URL(string: "https://i.ytimg.com/vi/\(videoID)/hqdefault.jpg")
    }

    private func playWhenAdding(mode: DownloadMode) -> Bool {
        mode == .bestAudio || mode == .mp3 || mode == .video || mode == .videoMP4
    }

    private func updateProgress(from text: String) {
        let normalized = text.replacingOccurrences(of: "\r", with: "\n")

        if let percent = latestDownloadPercent(in: normalized) {
            downloadProgress = max(0, min(1, percent / 100))
            progressDetail = "\(Int(percent.rounded()))%"
            return
        }

        if normalized.localizedCaseInsensitiveContains("Downloading webpage")
            || normalized.localizedCaseInsensitiveContains("Extracting URL") {
            downloadProgress = nil
            progressDetail = "解析链接"
            return
        }

        if normalized.localizedCaseInsensitiveContains("Postprocessing")
            || normalized.localizedCaseInsensitiveContains("Adding metadata")
            || normalized.localizedCaseInsensitiveContains("Merging formats") {
            downloadProgress = nil
            progressDetail = "正在处理文件"
        }
    }

    private func latestDownloadPercent(in text: String) -> Double? {
        let pattern = #"\[download\]\s+([0-9]+(?:\.[0-9]+)?)%"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).compactMap { match -> Double? in
            guard let captureRange = Range(match.range(at: 1), in: text) else { return nil }
            return Double(String(text[captureRange]))
        }.last
    }

    private func summarizeFailure(_ result: DownloadResult) -> String {
        let lines = (result.errorText + "\n" + result.outputText)
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let errorLine = lines.last(where: { $0.localizedCaseInsensitiveContains("ERROR:") }) {
            return errorLine
        }

        if let errorLine = lines.last(where: { $0.hasPrefix("错误：") }) {
            return errorLine
        }

        return "下载进程退出，代码：\(result.exitCode)"
    }

    private func resolvePlaylistEntry(_ entry: PlaylistDownloadEntry) async throws -> ResolvedPlaylistEntry {
        if let url = entry.url {
            return ResolvedPlaylistEntry(url: url, thumbnailURL: entry.thumbnailURL, matchTitle: nil, score: nil)
        }

        let results = try await searchService.search(query: entry.searchQuery, limit: 8)
        guard let match = bestSearchResult(for: entry, in: results) else {
            throw MediaSearchError.noResults
        }
        guard match.score >= PlaylistMatchScorer.minimumAcceptableScore else {
            throw MediaSearchError.commandFailed("没有找到足够可信的匹配结果：\(entry.displayName)")
        }
        appendLog("匹配：\(match.result.title) / \(match.result.channel)（评分 \(match.score)）\n")
        return ResolvedPlaylistEntry(
            url: match.result.url,
            thumbnailURL: match.result.thumbnailURL?.absoluteString,
            matchTitle: match.result.title,
            score: match.score
        )
    }

    private func bestSearchResult(for entry: PlaylistDownloadEntry, in results: [MediaSearchResult]) -> PlaylistDownloadMatch? {
        PlaylistMatchScorer(mode: selectedMode).bestMatch(for: entry, in: results)
    }

    private func updatePlaylistProgress(_ id: Int, state: PlaylistDownloadProgressState, detail: String) {
        guard let index = playlistProgressItems.firstIndex(where: { $0.id == id }) else { return }
        playlistProgressItems[index].state = state
        playlistProgressItems[index].detail = detail
    }
}

private struct ResolvedPlaylistEntry {
    let url: String
    let thumbnailURL: String?
    let matchTitle: String?
    let score: Int?
}

private enum ArtworkRefreshOutcome {
    case matched
    case fallback
    case skipped
}
