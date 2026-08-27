//
//  TooltipItemView.swift
//
//
//  Created by Abdulrahman Ameen Hariri on 26/03/2025.
//

import SwiftUI
import OrderedCollections

internal struct TooltipItemView<Context: TooltipContextType,
                       Item: TooltipItemConfigType,
                       Content: View,
                       TooltipContent: View>: View {
    
    @StateObject private var viewModel: TooltipItemViewModel<Context,Item>
    
    @Binding var item: Item?
    
    @ViewBuilder private let tooltipContent: (Item) -> TooltipContent
    @ViewBuilder private var content: () -> Content
    var backgroundColor: Color = Color.gray.opacity(0.50)
    
    init(context: Context, item: Binding<Item?>, backgroundColor: Color , @ViewBuilder tooltipContent: @escaping (Item) -> TooltipContent, content: @escaping () -> Content) {
        self._item = item
        self.content = content
        self.tooltipContent = tooltipContent
        self.backgroundColor = backgroundColor
        _viewModel = .init(wrappedValue: .init(context: context))
    }
    
    var body: some View {
        content()
            .onChange(of: item) { item in
                guard let item = item else {
                    reset()
                    return
                }
                
                Task { await assign(item: item, viewModel.context.id) }
            }
            .onDisappear {
                reset(force: true)
            }
            .onFirstAppear {
                Task {
                    // Before the guards below, a presenter always swept this
                    // context's container on mount: with no item — or, far more
                    // commonly, before any target had registered yet — `assign`
                    // fell through to `reset()`. `reset()` is now a no-op when
                    // nothing is presented, so that sweep is made explicit here
                    // instead of being an accident of the fall-through. It keeps
                    // the old guarantee that a presenter starts from a clean
                    // container, and runs before the assign below so it can
                    // never land after a show. Once per presenter, not per frame.
                    reset(force: true)
                    await assign(item: item, viewModel.context.id)
                }
            }
            .uiKitViewControllerLifeCycle { lifecycle in
                guard lifecycle == .onDeinit || lifecycle == .viewDidDisappear || lifecycle == .viewWillDisappear else { return }
                reset(force: true)
            }
            .overlayCover(contextId: viewModel.context.id,$viewModel.tooltipInfo) { tooltipInfo in
                show(tooltipInfo: tooltipInfo)
            }
            .onTooltipAction(context: viewModel.context.id, id: viewModel.context.id.hashValue, handelActions)
            .disabledScroll(isDisabled: viewModel.tooltipInfo != nil)
    }
    
    @ViewBuilder func show(tooltipInfo: TooltipInfoModel<Item>?) -> some View {
        TooltipHolderView(tooltipInfo: tooltipInfo,
                          backgroundColor: backgroundColor,
                          dismissToolTip: handelDismissToolTip) { tooltipInfo in
            self.tooltipContent(tooltipInfo)
                .background(tooltipInfo.backgroundColor)
                .cornerRadius(tooltipInfo.cornerRadius)
                .tooltipShadow(tooltipInfo.shadow)
        }
    }
    
    func handelActions(_ action: TooltipActions) {
        Task {@TooltipsBackgroundActor in
            switch action {
            case .register(let context, id: let id, frame: let frame):
                await viewModel.registerTarget(context,id, frame: frame)
                await assignOnRegister(item: item, context)
            case .unregister(let context,id: let id):
                await viewModel.unregisterTarget(context,id)
                await assign(item: item, context)
            }
        }
    }
}

extension TooltipItemView {
    /// Clears whatever this presenter is showing.
    ///
    /// When nothing is presented this is a no-op: writing `nil` over `nil` on an
    /// `@Published` still fires `objectWillChange` (re-rendering the whole
    /// wrapped content), and the dismiss would sweep an already-empty container
    /// through a `DispatchQueue.main.async` hop into the shared
    /// `ContainerManager`. Both used to run once per frame on the register path.
    ///
    /// `force` keeps the container sweep on the teardown paths (`onDisappear`,
    /// view-controller lifecycle), where the point is to guarantee nothing is
    /// left behind even if this presenter never tracked it — those fire once,
    /// not per frame.
    @MainActor
    private func reset(force: Bool = false) {
        let isPresenting = viewModel.tooltipInfo != nil
        guard isPresenting || force else { return }

        if isPresenting {
            viewModel.tooltipInfo = nil
        }
        OverlayContainersHelper.dismiss(contextId:  viewModel.context.id,animated: true)
    }
    
    @MainActor
    private func resetHelper(item: Item?, targets: OrderedDictionary<String, CGRect>) {
        if let invalidItem = viewModel.tooltipInfo?.item, invalidItem == item && targets[invalidItem.id] == nil {
            self.item = nil
        }
        
        reset()
    }
    
    /// `assign` for the `.register` path only.
    ///
    /// A target re-registers on EVERY frame it moves (see `getViewFrame`), so
    /// this runs at display rate while anything on screen animates. With no item
    /// presented, `assign` can only fall through its own guard into
    /// `resetHelper` -> `reset()` — resetting an already-empty presenter, which
    /// hops to the main actor and pokes `ContainerManager`'s app-wide singleton
    /// once per frame for nothing.
    ///
    /// Nothing is lost: opening a tooltip goes through `onChange(of: item)`, not
    /// through `.register`, and while one IS open `item != nil`, so a moving
    /// target still re-anchors it. `.unregister` is deliberately left alone — it
    /// is the cleanup path and fires once, not per frame.
    @TooltipsBackgroundActor
    private func assignOnRegister(item: Item?, _ context: String) async {
        guard item != nil else { return }
        await assign(item: item, context)
    }

    @TooltipsBackgroundActor
    private func assign(item: Item?, _ context: String) async {
        guard let item,
              let frame = await viewModel.getTarget(item.id), frame.size.isValidSize() else {
            await resetHelper(item: item, targets: viewModel.getTargets())
            return
        }
        
       await viewModel.assign(context, item: item, frame: frame)
    }
    
    @MainActor
    func handelDismissToolTip() {
        DispatchQueue.main.async {
            self.item = nil
            OverlayContainersHelper.dismiss(contextId:  viewModel.context.id,animated: false)
        }
    }
}


