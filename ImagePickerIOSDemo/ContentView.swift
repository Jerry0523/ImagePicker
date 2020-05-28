//
//  ContentView.swift
//  ImagePickerIOSDemo
//
//  Created by Jerry Wong on 2020/5/1.
//  Copyright © 2020 com.jerry. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        LibraryCollectionView(columnCount: 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationViewStyle(StackNavigationViewStyle())
    }
    
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
