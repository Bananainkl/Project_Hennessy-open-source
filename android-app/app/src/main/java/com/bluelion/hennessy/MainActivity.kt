package com.bluelion.hennessy

import android.app.Application
import android.os.Bundle
import android.os.Environment
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.animation.AnimatedContent
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.ArrowDownward
import androidx.compose.material.icons.rounded.Favorite
import androidx.compose.material.icons.rounded.FavoriteBorder
import androidx.compose.material.icons.rounded.Folder
import androidx.compose.material.icons.rounded.GraphicEq
import androidx.compose.material.icons.rounded.LibraryMusic
import androidx.compose.material.icons.rounded.Link
import androidx.compose.material.icons.rounded.Movie
import androidx.compose.material.icons.rounded.MusicNote
import androidx.compose.material.icons.rounded.Pause
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.material.icons.rounded.Replay
import androidx.compose.material.icons.rounded.Repeat
import androidx.compose.material.icons.rounded.Schedule
import androidx.compose.material.icons.rounded.Search
import androidx.compose.material.icons.rounded.Stop
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Slider
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import com.yausername.ffmpeg.FFmpeg
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLException
import com.yausername.youtubedl_android.YoutubeDLRequest
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID
import org.json.JSONObject
import kotlin.math.min

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            val density = LocalDensity.current
            CompositionLocalProvider(
                LocalDensity provides Density(density.density, min(density.fontScale, 1.08f))
            ) {
                HennessyTheme {
                    HennessyApp()
                }
            }
        }
    }
}

enum class DownloadMode(
    val title: String,
    val subtitle: String,
    val icon: ImageVector
) {
    BestAudio("最高质量音频", "保留源站提供的最佳音频格式", Icons.Rounded.GraphicEq),
    Mp3("MP3", "转换为高质量 MP3，兼容性更好", Icons.Rounded.MusicNote),
    Video("原质量视频", "最高质量视频与音频，默认 MKV", Icons.Rounded.Movie),
    VideoMp4("MP4 视频", "最高质量视频与音频，转换为可播放 MP4", Icons.Rounded.Movie);
}

enum class Section(val title: String, val icon: ImageVector) {
    Search("搜索", Icons.Rounded.Search),
    Download("下载", Icons.Rounded.ArrowDownward),
    Player("播放器", Icons.Rounded.LibraryMusic),
    History("历史", Icons.Rounded.Schedule)
}

data class LibraryItem(
    val id: String = UUID.randomUUID().toString(),
    val title: String,
    val sourceUrl: String,
    val path: String,
    val mode: DownloadMode,
    val addedAt: Long = System.currentTimeMillis(),
    val favorite: Boolean = false
) {
    val fileName: String get() = File(path).name
    val isVideo: Boolean get() = mode == DownloadMode.Video || mode == DownloadMode.VideoMp4
}

data class HistoryRecord(
    val title: String,
    val url: String,
    val mode: DownloadMode,
    val succeeded: Boolean,
    val createdAt: Long = System.currentTimeMillis()
)

data class MediaSearchResult(
    val id: String,
    val title: String,
    val url: String,
    val channel: String,
    val durationSeconds: Int
) {
    val durationText: String
        get() {
            if (durationSeconds <= 0) return "直播或未知时长"
            val hours = durationSeconds / 3600
            val minutes = (durationSeconds % 3600) / 60
            val seconds = durationSeconds % 60
            return if (hours > 0) {
                "$hours:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}"
            } else {
                "$minutes:${seconds.toString().padStart(2, '0')}"
            }
        }
}

data class AppState(
    val section: Section = Section.Download,
    val url: String = "",
    val mode: DownloadMode = DownloadMode.BestAudio,
    val titleOverride: String = "",
    val artistOverride: String = "",
    val allowPlaylist: Boolean = false,
    val isRunning: Boolean = false,
    val downloaderReady: Boolean = false,
    val status: String = "等待链接",
    val progress: Float? = null,
    val progressDetail: String = "",
    val log: String = "准备下载。",
    val error: String? = null,
    val library: List<LibraryItem> = emptyList(),
    val selectedItemId: String? = null,
    val history: List<HistoryRecord> = emptyList(),
    val repeatAll: Boolean = false,
    val searchQuery: String = "",
    val searchResults: List<MediaSearchResult> = emptyList(),
    val isSearching: Boolean = false,
    val searchError: String? = null
) {
    val canStart: Boolean get() = downloaderReady && !isRunning && url.trim().startsWith("http")
    val selectedItem: LibraryItem? get() = library.firstOrNull { it.id == selectedItemId } ?: library.firstOrNull()
}

class HennessyViewModel(application: Application) : AndroidViewModel(application) {
    private val appContext = application.applicationContext
    private val outputDir = File(
        application.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS) ?: application.filesDir,
        "Hennessy"
    )
    private val downloader = AndroidDownloader(outputDir)
    private val searchService = AndroidMediaSearchService()
    private var downloadJob: Job? = null
    private var searchJob: Job? = null

    private val _state = MutableStateFlow(AppState())
    val state: StateFlow<AppState> = _state.asStateFlow()

    init {
        outputDir.mkdirs()
        viewModelScope.launch(Dispatchers.IO) {
            try {
                _state.update { it.copy(status = "正在准备下载组件") }
                YoutubeDL.getInstance().init(appContext)
                FFmpeg.getInstance().init(appContext)
                runCatching {
                    YoutubeDL.getInstance().updateYoutubeDL(appContext, YoutubeDL.UpdateChannel.STABLE)
                }
                _state.update { it.copy(status = "已就绪", downloaderReady = true) }
            } catch (error: Exception) {
                _state.update {
                    it.copy(
                        status = "初始化失败",
                        downloaderReady = false,
                        error = "下载组件初始化失败，请确认网络后重启应用。",
                        log = error.localizedMessage ?: error.toString()
                    )
                }
            }
        }
    }

    fun selectSection(section: Section) = _state.update { it.copy(section = section) }
    fun updateUrl(value: String) = _state.update { it.copy(url = value) }
    fun updateMode(mode: DownloadMode) = _state.update { it.copy(mode = mode) }
    fun updateTitle(value: String) = _state.update { it.copy(titleOverride = value) }
    fun updateArtist(value: String) = _state.update { it.copy(artistOverride = value) }
    fun updatePlaylist(value: Boolean) = _state.update { it.copy(allowPlaylist = value) }
    fun toggleRepeatAll() = _state.update { it.copy(repeatAll = !it.repeatAll) }
    fun updateSearchQuery(value: String) = _state.update { it.copy(searchQuery = value) }

    fun toggleFavorite(item: LibraryItem) {
        _state.update { state ->
            state.copy(library = state.library.map {
                if (it.id == item.id) it.copy(favorite = !it.favorite) else it
            })
        }
    }

    fun selectItem(item: LibraryItem) {
        _state.update { it.copy(section = Section.Player, selectedItemId = item.id) }
    }

    fun useSearchResult(result: MediaSearchResult) {
        _state.update {
            it.copy(
                section = Section.Download,
                url = result.url,
                titleOverride = "",
                artistOverride = "",
                status = "已填入搜索结果",
                error = null
            )
        }
    }

    fun downloadSearchResult(result: MediaSearchResult, mode: DownloadMode) {
        _state.update {
            it.copy(
                section = Section.Download,
                url = result.url,
                titleOverride = "",
                artistOverride = "",
                mode = mode
            )
        }
        startDownload(playWhenDone = true)
    }

    fun searchMedia() {
        val query = _state.value.searchQuery.trim()
        if (query.isBlank() || _state.value.isSearching) return

        searchJob?.cancel()
        searchJob = viewModelScope.launch {
            _state.update {
                it.copy(isSearching = true, searchError = null, searchResults = emptyList(), status = "正在搜索媒体")
            }
            val result = searchService.search(query)
            _state.update {
                result.fold(
                    onSuccess = { results ->
                        it.copy(
                            isSearching = false,
                            searchResults = results,
                            searchError = if (results.isEmpty()) "没有找到可用结果。" else null,
                            status = "搜索完成"
                        )
                    },
                    onFailure = { error ->
                        it.copy(
                            isSearching = false,
                            searchError = error.localizedMessage ?: "搜索失败。",
                            status = "搜索失败"
                        )
                    }
                )
            }
        }
    }

    fun startDownload(playWhenDone: Boolean = false) {
        val snapshot = _state.value
        if (!snapshot.canStart) return

        downloadJob = viewModelScope.launch {
            _state.update {
                it.copy(
                    isRunning = true,
                    status = "正在下载",
                    progress = null,
                    progressDetail = "准备连接",
                    log = "",
                    error = null
                )
            }

            val request = DownloadSpec(
                url = snapshot.url.trim(),
                mode = snapshot.mode,
                titleOverride = snapshot.titleOverride.trim(),
                artistOverride = snapshot.artistOverride.trim(),
                allowPlaylist = snapshot.allowPlaylist
            )

            val result = downloader.download(request) { text, progress ->
                _state.update { state ->
                    state.copy(
                        log = trimLog(state.log + text),
                        progress = progress,
                        progressDetail = progress?.let { "${(it * 100).toInt()}%" } ?: parseProgressText(text, state.progressDetail)
                    )
                }
            }

            if (result.file != null) {
                val item = LibraryItem(
                    title = result.file.nameWithoutExtension,
                    sourceUrl = request.url,
                    path = result.file.absolutePath,
                    mode = request.mode
                )
                _state.update {
                    it.copy(
                        isRunning = false,
                        status = "下载完成",
                        progress = 1f,
                        progressDetail = "100%",
                        library = listOf(item) + it.library,
                        selectedItemId = item.id,
                        history = listOf(HistoryRecord(item.title, request.url, request.mode, true)) + it.history,
                        section = if (playWhenDone) Section.Player else it.section
                    )
                }
            } else {
                val readableError = summarizeDownloadFailure(result.error)
                _state.update {
                    it.copy(
                        isRunning = false,
                        status = "下载失败",
                        progress = null,
                        progressDetail = "",
                        error = readableError,
                        log = trimLog(it.log + "\n\n" + (result.error ?: "下载进程没有生成文件。")),
                        history = listOf(HistoryRecord(request.url, request.url, request.mode, false)) + it.history
                    )
                }
            }
        }
    }

    fun cancelDownload() {
        downloadJob?.cancel()
        downloader.cancel()
        _state.update {
            it.copy(
                isRunning = false,
                status = "已停止",
                progress = null,
                progressDetail = "",
                log = trimLog(it.log + "\n已停止当前下载。\n")
            )
        }
    }

    private fun parseProgressText(text: String, fallback: String): String {
        return when {
            text.contains("Extracting", ignoreCase = true) -> "解析链接"
            text.contains("Downloading", ignoreCase = true) -> fallback.ifBlank { "下载中" }
            text.contains("Post-process", ignoreCase = true) -> "正在处理文件"
            text.contains("Merging", ignoreCase = true) -> "合并音视频"
            else -> fallback
        }
    }

    private fun trimLog(value: String): String {
        return if (value.length <= 12_000) value else "已省略较早日志。\n" + value.takeLast(12_000)
    }

    private fun summarizeDownloadFailure(message: String?): String {
        val text = message.orEmpty()
        return when {
            text.contains("older than 90 days", ignoreCase = true) ||
                text.contains("QuickJS", ignoreCase = true) ||
                text.contains("challenge", ignoreCase = true) ->
                "YouTube 解析失败。应用已在启动时尝试更新 yt-dlp，请重新打开应用后再试。"
            text.contains("Sign in to confirm", ignoreCase = true) ->
                "该视频需要登录或验证，当前手机版暂时无法直接下载。"
            text.contains("Private video", ignoreCase = true) ->
                "这是私密视频，无法下载。"
            text.contains("Unsupported URL", ignoreCase = true) ->
                "暂不支持这个链接，请换一个视频链接。"
            text.isBlank() ->
                "下载进程没有生成文件。"
            else ->
                text.lineSequence().firstOrNull { it.contains("ERROR", ignoreCase = true) }?.take(140)
                    ?: "下载失败，请查看下方日志。"
        }
    }
}

data class DownloadSpec(
    val url: String,
    val mode: DownloadMode,
    val titleOverride: String,
    val artistOverride: String,
    val allowPlaylist: Boolean
)

data class DownloadOutcome(val file: File?, val error: String?)

class AndroidDownloader(private val outputDir: File) {
    private var activeRequestId: String? = null

    suspend fun download(
        spec: DownloadSpec,
        onProgress: suspend (String, Float?) -> Unit
    ): DownloadOutcome = withContext(Dispatchers.IO) {
        outputDir.mkdirs()
        val before = outputDir.listFiles()?.map { it.absolutePath }?.toSet().orEmpty()
        val requestId = "hennessy-${System.currentTimeMillis()}"
        activeRequestId = requestId

        val request = YoutubeDLRequest(spec.url).apply {
            addOption("--no-warnings")
            addOption("-o", File(outputDir, outputTemplate(spec)).absolutePath)
            if (!spec.allowPlaylist) addOption("--no-playlist")
            when (spec.mode) {
                DownloadMode.BestAudio -> {
                    addOption("-f", "bestaudio/best")
                    addOption("-x")
                    addOption("--embed-metadata")
                }
                DownloadMode.Mp3 -> {
                    addOption("-f", "bestaudio/best")
                    addOption("-x")
                    addOption("--audio-format", "mp3")
                    addOption("--audio-quality", "0")
                    addOption("--embed-metadata")
                }
                DownloadMode.Video -> addOption("-f", "bv*+ba/b")
                DownloadMode.VideoMp4 -> {
                    addOption("-f", "bv*+ba/b")
                    addOption("--merge-output-format", "mp4")
                }
            }
            if (spec.titleOverride.isNotBlank()) addOption("--parse-metadata", "title:${spec.titleOverride}")
            if (spec.artistOverride.isNotBlank()) addOption("--parse-metadata", "artist:${spec.artistOverride}")
        }

        try {
            YoutubeDL.getInstance().execute(request, requestId) { progress, etaInSeconds, line ->
                val eta = if (etaInSeconds > 0) " ETA ${etaInSeconds}s" else ""
                kotlinx.coroutines.runBlocking {
                    onProgress("\n$line$eta", (progress / 100f).coerceIn(0f, 1f))
                }
            }
            val output = outputDir.listFiles()
                ?.filter { it.isFile && it.absolutePath !in before }
                ?.maxByOrNull { it.lastModified() }
            DownloadOutcome(output, null)
        } catch (error: Exception) {
            DownloadOutcome(null, error.localizedMessage ?: error.toString())
        } finally {
            activeRequestId = null
        }
    }

    fun cancel() {
        activeRequestId?.let { YoutubeDL.getInstance().destroyProcessById(it) }
    }

    private fun outputTemplate(spec: DownloadSpec): String {
        val prefix = if (spec.titleOverride.isNotBlank()) sanitize(spec.titleOverride) else "%(title)s"
        return "$prefix.%(ext)s"
    }

    private fun sanitize(value: String): String {
        return value.replace(Regex("[\\\\/:*?\"<>|]"), "_").take(120)
    }
}

class AndroidMediaSearchService {
    suspend fun search(query: String, limit: Int = 20): Result<List<MediaSearchResult>> = withContext(Dispatchers.IO) {
        runCatching {
            val request = YoutubeDLRequest("ytsearch$limit:$query").apply {
                addOption("--dump-json")
                addOption("--flat-playlist")
                addOption("--playlist-end", limit)
            }
            val response = YoutubeDL.getInstance().execute(request, "search-${System.currentTimeMillis()}")
            response.out
                .lineSequence()
                .mapNotNull { parseSearchLine(it) }
                .distinctBy { it.url }
                .take(limit)
                .toList()
        }
    }

    private fun parseSearchLine(line: String): MediaSearchResult? {
        if (line.isBlank()) return null
        val json = runCatching { JSONObject(line) }.getOrNull() ?: return null
        val id = json.optString("id").ifBlank { json.optString("url") }
        val webpageUrl = json.optString("webpage_url")
        val url = when {
            webpageUrl.startsWith("http") -> webpageUrl
            id.isNotBlank() -> "https://www.youtube.com/watch?v=$id"
            else -> return null
        }
        val title = json.optString("title").ifBlank { return null }
        val channel = json.optString("channel").ifBlank { json.optString("uploader").ifBlank { "未知频道" } }
        return MediaSearchResult(
            id = id.ifBlank { url },
            title = title,
            url = url,
            channel = channel,
            durationSeconds = json.optInt("duration", 0)
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HennessyApp(viewModel: HennessyViewModel = viewModel()) {
    val state by viewModel.state.collectAsState()

    Scaffold(
        containerColor = Color.Transparent,
        contentWindowInsets = WindowInsets(0),
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text("Hennessy", fontSize = 25.sp, fontWeight = FontWeight.SemiBold, lineHeight = 28.sp)
                        Text(state.status, fontSize = 13.sp, color = Color(0xFF6E6E73), maxLines = 1, overflow = TextOverflow.Ellipsis)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.White.copy(alpha = 0.62f)),
                modifier = Modifier.statusBarsPadding()
            )
        },
        bottomBar = {
            GlassNavigation(
                selected = state.section,
                onSelect = viewModel::selectSection,
                modifier = Modifier.navigationBarsPadding()
            )
        }
    ) { padding ->
        LiquidBackdrop {
            AnimatedContent(
                targetState = state.section,
                label = "section",
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
            ) { section ->
                when (section) {
                    Section.Search -> SearchScreen(state, viewModel)
                    Section.Download -> DownloadScreen(state, viewModel)
                    Section.Player -> PlayerScreen(state, viewModel)
                    Section.History -> HistoryScreen(state)
                }
            }
        }
    }
}

@Composable
fun SearchScreen(state: AppState, viewModel: HennessyViewModel) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(18.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        item {
            GlassPanel {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    Icon(Icons.Rounded.Search, contentDescription = null, tint = Color(0xFF1C1C1E), modifier = Modifier.size(32.dp))
                    Column(Modifier.weight(1f)) {
                        Text("媒体搜索", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.SemiBold)
                        Text("搜索音乐、MV、演出和视频", color = Color(0xFF6E6E73))
                    }
                }
                Spacer(Modifier.height(14.dp))
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    OutlinedTextField(
                        value = state.searchQuery,
                        onValueChange = viewModel::updateSearchQuery,
                        placeholder = { Text("输入关键词") },
                        modifier = Modifier.weight(1f),
                        singleLine = true
                    )
                    Button(
                        onClick = viewModel::searchMedia,
                        enabled = state.searchQuery.trim().isNotEmpty() && !state.isSearching,
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF1C1C1E))
                    ) {
                        if (state.isSearching) {
                            CircularProgressIndicator(Modifier.size(18.dp), strokeWidth = 2.dp, color = Color.White)
                        } else {
                            Icon(Icons.Rounded.Search, contentDescription = null)
                        }
                    }
                }
                state.searchError?.let {
                    Spacer(Modifier.height(10.dp))
                    Text(it, color = Color(0xFFB3261E), style = MaterialTheme.typography.bodySmall)
                }
            }
        }

        if (state.isSearching) {
            item {
                GlassPanel {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        CircularProgressIndicator(Modifier.size(22.dp), strokeWidth = 2.dp)
                        Text("正在搜索...", color = Color(0xFF6E6E73))
                    }
                }
            }
        } else if (state.searchResults.isEmpty()) {
            item {
                GlassPanel {
                    EmptyState("搜索音乐或视频", "输入关键词后，选择结果填入下载链接，或直接下载音乐/视频。")
                }
            }
        } else {
            items(state.searchResults, key = { it.id }) { result ->
                SearchResultRow(
                    result = result,
                    isRunning = state.isRunning,
                    onUse = { viewModel.useSearchResult(result) },
                    onAudio = { viewModel.downloadSearchResult(result, DownloadMode.BestAudio) },
                    onVideo = { viewModel.downloadSearchResult(result, DownloadMode.VideoMp4) }
                )
            }
        }
    }
}

@Composable
fun DownloadScreen(state: AppState, viewModel: HennessyViewModel) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 14.dp, vertical = 12.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            GlassPanel {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    Icon(if (state.isRunning) Icons.Rounded.ArrowDownward else Icons.Rounded.GraphicEq, contentDescription = null, tint = Color(0xFF007AFF), modifier = Modifier.size(28.dp))
                    Column(Modifier.weight(1f)) {
                        Text("媒体下载", fontSize = 22.sp, lineHeight = 26.sp, fontWeight = FontWeight.SemiBold)
                        Text(state.status, fontSize = 14.sp, color = Color(0xFF6E6E73), maxLines = 1)
                    }
                    if (state.isRunning) {
                        IconButton(onClick = viewModel::cancelDownload) {
                            Icon(Icons.Rounded.Stop, contentDescription = "停止")
                        }
                    } else {
                        Button(
                            onClick = { viewModel.startDownload() },
                            enabled = state.canStart,
                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF007AFF))
                        ) {
                            Icon(Icons.Rounded.ArrowDownward, contentDescription = null)
                            Spacer(Modifier.width(4.dp))
                            Text(if (state.downloaderReady) "开始" else "准备中", fontSize = 14.sp)
                        }
                    }
                }
                if (state.isRunning || state.progress != null) {
                    Spacer(Modifier.height(12.dp))
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        if (state.progress == null) {
                            CircularProgressIndicator(Modifier.size(18.dp), strokeWidth = 2.dp)
                        } else {
                            LinearProgressIndicator(progress = { state.progress }, modifier = Modifier.weight(1f))
                        }
                        Text(state.progressDetail.ifBlank { "准备中" }, fontSize = 12.sp, color = Color(0xFF6E6E73))
                    }
                }
                state.error?.let {
                    Spacer(Modifier.height(12.dp))
                    FailureNotice(it)
                }
            }
        }

        item {
            GlassPanel {
                FieldHeader(Icons.Rounded.Link, "链接")
                OutlinedTextField(
                    value = state.url,
                    onValueChange = viewModel::updateUrl,
                    placeholder = { Text("粘贴 YouTube、Bilibili 或 yt-dlp 支持的网页链接") },
                    modifier = Modifier.fillMaxWidth(),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Uri),
                    singleLine = false,
                    maxLines = 3
                )
                Spacer(Modifier.height(12.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Rounded.Folder, contentDescription = null, tint = Color(0xFF6E6E73))
                    Spacer(Modifier.width(8.dp))
                    Text("应用下载目录 / Hennessy", color = Color(0xFF6E6E73), modifier = Modifier.weight(1f))
                    Switch(checked = state.allowPlaylist, onCheckedChange = viewModel::updatePlaylist)
                }
                Text("允许播放列表", style = MaterialTheme.typography.labelMedium, color = Color(0xFF6E6E73))
            }
        }

        item {
            GlassPanel {
                FieldHeader(Icons.Rounded.GraphicEq, "格式")
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    DownloadMode.values().forEach { mode: DownloadMode ->
                        ModeRow(mode, selected = state.mode == mode) { viewModel.updateMode(mode) }
                    }
                }
            }
        }

        item {
            GlassPanel {
                FieldHeader(Icons.Rounded.MusicNote, "可选命名")
                OutlinedTextField(
                    value = state.titleOverride,
                    onValueChange = viewModel::updateTitle,
                    placeholder = { Text("标题，默认自动识别") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                Spacer(Modifier.height(10.dp))
                OutlinedTextField(
                    value = state.artistOverride,
                    onValueChange = viewModel::updateArtist,
                    placeholder = { Text("作者，默认自动识别") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
            }
        }

        item {
            GlassPanel {
                Text("技术日志", fontSize = 15.sp, fontWeight = FontWeight.SemiBold)
                Spacer(Modifier.height(8.dp))
                Text(
                    state.log.ifBlank { "等待输出。" },
                    fontSize = 11.sp,
                    lineHeight = 15.sp,
                    color = Color(0xFF3A3A3C),
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(150.dp)
                        .verticalScroll(rememberScrollState())
                )
            }
        }
    }
}

@Composable
fun FailureNotice(message: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(Color(0xFFFFF2F2))
            .padding(12.dp),
        verticalAlignment = Alignment.Top,
        horizontalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Icon(Icons.Rounded.Stop, contentDescription = null, tint = Color(0xFFB3261E), modifier = Modifier.size(18.dp))
        Column(Modifier.weight(1f)) {
            Text("下载没有完成", fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = Color(0xFF8C1D18))
            Spacer(Modifier.height(3.dp))
            Text(message, fontSize = 12.sp, lineHeight = 16.sp, color = Color(0xFF8C1D18), maxLines = 3, overflow = TextOverflow.Ellipsis)
        }
    }
}

@Composable
fun SearchResultRow(
    result: MediaSearchResult,
    isRunning: Boolean,
    onUse: () -> Unit,
    onAudio: () -> Unit,
    onVideo: () -> Unit
) {
    GlassPanel {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Box(
                modifier = Modifier
                    .size(width = 78.dp, height = 54.dp)
                    .clip(RoundedCornerShape(14.dp))
                    .background(Color.White.copy(alpha = 0.66f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(Icons.Rounded.PlayArrow, contentDescription = null, tint = Color(0xFF1C1C1E))
            }
            Column(Modifier.weight(1f)) {
                Text(result.title, maxLines = 2, overflow = TextOverflow.Ellipsis, fontWeight = FontWeight.SemiBold)
                Spacer(Modifier.height(3.dp))
                Text("${result.channel} · ${result.durationText}", color = Color(0xFF6E6E73), style = MaterialTheme.typography.bodySmall)
                Text(result.url, maxLines = 1, overflow = TextOverflow.Ellipsis, color = Color(0xFF8A8F98), style = MaterialTheme.typography.labelSmall)
            }
        }
        Spacer(Modifier.height(12.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth()) {
            TextButton(onClick = onUse, modifier = Modifier.weight(1f)) {
                Icon(Icons.Rounded.Link, contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(4.dp))
                Text("使用链接")
            }
            TextButton(onClick = onAudio, enabled = !isRunning, modifier = Modifier.weight(1f)) {
                Icon(Icons.Rounded.MusicNote, contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(4.dp))
                Text("音乐")
            }
            TextButton(onClick = onVideo, enabled = !isRunning, modifier = Modifier.weight(1f)) {
                Icon(Icons.Rounded.Movie, contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(4.dp))
                Text("视频")
            }
        }
    }
}

@Composable
fun PlayerScreen(state: AppState, viewModel: HennessyViewModel) {
    val context = LocalContext.current
    val player = remember {
        ExoPlayer.Builder(context).build().apply {
            repeatMode = Player.REPEAT_MODE_OFF
        }
    }

    DisposableEffect(Unit) {
        onDispose { player.release() }
    }

    LaunchedEffect(state.selectedItem?.path) {
        state.selectedItem?.let {
            player.setMediaItem(MediaItem.fromUri(File(it.path).toURI().toString()))
            player.prepare()
            player.playWhenReady = true
        }
    }

    LaunchedEffect(state.repeatAll) {
        player.repeatMode = if (state.repeatAll) Player.REPEAT_MODE_ALL else Player.REPEAT_MODE_OFF
    }

    var currentPosition by remember { mutableStateOf(0L) }
    var duration by remember { mutableStateOf(0L) }
    LaunchedEffect(player) {
        while (true) {
            currentPosition = player.currentPosition.coerceAtLeast(0)
            duration = player.duration.coerceAtLeast(0)
            delay(500)
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(18.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        GlassPanel(modifier = Modifier.weight(1f)) {
            val item = state.selectedItem
            if (item == null) {
                EmptyState("暂无媒体", "下载完成的音频和视频会出现在这里。")
            } else {
                Text(item.title, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.SemiBold, maxLines = 2)
                Text(item.fileName, color = Color(0xFF6E6E73), maxLines = 1, overflow = TextOverflow.Ellipsis)
                Spacer(Modifier.height(16.dp))
                if (item.isVideo) {
                    AndroidView(
                        factory = { context ->
                            androidx.media3.ui.PlayerView(context).also { view ->
                                view.player = player
                                view.useController = true
                            }
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .aspectRatio(16 / 9f)
                            .clip(RoundedCornerShape(24.dp))
                    )
                } else {
                    AudioStage(isPlaying = player.isPlaying)
                }
                Spacer(Modifier.height(16.dp))
                Slider(
                    value = currentPosition.toFloat(),
                    onValueChange = { player.seekTo(it.toLong()) },
                    valueRange = 0f..duration.coerceAtLeast(1).toFloat()
                )
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(formatMillis(currentPosition), color = Color(0xFF6E6E73))
                    Spacer(Modifier.weight(1f))
                    IconButton(onClick = { player.seekTo(0); player.play() }) {
                        Icon(Icons.Rounded.Replay, contentDescription = "从头播放")
                    }
                    IconButton(onClick = { if (player.isPlaying) player.pause() else player.play() }) {
                        Icon(if (player.isPlaying) Icons.Rounded.Pause else Icons.Rounded.PlayArrow, contentDescription = "播放")
                    }
                    IconButton(onClick = viewModel::toggleRepeatAll) {
                        Icon(Icons.Rounded.Repeat, contentDescription = "列表循环", tint = if (state.repeatAll) Color(0xFF007AFF) else Color(0xFF6E6E73))
                    }
                    Spacer(Modifier.weight(1f))
                    Text(formatMillis(duration), color = Color(0xFF6E6E73))
                }
            }
        }

        GlassPanel(modifier = Modifier.height(220.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("播放列表", fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                Text("${state.library.size} 项", color = Color(0xFF6E6E73))
            }
            Spacer(Modifier.height(8.dp))
            LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                items(state.library, key = { item: LibraryItem -> item.id }) { item: LibraryItem ->
                    LibraryRow(item, selected = state.selectedItemId == item.id, onSelect = { viewModel.selectItem(item) }, onFavorite = { viewModel.toggleFavorite(item) })
                }
            }
        }
    }
}

@Composable
fun HistoryScreen(state: AppState) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(18.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        if (state.history.isEmpty()) {
            item { GlassPanel { EmptyState("暂无历史", "下载任务完成后会显示在这里。") } }
        } else {
            items(state.history) { record ->
                GlassPanel {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(record.mode.icon, contentDescription = null, tint = if (record.succeeded) Color(0xFF007AFF) else Color(0xFFB3261E))
                        Spacer(Modifier.width(12.dp))
                        Column(Modifier.weight(1f)) {
                            Text(record.title, maxLines = 1, overflow = TextOverflow.Ellipsis, fontWeight = FontWeight.SemiBold)
                            Text(record.url, maxLines = 1, overflow = TextOverflow.Ellipsis, color = Color(0xFF6E6E73), style = MaterialTheme.typography.bodySmall)
                        }
                        Text(dateText(record.createdAt), color = Color(0xFF6E6E73), style = MaterialTheme.typography.labelMedium)
                    }
                }
            }
        }
    }
}

@Composable
fun GlassNavigation(selected: Section, onSelect: (Section) -> Unit, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 14.dp, vertical = 8.dp)
            .clip(RoundedCornerShape(30.dp))
            .background(Color.White.copy(alpha = 0.78f))
            .padding(horizontal = 6.dp, vertical = 5.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Section.values().forEach { section ->
            val active = selected == section
            Column(
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(24.dp))
                    .background(if (active) Color.White.copy(alpha = 0.92f) else Color.Transparent)
                    .clickable { onSelect(section) }
                    .padding(vertical = 7.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Icon(section.icon, contentDescription = section.title, tint = if (active) Color(0xFF007AFF) else Color(0xFF6E6E73), modifier = Modifier.size(24.dp))
                Spacer(Modifier.height(2.dp))
                Text(section.title, fontSize = 11.sp, lineHeight = 12.sp, maxLines = 1, color = if (active) Color(0xFF007AFF) else Color(0xFF6E6E73))
            }
        }
    }
}

@Composable
fun GlassPanel(modifier: Modifier = Modifier, content: @Composable ColumnScope.() -> Unit) {
    Surface(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(24.dp),
        color = Color.White.copy(alpha = 0.74f),
        border = BorderStroke(1.dp, Color.White.copy(alpha = 0.86f)),
        shadowElevation = 0.dp
    ) {
        Column(Modifier.padding(15.dp), content = content)
    }
}

@Composable
fun LiquidBackdrop(content: @Composable () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    listOf(
                        Color(0xFFF7F8FA),
                        Color(0xFFFFFFFF),
                        Color(0xFFF1F3F6)
                    )
                )
            )
    ) {
        content()
    }
}

@Composable
fun FieldHeader(icon: ImageVector, title: String) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, contentDescription = null, tint = Color(0xFF007AFF))
        Spacer(Modifier.width(8.dp))
        Text(title, fontWeight = FontWeight.SemiBold)
    }
    Spacer(Modifier.height(12.dp))
}

@Composable
fun ModeRow(mode: DownloadMode, selected: Boolean, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(if (selected) Color.White.copy(alpha = 0.82f) else Color.White.copy(alpha = 0.36f))
            .clickable(onClick = onClick)
            .padding(14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(mode.icon, contentDescription = null, tint = Color(0xFF007AFF))
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text(mode.title, fontWeight = FontWeight.SemiBold)
            Text(mode.subtitle, color = Color(0xFF6E6E73), style = MaterialTheme.typography.bodySmall)
        }
    }
}

@Composable
fun LibraryRow(item: LibraryItem, selected: Boolean, onSelect: () -> Unit, onFavorite: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(if (selected) Color.White.copy(alpha = 0.82f) else Color.White.copy(alpha = 0.36f))
            .clickable(onClick = onSelect)
            .padding(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(item.mode.icon, contentDescription = null, tint = Color(0xFF007AFF))
        Spacer(Modifier.width(10.dp))
        Column(Modifier.weight(1f)) {
            Text(item.title, maxLines = 1, overflow = TextOverflow.Ellipsis, fontWeight = FontWeight.SemiBold)
            Text(item.fileName, maxLines = 1, overflow = TextOverflow.Ellipsis, color = Color(0xFF6E6E73), style = MaterialTheme.typography.bodySmall)
        }
        IconButton(onClick = onFavorite) {
            Icon(if (item.favorite) Icons.Rounded.Favorite else Icons.Rounded.FavoriteBorder, contentDescription = "收藏")
        }
    }
}

@Composable
fun AudioStage(isPlaying: Boolean) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(220.dp)
            .clip(RoundedCornerShape(28.dp))
            .background(Brush.linearGradient(listOf(Color(0xFF007AFF), Color(0xFFDDE8F7), Color(0xFF8E8E93)))),
        contentAlignment = Alignment.Center
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
            repeat(17) { index ->
                val height = if (isPlaying) 28 + ((index * 13) % 72) else 28
                Box(
                    modifier = Modifier
                        .width(7.dp)
                        .height(height.dp)
                        .clip(RoundedCornerShape(10.dp))
                        .background(Color.White.copy(alpha = 0.76f))
                )
            }
        }
    }
}

@Composable
fun EmptyState(title: String, body: String) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 42.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(Icons.Rounded.LibraryMusic, contentDescription = null, tint = Color(0xFF6E6E73), modifier = Modifier.size(42.dp))
        Spacer(Modifier.height(12.dp))
        Text(title, fontWeight = FontWeight.SemiBold)
        Text(body, color = Color(0xFF6E6E73))
    }
}

@Composable
fun HennessyTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = androidx.compose.material3.lightColorScheme(
            primary = Color(0xFF007AFF),
            secondary = Color(0xFF8E8E93),
            background = Color(0xFFF7FBFA),
            surface = Color.White
        ),
        content = content
    )
}

fun formatMillis(value: Long): String {
    if (value <= 0) return "0:00"
    val total = value / 1000
    return "${total / 60}:${(total % 60).toString().padStart(2, '0')}"
}

fun dateText(value: Long): String {
    return SimpleDateFormat("MM-dd HH:mm", Locale.getDefault()).format(Date(value))
}
