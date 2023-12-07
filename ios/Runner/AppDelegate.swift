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
        
        print("mahindra thar")
        
        let controller = window?.rootViewController as! FlutterViewController
              channel = FlutterMethodChannel(
                  name: "FlutterFramework/swift_native",
                  binaryMessenger: controller.binaryMessenger
              )
              
    

channel.setMethodCallHandler { (call, result) in
  switch call.method {
    case "getPunchInIOS":
      if let args = call.arguments as? [String: Any] {
        print("87878778")
        let arg1 = args["local"] as? String ?? ""
        let arg2 = args["captured"] as? String ?? ""
        print(arg1)
          
         // if let imagePath = arg2 { // Replace this with your image file path
              if let localImg = UIImage(contentsOfFile: arg1) {
                  print("localImg",localImg)
                  // Now 'image' contains the UIImage loaded from the file path
                  // You can use this UIImage as needed, such as displaying it in a UIImageView
                  
                  // For example, if you have a UIImageView named 'imageView':
                //  imageView.image = image
              } 
          else {
                  print("Unable to create UIImage from the file path")
              }
         // }
        
        // Use arg1 and arg2 as needed
        // Your logic here
      }
      // Handle the logic and return a result if needed
      result("Processed arguments successfully")
    default:
      result(FlutterMethodNotImplemented)
  }
}

        
        
        
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    
    
}
