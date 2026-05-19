//
//  SplashScreenView.swift
//  Employ210
//
//  Premium Splash Screen
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var textOpacity: Double = 0
    @State private var lineWidth: CGFloat = 0
    @State private var taglineOpacity: Double = 0
    @State private var animationOpacity: Double = 0
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        if isActive {
            RootCoordinator()
                .transition(.opacity)
        } else {
            ZStack {
                // Clean dark background
                Color(red: 0.03, green: 0.03, blue: 0.05)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // SwiftUI Animation
                    ZStack {
                        // Outer pulse ring
                        Circle()
                            .stroke(
                                Color(red: 0.0, green: 0.8, blue: 0.7).opacity(0.15),
                                lineWidth: 1.5
                            )
                            .frame(width: 220, height: 220)
                            .scaleEffect(pulseScale)

                        // Rotating arc
                        Circle()
                            .trim(from: 0, to: 0.65)
                            .stroke(
                                AngularGradient(
                                    colors: [
                                        Color(red: 0.0, green: 0.8, blue: 0.7),
                                        Color(red: 0.0, green: 0.6, blue: 0.8),
                                        Color(red: 0.0, green: 0.8, blue: 0.7).opacity(0)
                                    ],
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: 160, height: 160)
                            .rotationEffect(.degrees(rotationAngle))

                        // Inner static ring
                        Circle()
                            .stroke(
                                Color(red: 0.0, green: 0.8, blue: 0.7).opacity(0.25),
                                lineWidth: 1
                            )
                            .frame(width: 100, height: 100)

                        // Center dot
                        Circle()
                            .fill(Color(red: 0.0, green: 0.8, blue: 0.7))
                            .frame(width: 8, height: 8)
                    }
                    .frame(width: 280, height: 280)
                    .opacity(animationOpacity)
                    
                    Spacer()
                        .frame(height: 32)
                    
                    // App Name
                    HStack(spacing: 0) {
                        Text("employ")
                            .font(.system(size: 32, weight: .light, design: .default))
                            .tracking(2)
                            .foregroundColor(.white)
                        
                        Text("210")
                            .font(.system(size: 32, weight: .semibold, design: .default))
                            .tracking(2)
                            .foregroundColor(Color(red: 0.0, green: 0.8, blue: 0.7))
                    }
                    .opacity(textOpacity)
                    
                    Spacer()
                        .frame(height: 16)
                    
                    // Minimal line accent
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.0, green: 0.8, blue: 0.7),
                                    Color(red: 0.0, green: 0.6, blue: 0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: lineWidth, height: 1.5)
                        .opacity(textOpacity)
                    
                    Spacer()
                        .frame(height: 24)
                    
                    // Tagline
                    Text("Empowering Employment Success")
                        .font(.system(size: 13, weight: .regular))
                        .tracking(1.5)
                        .foregroundColor(.white.opacity(0.4))
                        .opacity(taglineOpacity)
                    
                    Spacer()
                }
            }
            .onAppear {
                startAnimations()
            }
        }
    }
    
    private func startAnimations() {
        // Animation fade in
        withAnimation(.easeOut(duration: 0.5)) {
            animationOpacity = 1
        }

        // Continuous rotation
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }

        // Pulse ring
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            pulseScale = 1.12
        }
        
        // Text fade in
        withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
            textOpacity = 1
        }
        
        // Line expand
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            lineWidth = 40
        }
        
        // Tagline fade in
        withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
            taglineOpacity = 1
        }
        
        // Transition to app
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.4)) {
                isActive = true
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
