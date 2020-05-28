//
//  ActivityIndicator.swift
//  ImagePickerMacOSDemo
//
//  Created by Jerry Wong on 2020/5/1.
//  Copyright © 2020 com.jerry. All rights reserved.
//

import SwiftUI

struct ActivityIndicator: SwiftUIViewRepresentable {

    @Binding var isAnimating: Bool
    
    @Environment(\.colorScheme) var colorScheme

#if os(macOS)
    func makeNSView(context: NSViewRepresentableContext<ActivityIndicator>) -> NSProgressIndicator {
        let indicator = NSProgressIndicator(frame: .init(x: 0, y: 0, width: 30, height: 30))
        indicator.style = .spinning
        return indicator
    }

    func updateNSView(_ nsView: NSProgressIndicator, context: NSViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? nsView.startAnimation(nil) : nsView.stopAnimation(nil)
    }
    
#else
    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(style: .large)
        switch colorScheme {
        case .dark:
            indicator.color = .white
        case .light:
            indicator.color = .black
        @unknown default:
            indicator.color = .black
        }
        return indicator
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
#endif
}

#if DEBUG
struct ActivityIndicator_Previews: PreviewProvider {
    static var previews: some View {
        ActivityIndicator(isAnimating: .constant(true))
    }
}
#endif
