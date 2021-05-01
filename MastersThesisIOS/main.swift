import UIKit

let isRunningTests = NSClassFromString("XCTestCase") != nil
let isUITesting = ProcessInfo.processInfo.arguments.contains("--uitesting")

var appDelegateClass: String? = nil

if(isRunningTests) {
    // Unit tests do not need to run the app
    appDelegateClass = nil
} else if(isUITesting) {
    // UI tests need to run the app with a fake delegate
    appDelegateClass = NSStringFromClass(TestingAppDelegate.self)
} else {
    // Run app normally
    appDelegateClass = NSStringFromClass(AppDelegate.self)
}

let args = UnsafeMutableRawPointer(CommandLine.unsafeArgv).bindMemory(
    to: UnsafeMutablePointer<Int8>.self,
    capacity: Int(CommandLine.argc)
)

// swiftlint:disable force_unwrapping
_ = UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, appDelegateClass)
