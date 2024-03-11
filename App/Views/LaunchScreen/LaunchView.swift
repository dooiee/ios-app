//
//  LaunchView.swift
//  Project-Shangri-La
//
//  Created by Nick Doolittle on 3/6/22.
//

import SwiftUI

struct LaunchView: View {

    @State private var rotationDegree = 0.0 // updates with degrees to be rotated
    @State private var totalRotation = 7200.0 // how many degrees the record will spin
    @State private var recordHeight: CGFloat = 105
    @State private var recordWidth: CGFloat = 105

    @State var recordSpinning: Bool = false
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
                .scaleEffect(animate ? 10.0 : 0.1)
                .opacity(animate ? 0.0 : 0.4)
                .frame(width: recordWidth, height: recordHeight)
                .foregroundColor(.black)

            Image("LaunchScreenIcon")
                .resizable()
                .frame(width: recordWidth, height: recordHeight)
                .rotationEffect(.degrees(rotationDegree))
                .opacity(fadeOut ? 0 : 1)
//                .scaleEffect(animate ? 0 : 1.0)
        }
        .onAppear {
            Task {
                await recordSpinningAnimation()
                await recordFadeOutAnimation()
                await animateCircleAndHideLaunchScreenAnimation()
            }
        }
    }

    private func recordSpinningAnimation() async {
        withAnimation(Animation.timingCurve(0.8, 0.0, 1.0, 0.9, duration: 2.2).speed(1.1).delay(0.2)) {
            self.rotationDegree = self.totalRotation
            self.recordSpinning = true
        }
    }

    private func recordFadeOutAnimation() async {
        withAnimation(.easeIn(duration: 1.8).delay(0.3)) {
            fadeOut = true
        }
    }

    private func animateCircleAndHideLaunchScreenAnimation() async {
        withAnimation(Animation.easeOut(duration: 0.5).delay(1.9)) {
            animate = true
            showLaunchView.toggle()
        }
    }
}

struct LaunchView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchView(showLaunchView: .constant(true))
    }
}
