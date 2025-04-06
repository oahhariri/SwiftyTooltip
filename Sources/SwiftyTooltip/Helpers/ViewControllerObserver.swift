//
//  ViewControllerObserver.swift
//  SwiftyTooltip
//
//  Created by Abdulrahman Ameen Hariri on 06/04/2025.
//

import SwiftUI

internal enum UIKitLifeCycle{
    case viewDidLoad
    case viewDidAppear
    case viewWillAppear
    case viewWillDisappear
    case appMovedToBackground
    case appMovedToForeground
    case viewDidDisappear
    case onDeinit
    case viewDidLayoutSubviews
    case loadView
}

internal class ViewControllerObserver: UIViewController {
    
    var onLoadView:(()->())?
    var onViewDidLoad:(()->())?
    let observeAppLifecycle:Bool
    var uiKitLifeCycle:((UIKitLifeCycle)->())?
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self)
        uiKitLifeCycle?(.onDeinit)
    }
    
    override var shouldAutorotate: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIInterfaceOrientation.portrait
    }
    
    init(observeAppLifecycle:Bool = false, onLoadView:(()->())? = nil,onViewDidLoad:(()->())? = nil,uiKitLifeCycle:((UIKitLifeCycle)->())? = nil) {
        self.onLoadView = onLoadView
        self.onViewDidLoad = onViewDidLoad
        self.uiKitLifeCycle = uiKitLifeCycle
        self.observeAppLifecycle = observeAppLifecycle
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
     
    override func loadView() {
        onLoadView?()
        super.loadView()
        uiKitLifeCycle?(.loadView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        uiKitLifeCycle?(.viewDidLayoutSubviews)
    }
    override func viewDidLoad() {
        if observeAppLifecycle {
            NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackgroundNotification), name: UIApplication.didEnterBackgroundNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(willEnterForegroundNotification), name: UIApplication.willEnterForegroundNotification, object: nil)
        }
        onViewDidLoad?()
        super.viewDidLoad()
        uiKitLifeCycle?(.viewDidLoad)
    }
    
    @objc func didEnterBackgroundNotification() {
        print("App moved to didEnterBackgroundNotification!")
        uiKitLifeCycle?(.appMovedToBackground)
    }
    
    @objc func willEnterForegroundNotification() {
        print("App moved to willEnterForegroundNotification!")
        uiKitLifeCycle?(.appMovedToForeground)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        uiKitLifeCycle?(.viewDidDisappear)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        uiKitLifeCycle?(.viewWillDisappear)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        uiKitLifeCycle?(.viewDidAppear)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        uiKitLifeCycle?(.viewWillAppear)
    }
}

internal struct ViewControllerObserverRepresentable: UIViewControllerRepresentable {
    
    var observeAppLifecycle:Bool = false
    var onLoadView:(()->())?
    var onViewDidLoad:(()->())?
    var uiKitLifeCycle:((UIKitLifeCycle)->())?

    func makeUIViewController(context: Context) -> ViewControllerObserver {
        ViewControllerObserver(observeAppLifecycle:observeAppLifecycle ,onLoadView: onLoadView, onViewDidLoad: onViewDidLoad,uiKitLifeCycle: uiKitLifeCycle)
        
    }
    func updateUIViewController(_ controller: ViewControllerObserver, context: Context) {
    }
}

internal extension View {
    @ViewBuilder func uiKitViewControllerLifeCycle(observeAppLifecycle:Bool = false,uiKitLifeCycle:((UIKitLifeCycle)->())?) -> some View {
        self.background(ViewControllerObserverRepresentable(observeAppLifecycle: observeAppLifecycle, uiKitLifeCycle: { lifeCycle in
            DispatchQueue.main.async {
                uiKitLifeCycle?(lifeCycle)
            }
            
        }))
    }
}
