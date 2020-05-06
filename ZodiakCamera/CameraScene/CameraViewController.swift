//
//  ViewController.swift
//  ZodiakCamera
//
//  Created by lynx on 14/10/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import UIKit
import Instructions

protocol CameraViewControllerRouter {
    func openSettings()
}

class CameraViewController: UIViewController {
    private let joystickView = JoystickView()
    private var panelView: PanelView!
    private let settings = UIButton(type: .custom)
    private let router: CameraViewControllerRouter
    private let ipCameraView = UIImageView()
    private var panelData: PanelData = PanelData(brightness: .initial, saturation: .initial, contrast: .initial, ir: false, resolution: ._640x480)
    private var model: CameraViewControllerModel
    
    init(model: CameraViewControllerModel,
         router: CameraViewControllerRouter) {
        self.router = router
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.panelView = PanelView(frame: .zero) { self.panelData }
        self.view.backgroundColor = .white
        self.setupLayout()
        self.panelView.eventHandler = self.handlePanelViewEvent
        self.joystickView.moveHandler = self.handleJoystickEvent
        model.imageProviderHandler = self.handleLiveImageEvent
        self.settings.addTarget(self, action: #selector(self.openSettings), for: .touchUpInside)
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tap)))
    }
    
    
    private func setupLayout() {
        ipCameraView.contentMode = model.contentMode
        view.addSubview(ipCameraView, constraints: .pin)
        view.addSubview(panelView, constraints: [
            constraint(\.leftAnchor),
            constraint(\.rightAnchor),
            constraint(\.bottomAnchor)
        ])
        
        panelView.constrainToView(ipCameraView, constraints: [
            constraint(\.topAnchor, \.bottomAnchor, constant: -84),
        ])
        
        view.addSubview(joystickView)
        joystickView.constrainToView(ipCameraView, constraints: [
            constraint(\.leadingAnchor),
            constraint(\.trailingAnchor),
            constraint(\.topAnchor)
        ])
        
        joystickView.constrainToView(panelView, constraints: [
            constraint(\.bottomAnchor, \.topAnchor)
        ])
        joystickView.backgroundColor = .clear
        settings.setImage(Images.settings.image, for: .normal)
        settings.tintColor = .white
        view.addSubview(settings, pairingTo: ipCameraView, constraints: [
            constraint(\.trailingAnchor, constant: -17),
            constraint(\.topAnchor, \.safeAreaLayoutGuide.topAnchor),
        ])
        settings.constrain(to:
            uconstraint(\.widthAnchor, constant: 34),
                           uconstraint(\.heightAnchor, constant: 34))
    }
    
    @objc func tap(_ sender: UITapGestureRecognizer) {
        showedSlider?.removeFromSuperview()
    }
    
    @objc func openSettings(_ sender: Any) {
        router.openSettings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model.start()
    }
    
    private lazy var coachMarksController: CoachMarksController = {
       let ctr = CoachMarksController()
        ctr.dataSource = self
        ctr.delegate = self
        ctr.overlay.allowTap = true
        ctr.overlay.color = UIColor.black.withAlphaComponent(0.4)
        return ctr
    }()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !model.isTourShowed {
            coachMarksController.start(in: .window(over: self))
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        model.pause()
    }
    
    enum State {
        case error(Error)
        case editing
        case active(UIImage?)
        enum Error {
            case noConnection
            case unknown
            case internetNotAvailable
        }
    }
    
    func update(_ state: State) {
        switch state {
        case .active(let image):
            DispatchQueue.main.async {
                self.noConnection.removeFromSuperview()
                self.ipCameraView.image = image
                self.joystickView.isHidden = false
            }
        case .editing:
            joystickView.isHidden = true
        case .error(let error):
            switch error {
            case .noConnection:
                DispatchQueue.main.async {
                    self.view.insertSubview(self.noConnection, aboveSubview: self.ipCameraView, constraints: .pin)
                    self.joystickView.isHidden = true
                    self.noConnection.render(state: .init(title: L10n.Error.NoAccess.title,
                                                          description: L10n.Error.NoAccess.description,
                                                          iconName: Images.cameraWarning.name))
                }
            case .internetNotAvailable:
                DispatchQueue.main.async {
                    self.view.insertSubview(self.noConnection, aboveSubview: self.ipCameraView, constraints: .pin)
                    self.joystickView.isHidden = true
                    self.noConnection.render(state: .init(title: L10n.Error.NoInternetConnection.title,
                                                          description: L10n.Error.NoInternetConnection.description,
                                                          iconName: Images.wifiWarning.name))
                }
            case .unknown:
                break;
            }
        }
    }
    
    private lazy var noConnection = NoCameraAccessView()
    func handleLiveImageEvent(_ event: LiveImageProviderState) {
        switch event {
        case .active(let image):
            update(.active(image))
        case .error(let error):
            switch error {
            case .invalidHost:
                update(.error(.noConnection))
            case .temprorary: update(.error(.unknown))
            case .noInternetConnection:
                update(.error(.internetNotAvailable))
            }
        }
    }
    
    private var showedSlider: ArcSlider?
 
    func handlePanelViewEvent(_ event: PanelView.Event) {
        switch event {
        case .itemSelected(let item):
            showedSlider?.removeFromSuperview()
            switch item {
            case .control(let control):
                let slider = ArcSlider(frame: .zero,
                                       model: .init(innerRadiusOffset: 30,
                                                    color: UIColor.black.withAlphaComponent(0.2),
                                                    tintColor: .white,
                                                    startImage: control.imageMin ?? UIImage.empty(),
                                                    endImage: control.imageMax ?? UIImage.empty(),
                                                    minValue: control.minValue,
                                                    maxValue: control.maxValue != 0 ? control.maxValue : 255,
                                                    currentValue: control.currentValue()))
                
                slider.valueChanged = control.newValueHandler
                slider.isEnabled = true
                view.addSubview(slider, constraints: [
                    constraint(\.leftAnchor, constant: -15),
                    constraint(\.rightAnchor, constant: 15),
                ])
                slider.constrainToView(panelView, constraints: [
                    constraint(\.bottomAnchor, \.topAnchor)
                ])
                slider.constrain(to: uconstraint(\.heightAnchor, constant: 120))
                slider.layoutIfNeeded()
                
                UIView.animate(withDuration: 0.2) {
                    slider.alpha = 1
                }
                self.showedSlider = slider
                update(.editing)
            case .toggle(let toggle):
                toggle.newValueHandler(!toggle.currentValue())
            case .text(let textItem):
                let current = textItem.currentValue().1
                let next = current >= 2 ? 0 : current + 1
                textItem.newValueHandler(CameraResolution(rawValue: next)!.text, next)
            }
        case .changePanelData(let changes):
            let change = CameraViewController.convertPanelChanges(changes)
            
            model.changeSettings(change, resultHandler: { result in
                switch result {
                case .failure:
                    self.update(.error(.unknown))
                case .success(let settings): self.panelData = .init(brightness: settings.brightness,
                                                                    saturation: settings.saturation,
                                                                    contrast: settings.contrast,
                                                                    ir: settings.ir,
                                                                    resolution: CameraResolution(rawValue: settings.resolution)!)
                }
            })
        }
    }
    
    static private func convertPanelChanges(_ change: PanelView.Event.PanelDataChanges) -> SettingsChange {
        switch  change {
        case .brightness(let value):
            return .brightness(value)
        case .contrast(let value):
            return .contrast(value)
        case .saturation(let value):
            return .saturation(value)
        case .ir(let value):
            return .ir(value)
        case .resolution(let resolution):
            return .resolution(resolution)
        }
    }
    
    private func handleJoystickEvent(_ event: JoystickView.Event) {
        model.userManipulate(command: CameraViewController.converter(event)) { result in
            switch result {
            case .success:
                return
            case .failure:
                self.update(.error(.unknown))
            }
        }
    }
    
    private static var converter:(JoystickView.Event) -> UserManipulation {
        return {
            switch $0 {
            case .move(let moveDirection):
                switch moveDirection {
                case .down: return .move(.down)
                case .up: return .move(.up)
                case .left: return .move(.left)
                case .right: return .move(.right)
                case .downleft: return .move(.downleft)
                case .downright: return .move(.downright)
                case .upleft: return .move(.upleft)
                case .upright: return .move(.upright)
                }
            case .stop: return .stop
            case .start: return .start
            }
        }
    }
}

struct PanelData {
    var brightness: LimitValue
    var saturation: LimitValue
    var contrast: LimitValue
    var ir: Bool
    var resolution: CameraResolution
}


// MARK: CoachMarksControllerDataSource, CoachMarksControllerDelegate
extension CameraViewController: CoachMarksControllerDataSource, CoachMarksControllerDelegate {
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkViewsAt index: Int, madeFrom coachMark: CoachMark) -> (bodyView: CoachMarkBodyView, arrowView: CoachMarkArrowView?) {
        switch index {
        case 0:
            let customView = MarkView(frame: .zero, offset: settings.bounds.midX/2 - 2)
            customView.model = .init(title: "Settings", subtitle: "Setup your camera here", direction: .up)
            return (bodyView: customView, arrowView: nil)
        case 1:
            let customView = MarkView(frame: .zero, offset: 0)
            customView.model = .init(title: "Video parameters", subtitle: "You can change video parameters here", direction: .down)
            return (bodyView: customView, arrowView: nil)
        default:
            assertionFailure("Checkmark at index: \(index) not exists")
            return coachMarksController.helper.makeDefaultCoachViews()
        }
        
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkAt index: Int) -> CoachMark {
        var mark: CoachMark
        switch index {
        case 0:
            mark = coachMarksController.helper.makeCoachMark(for: settings) { frame -> UIBezierPath in
                return UIBezierPath(ovalIn: frame.insetBy(dx: -6, dy: -6))
            }
            
            mark.gapBetweenCoachMarkAndCutoutPath = -6
        case 1:
            mark = coachMarksController.helper.makeCoachMark(for: self.panelView) { frame -> UIBezierPath in
                let offsettedFrame = frame.inset(by: .init(top: 0, left: 10, bottom: 20, right: 10))
                return UIBezierPath(roundedRect: offsettedFrame, cornerRadius: 20)
            }
            mark.gapBetweenCoachMarkAndCutoutPath = -6
        default:
            assertionFailure("Checkmark at index: \(index) not exists")
            mark = coachMarksController.helper.makeCoachMark()
            break
        }
        
        return mark
    }
    
    func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
        return 2
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController,
                              didEndShowingBySkipping skipped: Bool) {
        model.isTourShowed = true
        self.coachMarksController.stop(immediately: false)
    }
    
}


class MarkView: UIView, CoachMarkBodyView {
    var nextControl: UIControl? {
        return nil
    }
    
    var highlightArrowDelegate: CoachMarkBodyHighlightArrowDelegate? = nil
    
    struct Model {
        var title: String
        var subtitle: String
        var direction: Direction
        
        enum Direction {
            case up
            case down
        }
    }
    
    var model: Model? {
        didSet {
            titleLabel.text = model?.title
            subtitleLabel.text = model?.subtitle
            switch model?.direction {
            case .up: arrow.transform = .identity
            case .down:
                arrow.transform = .init(scaleX: 1, y: -1)
                if let firstSubview = arrowStack.arrangedSubviews.first{
                    arrowStack.removeArrangedSubview(firstSubview)
                    arrowStack.addArrangedSubview(firstSubview)
                }
            default: break
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    init(frame: CGRect, offset: CGFloat) {
        super.init(frame: frame)
        setup(offset: offset)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var titleLabel = UILabel()
    private var subtitleLabel = UILabel()
    private var arrow = ArrowView()
    private var arrowStack = UIStackView()
    private func setup(offset: CGFloat = 0) {
        self.translatesAutoresizingMaskIntoConstraints = false
         titleLabel.font = .systemFont(ofSize: 13, weight: .bold)
         titleLabel.textColor = .white
         titleLabel.textAlignment = .right
         titleLabel.numberOfLines = 0
         titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
         
         subtitleLabel.font = .systemFont(ofSize: 10)
         subtitleLabel.textColor = .white
         subtitleLabel.textAlignment = .right
         subtitleLabel.numberOfLines = 0
         subtitleLabel.setContentHuggingPriority(.required, for: .vertical)
         
         let vStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
         vStack.axis = .vertical
         vStack.alignment = .trailing
         
         //arrow.setContentCompressionResistancePriority(.required, for: .vertical)
        // arrow.setContentHuggingPriority(.required, for: .vertical)
         
         let space = UIView()
         arrowStack = UIStackView(arrangedSubviews: [arrow, space])
         arrowStack.axis = .vertical
         space.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
         arrowStack.distribution = .fillEqually
        
         let hStack = UIStackView(arrangedSubviews: [vStack, arrowStack])
         hStack.axis = .horizontal
         hStack.alignment = .center
        
        addSubview(hStack, constraints: .pinWithOffsets(top: 0, bottom: 0, left: 0, right: offset))
     }
}

extension MarkView {
    class ArrowView: UIView, CoachMarkArrowView {
        var isHighlighted: Bool = false
        
        override func draw(_ frame: CGRect) {
            let arrowPath = UIBezierPath()
            arrowPath.move(to: CGPoint(x: frame.minX + 0.57143 * frame.width, y: frame.minY + 0.11121 * frame.height))
            arrowPath.addCurve(to: CGPoint(x: frame.minX + 0.57143 * frame.width, y: frame.minY + 0.81799 * frame.height), controlPoint1: CGPoint(x: frame.minX + 0.57143 * frame.width, y: frame.minY + 0.11111 * frame.height), controlPoint2: CGPoint(x: frame.minX + 0.57143 * frame.width, y: frame.minY + 0.67290 * frame.height))
            arrowPath.addCurve(to: CGPoint(x: frame.minX + 0.67329 * frame.width, y: frame.minY + 0.83769 * frame.height), controlPoint1: CGPoint(x: frame.minX + 0.61262 * frame.width, y: frame.minY + 0.82176 * frame.height), controlPoint2: CGPoint(x: frame.minX + 0.64803 * frame.width, y: frame.minY + 0.82870 * frame.height))
            arrowPath.addCurve(to: CGPoint(x: frame.minX + 0.71429 * frame.width, y: frame.minY + 0.87037 * frame.height), controlPoint1: CGPoint(x: frame.minX + 0.69908 * frame.width, y: frame.minY + 0.84686 * frame.height), controlPoint2: CGPoint(x: frame.minX + 0.71429 * frame.width, y: frame.minY + 0.85815 * frame.height))
            arrowPath.addCurve(to: CGPoint(x: frame.minX + 0.66280 * frame.width, y: frame.minY + 0.90650 * frame.height), controlPoint1: CGPoint(x: frame.minX + 0.71429 * frame.width, y: frame.minY + 0.88416 * frame.height), controlPoint2: CGPoint(x: frame.minX + 0.69490 * frame.width, y: frame.minY + 0.89678 * frame.height))
            arrowPath.addCurve(to: CGPoint(x: frame.minX + 0.50000 * frame.width, y: frame.minY + 0.92593 * frame.height), controlPoint1: CGPoint(x: frame.minX + 0.62350 * frame.width, y: frame.minY + 0.91839 * frame.height), controlPoint2: CGPoint(x: frame.minX + 0.56514 * frame.width, y: frame.minY + 0.92593 * frame.height))
            arrowPath.addCurve(to: CGPoint(x: frame.minX + 0.28571 * frame.width, y: frame.minY + 0.87037 * frame.height), controlPoint1: CGPoint(x: frame.minX + 0.38165 * frame.width, y: frame.minY + 0.92593 * frame.height), controlPoint2: CGPoint(x: frame.minX + 0.28571 * frame.width, y: frame.minY + 0.90105 * frame.height))
            arrowPath.addCurve(to: CGPoint(x: frame.minX + 0.35897 * frame.width, y: frame.minY + 0.82854 * frame.height), controlPoint1: CGPoint(x: frame.minX + 0.28571 * frame.width, y: frame.minY + 0.85369 * frame.height), controlPoint2: CGPoint(x: frame.minX + 0.31407 * frame.width, y: frame.minY + 0.83873 * frame.height))
            arrowPath.addCurve(to: CGPoint(x: frame.minX + 0.42856 * frame.width, y: frame.minY + 0.81798 * frame.height), controlPoint1: CGPoint(x: frame.minX + 0.37917 * frame.width, y: frame.minY + 0.82396 * frame.height), controlPoint2: CGPoint(x: frame.minX + 0.40273 * frame.width, y: frame.minY + 0.82034 * frame.height))
            arrowPath.addCurve(to: CGPoint(x: frame.minX + 0.42857 * frame.width, y: frame.minY + 0.11111 * frame.height), controlPoint1: CGPoint(x: frame.minX + 0.42857 * frame.width, y: frame.minY + 0.67290 * frame.height), controlPoint2: CGPoint(x: frame.minX + 0.42857 * frame.width, y: frame.minY + 0.11111 * frame.height))
            arrowPath.addLine(to: CGPoint(x: frame.minX + 0.57143 * frame.width, y: frame.minY + 0.11111 * frame.height))
            arrowPath.addLine(to: CGPoint(x: frame.minX + 0.57143 * frame.width, y: frame.minY + 0.11121 * frame.height))
            arrowPath.close()
            
            UIColor.white.setFill()
            arrowPath.fill()
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear
            setNeedsDisplay()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override var intrinsicContentSize: CGSize {
            return .init(width: 15, height: 50)
        }
    }
}
