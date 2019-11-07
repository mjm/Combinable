#if canImport(UIKit)

import UIKit

extension CellIdentifier where CellType == UITableViewCell {
    func register(with tableView: UITableView) {
        switch cellType {
        case let .class(cellClass):
            tableView.register(cellClass, forCellReuseIdentifier: rawValue)
        case let .nib(cellClass):
            cellClass.registerNib(on: tableView, reuseIdentifier: rawValue)
        case .storyboard:
            break
        }
    }
}

extension CellIdentifier where CellType == UICollectionViewCell {
    func register(with collectionView: UICollectionView) {
        switch cellType {
        case let .class(cellClass):
            collectionView.register(cellClass, forCellWithReuseIdentifier: rawValue)
        case let .nib(cellClass):
            cellClass.registerNib(on: collectionView, reuseIdentifier: rawValue)
        case .storyboard:
            break
        }
    }
}

extension Cell {
    static var nib: UINib {
        UINib(nibName: String(describing: self), bundle: nil)
    }
}

extension UITableViewCell: Cell {
    public typealias View = UITableView

    class func registerNib(on tableView: UITableView, reuseIdentifier: String) {
        tableView.register(nib, forCellReuseIdentifier: reuseIdentifier)
    }
}

extension UICollectionViewCell: Cell {
    public typealias View = UICollectionView

    class func registerNib(on collectionView: UICollectionView, reuseIdentifier: String) {
        collectionView.register(nib, forCellWithReuseIdentifier: reuseIdentifier)
    }
}

#endif
