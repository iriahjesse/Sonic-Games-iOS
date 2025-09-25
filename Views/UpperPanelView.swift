
//
//  UpperPanelView.swift
//  SonicGames
//
//  Created by Jesse Iriah on 28/10/2024.
//

import SwiftUI

// Upper-Panel View
struct UpperPanelView: View {
    @ObservedObject private var progressManager = UserProgressManager.shared
    @Binding var showMoreTokensAlert: Bool
    @Binding var showWinsAlert: Bool
    
    var body: some View {
       
        
        HStack {
            Spacer()
            // Left Section
            Button(action: {
                showWinsAlert = true
            }) {
                Image("customCrownIcon") // Crown icon
                    .bold()
                    .scaleEffect(1.4)
                    .foregroundStyle(.yellow)
                    .offset(x: 25, y: 1)
                    .shadow(color: .black.opacity(0.20), radius: 1, x: 0, y: 1)
         
                ZStack {
                    Rectangle()
                        .fill(Color.yellow.opacity(0.4)) // Background color
                        .frame(width: 75 + CGFloat((numberOfDigits(UserProgressManager.shared.getTotalWins()) - 5) * 11), height: 30)
                        .border(Color.black.opacity(0.1), width: 2)
                        .cornerRadius(30)
                        .blur(radius: 0.2)
                    Text("\(UserProgressManager.shared.getTotalWins())") // Wins text
                        .font(.caption)
                        .bold()
                        .scaleEffect(1.1)
                        .fontWeight(.heavy)
                        .foregroundColor(.black)
                        .background(.clear)
                        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                        .blur(radius: 0.4)
                }
                .offset(x: 10, y: 3)
            }
            // Spacer to adjust layout(separation of left and right sections) based on total wins and cash digit count
            Spacer()
                .frame(width: max(194 - CGFloat(numberOfDigits(progressManager.totalWins) + numberOfDigits(progressManager.totalTokens))*10, 0))

           
            // Right section
    
            Image("customCashIcon") // Banknote icon
                .bold()
                .scaleEffect(1.2)
                .font(.system(size: 26))
                .foregroundStyle(.green)
                .offset(x: 13, y: 2)
                .shadow(color: .black.opacity(0.18), radius: 1, x: 0, y: 1)
            // Cash display
            ZStack {
                Rectangle()
                    .fill(Color.green.opacity(0.3)) // Background color
                    .frame(width: 75 + CGFloat((numberOfDigits(progressManager.totalTokens) - 5) * 11), height: 30)
                    .border(Color.black.opacity(0.1), width: 2)
                    .cornerRadius(30)
                    .blur(radius: 0.2)
                    .offset(x: 0, y: 3)
                Text("\(progressManager.totalTokens)") // Token text
                    .font(.caption)
                    .bold()
                    .scaleEffect(1.1)
                    .fontWeight(.heavy)
                    .foregroundColor(.black)
                    .background(.clear
                    )
                    .offset(x: 0, y: 3)
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                    .blur(radius: 0.4)
            }
            
            // Plus icon button with a circle background
            Button(action: {
                showMoreTokensAlert = true // Show the confirmation dialog
            }) {
                ZStack {
                    Circle()  // Circular background
                        .fill(Color.white)
                        .frame(width: 30, height: 30)
                    Image(systemName: "plus")  // Plus icon
                        .bold()
                        .font(.system(size: 20))
                        .foregroundStyle(.green)
                        .shadow(color: .black.opacity(0.18), radius: 1, x: 0, y: 1)
                }
                .offset(x: -18, y: -9)
            }
            
            Spacer()
        }
        
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.8))
            .shadow(color: Color.white.opacity(2), radius: 10, y: 20)
            .shadow(color: Color.white.opacity(2), radius: 10, y: -20)
            
    }
      
}

// Helper function to calculate the number of digits in an integer
func numberOfDigits(_ number: Int) -> Int {
    return String(abs(number)).count
}


// Preview provider for UpperPanelView
struct UpperPanelView_Previews: PreviewProvider {
    @State static var showMoreCashAlert: Bool = false
    @State static var showWinsAlert: Bool = false
    static var previews: some View {
        // Sample state variables
        
        UpperPanelView(showMoreTokensAlert: $showMoreCashAlert, showWinsAlert: $showWinsAlert)
            .previewLayout(.sizeThatFits)
            
    }
}

