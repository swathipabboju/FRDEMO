import UIKit
import Flutter


@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    var navigationController: UINavigationController!
    var channel: FlutterMethodChannel!
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        let controller = window?.rootViewController as! FlutterViewController
        channel = FlutterMethodChannel(
            name: "FlutterFramework/swift_native",
            binaryMessenger: controller.binaryMessenger
        )
        
        // Create and then add a new UINavigationController
        self.navigationController = UINavigationController(rootViewController: controller)
        self.window.rootViewController = self.navigationController
        self.navigationController.setNavigationBarHidden(true, animated: false)
        self.window.makeKeyAndVisible()
        
        channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            // Handle method calls from Flutter.
            switch call.method {
            case "getPunchInIOS":
                self?.navigateToVideoControllerPunchIn(completion: { (resultData) in
                    result(resultData)
                })
            case "getPunchOutIOS":
                self?.navigateToVideoControllerPunchOut(completion: { (resultData) in
                    result(resultData)
                })
              case "getRegistartionIOS":
            self?.navigateToVideoControllerProfileRegistration(completion: { (resultData) in
            result(resultData)
                })
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func navigateToVideoControllerPunchIn(completion: @escaping (_ result: Any) -> Void) {
        let storyboard = UIStoryboard(name: "VideoBuffer", bundle: nil) // Update with your storyboard name
        let vc = storyboard.instantiateViewController(withIdentifier: "VideoController") as! VideoController
        // Set up a completion handler to receive the result from VideoController
        vc.punchInresultHandler = { resultData in
            // Send the result back to Flutter
            // NSLog("12345", resultData)
            self.channel.invokeMethod("onResultFromPunchIniOS", arguments: resultData)
        }
        self.navigationController.present(vc, animated: true, completion: nil)
    }
    func navigateToVideoControllerPunchOut(completion: @escaping (_ result: Any) -> Void) {
        let storyboard = UIStoryboard(name: "VideoBuffer", bundle: nil) // Update with your storyboard name
        let vc = storyboard.instantiateViewController(withIdentifier: "VideoController") as! VideoController
        vc.punchOutresultHandler = { resultData in
            // Send the result back to Flutter
            // NSLog("12345", resultData)
            self.channel.invokeMethod("onResultFromPunchOutiOS", arguments: resultData)
        }
        self.navigationController.present(vc, animated: true, completion: nil)
    }
    func navigateToVideoControllerForgotPunchOut(completion: @escaping (_ result: Any) -> Void) {
        let storyboard = UIStoryboard(name: "VideoBuffer", bundle: nil) // Update with your storyboard name
        let vc = storyboard.instantiateViewController(withIdentifier: "VideoController") as! VideoController
        vc.forgotPunchOutresultHandler = { resultData in
            // Send the result back to Flutter
            // NSLog("12345", resultData)
            self.channel.invokeMethod("onResultFromForgotPunchOutiOS", arguments: resultData)
        }
        self.navigationController.present(vc, animated: true, completion: nil)
    }
    func navigateToVideoControllerProfileRegistration(completion: @escaping (_ result: Any) -> Void) {
       let storyboard = UIStoryboard(name: "Registration", bundle: nil) // Update with your storyboard name
       let vc = storyboard.instantiateViewController(withIdentifier: "ProfileRegistration") as! ProfileRegistration
       vc.profileRegistrationHandler = { resultData in
           // Send the result back to Flutter
           // NSLog("12345", resultData)
           self.channel.invokeMethod("onResultFromProfileRegistation", arguments: resultData)
       }
       self.navigationController.present(vc, animated: true, completion: nil)
   }
    
    
}

