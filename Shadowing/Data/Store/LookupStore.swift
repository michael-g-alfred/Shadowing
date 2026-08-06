import Foundation
import Observation

@MainActor
@Observable
final class LookupStore {
    
    private(set) var roles: [RoleLookup] = []
    private(set) var accountStatuses: [AccountStatusLookup] = []
    private(set) var countries: [CountryLookup] = []
    private(set) var governorates: [GovernorateLookup] = []
    // Fixed: was `[CurrenciesLookup]` — that type doesn't exist anywhere in
    // LookupModels.swift (the domain type there is `CurrencyLookup`,
    // singular). This wouldn't compile before.
    private(set) var currencies: [CurrencyLookup] = []
    private(set) var priorities: [PriorityLookup] = []
    private(set) var statuses: [StatusLookup] = []
    private(set) var escrowStatuses: [EscrowStatusLookup] = []
    private(set) var timesOfDay: [TimeOfDayLookup] = []
    private(set) var services: [TaskServiceLookup] = []

    
    private(set) var isLoaded = false
    private(set) var isLoading = false
    
    private let lookupRepo: LookupRepositoryProtocol
    
    init(lookupRepo: LookupRepositoryProtocol) {
        self.lookupRepo = lookupRepo
    }
    
    func loadIfNeeded(locale: Locale = .current) async {
        guard !isLoaded, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            let dto = try await lookupRepo.fetchAllLookups()
            let all = dto.toDomain(locale: locale)
            
            roles = all.roles
            priorities = all.priorities
            statuses = all.statuses
            accountStatuses = all.accountStatuses
            escrowStatuses = all.escrowStatuses
            timesOfDay = all.timesOfDay
            services = all.services
            countries = all.countries
            governorates = all.governorates
            // Fixed: this assignment was missing entirely, so `currencies`
            // stayed empty forever even after a successful load.
            currencies = all.currencies
            isLoaded = true
        } catch {
            AlertCenter.shared.showError(error)
        }
    }
    
    func reload(locale: Locale = .current) async {
        isLoaded = false
        await loadIfNeeded(locale: locale)
    }
    
        // MARK: - Convenience lookups by ID & Name
    
    func governorates(for countryId: Int) -> [GovernorateLookup] {
        governorates.filter { $0.countryId == countryId }
    }
    
    func service(named name: String) -> TaskServiceLookup? {
        services.first { $0.name == name }
    }
    
    func priority(named name: String) -> PriorityLookup? {
        priorities.first { $0.name == name }
    }
    
    func status(named name: String) -> StatusLookup? {
        statuses.first { $0.name == name }
    }
    
    func escrowStatus(named name: String) -> EscrowStatusLookup? {
        escrowStatuses.first { $0.name == name }
    }
    
    func timeOfDay(named name: String) -> TimeOfDayLookup? {
        timesOfDay.first { $0.name == name }
    }
    
    func accountStatus(named name: String) -> AccountStatusLookup? {
        accountStatuses.first { $0.name == name }
    }
    
    func role(named name: String) -> RoleLookup? {
        roles.first { $0.name == name }
    }
    
    // New: matches the `named:`/`id:` convenience pattern every other
    // lookup already has — needed by AddTaskSheetViewModel to default-select
    // EGP and to resolve the picker's tag back to a currency.
    func currency(named code: String) -> CurrencyLookup? {
        currencies.first { $0.code == code }
    }
    
    func country(id: Int) -> CountryLookup? {
        countries.first { $0.id == id }
    }
    
    func governorate(id: Int) -> GovernorateLookup? {
        governorates.first { $0.id == id }
    }
    
    func role(id: Int) -> RoleLookup? {
        roles.first { $0.id == id }
    }
    
    func priority(id: Int) -> PriorityLookup? {
        priorities.first { $0.id == id }
    }
    
    func status(id: Int) -> StatusLookup? {
        statuses.first { $0.id == id }
    }
    
    func accountStatus(id: Int) -> AccountStatusLookup? {
        accountStatuses.first { $0.id == id }
    }
    
    func escrowStatus(id: Int) -> EscrowStatusLookup? {
        escrowStatuses.first { $0.id == id }
    }
    
    func timeOfDay(id: Int) -> TimeOfDayLookup? {
        timesOfDay.first { $0.id == id }
    }
    
    func service(id: Int) -> TaskServiceLookup? {
        services.first { $0.id == id }
    }
    
    func currency(id: Int) -> CurrencyLookup? {
        currencies.first { $0.id == id }
    }
}
