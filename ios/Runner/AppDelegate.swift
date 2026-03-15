import Flutter
import UIKit
@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let didLaunch = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    registerCustomPlugins(with: self)
    return didLaunch
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    let registry = engineBridge.pluginRegistry
    GeneratedPluginRegistrant.register(with: registry)
    registerCustomPlugins(with: registry)
  }

  private func registerCustomPlugins(with registry: FlutterPluginRegistry) {
    if !registry.hasPlugin(HakaIosFileSaverPlugin.pluginKey),
      let registrar = registry.registrar(forPlugin: HakaIosFileSaverPlugin.pluginKey)
    {
      HakaIosFileSaverPlugin.register(with: registrar)
    }

    if !registry.hasPlugin(HakaFolderPickerPlugin.pluginKey),
      let registrar = registry.registrar(forPlugin: HakaFolderPickerPlugin.pluginKey)
    {
      HakaFolderPickerPlugin.register(with: registrar)
    }
  }
}

private final class HakaIosFileSaverPlugin: NSObject, FlutterPlugin, UIDocumentPickerDelegate {
  static let pluginKey = "HakaIosFileSaverPlugin"
  private static let channelName = "haka_comic/ios_file_saver"

  private var pendingResult: FlutterResult?

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
    presentSaveUI(for: fileURL)
  }

  private func presentSaveUI(for fileURL: URL) {
    DispatchQueue.main.async {
      guard let presenter = self.topViewController() else {
        self.finish(with: false)
        return
      }

      if #available(iOS 14.0, *) {
        let picker = UIDocumentPickerViewController(forExporting: [fileURL], asCopy: true)
        picker.delegate = self
        picker.shouldShowFileExtensions = true
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
    finish(with: !urls.isEmpty)
  }

  private func finish(with success: Bool) {
    pendingResult?(success)
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
