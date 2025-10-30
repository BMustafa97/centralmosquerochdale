import SwiftUI
import PassKit

// Donation Models
struct DonationProject: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let goal: Double
    let raised: Double
    let color: Color
    
    var progress: Double {
        min(raised / goal, 1.0)
    }
    
    var progressText: String {
        String(format: "£%.0f / £%.0f", raised, goal)
    }
}

// Payment Coordinator for Apple Pay
class PaymentCoordinator: NSObject, PKPaymentAuthorizationViewControllerDelegate {
    var onPaymentSuccess: (() -> Void)?
    var onPaymentFailure: ((Error) -> Void)?
    var amount: Decimal = 0
    var projectTitle: String = ""
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, 
                                           didAuthorizePayment payment: PKPayment, 
                                           handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        // Process the payment here
        // In production, you would send payment.token to your backend
        
        // Simulate successful payment
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
            self.onPaymentSuccess?()
        }
    }
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true)
    }
}

// ViewModel for Donation
class DonationViewModel: ObservableObject {
    @Published var selectedAmount: Double?
    @Published var customAmount: String = ""
    @Published var selectedProject: DonationProject?
    @Published var showingPaymentSheet = false
    @Published var showingSuccessMessage = false
    @Published var paymentMessage = ""
    
    let quickAmounts = [5.0, 10.0, 20.0, 50.0, 100.0, 200.0]
    
    let projects = [
        DonationProject(
            title: "General Fund",
            description: "Support daily operations and maintenance",
            icon: "building.2",
            goal: 10000,
            raised: 6500,
            color: Color.green
        ),
        DonationProject(
            title: "Renovation Project",
            description: "Mosque building improvements",
            icon: "hammer",
            goal: 50000,
            raised: 32000,
            color: Color.blue
        ),
        DonationProject(
            title: "Community Programs",
            description: "Education and youth activities",
            icon: "person.3",
            goal: 15000,
            raised: 8500,
            color: Color.orange
        ),
        DonationProject(
            title: "Ramadan Food Bank",
            description: "Provide meals for those in need",
            icon: "heart",
            goal: 8000,
            raised: 5200,
            color: Color.red
        ),
        DonationProject(
            title: "Islamic School",
            description: "Support Quran and Arabic classes",
            icon: "book",
            goal: 12000,
            raised: 7800,
            color: Color.purple
        )
    ]
    
    var donationAmount: Double {
        if let selected = selectedAmount {
            return selected
        }
        return Double(customAmount) ?? 0.0
    }
    
    func processApplePayment(project: DonationProject?, completion: @escaping (Bool, String) -> Void) {
        guard donationAmount > 0 else {
            completion(false, "Please enter a valid amount")
            return
        }
        
        // Check if Apple Pay is available
        if !PKPaymentAuthorizationViewController.canMakePayments() {
            completion(false, "Apple Pay is not available on this device")
            return
        }
        
        // Create payment request
        let request = PKPaymentRequest()
        request.merchantIdentifier = "merchant.com.centralmosquerochdale" // Replace with your merchant ID
        request.supportedNetworks = [.visa, .masterCard, .amex, .discover]
        request.merchantCapabilities = .capability3DS
        request.countryCode = "GB"
        request.currencyCode = "GBP"
        
        let projectName = project?.title ?? "General Donation"
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: projectName, amount: NSDecimalNumber(value: donationAmount)),
            PKPaymentSummaryItem(label: "Central Mosque Rochdale", amount: NSDecimalNumber(value: donationAmount))
        ]
        
        if let controller = PKPaymentAuthorizationViewController(paymentRequest: request) {
            let coordinator = PaymentCoordinator()
            coordinator.amount = Decimal(donationAmount)
            coordinator.projectTitle = projectName
            coordinator.onPaymentSuccess = {
                completion(true, "Thank you for your generous donation of £\(String(format: "%.2f", self.donationAmount))!")
            }
            coordinator.onPaymentFailure = { error in
                completion(false, "Payment failed: \(error.localizedDescription)")
            }
            controller.delegate = coordinator
            
            // Present the controller
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(controller, animated: true)
            }
        } else {
            completion(false, "Unable to process Apple Pay")
        }
    }
    
    func resetSelection() {
        selectedAmount = nil
        customAmount = ""
        selectedProject = nil
    }
}

// Main Donation View
struct DonationView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var viewModel = DonationViewModel()
    @State private var showingProjectSelection = false
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(themeManager.accentColor)
                        
                        Text("Support Your Mosque")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.textPrimary)
                        
                        Text("Your donations help maintain our mosque and support community programs")
                            .font(.subheadline)
                            .foregroundColor(themeManager.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // Active Projects
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Active Projects")
                            .font(.headline)
                            .foregroundColor(themeManager.textPrimary)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.projects) { project in
                                    ProjectCard(project: project, isSelected: viewModel.selectedProject?.id == project.id)
                                        .onTapGesture {
                                            withAnimation {
                                                if viewModel.selectedProject?.id == project.id {
                                                    viewModel.selectedProject = nil
                                                } else {
                                                    viewModel.selectedProject = project
                                                }
                                            }
                                        }
                                        .environmentObject(themeManager)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Quick Donation Amounts
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Select Amount")
                            .font(.headline)
                            .foregroundColor(themeManager.textPrimary)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(viewModel.quickAmounts, id: \.self) { amount in
                                QuickAmountButton(
                                    amount: amount,
                                    isSelected: viewModel.selectedAmount == amount
                                )
                                .onTapGesture {
                                    withAnimation {
                                        if viewModel.selectedAmount == amount {
                                            viewModel.selectedAmount = nil
                                        } else {
                                            viewModel.selectedAmount = amount
                                            viewModel.customAmount = ""
                                        }
                                    }
                                }
                                .environmentObject(themeManager)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Custom Amount
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Or Enter Custom Amount")
                            .font(.headline)
                            .foregroundColor(themeManager.textPrimary)
                            .padding(.horizontal)
                        
                        HStack {
                            Text("£")
                                .font(.title2)
                                .foregroundColor(themeManager.textSecondary)
                            
                            TextField("Enter amount", text: $viewModel.customAmount)
                                .keyboardType(.decimalPad)
                                .font(.title2)
                                .foregroundColor(themeManager.textPrimary)
                                .onChange(of: viewModel.customAmount) { _ in
                                    viewModel.selectedAmount = nil
                                }
                        }
                        .padding()
                        .background(themeManager.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(themeManager.accentColor.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal)
                    }
                    
                    // Selected Project Info
                    if let project = viewModel.selectedProject {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: project.icon)
                                    .foregroundColor(project.color)
                                Text("Donating to: \(project.title)")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.textPrimary)
                                Spacer()
                            }
                            .padding()
                            .background(project.color.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Payment Buttons
                    VStack(spacing: 12) {
                        // Apple Pay Button
                        Button(action: {
                            viewModel.processApplePayment(project: viewModel.selectedProject) { success, message in
                                viewModel.paymentMessage = message
                                viewModel.showingSuccessMessage = true
                                
                                if success {
                                    // Reset after success
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        viewModel.resetSelection()
                                    }
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "apple.logo")
                                    .font(.title3)
                                Text("Pay with Apple Pay")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.donationAmount <= 0)
                        .opacity(viewModel.donationAmount > 0 ? 1 : 0.5)
                        
                        // Google Pay Button (Placeholder for iOS)
                        Button(action: {
                            // Google Pay would be handled differently on iOS
                            viewModel.paymentMessage = "Google Pay is primarily for Android. Please use Apple Pay on this device."
                            viewModel.showingSuccessMessage = true
                        }) {
                            HStack {
                                Image(systemName: "g.circle.fill")
                                    .font(.title3)
                                Text("Pay with Google Pay")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(Color(red: 0.26, green: 0.52, blue: 0.96))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 0.26, green: 0.52, blue: 0.96), lineWidth: 1)
                            )
                        }
                        .disabled(viewModel.donationAmount <= 0)
                        .opacity(viewModel.donationAmount > 0 ? 1 : 0.5)
                        
                        // Alternative: Card Payment Button
                        Button(action: {
                            viewModel.paymentMessage = "Card payment integration coming soon!"
                            viewModel.showingSuccessMessage = true
                        }) {
                            HStack {
                                Image(systemName: "creditcard")
                                    .font(.title3)
                                Text("Pay with Card")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(themeManager.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.donationAmount <= 0)
                        .opacity(viewModel.donationAmount > 0 ? 1 : 0.5)
                    }
                    .padding(.horizontal)
                    
                    // Info Section
                    VStack(spacing: 12) {
                        InfoRow(icon: "lock.shield", text: "Secure payment processing")
                        InfoRow(icon: "checkmark.seal", text: "100% of your donation goes to the mosque")
                        InfoRow(icon: "doc.text", text: "Receipt sent via email")
                    }
                    .padding()
                    .background(themeManager.cardBackground.opacity(0.5))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
            }
        }
        .navigationTitle("Donate")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Donation Status", isPresented: $viewModel.showingSuccessMessage) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.paymentMessage)
        }
    }
}

// Supporting Views
struct ProjectCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let project: DonationProject
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: project.icon)
                    .font(.title2)
                    .foregroundColor(project.color)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(project.color)
                }
            }
            
            Text(project.title)
                .font(.headline)
                .foregroundColor(themeManager.textPrimary)
                .lineLimit(2)
            
            Text(project.description)
                .font(.caption)
                .foregroundColor(themeManager.textSecondary)
                .lineLimit(2)
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(themeManager.textSecondary.opacity(0.2))
                            .frame(height: 6)
                            .cornerRadius(3)
                        
                        Rectangle()
                            .fill(project.color)
                            .frame(width: geometry.size.width * project.progress, height: 6)
                            .cornerRadius(3)
                    }
                }
                .frame(height: 6)
                
                Text(project.progressText)
                    .font(.caption2)
                    .foregroundColor(themeManager.textSecondary)
            }
        }
        .padding()
        .frame(width: 200)
        .background(isSelected ? project.color.opacity(0.1) : themeManager.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? project.color : Color.clear, lineWidth: 2)
        )
        .shadow(color: themeManager.primaryColor.opacity(0.1), radius: 3, x: 0, y: 2)
    }
}

struct QuickAmountButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    let amount: Double
    let isSelected: Bool
    
    var body: some View {
        VStack {
            Text("£\(Int(amount))")
                .font(.headline)
                .foregroundColor(isSelected ? .white : themeManager.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(isSelected ? themeManager.accentColor : themeManager.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager.accentColor.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
        )
        .shadow(color: themeManager.primaryColor.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
        }
    }
}

#Preview {
    NavigationView {
        DonationView()
            .environmentObject(ThemeManager())
    }
}
