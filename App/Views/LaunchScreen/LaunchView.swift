//
//  LaunchView.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 3/6/22.
//

import SwiftUI

struct LaunchView: View {
    
    @State var spinSlow: Bool = false
    @State var spinFast: Bool = false
    @State var fadeOut: Bool = false
    @State var animate: Bool = false
    @Binding var showLaunchView: Bool
    
    var body: some View {
        ZStack {
            Color.launch.background
                .ignoresSafeArea()
            
            Circle()
                .stroke(lineWidth: 2.0)
//                .scale(animate ? 1.0 : 0) // shrink animate
                .scale(animate ? 0.1 : 8.0) // grow animate
                .opacity(animate ? 0.4 : 0.0)
                .frame(width: 100, height: 100)
                .foregroundColor(.black)
            
            Image("LaunchScreenIcon")
                .resizable()
                .frame(width: 100, height: 100)
                .rotationEffect(Angle(degrees: spinSlow ? 180 : 0), anchor: .center)
                .rotationEffect(Angle(degrees: spinFast ? 3000 : 0), anchor: .center)
//                .rotationEffect(Angle(degrees: spinFast ? 3400 : 0), anchor: .center) // original rotation angle
                .opacity(fadeOut ? 0 : 1)
                .scaleEffect(animate ? 1.0 : 0)
            
            
        } //ZStack
        .onAppear {
            animate.toggle()
//            DispatchQueue.main.async {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 1.0)) {
                    spinSlow.toggle()
                    
                }
            }
//            DispatchQueue.main.async {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeIn(duration: 2.5)) {
                    spinFast.toggle()
                    fadeOut.toggle()
                }
            }
//            DispatchQueue.main.async {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(animate ? Animation.easeOut(duration: 0.5) : .none) {
                    animate.toggle()
                    
                    }
            }
//            DispatchQueue.main.async {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.9) {
                showLaunchView = false
            }
        }
    }
}

struct LaunchView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchView(showLaunchView: .constant(true))
    }
}
