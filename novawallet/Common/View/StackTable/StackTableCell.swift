import UIKit

class StackTableCell: RowView<GenericTitleValueView<UILabel, IconDetailsView>> {
    var titleLabel: UILabel { rowContentView.titleView }

    var detailsLabel: UILabel { rowContentView.valueView.detailsLabel }

    var iconImageView: UIImageView { rowContentView.valueView.imageView }

    private var imageViewModel: ImageViewModelProtocol?

    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureStyle()
    }

    func bind(viewModel: StackCellViewModel?) {
        bind(
            details: viewModel?.details,
            imageViewModel: viewModel?.imageViewModel,
            cornerRadius: rowContentView.valueView.iconWidth / 2.0
        )
    }

    func bind(viewModel: StackCellViewModel?, cornerRadius: CGFloat?) {
        bind(
            details: viewModel?.details,
            imageViewModel: viewModel?.imageViewModel,
            cornerRadius: cornerRadius
        )
    }

    func bind(details: String) {
        bind(details: details, imageViewModel: nil, cornerRadius: nil)
    }

    private func bind(details: String?, imageViewModel: ImageViewModelProtocol?, cornerRadius: CGFloat?) {
        self.imageViewModel?.cancel(on: iconImageView)

        self.imageViewModel = imageViewModel

        detailsLabel.text = details
        iconImageView.image = nil

        let imageSize = rowContentView.valueView.iconWidth

        if let cornerRadius = cornerRadius {
            imageViewModel?.loadImage(
                on: iconImageView,
                targetSize: CGSize(width: imageSize, height: imageSize),
                cornerRadius: cornerRadius,
                animated: true
            )
        } else {
            imageViewModel?.loadImage(
                on: iconImageView,
                targetSize: CGSize(width: imageSize, height: imageSize),
                animated: true
            )
        }
    }

    private func configureStyle() {
        titleLabel.textColor = R.color.colorTextSecondary()
        titleLabel.font = .regularFootnote

        let valueView = rowContentView.valueView
        valueView.mode = .iconDetails
        detailsLabel.textColor = R.color.colorTextPrimary()
        detailsLabel.font = .regularFootnote
        detailsLabel.numberOfLines = 1
        valueView.spacing = 8.0
        valueView.iconWidth = 20.0

        preferredHeight = 44.0
        borderView.strokeColor = R.color.colorDivider()!

        isUserInteractionEnabled = false

        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        valueView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        valueView.detailsLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }
}

extension StackTableCell: StackTableViewCellProtocol {}
