# 项目交接文档

> 本文档由 AI 编码助手（Qoder/Codex）在每次任务结束时更新，用于跨对话上下文同步。

---

## 最新更新：2026-07-31 14:41（Asia/Shanghai）

### 最近完成
- 将 macOS“桌面透视”皮肤扩展到完整播放器界面，使桌面内容可透过播放器背景显示。
- 为播放器保留轻微明暗遮罩，确保封面、播放队列和控制区可读。
- 保持“经典玻璃”和系统“降低透明度”状态下原有的不透明播放器背景。

### 当前状态
- 公开源码已发布为 `1.7.14 (184)`。
- 私有/公开 Swift 各 32 项测试、Android 单测/Lint/APK、macOS Release/DMG、凭据路径扫描和精确许可证检查均已通过。
- 完整播放器透明效果已在实际桌面环境中验证，封面、队列和控制区正常可见。

### 下一步
- 收集完整播放器透明效果在不同壁纸与显示设置下的用户反馈。
- 如需分发二进制安装包，先登录 `gh`，再上传已验证的 macOS DMG；Android Debug APK 不作为 Release 附件。

### 阻塞/待确认
- 无。

### 不可破坏的决定
- 透明皮肤不得通过降低整个窗口 `alphaValue` 实现；只调整窗口底材和内容遮罩，确保文字与控件可读。
- 桌面透视侧栏不得叠加独立材质；使用整窗透视底材并清除系统窗口容器背景。
- 系统开启“降低透明度”时必须回退到经典玻璃背景。
- 完整播放器仅在“桌面透视”且系统未启用“降低透明度”时使用透明遮罩；其他状态保留原背景。

### 涉及文件
- `Sources/Hennessy/Views/PlayerView.swift`
- `VERSION`、`BUILD_NUMBER`
- `CHANGELOG.md`、`RELEASE_NOTES.md`
- `docs/CURRENT_HANDOFF.md`

### 生产环境变更
- 公开提交 `0f29463` 已推送；注解标签 `v1.7.14` 与 GitHub Release 已验证。
- Release：https://github.com/Bananainkl/Project_Hennessy-open-source/releases/tag/v1.7.14（源码归档发布，无二进制附件）。
- 已验证 DMG SHA-256：`f020ca5376792d2be9a7e12ccc501df84e2af5fd72a61c3bfedf80ff80753d37`。
- 已验证 Debug APK SHA-256：`c9501f2842ed4139f1ed5b48a7cd4698b449504db34acfa838bde5a6085a4564`，不作为 Release 附件发布。
- GitHub 源码归档已验证：tar.gz `1daf0e9b634a18d27404528f9ed5a8707846487e121af3067b0cef63e8589dc0`，zip `29b2dbdf919550b0cb43f51a98e88da053669091d2e879e81163f80abab267f2`。

---

<!-- 以下为历史交接记录，最新的在最上面 -->
