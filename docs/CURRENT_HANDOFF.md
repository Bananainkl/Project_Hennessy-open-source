# 项目交接文档

> 本文档由 AI 编码助手（Qoder/Codex）在每次任务结束时更新，用于跨对话上下文同步。

## 最新更新：2026-11-02

### 最近完成
- 修复歌单下载文件名冲突，并让单次歌单下载保留、记录和导入每个完成的媒体文件。
- 损坏的资料库 JSON 不再被空数组覆盖；取消下载不会作为失败处理。
- 搜索进程并发读取 stdout/stderr，避免大输出卡住子进程。
- 删除 Android 项目和未来 APK 构建/回填工作流；新的 GitHub Release 只提供 macOS DMG。
- 发布版本文件和说明更新为 `1.7.21 (191)`。

### 当前状态
- 私有与公开源代码都已通过 39 项 Swift 测试及 `./script/build_and_run.sh --verify`。
- macOS `1.7.21 (191)` arm64 DMG 已校验镜像、adhoc 签名和版本，包内不含第三方命令行工具；SHA-256：`8c610ee551e82a96ef4a0260c0644e57843738d76b1cf3823a8900c28ec3c42e`。
- 代码已提交并推送到公开 `main`（`feef243`）；尚未创建或发布 `v1.7.21`，历史 GitHub Release 与 Android 附件保持原样。

### 下一步
- 当前无待完成代码工作；只有完成远程 Release 验证后才创建发布标签。公开敏感路径/密钥样式扫描无命中，Android 构建入口扫描仅命中历史说明。

### 不可破坏的决定
- Hennessy 仅支持 macOS；不再构建或发布 Android 工件，但保留历史发布。
- 不能因资料库解码失败而覆盖原始 JSON；取消操作不记为失败。

---

## 最新更新：2026-08-12 22:19（Asia/Hong_Kong）

### 最近完成
- 为 `v1.7.12` 至 `v1.7.19` 八个历史 Release 逐版从对应标签构建并补传 DMG、Android arm64 APK 与 SHA-256 校验文件。
- 八个历史回填任务全部成功；线上回下载复验确认每版校验和、DMG 镜像、arm64 架构、包内版本、代码签名与 APK 签名/版本均正确。
- 将历史回填工作流收口为仅手动触发，避免普通提交意外重复上传。
- 修复 GitHub Release 只发布源码、不上传安装包的问题；标签发布现在自动构建并上传 macOS DMG、Android arm64 APK 与 SHA-256 校验文件。
- 发布 `1.7.20 (190)`，并从 GitHub 下载三个线上附件完成校验和、DMG 镜像、APK 签名与版本复验。
- 发布工作流固定使用 arm64 `macos-15` Runner 和 Xcode 26.2，以支持项目中的 macOS 26 玻璃 API。
- 修复全屏播放器隐藏工具栏后原生窗口控制上移的问题：记录并恢复主界面的窗口坐标，同时将下拉箭头与交通灯垂直居中对齐。
- 全屏播放器改为保留原生红黄绿窗口控制，只隐藏常规工具栏；交通灯右侧保留单一下拉返回按钮，移除重复双按钮胶囊。
- 为贴边侧栏加入 188-360pt 拖动调宽、跨启动持久化、无障碍增减操作和双击复位；按用户确认将默认值设为 195pt。
- 移除侧栏右侧常驻分隔线，仅在鼠标悬停拖动区域时显示细微强调色提示。
- 将底部播放器高度从 72pt 增加到 84pt，并在桌面透视模式恢复可见的系统磨砂玻璃材质。
- 移除侧栏导航按钮的持久蓝色焦点框，并提高桌面透视模式下品牌文字的对比度。
- 将 macOS 26 自动生成悬浮圆角效果的 `NavigationSplitView` 替换为贴边内联侧栏，并保留显式工具栏折叠按钮。
- 侧栏改为更紧凑的品牌行与导航分组，桌面透视使用无模糊的深色对比遮罩。
- 将底部播放器提升到根视图，使其横跨侧栏与内容区；真实验证了展开、折叠和恢复状态。
- 收窄 macOS 侧栏并降低标题、间距、圆角和面板高光强度。
- 将下载页头部改为平整内容标题区，格式卡片与通用内容面板改为更紧凑的弱边框层次。
- 将迷你播放器改为贴底全宽控制栏，按“歌曲信息 / 播放控制 / 工具”分区，并突出主播放按钮。
- 在真实窗口中验证桌面透视、经典玻璃和最小窗口宽度。

### 当前状态
- 公开源码与安装包已发布为 `1.7.20 (190)`。
- 私有/公开 Swift 各 32 项测试、Android 单测/Lint/APK、macOS Release/DMG、凭据路径扫描和精确许可证检查均已通过。
- GitHub `v1.7.12` 至 `v1.7.20` 九个 Release 均已包含并验证 macOS DMG、Android arm64 Debug APK、SHA-256 校验文件和源码归档。

### 下一步
- 收集可调侧栏与播放器磨砂玻璃在不同壁纸和显示设置下的用户反馈。
- 获取 Apple Developer ID 并接入公证，替换当前 macOS 临时签名包；为 Android 配置正式 Release 签名后替换 Debug APK。

### 阻塞/待确认
- 安装包已可下载；正式免警告分发仍需要 Apple Developer ID/公证凭据和 Android Release 签名密钥。
- `v1.7.12` 保留其标签源码中的 Android API 版本 Lint 历史警告；从 `v1.7.13` 起已修复，未用新版代码冒充旧版包。

### 不可破坏的决定
- 每个后续公开版本必须由标签工作流上传 DMG、APK 和 `SHA256SUMS.txt`，并在 Release 中明确披露签名级别。
- 构建包含 macOS 26 API 的版本时必须显式选择 Xcode 26.2 或兼容的新版本，不能退回默认 Xcode 16 工具链。
- 全屏播放器必须使用 AppKit 原生红黄绿窗口控制；常规工具栏隐藏时仍需保持交通灯可见并维持主界面坐标，下拉箭头与交通灯中心线对齐。
- 侧栏默认宽度为用户确认的 195pt，可在 188-360pt 范围内拖动并持久化；常驻分隔线不得恢复。
- 桌面透视模式的底部播放器必须保留可见磨砂玻璃，播放器高度保持 84pt。
- 侧栏按钮保留键盘焦点能力但不绘制持久蓝框；桌面透视下品牌文字必须保持浅色高对比。
- 视觉升级只改变界面层次与布局，不改变下载模式、快捷键、播放语义或无障碍标识。
- 主侧栏不得恢复为 `NavigationSplitView` 的系统悬浮样式；保持贴边内联布局与显式折叠控制。
- 迷你播放器保持贴底全宽，并按左侧歌曲、中间播放、右侧工具的稳定分区布局。
- 透明皮肤不得通过降低整个窗口 `alphaValue` 实现；只调整窗口底材和内容遮罩，确保文字与控件可读。
- 桌面透视侧栏不得叠加独立材质；使用整窗透视底材并清除系统窗口容器背景。
- 系统开启“降低透明度”时必须回退到经典玻璃背景。
- 完整播放器仅在“桌面透视”且系统未启用“降低透明度”时使用透明遮罩；其他状态保留原背景。

### 涉及文件
- `.github/workflows/release.yml`
- `.github/workflows/backfill-installers.yml`
- `docs/PROJECT_CONTEXT.md`
- `Sources/Hennessy/Support/AppleMusicDesignSystem.swift`
- `Sources/Hennessy/Support/ViewModifiers.swift`
- `Sources/Hennessy/Views/ContentView.swift`
- `Sources/Hennessy/Views/SidebarView.swift`
- `VERSION`、`BUILD_NUMBER`
- `CHANGELOG.md`、`RELEASE_NOTES.md`
- `docs/CURRENT_HANDOFF.md`

### 生产环境变更
- 公开提交 `2ae5e08` 已推送；历史回填工作流 https://github.com/Bananainkl/Project_Hennessy-open-source/actions/runs/31604268921 的八个子任务全部成功。
- `v1.7.12` 至 `v1.7.20` 每个 Release 均经 API 核对为三个附件；`v1.7.12` 至 `v1.7.19` 的 24 个历史附件已全部回下载复验。
- 公开提交 `ff5debe`、`d38a9c6`、`8b07a14`、`8d8fdb8`、`cf667ca` 已推送；公开注解标签 `v1.7.20` 最终指向 `cf667ca`。
- Release：https://github.com/Bananainkl/Project_Hennessy-open-source/releases/tag/v1.7.20，含三个已验证附件。
- 线上 DMG SHA-256：`0830020435857aeeef0a54d5f5c88d180ea42882050536ce22125a5465a635bf`。
- 线上 Android APK SHA-256：`a0da8ddf99752e43fdd8f701487135f0545f97d33cd1c59d67daaef8c2a66597`。
- DMG 为 arm64、临时签名且未公证；APK 为 arm64 Debug v2 签名，Release Notes 已明确披露。
- 公开提交 `0ac8b38` 已推送；注解标签 `v1.7.19` 指向 `0ac8b38`。
- Release：https://github.com/Bananainkl/Project_Hennessy-open-source/releases/tag/v1.7.19（源码归档发布，无二进制附件）。
- 已验证 DMG SHA-256：`dc37067a5d5d033d53ce184ba97c52d84058f2d4bf357b0bf5fbb477112f26c8`。
- 已验证 Debug APK SHA-256：`40dc706829683897e3d72f5780d822b7cc95fba62cd5a6601a607d25a41964b0`，不作为 Release 附件发布。
- GitHub 源码归档已验证：tar.gz `9a155307e18618d77859720ee0963f8c31b98c671ac65aeea1690f7880bed113`，zip `04e960d6f263a2d77c62c7bec81eb0fd9f3b9599b5cccb9123d5cbf778e2e4ed`。
- 公开提交 `fe1aadd` 已推送；注解标签 `v1.7.18` 指向 `fe1aadd`。
- Release：https://github.com/Bananainkl/Project_Hennessy-open-source/releases/tag/v1.7.18（源码归档发布，无二进制附件）。
- 已验证 DMG SHA-256：`1321f53ee410dbccd0ba95db73f9a4af8ae0d37811ad82434e73d82cb81c5ebd`。
- 已验证 Debug APK SHA-256：`f4865fb68fe230dabd81271cba2d6b948ea13be14a678146fca3f72098e5b999`，不作为 Release 附件发布。
- GitHub 源码归档已验证：tar.gz `d5881fcf1e62f635d88f437f0d87c0de71fc2fcafe17aeebb4beb6d3af4e058f`，zip `4bdfb130d24e04a2b7a1689c9e1c033537d07f28667a07477bb56cf6c49a75bf`。
- 公开提交 `0746613`、`b192d23` 已推送；注解标签 `v1.7.17` 指向 `b192d23`。
- Release：https://github.com/Bananainkl/Project_Hennessy-open-source/releases/tag/v1.7.17（源码归档发布，无二进制附件）。
- 已验证 DMG SHA-256：`c579f646fad6057b4c74deb789178e1a75d7b5f6309522d8dfe65371046af844`。
- 已验证 Debug APK SHA-256：`da279c8844eddee19cadf32f7a22d04bd2c0b4f94e1082d6df4310c564592d43`，不作为 Release 附件发布。
- GitHub 源码归档已验证：tar.gz `7c0c86ce84ea2a9ea5cba07c395d67922d9a81a3a4dd474e7853a7e25577c4b4`，zip `48d23fb0bc6fa7c936418cbc34878b033e4c7a0ed36db0eaddfcfb3a3b3dac0b`。
- 公开提交 `f794d04` 已推送；注解标签 `v1.7.16` 与 GitHub Release 已验证。
- Release：https://github.com/Bananainkl/Project_Hennessy-open-source/releases/tag/v1.7.16（源码归档发布，无二进制附件）。
- 已验证 DMG SHA-256：`8b5d637a27f9bb1e711c8be800cd14c0245163510a30283e662fc0a452c0b0d8`。
- 已验证 Debug APK SHA-256：`7532894bd65b5bc9aed5b7cb4dbe20a9063d8156b523cac4fbe7fbf76b746329`，不作为 Release 附件发布。
- GitHub 源码归档已验证：tar.gz `1c0e7e291ba998f6a921339b510159701a3bbd75e91ae55a02bc47f8fb950fd3`，zip `5608ddf68bd9e9d311e307ed01080b1a2f4e2c329a1dc743642389ff64c41b46`。

---

<!-- 以下为历史交接记录，最新的在最上面 -->
