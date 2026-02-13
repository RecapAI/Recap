import Foundation

extension String {
  var lastReverseDNSComponent: String? {
    components(separatedBy: ".").last.flatMap { $0.isEmpty ? nil : $0 }
  }
}
