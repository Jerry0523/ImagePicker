//
//  LivePhotoView.swift
//  ImagePickerMacOSDemo
//
//  Created by Jerry Wong on 2020/5/29.
//  Copyright © 2020 com.jerry. All rights reserved.
//

import SwiftUI
import PhotosUI

struct LivePhotoView : SwiftUIViewRepresentable {
    
    let livePhoto: PHLivePhoto
    
    var isPlaying: Binding<Bool>
    
    #if os(macOS)
        func makeNSView(context: NSViewRepresentableContext<LivePhotoView>) -> PHLivePhotoView {
            let photoView = PHLivePhotoView()
            photoView.delegate = context.coordinator
            photoView.livePhoto = livePhoto
            return photoView
        }

        func updateNSView(_ nsView: PHLivePhotoView, context: NSViewRepresentableContext<LivePhotoView>) {
            isPlaying.wrappedValue ? nsView.startPlayback(with: .hint) : nsView.stopPlayback()
        }
        
    #else
        func makeUIView(context: UIViewRepresentableContext<LivePhotoView>) -> PHLivePhotoView {
            let photoView = PHLivePhotoView()
            photoView.livePhoto = livePhoto
            return photoView
        }

        func updateUIView(_ uiView: PHLivePhotoView, context: UIViewRepresentableContext<LivePhotoView>) {
            isPlaying.wrappedValue ? uiView.startPlayback(with: .hint) : uiView.stopPlayback()
        }
    #endif
    
    func makeCoordinator() -> LivePhotoViewCoordinator {
        LivePhotoViewCoordinator(livePhotoView: self)
    }
    
}

extension LivePhotoView {

    public class LivePhotoViewCoordinator: NSObject, PHLivePhotoViewDelegate {
        
        let livePhotoView: LivePhotoView
        
        init(livePhotoView: LivePhotoView){
            self.livePhotoView = livePhotoView
            super.init()
        }
        
        func livePhotoView(_ livePhotoView: PHLivePhotoView, willBeginPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
            
        }

        func livePhotoView(_ livePhotoView: PHLivePhotoView, didEndPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
            self.livePhotoView.isPlaying.wrappedValue = false
        }
        
    }

}
