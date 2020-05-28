//
//  AppDelegate.swift
//  ImagePicker
//
//  Created by Jerry Wong on 2020/5/1.
//  Copyright © 2020 com.jerry. All rights reserved.
//

import Cocoa
import Photos
import Combine
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!

    @IBOutlet weak var toolbar: NSToolbar!
    
    @IBOutlet weak var segmentControl: NSSegmentedControl!
    
    @IBOutlet weak var selectionButton: NSButton!
    
    @IBOutlet weak var goBackButton: NSButton!
    
    private var toolbarItemsStack = [[NSToolbarItem]]()
    
    private var subscriptions = Set<AnyCancellable>()
    
    private var assetsProvider: AssetsProvider?
    
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
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        assetsProviderSubscription = assetsProviderPublisher
            .receive(on: DispatchQueue.main)
            .sink{ assetsProvider in
                self.assetsProvider = assetsProvider
                assetsProvider
                    .$selectedAssets
                    .map { $0.count }
                    .sink { selectedCount in
                        self.selectionButton.title = "\(selectedCount) item\(selectedCount > 1 ? "s" : "")"
                        self.selectionButton.isHidden = selectedCount <= 0
                    }
                .store(in: &self.subscriptions)
                assetsProvider
                    .$focusedAssets
                    .sink {
                        if $0 != nil && $0!.count > 0 {
                            self.stashToolbar()
                            self.configToolBarForPhotoDetail(focused: $0)
                        } else {
                            self.restoreToolbar()
                        }
                    }
                .store(in: &self.subscriptions)
                
                self.segmentControl.segmentCount = assetsProvider.fetchDiscriptors.count
                assetsProvider.fetchDiscriptors.enumerated().forEach { (index, element) in
                    self.segmentControl.setLabel(element.name, forSegment: index)
                }

                // Create the window and set the content view.
                self.window = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
                    styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                    backing: .buffered, defer: false)
                self.window.center()
                self.window.setFrameAutosaveName("Main Window")
                self.window.contentView = NSHostingView(rootView: ContentView().environmentObject(assetsProvider))
                self.window.toolbar = self.toolbar
                self.window.titleVisibility = .hidden
                self.window.makeKeyAndOrderFront(nil)
            }
    }
    
    func restoreToolbar() {
        guard toolbarItemsStack.count > 0 else {
            return
        }
        let stashedItems = toolbarItemsStack.remove(at: toolbarItemsStack.count - 1)
        toolbar.items.enumerated().reversed().forEach { (offset, _) in
            toolbar.removeItem(at: offset)
        }
        stashedItems.enumerated().forEach { (offset, item) in
            toolbar.insertItem(withItemIdentifier: item.itemIdentifier, at: offset)
        }
    }
    
    func stashToolbar() {
        let items = toolbar.items
        toolbarItemsStack.append(items)
        items.enumerated().reversed().forEach { (offset, _) in
            toolbar.removeItem(at: offset)
        }
    }
    
    func configToolBarForPhotoDetail(focused: [PHAsset]?) {
        toolbar.insertItem(withItemIdentifier: NSToolbarItem.Identifier("go-back"), at: 0)
        toolbar.insertItem(withItemIdentifier: NSToolbarItem.Identifier("NSToolbarFlexibleSpaceItem"), at: 1)
        if (focused?.count ?? 0) > 1 {
            toolbar.insertItem(withItemIdentifier: NSToolbarItem.Identifier("pick-page-contol"), at: 2)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @IBAction func didClickGalleryButton(_ sender: NSButton) {
        assetsProvider?.focusedAssets = assetsProvider?.selectedAssets
    }
    
    @IBAction func didChangeSegmentControlValue(_ sender: NSSegmentedControl) {
        assetsProvider?.select(sender.selectedSegment)
    }
    
    @IBAction func didClickGoBackButton(_ sender: NSButton) {
        assetsProvider?.focusedAssets = nil
    }
    
    @IBAction func didClickPageControl(_ sender: NSSegmentedControl) {
        let focusedIndex = assetsProvider?.focusedIndex ?? 0
        switch sender.selectedSegment {
        case 0:
            assetsProvider?.focusedIndex = max(focusedIndex - 1, 0)
        case 1:
            assetsProvider?.focusedIndex = min((assetsProvider?.focusedAssets?.count ?? 0) - 1, focusedIndex + 1)
        default:
            fatalError()
        }
        sender.selectedSegment = -1
    }

}

