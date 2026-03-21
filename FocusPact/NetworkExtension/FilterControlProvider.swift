import NetworkExtension
import Foundation

class FilterControlProvider: NEFilterControlProvider {

    override func startFilter(completionHandler: @escaping (Error?) -> Void) {
        completionHandler(nil)
    }

    override func stopFilter(
        with reason: NEProviderStopReason,
        completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }

    override func handleRemediation(
        for flow: NEFilterFlow,
        completionHandler: @escaping (NEFilterControlVerdict) -> Void
    ) {
        completionHandler(.allow(withUpdateRules: false))
    }

    override func handleNewFlow(
        _ flow: NEFilterFlow,
        completionHandler: @escaping (NEFilterControlVerdict) -> Void
    ) {
        completionHandler(.allow(withUpdateRules: false))
    }
}
