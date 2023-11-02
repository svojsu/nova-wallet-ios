import SoraUI

final class SwapNetworkFeeViewCell: RowView<SwapNetworkFeeView>, StackTableViewCellProtocol {
    var titleButton: RoundedButton { rowContentView.titleView }
    var valueTopButton: RoundedButton { rowContentView.valueView.fView }
    var valueBottomLabel: UILabel { rowContentView.valueView.sView }

    func bind(loadableViewModel: LoadableViewModelState<SwapFeeViewModel>) {
        rowContentView.bind(loadableViewModel: loadableViewModel)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let pointInContentViewSpace = convert(point, to: rowContentView)
        if rowContentView.valueView.frame.contains(pointInContentViewSpace) {
            return valueTopButton
        } else {
            return super.hitTest(point, with: event)
        }
    }
}
