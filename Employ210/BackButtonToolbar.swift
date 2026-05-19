//
//  BackButtonToolbar.swift
//  Employ210
//
//  Created by Manan Shukla on 10/15/25.
//


import SwiftUI

struct BackButtonToolbar: ToolbarContent {
@Environment(\.dismiss) private var dismiss
var body: some ToolbarContent {
ToolbarItem(placement: .topBarLeading) {
Button { dismiss() } label: {
HStack(spacing: 6) {
Image(systemName: "chevron.left")
Text("Back")
}
}
}
}
}
