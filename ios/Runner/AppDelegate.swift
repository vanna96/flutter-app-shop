import UIKit
import Flutter
import PhotosUI
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = self.registrar(forPlugin: "ProfileImagePickerPlugin") {
      ProfileImagePickerPlugin.register(with: registrar)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

final class ProfileImagePickerPlugin: NSObject, FlutterPlugin, PHPickerViewControllerDelegate {
  private var pendingResult: FlutterResult?

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "grocery_app/profile_image_picker",
      binaryMessenger: registrar.messenger()
    )
    let instance = ProfileImagePickerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "pickImage" else {
      result(FlutterMethodNotImplemented)
      return
    }

    guard pendingResult == nil else {
      result(
        FlutterError(
          code: "multiple_request",
          message: "A profile image request is already in progress.",
          details: nil
        )
      )
      return
    }

    guard #available(iOS 14, *) else {
      result(
        FlutterError(
          code: "unsupported_ios_version",
          message: "Profile image picking requires iOS 14 or newer.",
          details: nil
        )
      )
      return
    }

    guard let presenter = Self.topViewController() else {
      result(
        FlutterError(
          code: "no_presenter",
          message: "Unable to open the image picker right now.",
          details: nil
        )
      )
      return
    }

    pendingResult = result

    var configuration = PHPickerConfiguration(photoLibrary: .shared())
    configuration.selectionLimit = 1
    configuration.filter = .images
    configuration.preferredAssetRepresentationMode = .current

    let picker = PHPickerViewController(configuration: configuration)
    picker.delegate = self
    presenter.present(picker, animated: true)
  }

  @available(iOS 14, *)
  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)

    guard let result = pendingResult else {
      return
    }

    guard let provider = results.first?.itemProvider else {
      pendingResult = nil
      result(nil)
      return
    }

    let typeIdentifier = UTType.image.identifier
    guard provider.hasItemConformingToTypeIdentifier(typeIdentifier) else {
      pendingResult = nil
      result(
        FlutterError(
          code: "invalid_image",
          message: "The selected file is not a supported image.",
          details: nil
        )
      )
      return
    }

    provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { [weak self] data, error in
      DispatchQueue.main.async {
        guard let self else { return }
        defer { self.pendingResult = nil }

        if let error {
          result(
            FlutterError(
              code: "image_load_failed",
              message: error.localizedDescription,
              details: nil
            )
          )
          return
        }

        guard let data else {
          result(
            FlutterError(
              code: "empty_image_data",
              message: "The selected image could not be read.",
              details: nil
            )
          )
          return
        }

        let fileUrl = FileManager.default.temporaryDirectory
          .appendingPathComponent("profile_\(UUID().uuidString).jpg")

        do {
          try data.write(to: fileUrl, options: .atomic)
          result(fileUrl.path)
        } catch {
          result(
            FlutterError(
              code: "image_save_failed",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
      }
    }
  }

  private static func topViewController() -> UIViewController? {
    let rootViewController: UIViewController?

    if #available(iOS 13.0, *) {
      rootViewController = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first(where: \.isKeyWindow)?
        .rootViewController
    } else {
      rootViewController = UIApplication.shared.keyWindow?.rootViewController
    }

    var current = rootViewController
    while let presented = current?.presentedViewController {
      current = presented
    }

    return current
  }
}
