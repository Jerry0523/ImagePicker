//
//  PHContentView.swift
//  ImagePickerMacOSDemo
//
//  Created by Jerry Wong on 2020/5/1.
//  Copyright © 2020 com.jerry. All rights reserved.
//

import SwiftUI
import Photos

struct PHContentControlView<Content: View> : View {
    
    @State var magnifyBy = CGFloat(1.0)
       
    @State var offsetBy = CGSize.zero
       
    @State var accumulatedOffsetBy = CGSize.zero
       
    @State var accumulatedMagnifyBy = CGFloat(0)
    
    let onMagnifyEnded: ((CGFloat) -> ())?
    
    let content: () -> Content
    
    var magnification: some Gesture {
        MagnificationGesture()
            .onChanged {
                self.magnifyBy = $0 + self.accumulatedMagnifyBy
            }.onEnded { _ in
                withAnimation {
                    self.magnifyBy = min(2.0, max(1.0, self.magnifyBy))
                    self.accumulatedMagnifyBy = self.magnifyBy - 1.0
                    self.onMagnifyEnded?(self.magnifyBy)
                }
            }
        }
    
    var move: some Gesture {
        DragGesture()
            .onChanged {
                let translation = $0.translation
                self.offsetBy = CGSize(width: self.accumulatedOffsetBy.width + translation.width, height: self.accumulatedOffsetBy.height + translation.height)
            }.onEnded { _ in
                withAnimation {
                    if self.magnifyBy <= 1 {
                        self.offsetBy = .zero
                    }
                    self.accumulatedOffsetBy = self.offsetBy
                }
            }
    }
    
    var doubleTap: some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    self.magnifyBy = 1.0
                    self.offsetBy = .zero
                    self.accumulatedOffsetBy = .zero
                    self.accumulatedMagnifyBy = 0
                }
            }
    }
    
    var body: some View {
        content()
            .scaleEffect(self.magnifyBy)
            .offset(offsetBy)
            .gesture(magnification)
            .simultaneousGesture(move)
            .simultaneousGesture(doubleTap)
    }
}

struct PHLivePhotoContentView : View {
    
    @ObservedObject var task: AssetsLoader.Task<PHLivePhoto>
    
    @State var isPlaying = false
    
    let containerSize: CGSize
    
    init(_ task: AssetsLoader.Task<PHLivePhoto>, containerSize: CGSize) {
        self.task = task
        self.containerSize = containerSize
    }
    
    var body: some View {
        let makeView = { () -> AnyView in
            switch self.task.result(for: .zero) {
            case .onCompletion(let item):
                return AnyView(PHContentControlView(onMagnifyEnded: nil) {
                    LivePhotoView(livePhoto: item, isPlaying: self.$isPlaying)
                })
            case .onError(let error):
                return AnyView(Text(error.localizedDescription))
            case .inProgress(let p):
                return AnyView(ProgressIndicator(progress: p))
            case .idle:
                return AnyView(ActivityIndicator(isAnimating: .constant(true)))
            }
        }
        
        return makeView()
            .frame(width: containerSize.width, height: containerSize.height)
            .onAppear {
                self.task.load(size: .zero, isCache: false)
            }
    }
    
}

struct PHVideoContentView : View {
    
    @ObservedObject var task: AssetsLoader.Task<AVPlayerItem>
    
    let containerSize: CGSize
    
    init(_ task: AssetsLoader.Task<AVPlayerItem>, containerSize: CGSize) {
        self.task = task
        self.containerSize = containerSize
    }
    
    var body: some View {
        let makeView = { () -> AnyView in
            switch self.task.result(for: .zero) {
            case .onCompletion(let item):
                return AnyView(VideoPlayerView(item: item))
            case .onError(let error):
                return AnyView(Text(error.localizedDescription))
            case .inProgress(let p):
                return AnyView(ProgressIndicator(progress: p))
            case .idle:
                return AnyView(ActivityIndicator(isAnimating: .constant(true)))
            }
        }
        
        return makeView()
            .frame(width: containerSize.width, height: containerSize.height)
            .onAppear {
                self.task.load(size: .zero, isCache: false)
            }
    }
    
}

struct PHImageContentView : View {
    
    @ObservedObject var task: AssetsLoader.Task<ImageType>
    
    let targetSize: CGSize
    
    var imageFetchSize: CGSize {
        .init(width: targetSize.width * ScreenScale, height: targetSize.height * ScreenScale)
    }
    
    init(_ asset: PHAsset, containerSize: CGSize, task: AssetsLoader.Task<ImageType>) {
        self.task = task
        let phWidth = asset.pixelWidth
        let phHeight = asset.pixelHeight
        let phRatio = CGFloat(phWidth) / CGFloat(phHeight)
        let ratio = containerSize.width / containerSize.height
        if phRatio > ratio {
            self.targetSize = .init(width: containerSize.width, height: containerSize.width / phRatio)
        } else {
            self.targetSize = .init(width: phRatio * containerSize.height, height: containerSize.height)
        }
        self.task.load(size: self.imageFetchSize, isCache: false)
    }
    
    var body: some View {
        let makeView = { () -> AnyView in
            switch self.task.result(for: nil) {
            case .onCompletion(let image):
                return AnyView(
                    PHContentControlView(
                        onMagnifyEnded: { magnifyBy in
                            self.task.load(size: .init(
                                width: self.targetSize.width * magnifyBy * ScreenScale,
                                height: self.targetSize.height * magnifyBy * ScreenScale
                            ), isCache: false)
                        }, content: {
                            Image(imageType: image).resizable().aspectRatio(contentMode: .fit)
                        }
                    )
                )
            case .onError(let error):
                return AnyView(Text(error.localizedDescription))
            case .inProgress(let p):
                return AnyView(ProgressIndicator(progress: p))
            case .idle:
                return AnyView(ActivityIndicator(isAnimating: .constant(true)))
            }
        }
        
        return makeView()
            .frame(width: targetSize.width, height: targetSize.height, alignment: .center)
            .onDisappear {
                self.task.unload(clearUnCached: true)
            }
    }
}

struct PHThumbnailContentView: View {
    
    @ObservedObject var task: AssetsLoader.Task<ImageType>
    
    let targetSize: CGSize
    
    init(targetSize: CGSize,loadTask: AssetsLoader.Task<ImageType>) {
        self.targetSize = targetSize
        self.task = loadTask
    }
    
    var body: some View {
        let makeView = { () -> AnyView in
            switch self.task.result(for: self.targetSize) {
            case .onCompletion(let image):
            #if os(macOS)
                return AnyView(Image(nsImage: image).resizable())
            #else
                return AnyView(Image(uiImage: image).resizable())
            #endif
            case .onError(let error):
                return AnyView(Text(error.localizedDescription))
            case .inProgress(let p):
                return AnyView(Text("\(p)"))
            case .idle:
                return AnyView(Text("   "))
            }
        }
        return makeView()
            .onAppear {
                self.task.load(size: self.targetSize)
            }
            .onDisappear {
                self.task.unload()
            }
    }
}
