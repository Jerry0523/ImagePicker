//
//  PHAssetSummaryView.swift
//  ImagePickerMacOSDemo
//
//  Created by Jerry Wong on 2020/5/1.
//  Copyright © 2020 com.jerry. All rights reserved.
//

import Photos
import SwiftUI

struct PHAssetSelectedView : View {
    
    var isSelected: Bool
    
    var isHidden: Bool
    
    var body: some View {
    #if os(macOS)
        return (isHidden || !isSelected) ? AnyView(EmptyView()) : AnyView(
            ZStack {
                RoundedRectangle(cornerRadius: 5).inset(by: 1.5).stroke(Color.white, lineWidth: 5)
                RoundedRectangle(cornerRadius: 3).inset(by: 1.5).stroke(PHAssetSelectedView.selectedColor, lineWidth: 3)
            }
        )
    #else
        return (isHidden || !isSelected) ? AnyView(EmptyView()) : AnyView(
            ZStack(alignment: .bottomTrailing) {
                Color(white: 1).opacity(0.3)
                ZStack {
                    Circle()
                        .fill(Color(red: 50.0 / 255.0, green: 125.0 / 255.0, blue: 246.0 / 255.0))
                        .frame(width: 16, height: 16)
                    Path { path in
                        path.addArc(center: .init(x:8, y:8), radius: 8, startAngle: .init(degrees: 0), endAngle: .init(degrees: 360), clockwise: false, transform: .identity)
                        if isSelected {
                            path.move(to: .init(x: 5, y: 8))
                            path.addLine(to: .init(x: 8, y: 11))
                            path.addLine(to: .init(x: 12, y: 5))
                        }
                    }
                        .stroke(Color.white, style: .init(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                        .frame(width: 16, height: 16)
                }
                    .offset(x: -5, y: -5)
            }
        )
    #endif
    }
    
    static let selectedColor = Color(red: 37.0 / 255.0, green: 101.0 / 255.0, blue: 217.0 / 255.0)
}

struct PHAssetSummaryView: View {
    
    @EnvironmentObject var assetsProvider: AssetsProvider
    @Environment(\.assetsLoader) var assetsLoader: AssetsLoader
    
    let asset: PHAsset?
    
    let targetSize: CGSize
    
    init(_ asset: PHAsset?, targetSize: CGSize) {
        self.asset = asset
        self.targetSize = targetSize
    }
    
    var body: some View {
        if let asset = asset {
            return AnyView(
                ZStack(alignment: .bottomTrailing) {
                    PHThumbnailContentView(targetSize: targetSize, loadTask: assetsLoader.imageTask(for: asset))
                    if asset.playbackStyle == .video {
                        Text(secondsToHoursMinutesSeconds(seconds: asset.duration))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 0)
                            .font(.footnote)
                            .padding(5)
                    }
                }
                .cornerRadius(self.assetsProvider.isSelected(for: asset) ? 3 : 0)
                .overlay(
                    PHAssetSelectedView (
                        isSelected: self.assetsProvider.isSelected(for: asset),
                        isHidden: self.assetsProvider.selectionType == .none
                    )
                )
                .bridge_doubleTap {
                    self.assetsProvider.focusedAssets = [asset]
                }
                .onTapGesture(count: 1) {
                #if os(macOS)
                    self.assetsProvider.toggleSelection(for: self.asset)
                #else
                    if self.assetsProvider.selectionType != .none {
                        self.assetsProvider.toggleSelection(for: self.asset)
                    } else {
                        guard let asset = self.asset else { return }
                        self.assetsProvider.focusedAssets = [asset]
                    }
                #endif
                }
            )
        } else {
            return AnyView (
                EmptyView()
            )
        }
    }
    
    func secondsToHoursMinutesSeconds (seconds: TimeInterval) -> String {
        guard seconds > 0 else { return "" }
        let secInt = Int(floor(seconds))
        let hour = secInt / 3600
        let min = (secInt % 3600) / 60
        let sec = (secInt % 3600) % 60
        return hour > 0
            ? String(format: "%d:%02d:%02d", hour, min, sec)
            : String(format: "%02d:%02d", min, sec)
    }
    
}
