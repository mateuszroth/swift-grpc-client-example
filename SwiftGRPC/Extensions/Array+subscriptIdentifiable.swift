import Foundation

extension Array where Element: Identifiable {
    public subscript(id: Element.ID) -> Element? {
        first { $0.id == id }
    }
}
