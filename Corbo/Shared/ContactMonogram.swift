//
//  ContactMonogram.swift
//  Corbo
//
//  Created by Agustín Nanni on 21/06/2024.
//  Copyright © 2024 Nom Development. All rights reserved.
//

import SwiftUI

struct ContactMonogram: View {
    let first: String
    let last: String
    
    init(firstName: String?, lastName: String?) {
        self.first = firstName?.first?.uppercased() ?? ""
        self.last = lastName?.first?.uppercased() ?? ""
    }
    
    var body: some View {
        ZStack(alignment: .center){
            Circle()
                .frame(height: 130)
            Text("\(first)\(last)")
                .font(Theme.monogram)
                .foregroundStyle(.textPrimary)
        }
    }
}

#Preview {
    ContactMonogram(firstName: "Agustin", lastName: "Nanni")
}
