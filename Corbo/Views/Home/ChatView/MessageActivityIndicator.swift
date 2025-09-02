import SwiftUI

struct MessageActivityIndicator: View {
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 2){
            loadingCircle(animate: $animate, delay: 0.4)
            loadingCircle(animate: $animate, delay: 0.2)
            loadingCircle(animate: $animate, delay: 0)
        }.onAppear{
            animate = true
        }
    }
}

fileprivate struct loadingCircle: View {
    @Binding var animate: Bool
    let delay: Double
    
    var body: some View {
        ZStack{
            Circle()
                .foregroundColor(.clear)
                .frame(width: 10)
            
            Circle()
                .foregroundColor(.chatTextTranscript)
                .frame(width: 10)
                .opacity(animate ? 0.8 : 1)
                .scaleEffect(animate ? 0.8 : 1)
                .animation(.easeInOut(duration: 0.4).delay(delay).repeatForever(autoreverses: true), value: animate)
        }
    }
}

#Preview {
    MessageActivityIndicator()
}
