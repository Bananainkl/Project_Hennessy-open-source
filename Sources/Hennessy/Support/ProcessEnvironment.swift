import Foundation

enum ProcessEnvironment {
    static var downloader: [String: String] {
        var environment = ProcessInfo.processInfo.environment
        let bundledToolsPath = Bundle.main.resourceURL?
            .appendingPathComponent("Tools", isDirectory: true)
            .path
        let defaultPaths = [
            bundledToolsPath,
            "/opt/homebrew/bin",
            "/usr/local/bin",
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin"
        ].compactMap(\.self)
        let defaultPath = defaultPaths.joined(separator: ":")
        if let currentPath = environment["PATH"], !currentPath.isEmpty {
            environment["PATH"] = "\(defaultPath):\(currentPath)"
        } else {
            environment["PATH"] = defaultPath
        }
        environment["PYTHONIOENCODING"] = "utf-8"
        return environment
    }
}
