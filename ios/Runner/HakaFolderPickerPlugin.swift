import Flutter
import UIKit
import MobileCoreServices
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

final class HakaFolderPickerPlugin: NSObject, FlutterPlugin, UIDocumentPickerDelegate {
  static let pluginKey = "HakaFolderPickerPlugin"
  private static let channelName = "haka_comic/folder_picker"

  private var pendingResult: FlutterResult?
  private var recursive = true

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    let instance = HakaFolderPickerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "pickDirectorySnapshot" else {
      result(FlutterMethodNotImplemented)
      return
    }

    guard pendingResult == nil else {
      result(
        FlutterError(
          code: "busy",
          message: "Another folder picker request is already running.",
          details: nil
        )
      )
      return
    }

    let args = call.arguments as? [String: Any]
    recursive = args?["recursive"] as? Bool ?? true
    pendingResult = result
    presentPicker()
  }

  private func presentPicker() {
    DispatchQueue.main.async {
      guard let presenter = self.topViewController() else {
        self.finish(
          error: FlutterError(
            code: "unavailable",
            message: "Unable to present folder picker.",
            details: nil
          )
        )
        return
      }

      let picker: UIDocumentPickerViewController
      if #available(iOS 14.0, *) {
        picker = UIDocumentPickerViewController(
          forOpeningContentTypes: [UTType.folder],
          asCopy: false
        )
      } else {
        picker = UIDocumentPickerViewController(
          documentTypes: [kUTTypeFolder as String],
          in: .open
        )
      }

      picker.delegate = self
      picker.allowsMultipleSelection = false
      self.configurePopoverIfNeeded(for: picker, presenter: presenter)
      presenter.present(picker, animated: true)
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    finish(value: nil)
  }

  func documentPicker(
    _ controller: UIDocumentPickerViewController,
    didPickDocumentsAt urls: [URL]
  ) {
    guard let folderURL = urls.first else {
      finish(value: nil)
      return
    }

    do {
      let snapshot = try createSnapshot(from: folderURL, recursive: recursive)
      finish(value: snapshot)
    } catch {
      finish(
        error: FlutterError(
          code: "snapshot_failed",
          message: error.localizedDescription,
          details: nil
        )
      )
    }
  }

  private func createSnapshot(from folderURL: URL, recursive: Bool) throws -> [String: Any] {
    let didAccess = folderURL.startAccessingSecurityScopedResource()
    defer {
      if didAccess {
        folderURL.stopAccessingSecurityScopedResource()
      }
    }

    var isDirectory: ObjCBool = false
    guard
      FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDirectory),
      isDirectory.boolValue
    else {
      throw NSError(
        domain: "HakaFolderPickerPlugin",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Selected URL is not a directory."]
      )
    }

    let folderName = folderURL.lastPathComponent.isEmpty ? "folder" : folderURL.lastPathComponent
    let cacheRoot = try folderPickerCacheRoot()
    let snapshotDir = cacheRoot.appendingPathComponent(
      "\(Int(Date().timeIntervalSince1970 * 1000))_\(UUID().uuidString)_\(sanitizeForPath(folderName))",
      isDirectory: true
    )
    try FileManager.default.createDirectory(
      at: snapshotDir,
      withIntermediateDirectories: true,
      attributes: nil
    )

    var files = [[String: Any]]()
    try copyFolderContents(
      from: folderURL,
      to: snapshotDir,
      snapshotRoot: snapshotDir,
      recursive: recursive,
      files: &files
    )

    return [
      "name": folderName,
      "localPath": snapshotDir.path,
      "files": files,
    ]
  }

  private func folderPickerCacheRoot() throws -> URL {
    let cacheRoot = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    let folderRoot = cacheRoot.appendingPathComponent("folder_picker", isDirectory: true)
    try FileManager.default.createDirectory(
      at: folderRoot,
      withIntermediateDirectories: true,
      attributes: nil
    )
    return folderRoot
  }

  private func copyFolderContents(
    from sourceURL: URL,
    to destinationURL: URL,
    snapshotRoot: URL,
    recursive: Bool,
    files: inout [[String: Any]]
  ) throws {
    let resourceKeys: [URLResourceKey] = [
      .isDirectoryKey,
      .fileSizeKey,
      .typeIdentifierKey,
    ]
    let children = try FileManager.default.contentsOfDirectory(
      at: sourceURL,
      includingPropertiesForKeys: resourceKeys,
      options: [.skipsHiddenFiles]
    )

    for childURL in children {
      let values = try childURL.resourceValues(forKeys: Set(resourceKeys))
      let isDirectory = values.isDirectory ?? false
      let destinationChildURL = destinationURL.appendingPathComponent(
        childURL.lastPathComponent,
        isDirectory: isDirectory
      )

      if isDirectory {
        guard recursive else {
          continue
        }
        try FileManager.default.createDirectory(
          at: destinationChildURL,
          withIntermediateDirectories: true,
          attributes: nil
        )
        try copyFolderContents(
          from: childURL,
          to: destinationChildURL,
          snapshotRoot: snapshotRoot,
          recursive: true,
          files: &files
        )
        continue
      }

      try FileManager.default.copyItem(at: childURL, to: destinationChildURL)
      files.append([
        "name": childURL.lastPathComponent,
        "relativePath": relativePath(from: snapshotRoot, to: destinationChildURL),
        "localPath": destinationChildURL.path,
        "size": values.fileSize ?? 0,
        "mimeType": values.typeIdentifier ?? NSNull(),
      ])
    }
  }

  private func relativePath(from rootURL: URL, to targetURL: URL) -> String {
    let rootPath = rootURL.path
    let targetPath = targetURL.path
    guard targetPath.hasPrefix(rootPath) else {
      return targetURL.lastPathComponent
    }

    let index = targetPath.index(targetPath.startIndex, offsetBy: rootPath.count)
    let suffix = String(targetPath[index...])
      .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    return suffix.replacingOccurrences(of: "\\", with: "/")
  }

  private func sanitizeForPath(_ name: String) -> String {
    return name.replacingOccurrences(
      of: #"[\\/:*?"<>|]"#,
      with: "_",
      options: .regularExpression
    )
  }

  private func finish(value: Any?) {
    pendingResult?(value)
    pendingResult = nil
  }

  private func finish(error: FlutterError) {
    pendingResult?(error)
    pendingResult = nil
  }

  private func topViewController(base: UIViewController? = nil) -> UIViewController? {
    let controller = base ?? keyWindow()?.rootViewController

    if let navigationController = controller as? UINavigationController {
      return topViewController(base: navigationController.visibleViewController)
    }

    if let tabBarController = controller as? UITabBarController {
      return topViewController(base: tabBarController.selectedViewController)
    }

    if let presentedViewController = controller?.presentedViewController {
      return topViewController(base: presentedViewController)
    }

    return controller
  }

  private func keyWindow() -> UIWindow? {
    let activeScenes = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .filter { $0.activationState == .foregroundActive }

    for scene in activeScenes {
      if let window = scene.windows.first(where: { $0.isKeyWindow }) {
        return window
      }
    }

    return UIApplication.shared.windows.first(where: { $0.isKeyWindow })
  }

  private func configurePopoverIfNeeded(
    for controller: UIViewController,
    presenter: UIViewController
  ) {
    guard let popover = controller.popoverPresentationController else {
      return
    }

    popover.sourceView = presenter.view
    popover.sourceRect = CGRect(
      x: presenter.view.bounds.midX,
      y: presenter.view.bounds.midY,
      width: 1,
      height: 1
    )
    popover.permittedArrowDirections = []
  }
}
