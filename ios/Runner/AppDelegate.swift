import Flutter
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    let registry = engineBridge.pluginRegistry
    GeneratedPluginRegistrant.register(with: registry)

    if !registry.hasPlugin(HakaIosFileSaverPlugin.pluginKey),
      let registrar = registry.registrar(forPlugin: HakaIosFileSaverPlugin.pluginKey)
    {
      HakaIosFileSaverPlugin.register(with: registrar)
    }
  }
}

private final class HakaIosFileSaverPlugin: NSObject, FlutterPlugin, UIDocumentPickerDelegate {
  static let pluginKey = "HakaIosFileSaverPlugin"
  private static let channelName = "haka_comic/ios_file_saver"
  private static let bufferSize = 1024 * 1024

  private var pendingResult: FlutterResult?
  private var sourceFileURL: URL?

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    let instance = HakaIosFileSaverPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "copy" else {
      result(FlutterMethodNotImplemented)
      return
    }

    guard pendingResult == nil else {
      result(false)
      return
    }

    guard
      let args = call.arguments as? [String: Any],
      let path = args["path"] as? String
    else {
      result(false)
      return
    }

    let fileURL = URL(fileURLWithPath: path)
    var isDirectory = ObjCBool(false)
    guard
      FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDirectory),
      !isDirectory.boolValue
    else {
      result(false)
      return
    }

    pendingResult = result
    sourceFileURL = fileURL
    presentSaveUI(for: fileURL)
  }

  private func presentSaveUI(for fileURL: URL) {
    DispatchQueue.main.async {
      guard let presenter = self.topViewController() else {
        self.finish(with: false)
        return
      }

      if #available(iOS 14.0, *) {
        let picker = UIDocumentPickerViewController(
          forOpeningContentTypes: [.folder],
          asCopy: false
        )
        picker.delegate = self
        picker.allowsMultipleSelection = false
        self.configurePopoverIfNeeded(for: picker, presenter: presenter)
        presenter.present(picker, animated: true)
        return
      }

      let activityController = UIActivityViewController(
        activityItems: [fileURL],
        applicationActivities: nil
      )
      activityController.completionWithItemsHandler = { [weak self] _, completed, _, error in
        self?.finish(with: completed && error == nil)
      }
      self.configurePopoverIfNeeded(for: activityController, presenter: presenter)
      presenter.present(activityController, animated: true)
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    finish(with: false)
  }

  func documentPicker(
    _ controller: UIDocumentPickerViewController,
    didPickDocumentsAt urls: [URL]
  ) {
    guard let folderURL = urls.first, let sourceFileURL else {
      finish(with: false)
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      let success = self.copyFile(from: sourceFileURL, toFolder: folderURL)
      DispatchQueue.main.async {
        self.finish(with: success)
      }
    }
  }

  private func copyFile(from sourceURL: URL, toFolder folderURL: URL) -> Bool {
    let accessedSecurityScope = folderURL.startAccessingSecurityScopedResource()
    defer {
      if accessedSecurityScope {
        folderURL.stopAccessingSecurityScopedResource()
      }
    }

    var isDirectory = ObjCBool(false)
    guard
      FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDirectory),
      isDirectory.boolValue
    else {
      return false
    }

    let destinationURL = uniqueDestinationURL(
      in: folderURL,
      fileName: sourceURL.lastPathComponent
    )

    if streamCopyFile(from: sourceURL, to: destinationURL) {
      return true
    }

    do {
      if FileManager.default.fileExists(atPath: destinationURL.path) {
        try FileManager.default.removeItem(at: destinationURL)
      }
      try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
      return true
    } catch {
      NSLog("HakaIosFileSaverPlugin fallback copy failed: %@", error.localizedDescription)
      return false
    }
  }

  private func streamCopyFile(from sourceURL: URL, to destinationURL: URL) -> Bool {
    FileManager.default.createFile(atPath: destinationURL.path, contents: nil)

    guard
      let inputStream = InputStream(url: sourceURL),
      let outputStream = OutputStream(url: destinationURL, append: false)
    else {
      return false
    }

    inputStream.open()
    outputStream.open()

    defer {
      inputStream.close()
      outputStream.close()
    }

    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Self.bufferSize)
    defer {
      buffer.deallocate()
    }

    while true {
      let readCount = inputStream.read(buffer, maxLength: Self.bufferSize)
      if readCount < 0 {
        cleanupPartialFile(at: destinationURL)
        NSLog(
          "HakaIosFileSaverPlugin read failed: %@",
          inputStream.streamError?.localizedDescription ?? "unknown error"
        )
        return false
      }

      if readCount == 0 {
        return true
      }

      var writtenCount = 0
      while writtenCount < readCount {
        let currentPointer = buffer.advanced(by: writtenCount)
        let bytesWritten = outputStream.write(
          currentPointer,
          maxLength: readCount - writtenCount
        )

        if bytesWritten <= 0 {
          cleanupPartialFile(at: destinationURL)
          NSLog(
            "HakaIosFileSaverPlugin write failed: %@",
            outputStream.streamError?.localizedDescription ?? "unknown error"
          )
          return false
        }

        writtenCount += bytesWritten
      }
    }
  }

  private func uniqueDestinationURL(in folderURL: URL, fileName: String) -> URL {
    let fileExtension = (fileName as NSString).pathExtension
    let baseName = (fileName as NSString).deletingPathExtension

    var candidate = folderURL.appendingPathComponent(fileName, isDirectory: false)
    var index = 1

    while fileExists(at: candidate) {
      let nextName: String
      if fileExtension.isEmpty {
        nextName = "\(baseName) (\(index))"
      } else {
        nextName = "\(baseName) (\(index)).\(fileExtension)"
      }
      candidate = folderURL.appendingPathComponent(nextName, isDirectory: false)
      index += 1
    }

    return candidate
  }

  private func fileExists(at url: URL) -> Bool {
    if FileManager.default.fileExists(atPath: url.path) {
      return true
    }
    return (try? url.checkResourceIsReachable()) ?? false
  }

  private func cleanupPartialFile(at url: URL) {
    try? FileManager.default.removeItem(at: url)
  }

  private func finish(with success: Bool) {
    pendingResult?(success)
    pendingResult = nil
    sourceFileURL = nil
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
