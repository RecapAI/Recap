import Foundation

protocol LLMModelType: Identifiable, Hashable {
  var id: String { get }
  var name: String { get }
  var provider: String { get }
  var contextLength: Int32? { get }
}
