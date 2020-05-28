//
//  ContentView.swift
//  ImagePicker
//
//  Created by Jerry Wong on 2020/5/1.
//  Copyright © 2020 com.jerry. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        LibraryCollectionView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
