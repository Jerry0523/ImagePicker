//
//  SceneDelegate.swift
//  ImagePickerIOSDemo
//
//  Created by Jerry Wong on 2020/5/1.
//  Copyright © 2020 com.jerry. All rights reserved.
//

import UIKit
import Photos
import SwiftUI
import Combine

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private let assetsProviderPublisher = AssetsProvider.publisherForNewInstance(with: [
        .init("All") { PHFetchOptions() },
        .init("Photos") {
            let opt = PHFetchOptions()
            opt.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
            return opt
        },
        .init("Videos") {
            let opt = PHFetchOptions()
            opt.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
            return opt
        },
        .init("Live Photos") {
            let opt = PHFetchOptions()
            opt.predicate = NSPredicate(format: "mediaSubtypes == %d", PHAssetMediaSubtype.photoLive.rawValue)
            return opt
        }
    ])
    
    private var assetsProviderSubscription: AnyCancellable?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        // Create the SwiftUI view that provides the window contents.
        assetsProviderSubscription = assetsProviderPublisher
            .receive(on: DispatchQueue.main)
            .sink{ assetsProvider in
                assetsProvider.selectionType = .none
                let contentView = ContentView().environmentObject(assetsProvider)

                // Use a UIHostingController as window root view controller.
                if let windowScene = scene as? UIWindowScene {
                    let window = UIWindow(windowScene: windowScene)
                    window.rootViewController = UIHostingController(rootView: contentView)
                    self.window = window
                    window.makeKeyAndVisible()
                }
            }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

