import UIKit
import SoraFoundation

final class AnalyticsValidatorsViewController: UIViewController, ViewHolder {
    typealias RootViewType = AnalyticsValidatorsView

    let presenter: AnalyticsValidatorsPresenterProtocol

    private var state: AnalyticsViewState<AnalyticsValidatorsViewModel>?

    init(presenter: AnalyticsValidatorsPresenterProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = AnalyticsValidatorsView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTable()
        rootView.pageSelector.delegate = self
        presenter.setup()
    }

    private func setupTable() {
        rootView.tableView.registerClassForCell(AnalyticsValidatorsCell.self)
        rootView.tableView.dataSource = self
        rootView.tableView.delegate = self
        rootView.tableView.refreshControl?.addTarget(
            self,
            action: #selector(refreshControlDidTriggered),
            for: .valueChanged
        )
    }

    @objc
    private func refreshControlDidTriggered() {
        presenter.reload()
    }
}

extension AnalyticsValidatorsViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        guard case let .loaded(viewModel) = state else { return 0 }
        return viewModel.validators.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithType(AnalyticsValidatorsCell.self, forIndexPath: indexPath)
        guard case let .loaded(viewModel) = state else {
            return cell
        }
        let cellViewModel = viewModel.validators[indexPath.row]
        cell.bind(viewModel: cellViewModel)
        cell.delegate = self
        return cell
    }
}

extension AnalyticsValidatorsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard case let .loaded(viewModel) = state else {
            return
        }
        // TODO: show selected pie chart segment
    }
}

extension AnalyticsValidatorsViewController: AnalyticsValidatorsViewProtocol {
    var localizedTitle: LocalizableResource<String> {
        LocalizableResource { _ in
            "Validators"
        }
    }

    func reload(viewState: AnalyticsViewState<AnalyticsValidatorsViewModel>) {
        state = viewState

        switch viewState {
        case .loading:
            if !(rootView.tableView.refreshControl?.isRefreshing ?? true) {
                rootView.tableView.refreshControl?.beginRefreshing()
            }
        case let .loaded(viewModel):
            rootView.tableView.refreshControl?.endRefreshing()
            if !viewModel.validators.isEmpty {
                rootView.tableView.isHidden = false
                rootView.headerView.titleLabel.text = "Rewards"
                rootView.headerView.pieChart.setAmounts(
                    segmentValues: viewModel.pieChartSegmentValues,
                    inactiveSegmentValue: viewModel.pieChartInactiveSegmentValue
                )
                rootView.headerView.pieChart.setCenterText(viewModel.chartCenterText)
                rootView.headerView.titleLabel.text = viewModel.listTitle
                rootView.tableView.reloadData()
            }
        case let .error(error):
            rootView.tableView.refreshControl?.endRefreshing()
            rootView.tableView.isHidden = true
        }
    }
}

extension AnalyticsValidatorsViewController: AnalyticsValidatorsCellDelegate {
    func didTapInfoButton(in cell: AnalyticsValidatorsCell) {
        guard
            let indexPath = rootView.tableView.indexPath(for: cell),
            case let .loaded(viewModel) = state else {
            return
        }
        let cellViewModel = viewModel.validators[indexPath.row]

        presenter.handleValidatorInfoAction(validatorAddress: cellViewModel.validatorAddress)
    }
}

extension AnalyticsValidatorsViewController: AnalyticsValidatorsPageSelectorDelegate {
    func didSelectPage(_ page: AnalyticsValidatorsPage) {
        presenter.handlePageAction(page: page)
    }
}
