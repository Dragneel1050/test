//

import SwiftUI

struct AppProgressView: View {
    var body: some View {
        VStack{
            Spacer()
            ProgressView()
                .tint(.textHeader)
            Spacer()
            HStack{
                Spacer()
            }
        }
    }
}

#Preview {
    AppProgressView()
}
