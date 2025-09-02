//
//  FullProgressView.swift
//  Corbo
//
//  Created by Agustín Nanni on 21/06/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI

struct FullProgressView: View {
    var body: some View {
        VStack{
            Spacer()
            ProgressView()
                .tint(.textPrimary)
            Spacer()
        }
    }
}

#Preview {
    FullProgressView()
}
