# 项目交接文档

> 本文档由 AI 编码助手（Qoder/Codex）在每次任务结束时更新，用于跨对话上下文同步。

---

## 最新更新：2026-07-31 12:52（Asia/Shanghai）

### 最近完成
- 完成 macOS“经典玻璃 / 桌面透视”皮肤选择、持久化设置、深色可读性适配与“降低透明度”回退。
- 清除了桌面透视模式下侧栏的重复材质与系统窗口容器底色，使桌面可透过侧栏显示。
- 修复 Android API 26 主题误用 API 27 导航栏属性的问题。

### 当前状态
- 公开源码已发布为 `1.7.13 (183)`。
- Swift 32 项测试、Android 单测/Lint/APK、macOS Release/DMG、凭据路径扫描和许可证检查均已通过。

### 下一步
- 收集桌面透视皮肤在不同壁纸与显示设置下的用户反馈。
- 如需分发二进制安装包，先登录 `gh`，再上传已验证的 macOS DMG；Android Debug APK 不作为 Release 附件。

### 阻塞/待确认
- 无。

### 不可破坏的决定
- 透明皮肤不得通过降低整个窗口 `alphaValue` 实现；只调整窗口底材和内容遮罩，确保文字与控件可读。
- 桌面透视侧栏不得叠加独立材质；使用整窗透视底材并清除系统窗口容器背景。
- 系统开启“降低透明度”时必须回退到经典玻璃背景。

### 涉及文件
- `Sources/Hennessy/Support`、`Sources/Hennessy/Views` 中的外观与背景实现
- `Tests/HennessyTests/WindowAppearanceStyleTests.swift`
- `android-app/app/src/main/res/values*/styles.xml`
- `VERSION`、`BUILD_NUMBER`、`CHANGELOG.md`、`RELEASE_NOTES.md` 与项目文档

### 生产环境变更
- 公开提交 `a19e4ab` 已推送；注解标签 `v1.7.13` 与 GitHub Release 已验证。
- Release：https://github.com/Bananainkl/Project_Hennessy-open-source/releases/tag/v1.7.13（源码归档发布，无二进制附件）。
- 已验证 DMG SHA-256：`d46b457be160666eccb6509b0e2f7c3a3f3406b894c568aa8a7db79752e9beb3`。
- 已验证 Debug APK SHA-256：`7d292e5d065e80af1b205032f2b15b43a7f9b8f83e328066deabb5226277d6a2`，不作为 Release 附件发布。

---

<!-- 以下为历史交接记录，最新的在最上面 -->
