import SwiftUI

struct WalletView: View {

    // MARK: Environment
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale

    // MARK: State
    @State private var vm: WalletViewModel

    // MARK: Init
    init(vm: WalletViewModel) {
        _vm = State(initialValue: vm)
    }

    private var listRowColor: Color? {
        colorScheme == .dark ? Color.accentColor.opacity(0.15) : nil
    }

    // MARK: Body
    var body: some View {
        ScreenContainer(content: {
            content
        })
        .navigationTitle("Wallet")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.loadWallet() }
        .refreshable { await vm.loadWallet(showLoadingIndicator: false) }
    }

    // MARK: Content
    @ViewBuilder
    private var content: some View {
        if vm.isLoading && vm.balance == nil {
            LoadingState.loading(title: "Loading wallet").view
        } else if let error = vm.errorMessage, vm.balance == nil {
            LoadingState.error(message: error).view
        } else if let balance = vm.balance {
            List {
                balanceSection(balance)
                withdrawSection(balance)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }

    // MARK: Balance
    private func balanceSection(_ balance: WalletBalance) -> some View {
        Section {
            InfoRow(
                title: "Pending",
                systemImage: "hourglass",
                value: money(balance.pendingEGP),
                iconColor: .orange
            )
            InfoRow(
                title: "Available",
                systemImage: "checkmark.circle.fill",
                value: money(balance.availableEGP),
                iconColor: .green
            )
            InfoRow(
                title: "Withdrawn",
                systemImage: "arrow.up.right.circle.fill",
                value: money(balance.withdrawnEGP),
                iconColor: .blue
            )
        } header: {
            Text("Balance")
        } footer: {
            Text("Earnings become available once the requester confirms the task is completed.")
        }
        .listRowBackground(listRowColor)
    }

    // MARK: Withdraw
    private func withdrawSection(_ balance: WalletBalance) -> some View {
        Section {
            TextField("Amount", value: Bindable(vm).amount, format: .number)
                .keyboardType(.decimalPad)

            TextField("Mobile wallet number", text: Bindable(vm).walletNumber)
                .keyboardType(.numberPad)
                .textContentType(.telephoneNumber)

            Button {
                Task { await vm.requestPayout() }
            } label: {
                HStack {
                    Spacer()
                    if vm.isSubmitting {
                        ProgressView()
                    } else {
                        Text("Request Withdrawal").bold()
                    }
                    Spacer()
                }
            }
            .disabled(!vm.canSubmit)
        } header: {
            Text("Withdraw Earnings")
        } footer: {
            Text("Withdrawals are sent manually to your mobile wallet after review.")
        }
        .listRowBackground(listRowColor)
        .disabled(vm.isSubmitting)
    }

    // MARK: Helpers
    private func money(_ value: Double) -> String {
        value.formatted(.currency(code: "EGP").locale(locale))
    }
}
