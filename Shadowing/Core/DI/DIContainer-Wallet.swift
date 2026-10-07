import Foundation
import SwiftUI

    /// Factory methods for the earnings wallet screen.
extension DIContainer {

        /// The wallet screen (balance + withdrawal request), pushed from the profile.
    func makeWalletView() -> WalletView {
        WalletView(vm: makeWalletViewModel())
    }

        /// Creates a fresh view model for the wallet screen.
    func makeWalletViewModel() -> WalletViewModel {
        WalletViewModel(repo: walletRepository)
    }
}
