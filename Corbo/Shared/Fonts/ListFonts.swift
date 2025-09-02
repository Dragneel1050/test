//

import SwiftUI

struct ListFonts: View {
    var body: some View {
        Text("Hello, World!")
            .onAppear{
                for family in UIFont.familyNames.sorted() {
                    let names = UIFont.fontNames(forFamilyName: family)
                    AppLogs.defaultLogger.info("Family: \(family) Font names: \(names)")
                }
            }
    }
}

#Preview {
    ListFonts()
}
