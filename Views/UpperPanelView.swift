//
//  UpperPanelView.swift
//  SonicGames
//
//  Created by Jesse Iriah on 28/10/2024.
//

import SwiftUI

// MARK: - View
struct UpperPanelView: View {
    @ObservedObject private var progressManager = UserProgressManager.shared
    
    @Binding var showMoreTokensAlert: Bool
    @Binding var showWinsAlert: Bool
    
    // MARK: - Layout Constants
    private let textHeight: CGFloat = 30
    private let baseWidth: CGFloat = 75 // Base width for the token/wins pill
    private let digitWidth: CGFloat = 11 // Estimated width increase per extra digit

    var body: some View {
        HStack(spacing: 0) { // Explicit spacing control
            
            Spacer()

            // MARK: - Wins Section (Left)
            WinDisplayView(
                totalWins: progressManager.totalWins, // CRITICAL FIX: Use the ObservedObject property
                showWinsAlert: $showWinsAlert
            )
            
            // Spacer for layout separation. Calculation logic moved to a computed property.
            Spacer()
                // Dynamic spacing calculation (now using ObservedObject properties)
                .frame(width: max(180 - dynamicWidthAdjustment, 0)) // Adjusted magic number slightly
            
            // MARK: - Tokens Section (Right)
            TokenDisplayView(
                totalTokens: progressManager.totalTokens, // CRITICAL FIX: Use the ObservedObject property
                showMoreTokensAlert: $showMoreTokensAlert
            )
            
            Spacer()
        }
        .frame(height: 48)
        .frame(maxWidth: .infinity)
        // Cleaned up background and shadow (White opacity is likely the issue for harsh shadows)
        .background(Color.white.opacity(0.8)) 
        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 1)
    }

    // MARK: - Helper Logic
    
    // Helper property to calculate the total width adjustment needed
    private var dynamicWidthAdjustment: CGFloat {
        let winsDigits = numberOfDigits(progressManager.totalWins)
        let tokenDigits = numberOfDigits(progressManager.totalTokens)
        
        // This rough formula attempts to account for the total space taken by both expanding pills
        return CGFloat((winsDigits + tokenDigits) * 10) 
    }
}

// Helper function to calculate the number of digits in an integer (moved inside)
private func numberOfDigits(_ number: Int) -> Int {
    return String(abs(number)).count
}

// MARK: - Subviews for Clarity and Reusability

// Extracted Subview for Wins Display
private struct WinDisplayView: View {
    let totalWins: Int
    @Binding var showWinsAlert: Bool
    
    // Calculates the required width based on the number of digits
    private var pillWidth: CGFloat {
        let digitCount = numberOfDigits(totalWins)
        return 75 + CGFloat(max(0, digitCount - 5) * 11)
    }
    
    var body: some View {
        Button(action: {
            showWinsAlert = true
        }) {
            // Icon
            Image("customCrownIcon")
                .scaleEffect(1.4)
                .foregroundStyle(.yellow)
                .offset(x: 25, y: 1)
                .shadow(color: .black.opacity(0.20), radius: 1, x: 0, y: 1)
            
            // Text Pill
            ZStack {
                Rectangle()
                    .fill(Color.yellow.opacity(0.4))
                    .frame(width: pillWidth, height: 30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.black.opacity(0.1), lineWidth: 2)
                    )
                    .cornerRadius(30)
                    .blur(radius: 0.2)
                
                Text("\(totalWins)")
                    .font(.caption)
                    .fontWeight(.heavy)
                    .scaleEffect(1.1)
                    .foregroundColor(.black)
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                    .blur(radius: 0.4)
            }
            .offset(x: 10, y: 3)
        }
    }
}

// Extracted Subview for Token Display
private struct TokenDisplayView: View {
    let totalTokens: Int
    @Binding var showMoreTokensAlert: Bool
    
    // Calculates the required width based on the number of digits
    private var pillWidth: CGFloat {
        let digitCount = numberOfDigits(totalTokens)
        return 75 + CGFloat(max(0, digitCount - 5) * 11)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Icon
            Image("customCashIcon")
                .scaleEffect(1.2)
                .font(.system(size: 26))
                .foregroundStyle(.green)
                .offset(x: 13, y: 2)
                .shadow(color: .black.opacity(0.18), radius: 1, x: 0, y: 1)
            
            // Text Pill
            ZStack {
                Rectangle()
                    .fill(Color.green.opacity(0.3))
                    .frame(width: pillWidth, height: 30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.black.opacity(0.1), lineWidth: 2)
                    )
                    .cornerRadius(30)
                    .blur(radius: 0.2)
                    .offset(x: 0, y: 3)
                
                Text("\(totalTokens)")
                    .font(.caption)
                    .fontWeight(.heavy)
                    .scaleEffect(1.1)
                    .foregroundColor(.black)
                    .offset(x: 0, y: 3)
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                    .blur(radius: 0.4)
            }
            
            // Plus icon button
            Button(action: {
                showMoreTokensAlert = true
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 30, height: 30)
                    Image(systemName: "plus")
                        .fontWeight(.bold)
                        .font(.system(size: 20))
                        .foregroundStyle(.green)
                        .shadow(color: .black.opacity(0.18), radius: 1, x: 0, y: 1)
                }
                .offset(x: -18, y: -9)
            }
        }
    }
}

// MARK: - Preview
struct UpperPanelView_Previews: PreviewProvider {
    @State static var showMoreTokensAlert: Bool = false 
    @State static var showWinsAlert: Bool = false
    
    static var previews: some View {
        UpperPanelView(showMoreTokensAlert: $showMoreTokensAlert, showWinsAlert: $showWinsAlert)
            .previewLayout(.sizeThatFits)
    }
}
