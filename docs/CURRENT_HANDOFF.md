# 项目交接文档

> 本文档由 AI 编码助手（Qoder/Codex）在每次任务结束时更新，用于跨对话上下文同步。

---

## 最新更新：2026-07-31 15:23（Asia/Shanghai）

### 最近完成
- 收窄 macOS 侧栏并降低标题、间距、圆角和面板高光强度。
- 将下载页头部改为平整内容标题区，格式卡片与通用内容面板改为更紧凑的弱边框层次。
- 将迷你播放器改为贴底全宽控制栏，按“歌曲信息 / 播放控制 / 工具”分区，并突出主播放按钮。
- 在真实窗口中验证桌面透视、经典玻璃和最小窗口宽度。

### 当前状态
- 公开源码已发布为 `1.7.15 (185)`。
- 私有/公开 Swift 各 32 项测试、Android 单测/Lint/APK、macOS Release/DMG、凭据路径扫描和精确许可证检查均已通过。
- GitHub Release 已发布源码归档；已验证 DMG 未捆绑第三方工具，暂未上传二进制附件。

### 下一步
- 收集新侧栏、内容面板和贴底播放器在不同壁纸与显示设置下的用户反馈。
- 如需分发二进制安装包，先登录 `gh`，再上传已验证的 macOS DMG；Android Debug APK 不作为 Release 附件。

### 阻塞/待确认
- 无。

### 不可破坏的决定
- 视觉升级只改变界面层次与布局，不改变下载模式、快捷键、播放语义或无障碍标识。
- 迷你播放器保持贴底全宽，并按左侧歌曲、中间播放、右侧工具的稳定分区布局。
- 透明皮肤不得通过降低整个窗口 `alphaValue` 实现；只调整窗口底材和内容遮罩，确保文字与控件可读。
- 桌面透视侧栏不得叠加独立材质；使用整窗透视底材并清除系统窗口容器背景。
- 系统开启“降低透明度”时必须回退到经典玻璃背景。
- 完整播放器仅在“桌面透视”且系统未启用“降低透明度”时使用透明遮罩；其他状态保留原背景。

### 涉及文件
- `Sources/Hennessy/Support/AppleMusicDesignSystem.swift`
- `Sources/Hennessy/Views/ContentView.swift`
- `Sources/Hennessy/Views/DownloadFormView.swift`
- `Sources/Hennessy/Views/SidebarView.swift`
- `VERSION`、`BUILD_NUMBER`
- `CHANGELOG.md`、`RELEASE_NOTES.md`
- `docs/CURRENT_HANDOFF.md`

### 生产环境变更
- 公开提交 `564a0ca` 已推送；注解标签 `v1.7.15` 与 GitHub Release 已验证。
- Release：https://github.com/Bananainkl/Project_Hennessy-open-source/releases/tag/v1.7.15（源码归档发布，无二进制附件）。
- 已验证 DMG SHA-256：`1e8e71b19c233c6ba4c14da30143deef4236ba2d019123dcb0afa2e0552940d1`。
- 已验证 Debug APK SHA-256：`1d7dcbe54d135dcb18586a4b1321517360e006ddac6dc3e55f712c0973fce36b`，不作为 Release 附件发布。
- GitHub 源码归档已验证：tar.gz `98b285e8153b151ac3ca0f8d2ae8fd2903d6354b0606e9cb9b374976aed03c7e`，zip `b071e522c1f65f9270cbf672c80f65a28292bbdebe0de7e8fbb920c6a3919ead`。

---

<!-- 以下为历史交接记录，最新的在最上面 -->
