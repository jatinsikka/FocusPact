import NetworkExtension
import Foundation

class FilterDataProvider: NEFilterDataProvider {

    private let appGroupID = "group.com.yourname.focuspact"

    override func startFilter(completionHandler: @escaping (Error?) -> Void) {
        // On iOS, NEFilterDataProvider doesn't use NEFilterSettings
        // Simply complete the handler to indicate the filter is ready
        completionHandler(nil)
    }

    override func stopFilter(
        with reason: NEProviderStopReason,
        completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }

    override func handleNewFlow(_ flow: NEFilterFlow) -> NEFilterNewFlowVerdict {
        // Handle socket flows for domain-based filtering
        guard let socketFlow = flow as? NEFilterSocketFlow,
              let remoteEndpoint = socketFlow.remoteHostname else {
            return .allow()
        }

        let blockedDomains = loadBlockedDomains()
        let hostname = remoteEndpoint.lowercased()

        // Check if hostname matches any blocked domain
        for domain in blockedDomains {
            let lowerDomain = domain.lowercased()
            if hostname == lowerDomain || hostname.hasSuffix(".\(lowerDomain)") {
                // Block the connection
                return .drop()
            }
        }

        return .allow()
    }

    // MARK: - Private

    private func loadBlockedDomains() -> [String] {
        guard
            let defaults = UserDefaults(suiteName: appGroupID),
            let data = defaults.data(forKey: "activeBlockedDomains"),
            let domains = try? JSONDecoder().decode([String].self, from: data)
        else {
            return []
        }
        return domains
    }
}
