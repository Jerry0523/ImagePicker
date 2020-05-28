//
//  ProgressIndicator.swift
//  ImagePicker
//
//  Created by Jerry Wong on 2020/5/1.
//  Copyright © 2020 com.jerry. All rights reserved.
//

import SwiftUI

struct Pie : Shape {
    
    var start: Double
    
    var end: Double
    
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: .init(x: rect.width * 0.5, y: rect.height * 0.5))
            path.addArc(
                center: .init(x: rect.width * 0.5, y: rect.height * 0.5),
                radius: min(rect.width, rect.height) * 0.5,
                startAngle: .init(degrees: start - 90.0),
                endAngle: .init(degrees: end - 90.0),
                clockwise: false
            )
        }
    }
    
    var animatableData: AnimatablePair<Double, Double> {
        get {
            .init(start, end)
        }
        set {
            start = newValue.first
            end = newValue.second
        }
    }
}

struct ProgressIndicator: View {
    
    let progress: Double
    
    var body: some View {
        ZStack {
            if progress == 0 {
                ActivityIndicator(isAnimating: .constant(true))
            } else {
                Circle()
                    .stroke(Color(red: 50.0 / 255.0, green: 125.0 / 255.0, blue: 246.0 / 255.0))
                    .frame(width: 35, height: 35)
                Pie(start: 0, end: progress * 360.0)
                    .fill(Color(red: 50.0 / 255.0, green: 125.0 / 255.0, blue: 246.0 / 255.0))
                    .animation(.easeInOut(duration: 0.2))
                    .frame(width: 30, height: 30)
            }
        }
        
        
    }
}

#if DEBUG
struct ProgressIndicator_Previews: PreviewProvider {
    static var previews: some View {
        ProgressIndicator(progress: 0.3)
    }
}
#endif
