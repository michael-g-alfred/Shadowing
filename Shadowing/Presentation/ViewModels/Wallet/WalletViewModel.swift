import Foundation

/// Drives the wallet screen: shows the user's earnings and submits
/// withdrawal requests.
@MainActor
@Observable
final class WalletViewModel {

    // MARK: - State

    private(set) var balance: WalletBalance?
    private(set) var isLoading = false
    private(set) var isSubmitting = false
    private(set) var errorMessage: String?

    /// Amount typed by the user (EGP).
    var amount: Double?

    /// Mobile wallet number typed by the user.
    var walletNumber = ""

    private let repo: WalletRepositoryProtocol

    init(repo: WalletRepositoryProtocol) {
        self.repo = repo
    }

    // MARK: - Validation

    /// The wallet number with Arabic-Indic / Persian digits turned into
    /// ASCII digits (the server only accepts ASCII), spaces and dashes removed.
    var normalizedWalletNumber: String {
        var result = ""
        for character in walletNumber {
            if let scalar = character.unicodeScalars.first {
                switch scalar.value {
                    case 0x0660...0x0669: // Arabic-Indic digits
                        result.append(String(scalar.value - 0x0660))
                    case 0x06F0...0x06F9: // Extended Arabic-Indic digits
                        result.append(String(scalar.value - 0x06F0))
                    default:
                        if character != " " && character != "-" {
                            result.append(character)
                        }
                }
            }
        }
        return result
    }

    /// Egyptian mobile wallet number: 01[0|1|2|5] + 8 digits (same rule as the server).
    var isWalletNumberValid: Bool {
        normalizedWalletNumber.range(of: "^01[0125][0-9]{8}$", options: .regularExpression) != nil
    }

    private var roundedAmount: Double? {
        guard let amount else { return nil }
        return (amount * 100).rounded() / 100
    }

    var isAmountValid: Bool {
        guard let roundedAmount, roundedAmount > 0, let balance else { return false }
        return roundedAmount <= balance.availableEGP
    }

    var canSubmit: Bool {
        isAmountValid && isWalletNumberValid && !isSubmitting
    }

    // MARK: - Loading

    func loadWallet(showLoadingIndicator: Bool = true) async {
        if showLoadingIndicator { isLoading = true }
        errorMessage = nil
        defer { isLoading = false }

        do {
            balance = try await repo.getWallet()
        } catch {
            // Keep showing the last known balance on a refresh failure.
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Withdraw

    func requestPayout() async {
        guard canSubmit, let roundedAmount else { return }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let receipt = try await repo.requestPayout(
                amount: roundedAmount,
                walletNumber: normalizedWalletNumber
            )

            AlertCenter.shared.show(
                responseType: receipt.type,
                message: receipt.message
            )

            amount = nil
            await loadWallet(showLoadingIndicator: false)
        } catch {
            AlertCenter.shared.showError(error.localizedDescription)
        }
    }
}
