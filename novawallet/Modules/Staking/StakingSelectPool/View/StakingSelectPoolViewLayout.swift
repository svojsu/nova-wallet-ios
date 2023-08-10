import UIKit
import SoraUI

final class StakingSelectPoolViewLayout: UIView {
    let recommendedButton: RoundedButton = .create {
        $0.applySecondaryStyle()
        $0.roundedBackgroundView?.fillColor = R.color.colorButtonBackgroundInactive()!
        $0.roundedBackgroundView?.highlightedFillColor = R.color.colorButtonBackgroundSecondary()!
    }

    let tableView: UITableView = .create {
        $0.tableFooterView = UIView()
        $0.backgroundColor = .clear
        $0.separatorStyle = .none
        $0.registerClassForCell(StakingPoolTableViewCell.self)
        $0.registerHeaderFooterView(withClass: StakingSelectPoolListHeaderView.self)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = R.color.colorSecondaryScreenBackground()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        addSubview(recommendedButton)
        recommendedButton.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.top.equalToSuperview().inset(12)
            $0.trailing.lessThanOrEqualToSuperview()
            $0.height.equalTo(32)
        }

        addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(recommendedButton.snp.bottom).inset(16)
            $0.leading.bottom.trailing.equalToSuperview()
        }
    }
}
