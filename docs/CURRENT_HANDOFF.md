# 项目交接文档

> 本文档由 AI 编码助手（Qoder/Codex）在每次任务结束时更新，用于跨对话上下文同步。

---

## 最新更新：2026-07-31 19:13（Asia/Shanghai）

### 最近完成
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
- 公开源码已同步为 `1.7.19 (189)`，等待提交和 GitHub Release 验证。
- 私有/公开 Swift 各 32 项测试、Android 单测/Lint/APK、macOS Release/DMG、凭据路径扫描和精确许可证检查均已通过。
- GitHub Release 已发布并验证源码归档；DMG 未捆绑第三方工具，未上传二进制附件。

### 下一步
- 收集可调侧栏与播放器磨砂玻璃在不同壁纸和显示设置下的用户反馈。
- 如需分发二进制安装包，先登录 `gh`，再上传已验证的 macOS DMG；Android Debug APK 不作为 Release 附件。

### 阻塞/待确认
- 无。

### 不可破坏的决定
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
- `Sources/Hennessy/Support/AppleMusicDesignSystem.swift`
- `Sources/Hennessy/Support/ViewModifiers.swift`
- `Sources/Hennessy/Views/ContentView.swift`
- `Sources/Hennessy/Views/SidebarView.swift`
- `VERSION`、`BUILD_NUMBER`
- `CHANGELOG.md`、`RELEASE_NOTES.md`
- `docs/CURRENT_HANDOFF.md`

### 生产环境变更
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
