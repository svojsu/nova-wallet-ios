import UIKit
import SoraUI

struct StakingStateSkeletonOptions: OptionSet {
    typealias RawValue = UInt8

    static let stake = StakingStateSkeletonOptions(rawValue: 1 << 0)
    static let status = StakingStateSkeletonOptions(rawValue: 1 << 1)
    static let price = StakingStateSkeletonOptions(rawValue: 1 << 2)

    let rawValue: UInt8

    init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
}

protocol StakingStateViewDelegate: AnyObject {
    func stakingStateViewDidReceiveMoreAction(_ view: StakingStateView)
}

class StakingStateView: UIView {
    weak var delegate: StakingStateViewDelegate?

    let backgroundView: UIView = TriangularedBlurView()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .p1Paragraph
        label.textColor = R.color.colorTransparentText()
        return label
    }()

    let iconMore: UIImageView = {
        let view = UIImageView()
        view.image = R.image.iconMore()?.withRenderingMode(.alwaysTemplate)
        view.tintColor = R.color.colorWhite48()
        return view
    }()

    let stakeAmountView: MultiValueView = {
        let view = MultiValueView()
        view.valueTop.font = .boldTitle1
        view.valueTop.textColor = R.color.colorWhite()
        view.valueTop.textAlignment = .center
        view.valueBottom.font = .p0Paragraph
        view.valueBottom.textColor = R.color.colorTransparentText()
        view.valueBottom.textAlignment = .center
        view.spacing = 6.0
        view.isUserInteractionEnabled = false
        return view
    }()

    let statusView: StakingStatusView = {
        let view = StakingStatusView()
        view.backgroundView.fillColor = R.color.colorWhite8()!
        view.backgroundView.highlightedFillColor = R.color.colorWhite8()!
        view.isUserInteractionEnabled = false
        return view
    }()

    let moreButton: RoundedButton = {
        let button = RoundedButton()
        button.roundedBackgroundView?.cornerRadius = 12.0
        button.roundedBackgroundView?.fillColor = .clear
        button.roundedBackgroundView?.highlightedFillColor = R.color.colorAccentSelected()!
        button.roundedBackgroundView?.shadowOpacity = 0.0
        return button
    }()

    private var skeletonView: SkrullableView?
    private var skeletonOptions: StakingStateSkeletonOptions?

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()
        configure()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure() {
        moreButton.addTarget(self, action: #selector(actionOnMore), for: .touchUpInside)
    }

    func setupLayout() {
        addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        addSubview(iconMore)
        iconMore.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16.0)
            make.top.equalToSuperview().inset(12.0)
        }

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(20.0)
            make.centerX.equalToSuperview()
            make.trailing.lessThanOrEqualTo(iconMore.snp.leading).offset(2.0)
        }

        addSubview(stakeAmountView)
        stakeAmountView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4.0)
            make.centerX.equalToSuperview()
        }

        addSubview(statusView)
        statusView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(stakeAmountView.snp.bottom).offset(14.0)
            make.bottom.equalToSuperview().offset(-24.0)
        }

        insertSubview(moreButton, aboveSubview: backgroundView)
        moreButton.snp.makeConstraints { make in
            make.edges.equalTo(backgroundView)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if let options = skeletonOptions {
            setupSkeleton(options: options)
        }
    }

    @objc private func actionOnMore() {
        delegate?.stakingStateViewDidReceiveMoreAction(self)
    }
}

extension StakingStateView {
    func setupSkeleton(options: StakingStateSkeletonOptions) {
        skeletonOptions = nil

        guard !options.isEmpty else {
            skeletonView?.removeFromSuperview()
            skeletonView = nil
            return
        }

        skeletonOptions = options

        let spaceSize = backgroundView.frame.size

        let skeletons = createSkeletons(for: spaceSize, options: options)

        let builder = Skrull(
            size: spaceSize,
            decorations: [],
            skeletons: skeletons
        )

        let currentSkeletonView: SkrullableView?

        if let skeletonView = skeletonView {
            currentSkeletonView = skeletonView
            builder.updateSkeletons(in: skeletonView)
        } else {
            let view = builder
                .fillSkeletonStart(R.color.colorSkeletonStart()!)
                .fillSkeletonEnd(color: R.color.colorSkeletonEnd()!)
                .build()
            view.autoresizingMask = []
            insertSubview(view, aboveSubview: backgroundView)

            currentSkeletonView = view
            skeletonView = view

            view.startSkrulling()
        }

        currentSkeletonView?.frame = CGRect(origin: .zero, size: spaceSize)
    }

    private func createSkeletons(
        for spaceSize: CGSize,
        options: StakingStateSkeletonOptions
    ) -> [Skeletonable] {
        guard spaceSize.width > 0.0, spaceSize.height > 0.0 else {
            return []
        }

        var skeletons: [Skeletonable] = []

        if options.contains(.stake) {
            let stakeSkeletons = createMultilineSkeleton(
                under: titleLabel,
                containerView: backgroundView,
                spaceSize: spaceSize,
                hasAuxRow: options.contains(.price)
            )

            skeletons.append(contentsOf: stakeSkeletons)
        }

        if options.contains(.status) {
            let statusSkeleton = createStatusSkeleton(for: spaceSize)
            skeletons.append(statusSkeleton)
        }

        return skeletons
    }

    private func createStatusSkeleton(for spaceSize: CGSize) -> Skeletonable {
        let bigRowSize = UIConstants.skeletonBigRowSize

        let offset = CGPoint(
            x: statusView.frame.midX - bigRowSize.width / 2.0,
            y: spaceSize.height - 24.0 - statusView.frame.size.height / 2.0 - bigRowSize.height / 2.0
        )

        return SingleSkeleton.createRow(
            on: backgroundView,
            containerView: backgroundView,
            spaceSize: spaceSize,
            offset: offset,
            size: bigRowSize
        )
    }

    private func createMultilineSkeleton(
        under view: UIView,
        containerView: UIView,
        spaceSize: CGSize,
        hasAuxRow: Bool
    ) -> [Skeletonable] {
        let topInset: CGFloat = 7.0
        let verticalSpacing: CGFloat = 10.0

        var skeletons: [Skeletonable] = [
            SingleSkeleton.createRow(
                under: view,
                containerView: containerView,
                spaceSize: spaceSize,
                offset: CGPoint(x: 0.0, y: topInset),
                size: UIConstants.skeletonBigRowSize
            )
        ]

        if hasAuxRow {
            let yOffset = topInset + UIConstants.skeletonBigRowSize.height + verticalSpacing
            skeletons.append(
                SingleSkeleton.createRow(
                    under: view,
                    containerView: containerView,
                    spaceSize: spaceSize,
                    offset: CGPoint(x: 0.0, y: yOffset),
                    size: UIConstants.skeletonSmallRowSize
                )
            )
        }

        return skeletons
    }
}

extension StakingStateView: SkeletonLoadable {
    func didDisappearSkeleton() {
        skeletonView?.stopSkrulling()
    }

    func didAppearSkeleton() {
        skeletonView?.stopSkrulling()
        skeletonView?.startSkrulling()
    }

    func didUpdateSkeletonLayout() {
        guard let skeletonOptions = skeletonOptions else {
            return
        }

        setupSkeleton(options: skeletonOptions)
    }
}