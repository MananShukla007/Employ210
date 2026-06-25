//
//  MaintenanceView.swift
//  Employ210
//
//  Full-screen maintenance screen shown when the remote status flag is active.
//  Spinning-gears motif, dark background, remote message text.
//

import SwiftUI

struct MaintenanceView: View {
    let message: String

    @State private var outerRotation: Double = 0
    @State private var innerRotation: Double = 0

    var body: some View {
        ZStack {
            // Background — matches app dark theme
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.07, blue: 0.11),
                    Color(red: 0.03, green: 0.05, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 48) {
                Spacer()

                // Spinning gears
                ZStack {
                    // Large outer gear
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 96))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.teal.opacity(0.7), Color.blue.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(outerRotation))
                        .offset(x: -22, y: 0)

                    // Smaller inner gear (counter-rotates, offset so teeth mesh)
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.65), Color.teal.opacity(0.45)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(innerRotation))
                        .offset(x: 52, y: -12)
                }
                .frame(width: 180, height: 130)

                // Text block
                VStack(spacing: 16) {
                    Text("We'll Be Right Back")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(message.isEmpty
                         ? "Employ210 is currently undergoing maintenance.\nPlease check back soon."
                         : message)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(4)
                }

                Spacer()

                // Wordmark footer
                HStack(spacing: 0) {
                    Text("employ")
                        .font(.system(size: 13, weight: .light))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.25))
                    Text("210")
                        .font(.system(size: 13, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(Color.teal.opacity(0.35))
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 7).repeatForever(autoreverses: false)) {
                outerRotation = 360
            }
            withAnimation(.linear(duration: 4.5).repeatForever(autoreverses: false)) {
                innerRotation = -360
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MaintenanceView(message: "We're upgrading our systems to serve you better. Back in a few minutes!")
}

#Preview("Empty message") {
    MaintenanceView(message: "")
}
