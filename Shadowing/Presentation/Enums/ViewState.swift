import Foundation

enum ViewState<Value> {
    case loading
    case error(String)
    case empty
    case loaded(Value)
}
