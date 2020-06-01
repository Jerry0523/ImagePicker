//
//  PHAssetDetailView.swift
//  ImagePickerMacOSDemo
//
//  Created by Jerry Wong on 2020/5/1.
//  Copyright © 2020 com.jerry. All rights reserved.
//

import SwiftUI

struct PHAssetDetailView: View {
    
    @EnvironmentObject var assetsProvider: AssetsProvider
    @Environment(\.assetsLoader) var assetsLoader: AssetsLoader
    
    var body: some View {
        GeometryReader<AnyView> { proxy in
            if let assets = self.assetsProvider.focusedAssets {
                let asset = assets[self.assetsProvider.focusedIndex ?? 0]
                switch asset.playbackStyle {
                case .image, .imageAnimated:
                    return AnyView (
                       PHImageContentView(asset, containerSize: proxy.size, task: self.assetsLoader.imageTask(for: asset))
                            .frame(width: proxy.size.width, height: proxy.size.height)
                    )
                case .video, .videoLooping:
                    return AnyView(PHVideoContentView(self.assetsLoader.videoTask(for: asset), containerSize: proxy.size).frame(width: proxy.size.width, height: proxy.size.height))
                case .livePhoto:
                    return AnyView(PHLivePhotoContentView(self.assetsLoader.livePhotoTask(for: asset), containerSize: proxy.size).frame(width: proxy.size.width, height: proxy.size.height))
                default:
                    return AnyView(EmptyView())
                }
               
            } else {
                return AnyView(EmptyView())
            }
        }
            .clipped()
            .bridge_navigationBarItems(trailing: (self.assetsProvider.focusedAssets?.count ?? 0) > 1 ? AnyView (
                    HStack {
                        Button(action: {
                            self.assetsProvider.focusedIndex = max(0, (self.assetsProvider.focusedIndex ?? 0) - 1)
                        }) {
                            Image(systemName: "chevron.left").padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 10))
                        }
                        Button(action: {
                            self.assetsProvider.focusedIndex = min((self.assetsProvider.focusedAssets?.count ?? 0) - 1, (self.assetsProvider.focusedIndex ?? 0) + 1)
                        }) {
                            Image(systemName: "chevron.right").padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 6))
                        }
                    }
                ) : AnyView(EmptyView()))
            .onDisappear {
                self.assetsProvider.focusedAssets = nil
                self.assetsProvider.focusedIndex = nil
            }
    }
}
