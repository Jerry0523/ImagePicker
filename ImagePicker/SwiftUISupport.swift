//
//  SwiftUISupport.swift
//  ImagePickerMacOSDemo
//
//  Created by Jerry Wong on 2020/5/1.
//  Copyright © 2020 com.jerry. All rights reserved.
//

import SwiftUI
import Combine

#if os(macOS)
import AppKit
let ScreenScale = NSScreen.main?.backingScaleFactor ?? 1.0
typealias ImageType = NSImage
typealias SwiftUIViewRepresentable = NSViewRepresentable
typealias SwiftUIViewControllerRepresentable = NSViewControllerRepresentable
#else
import UIKit
let ScreenScale = UIScreen.main.scale
typealias ImageType = UIImage
typealias SwiftUIViewRepresentable = UIViewRepresentable
typealias SwiftUIViewControllerRepresentable = UIViewControllerRepresentable
#endif

extension Image {

    init(imageType: ImageType) {
    #if os(macOS)
        self.init(nsImage: imageType)
    #else
        self.init(uiImage: imageType)
    #endif
    }
    
}

extension View {
    
    public func bridge_doubleTap(perform action: @escaping () -> Void) -> some View {
    #if os(macOS)
        return self.onTapGesture(count: 2, perform: action)
    #else
        return self
    #endif
    }
    
    public func bridge_removeWhiteSpace() -> some View {
    #if os(macOS)
        return self.padding(.horizontal, -8)
    #else
        return self
    #endif
    }
    
    public func bridge_navigationBarTitle(_ title: String) -> some View {
    #if os(macOS)
        return self
    #else
        return self.navigationBarTitle(Text(title), displayMode: .inline)
    #endif
    }
    
    public func bridge_navigationBarItems<L, T>(leading: L, trailing: T) -> some View where L : View, T : View {
    #if os(macOS)
        return self
    #else
        return self.navigationBarItems(leading: leading.offset(x: -6, y: 0), trailing: trailing.offset(x: 6, y: 0))
    #endif
    }
}

struct BridgeNavigationView<Master: View, Detail: View> : View {
    
    let master: () -> Master
    
    let detail: () -> Detail
    
    let showDetailPublisher: AnyPublisher<Bool, Never>
    
    @State var showDetail = false
    
    var body: some View {
#if os(macOS)
        return ZStack {
            if !self.showDetail {
                master()
                    .transition(.slideOut)
            }
            if self.showDetail {
                detail()
                    .transition(.slideIn)
            }
        }.onReceive(showDetailPublisher) { showDetail in
            withAnimation {
                self.showDetail = showDetail
            }
        }
#else
        return NavigationView {
            ZStack {
                master()
                NavigationLink(destination: detail(), isActive: self.$showDetail) { EmptyView() }.hidden()
            }
        }.onReceive(showDetailPublisher) {
            self.showDetail = $0
        }
#endif
    }
    
}

#if os(macOS)
extension AnyTransition {
    
    static var slideOut: AnyTransition {
        let insertion = AnyTransition.move(edge: .leading)
        let removal = AnyTransition.move(edge: .leading)
        return .asymmetric(insertion: insertion, removal: removal)
    }
    
    static var slideIn: AnyTransition {
        let insertion = AnyTransition.move(edge: .trailing)
        let removal = AnyTransition.move(edge: .trailing)
        return .asymmetric(insertion: insertion, removal: removal)
    }
}
#endif

struct AssetsLoaderKey: EnvironmentKey {
    
    static let defaultValue: AssetsLoader = AssetsLoader()
    
}

extension EnvironmentValues {
    
    var assetsLoader: AssetsLoader {
        
        get {
            return self[AssetsLoaderKey.self]
        }
        
        set {
            self[AssetsLoaderKey.self] = newValue
        }
    }
    
}
