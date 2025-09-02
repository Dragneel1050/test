//

import SwiftUI

struct Onboarding: View {
    @State private var state = OnboardingState()
    @State private var locationModel = LocationModel.shared
    @FocusState private var phoneFocus
    
    var body: some View {
        VStack{
            switch state.currentStep {
            case .entry:
                phoneEntry(focus: $phoneFocus)
            case .sent:
                codeEntry()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            phoneFocus = false
        }
        .background{
            Background()
        }
    }
    
    func phoneTextField(focus: FocusState<Bool>.Binding) -> some View {
        HStack(spacing: 10){
            Picker("Onboarding.SelectCode", selection: $state.countryCode) {
                ForEach(state.countryCodes, id: \.self) {
                    Text($0)
                        .font(Theme.barlowLight)
                }
            }
            .tint(.textPrimary)
            .pickerStyle(.automatic)
            Rectangle()
                .foregroundColor(.borderForm)
                .frame(width: 1, height: 20)
            TextField("", text: $state.phoneNumber)
                .font(Theme.barlowLight)
                .foregroundColor(.textPrimary)
                .keyboardType(.numberPad)
                .focused(focus)
            Spacer()
        }
        .frame(alignment: .top)
        .padding(.vertical, 10)
        .padding(.horizontal)
        .background{
            RoundedRectangle(cornerRadius: 8)
                .inset(by: 0.5)
                .fill(.surfaceFormControl)
                .stroke(state.phoneError ? .textError : .borderForm)
        }
        .padding(.horizontal, 20)
        .padding(.top, 30)
        .onChange(of: state.phoneNumber, { _, _ in
            state.phoneError = false
        })
    }
    
    func phoneEntry(focus: FocusState<Bool>.Binding) -> some View {
        VStack{
            OnboardingTopNav()
            ZStack{
                VStack{
                    Spacer()
                        .frame(height: 50)
                    Text("Onboarding.Welcome")
                        .font(Theme.onboardingSubtitle)
                        .foregroundStyle(.textHeader)
                    Text("Onboarding.Subtitle")
                        .font(Theme.regular)
                        .foregroundStyle(.textTitle)
                    Spacer()
                }
                VStack{
                    Spacer()
                        .frame(height: 230)
                    Text("Onboarding.PhoneNumberPrompt")
                        .font(Theme.formLabelTitle)
                        .foregroundStyle(.textHeader)
                    Text("Onboarding.PhoneNumberSubtitle")
                        .font(Theme.formLabelSubtitle)
                        .foregroundStyle(.textSecondary)
                    phoneTextField(focus: focus)
                    Spacer()
                        .frame(height: 40)
                    FormButton(action: state.sendSms, label: String(localized: "Onboarding.PhoneNumberVerify"), working: $state.working)
                        .padding(.vertical)
                    Spacer()
                }
            }
        }
    }
    
    func codeEntry() -> some View {
        VStack{
            OnboardingTopNav(onBack: state.back)
            VStack{
                Spacer()
                    .frame(height: 230)
                Text("SMS Verification")
                    .font(Theme.formLabelTitle)
                    .foregroundStyle(.textHeader)
                Text("Enter the code sent to \(state.completeNumber)")
                    .font(Theme.formLabelSubtitle)
                    .foregroundStyle(.textSecondary)
                CodeView(text: $state.code, error: $state.codeError)
                    .onChange(of: state.code, { _, _ in
                        state.codeError = false
                    })
                Spacer()
                    .frame(height: 50)
                FormButton(action: state.verifyCode, label: String(localized: "Onboarding.PhoneNumberVerifyAndContinue"), working: $state.working)
                Spacer()
                codeSubtitle()
                    .padding(.horizontal)
                Spacer()
                FormButton(action: state.resend, label: String(localized: "Onboarding.PhoneNumberVerifyResend"), working: $state.working, variant: .secondary)
                    .disabled(state.resendDisabled)
                Spacer()
            }
        }
    }
    
    func codeSubtitle() -> some View {
        if state.codeError {
            Text("Onboarding.PhoneNumberVerifyErrorInvalid")
                .font(Theme.formLabelSubtitle)
                .foregroundStyle(.textError)
        } else {
            Text("Onboarding.ResendPrompt")
                .font(Theme.formLabelSubtitle)
                .foregroundStyle(.textSecondary)
        }
    }
}

@Observable
class OnboardingState {
    enum verificationState{
        case entry, sent
    }
    
    let countryCodes = ["+1", "+54", "+92", "+598"]
    var countryCode = "+1"
    var phoneNumber = ""
    var code = ""
    var currentStep = verificationState.entry
    var resendDisabled = false
    var codeError = false
    var phoneError = false
    var working = false
    var completeNumber: String {
        self.countryCode +  self.phoneNumber
    }
    
    func back() {
        codeError = false
        currentStep = .entry
    }
    
    func sendSms() async {
        if self.phoneNumber.count < 5 {
            phoneError = true
            return
        }
        
        do {
            try await AuthModel.shared.requestPhoneCode(self.completeNumber)
            EventsModel.shared.track(PhoneLoginEvent(phoneNumber: self.completeNumber))
        } catch let err {
            
            if case ApiErrors.RequestTimeout = err {
                // Handle the timeout error
                await ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
            } else {
                AppLogs.defaultLogger.error("sendSms: \(err)")
                await ToastsModel.shared.notifyError(context: "OnboardingState.sendSms", error: err)
            }
        }
        currentStep = .sent
    }
    
    func resend() async {
        resendDisabled = true
        await self.sendSms()
        EventsModel.shared.track(SmsCodeResend(phoneNumber: self.completeNumber))
        Task{
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            resendDisabled = false
        }
    }
    
    func verifyCode() async {
        if self.code.count != 4 {
            self.codeError = true
            return
        }
        
        do {
            try await AuthModel.shared.verifyCode(number: self.completeNumber, code: self.code)
            doLogin()
            EventsModel.shared.track(SmsCodeVerification(phoneNumber: self.completeNumber))
        } catch let err {
            
            if case ApiErrors.RequestTimeout = err {
                // Handle the timeout error
                await ToastsModel.shared.notifyError(message: ApiErrors.RequestTimeout.message)
            } else {
                AppLogs.defaultLogger.error("verifyCode: \(err)")
                await ToastsModel.shared.notifyError(context: "OnboardingState.verifyCode", error: err )
            }
        }
    }
    
    func doLogin() {
        Task{ @MainActor in
            NavigationModel.shared.navigate(.home)
        }
        Task{
            _ = try? await ContactsModel.shared.listContacts()
        }
    }
}

#Preview {
    Onboarding()
}
