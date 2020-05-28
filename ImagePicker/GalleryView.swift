//
//  GalleryView.swift
//  ImagePickerMacOSDemo
//
//  Created by Jerry Wong on 2020/5/1.
//  Copyright © 2020 com.jerry. All rights reserved.
//

import SwiftUI

struct GalleryView: View {
    
    @EnvironmentObject var assetsProvider: AssetsProvider
    @Environment(\.assetsLoader) var assetsLoader: AssetsLoader
    
    var body: some View {
        GeometryReader<AnyView> { proxy in
            if let assets = self.assetsProvider.focusedAssets {
                let asset = assets[self.assetsProvider.focusedIndex ?? 0]
                switch asset.playbackStyle {
                case .image, .imageAnimated:
                    return AnyView (
                        PHDetailImageView(asset, containerSize: proxy.size, task: self.assetsLoader.imageTask(for: asset))
                            .frame(width: proxy.size.width, height: proxy.size.height)
                    )
                case .video, .videoLooping:
                    return AnyView(PHDetailVideoView(self.assetsLoader.videoTask(for: asset), containerSize: proxy.size).frame(width: proxy.size.width, height: proxy.size.height))
                case .livePhoto:
                    return AnyView(PHDetailLivePhotoView(self.assetsLoader.livePhotoTask(for: asset), containerSize: proxy.size).frame(width: proxy.size.width, height: proxy.size.height))
                default:
                    return AnyView(EmptyView())
                }
               
            } else {
                return AnyView(EmptyView())
            }
        }
            .clipped()
            .edgesIgnoringSafeArea(.bottom)
            .onDisappear {
                self.assetsProvider.focusedAssets = nil
                self.assetsProvider.focusedIndex = nil
            }
    }
}

#if DEBUG
struct GalleryView_Previews: PreviewProvider {
    static var previews: some View {
        GalleryView().frame(width: 500, height: 500)
    }
}
#endif
