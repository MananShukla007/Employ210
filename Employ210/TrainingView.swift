//
//  TrainorView.swift
//  Employ210
//
//  Created by Manan Shukla
import SwiftUI
import UIKit

struct TrainingView: View {
    var body: some View {
        HStack(alignment:.top) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.blue)
                    .frame(width: 100, height: 50)
                    .border(.white)
                Text("Add User")
            }
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.orange)
                    .frame(width: 100, height: 50)
                    .border(.white)
                Text("Add User")
            }
        }
        Spacer()
    }
}

      
#Preview {
    TrainingView()
}
