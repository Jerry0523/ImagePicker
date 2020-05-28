//
//  LibraryCollectionView.swift
//  ImagePickerMacOSDemo
//
//  Created by Jerry Wong on 2020/5/1.
//  Copyright © 2020 com.jerry. All rights reserved.
//

import SwiftUI
import Combine

struct LibraryCollectionView : View {
    
    @EnvironmentObject var assetsProvider: AssetsProvider
    
    let columnCount: Int
    
    let gridRatio: Float

    init(columnCount: Int = 5, gridRatio: Float = 1.0) {
        precondition(columnCount > 0 && gridRatio > 0)
        self.columnCount = columnCount
        self.gridRatio = gridRatio
    }
    
    var body: some View {
        GeometryReader<AnyView> { geometryProxy in
            let gridWidth = (geometryProxy.size.width - CGFloat(self.columnCount - 1) * LibraryCollectionView.CellInsets) / CGFloat(self.columnCount)
            let gridHeight = gridWidth / CGFloat(self.gridRatio)
            let targetSize = CGSize(width: gridWidth * ScreenScale, height: gridHeight * ScreenScale)
            return AnyView (
                ZStack {
                    BridgeNavigationView(master: {
                        List {
                             ForEach(self.assetsProvider.rowCountIdentifier(for: self.columnCount), id: \.self) { rowIdentifier in
                                HStack(spacing: LibraryCollectionView.CellInsets) {
                                    ForEach(0..<self.columnCount, id: \.self) { column in
                                        PHAssetView(
                                            self.assetsProvider.asset (
                                                at: rowIdentifier.index,
                                                column: column,
                                                columnCount: self.columnCount
                                            ),
                                            targetSize: targetSize
                                        ).frame(width: gridWidth, height:gridHeight)
                                    }
                                }
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom:LibraryCollectionView.CellInsets, trailing: 0))
                                .bridge_removeWhiteSpace()
                                .animation(.none)
                            }
                        }
                          .environment(\.defaultMinListRowHeight, gridHeight)
                          .opacity(self.assetsProvider.status == .idle ? 1.0 : 0)
                          .bridge_navigationBarTitle("Photo")
                          .bridge_navigationBarItems(leading: Button(action: {
                              self.assetsProvider.selectionType = self.assetsProvider.selectionType == .none ? .multi : .none
                          }) {
                              Text(self.assetsProvider.selectionType == .none ? "Select" : "Cancel").font(.subheadline)
                          }, trailing: Button(action: {
                              self.assetsProvider.focusedAssets = self.assetsProvider.selectedAssets
                          }) {
                            self.assetsProvider.selectedAssets.count > 0 ? AnyView(Text("\(self.assetsProvider.selectedAssets.count) selected ").font(.subheadline)) : AnyView(EmptyView())
                          })
                    }, detail: {
                        GalleryView()
                    }, showDetailPublisher: self.assetsProvider
                        .$focusedAssets
                        .map{ ($0?.count ?? 0) > 0 }
                        .eraseToAnyPublisher()
                    )
                    
                    if self.assetsProvider.status == .isLoading {
                        ActivityIndicator(isAnimating: .constant(true))
                    }
                }
            )
        }
    }
    
    static let CellInsets = CGFloat(2.0)
    
}

#if DEBUG
struct LibraryCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryCollectionView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
#endif
