//
//  LivePhoto.swift
//  ImagePickerMacOSDemo
//
//  Created by Jerry Wong on 2020/5/29.
//  Copyright © 2020 com.jerry. All rights reserved.
//

import SwiftUI
import PhotosUI

struct LivePhoto : SwiftUIViewRepresentable {
    
    let livePhoto: PHLivePhoto
    
    var isPlaying: Binding<Bool>
    
    #if os(macOS)
        func makeNSView(context: NSViewRepresentableContext<LivePhoto>) -> PHLivePhotoView {
            let photoView = PHLivePhotoView()
            photoView.delegate = context.coordinator
            photoView.livePhoto = livePhoto
            return photoView
        }

        func updateNSView(_ nsView: PHLivePhotoView, context: NSViewRepresentableContext<LivePhoto>) {
            isPlaying.wrappedValue ? nsView.startPlayback(with: .hint) : nsView.stopPlayback()
        }
        
    #else
        func makeUIView(context: UIViewRepresentableContext<LivePhoto>) -> PHLivePhotoView {
            let photoView = PHLivePhotoView()
            photoView.livePhoto = livePhoto
            return photoView
        }

        func updateUIView(_ uiView: PHLivePhotoView, context: UIViewRepresentableContext<LivePhoto>) {
            isPlaying.wrappedValue ? uiView.startPlayback(with: .hint) : uiView.stopPlayback()
        }
    #endif
    
    func makeCoordinator() -> LivePhotoCoordinator {
        LivePhotoCoordinator(livePhoto: self)
    }
    
}

extension LivePhoto {

    public class LivePhotoCoordinator: NSObject, PHLivePhotoViewDelegate {
        
        let livePhoto: LivePhoto
        
        init(livePhoto: LivePhoto){
            self.livePhoto = livePhoto
            super.init()
        }
        
        func livePhotoView(_ livePhotoView: PHLivePhotoView, willBeginPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
            
        }

        func livePhotoView(_ livePhotoView: PHLivePhotoView, didEndPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
            livePhoto.isPlaying.wrappedValue = false
        }
        
    }

}
