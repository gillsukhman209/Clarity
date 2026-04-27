//
//  AppDelegate.swift
//  Clarity
//
//  Registers the app for silent remote notifications so SwiftData + CloudKit
//  can wake us up to pull down changes pushed from other devices. Without this,
//  cross-device sync only happens on cold launch / foreground.
//

import Foundation

#if canImport(UIKit)
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        application.registerForRemoteNotifications()
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // CloudKit / SwiftData consume the token internally via NSPersistentCloudKitContainer.
        print("✓ Registered for remote notifications (\(deviceToken.count) bytes)")
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("⚠️ Remote notification registration failed: \(error.localizedDescription)")
    }
}

#elseif canImport(AppKit)
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.registerForRemoteNotifications()
    }

    func application(
        _ application: NSApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        print("✓ Registered for remote notifications (\(deviceToken.count) bytes)")
    }

    func application(
        _ application: NSApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("⚠️ Remote notification registration failed: \(error.localizedDescription)")
    }
}
#endif
