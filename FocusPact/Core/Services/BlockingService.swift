import Foundation
import NetworkExtension
import Combine

@MainActor
final class BlockingService: ObservableObject {
    @Published var isBlocking: Bool = false
    @Published var activeBlocklistName: String = ""
    @Published var activeDomains: [String] = []

    private let appGroupID = "group.com.yourname.focuspact"
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    func startBlocking(name: String, domains: [String]) {
        if let data = try? JSONEncoder().encode(domains) {
            sharedDefaults?.set(data, forKey: "activeBlockedDomains")
        }
        sharedDefaults?.set(name, forKey: "activeBlocklistName")
        sharedDefaults?.synchronize()
        activeDomains = domains
        activeBlocklistName = name

        NEFilterManager.shared().loadFromPreferences { [weak self] _ in
            guard let self else { return }
            if NEFilterManager.shared().providerConfiguration == nil {
                let config = NEFilterProviderConfiguration()
                config.filterSockets = true
                NEFilterManager.shared().providerConfiguration = config
            }
            NEFilterManager.shared().isEnabled = true
            NEFilterManager.shared().saveToPreferences { _ in
                Task { @MainActor in
                    self.isBlocking = true
                }
            }
        }
    }

    func stopBlocking() {
        sharedDefaults?.removeObject(forKey: "activeBlockedDomains")
        sharedDefaults?.removeObject(forKey: "activeBlocklistName")
        sharedDefaults?.synchronize()
        activeDomains = []
        activeBlocklistName = ""

        NEFilterManager.shared().loadFromPreferences { [weak self] _ in
            NEFilterManager.shared().isEnabled = false
            NEFilterManager.shared().saveToPreferences { _ in
                Task { @MainActor [weak self] in
                    self?.isBlocking = false
                }
            }
        }
    }

    func isURLBlocked(_ urlString: String) -> Bool {
        let host: String
        if let h = URL(string: urlString)?.host {
            host = h
        } else if let h = urlString.components(separatedBy: "/").first {
            host = h
        } else {
            return false
        }
        let normalized = host.lowercased().hasPrefix("www.")
            ? String(host.dropFirst(4))
            : host.lowercased()
        return activeDomains.contains { domain in
            normalized == domain || normalized.hasSuffix("." + domain)
        }
    }

    func updateActiveDomainsIfNeeded(for blocklist: BlockList) {
        guard isBlocking && activeBlocklistName == blocklist.name else { return }
        activeDomains = blocklist.domains
        if let data = try? JSONEncoder().encode(blocklist.domains) {
            sharedDefaults?.set(data, forKey: "activeBlockedDomains")
            sharedDefaults?.synchronize()
        }
    }

    func loadActiveState() {
        guard
            let name = sharedDefaults?.string(forKey: "activeBlocklistName"),
            !name.isEmpty,
            let data = sharedDefaults?.data(forKey: "activeBlockedDomains"),
            let domains = try? JSONDecoder().decode([String].self, from: data)
        else { return }
        activeBlocklistName = name
        activeDomains = domains
        isBlocking = true
    }
}
