public protocol BindableCell: ReusableCell {
    func bind(to cell: Identifier.CellType)
}
