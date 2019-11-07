public protocol ReusableCell: Hashable {
    associatedtype Identifier: CellIdentifier

    var cellIdentifier: Identifier { get }

    static var allCellIdentifiers: [Identifier] { get }
}

extension ReusableCell {
    public static func register(with view: Identifier.CellType.View) {
        for identifier in allCellIdentifiers {
            identifier.register(with: view)
        }
    }
}

extension ReusableCell where Identifier: CaseIterable {
    public static var allCellIdentifiers: [Identifier] {
        Array(Identifier.allCases)
    }
}

public protocol CellIdentifier: RawRepresentable where RawValue == String {
    associatedtype CellType: Cell

    var cellType: RegisteredCellType<CellType> { get }
    func register(with: CellType.View)
}

public enum RegisteredCellType<T: Cell> {
    case `class`(T.Type)
    case nib(T.Type)
    case storyboard
}

public protocol Cell: class {
    associatedtype View
}
