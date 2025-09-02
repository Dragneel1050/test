//
//  AppDivider.swift
//  Corbo
//
//  Created by Agustín Nanni on 31/07/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI

struct AppDivider: View {
    
    var color: Color = .textSecondary
    
    var body: some View {
        RoundedRectangle(cornerRadius: 25.0)
            .fill(color)
            .frame(height: 1)
    }
}

#Preview {
    AppDivider()
}
