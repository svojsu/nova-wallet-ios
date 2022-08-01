import Foundation

final class ParitySignerWelcomePresenter {
    weak var view: ParitySignerWelcomeViewProtocol?
    let wireframe: ParitySignerWelcomeWireframeProtocol

    init(wireframe: ParitySignerWelcomeWireframeProtocol) {
        self.wireframe = wireframe
    }
}

extension ParitySignerWelcomePresenter: ParitySignerWelcomePresenterProtocol {
    func scanQr() {}
}

extension ParitySignerWelcomePresenter: ParitySignerWelcomeInteractorOutputProtocol {}
