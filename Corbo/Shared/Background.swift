//

import SwiftUI

struct Background: View {
    var body: some View {
        GeometryReader { geo in
            VStack{
                LinearGradient(colors: [
                    Color.surfaceApp,
                    Color.bgGradient
                ], startPoint: UnitPoint(x: 0, y: 0), endPoint: UnitPoint(x: 1.2, y: 0))
                .rotationEffect(.degrees(180))
                .rotationEffect(.degrees(150))
                .offset(x: -90, y: geo.frame(in: .global).height * -0.95)
                .blur(radius: 40)
                Spacer()
            }
        }.background(.surfaceApp)
    }
}

#Preview {
    Background()
}
