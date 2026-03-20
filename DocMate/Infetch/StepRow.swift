//
//  StepRow.swift
//  DocMate
//
//  Created by Naman Yadav on 20/03/26.
//

import SwiftUI

struct StepRow: View {
    
    let number: String
    let title: String
    let desc: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            
            // Number Circle
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 38, height: 38)
                
                Text(number)
                    .font(.headline)
                    .foregroundStyle(.blue)
            }
            
            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(desc)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}
