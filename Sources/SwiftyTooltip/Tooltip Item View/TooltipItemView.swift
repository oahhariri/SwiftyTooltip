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
                reset()
            }
            .onFirstAppear {
                Task { await  assign(item: item, viewModel.context.id) }
            }
            .uiKitViewControllerLifeCycle { lifecycle in
                guard lifecycle == .onDeinit || lifecycle == .viewDidDisappear || lifecycle == .viewWillDisappear else { return }
                reset()
            }
            .overlayCover(contextId: viewModel.context.id,$viewModel.tooltipInfo) { tooltipInfo in
                show(tooltipInfo: tooltipInfo)
            }
            .onTooltipAction(handelActions)
            .disabledScroll(isDisabled: viewModel.tooltipInfo != nil)
    }
    
    @ViewBuilder func show(tooltipInfo: TooltipInfoModel<Item>?) -> some View {
        TooltipHolderView(tooltipInfo: tooltipInfo,
                          backgroundColor: backgroundColor,
                          dismissToolTip: handelDismissToolTip) { tooltipInfo in
            self.tooltipContent(tooltipInfo)
                .background(tooltipInfo.backgroundColor)
                .cornerRadius(13)
                .shadow(color: Color.black.opacity(0.4), radius: 9, x: 0, y: 3)
        }
    }
    
    func handelActions(_ action: TooltipActions) {
        Task {@TooltipsBackgroundActor in
            switch action {
            case .register(let context, id: let id, frame: let frame):
                await viewModel.registerTarget(context,id, frame: frame)
                await assign(item: item, context)
            case .unregister(let context,id: let id):
                await viewModel.unregisterTarget(context,id)
                await assign(item: item, context)
            }
        }
    }
}

extension TooltipItemView {
    @MainActor
    private func reset() {
        viewModel.tooltipInfo = nil
        OverlayContainersHelper.dismiss(contextId:  viewModel.context.id,animated: true)
    }
    
    @MainActor
    private func resetHelper(item: Item?, targets: OrderedDictionary<String, CGRect>) {
        if let invalidItem = viewModel.tooltipInfo?.item, invalidItem == item && targets[invalidItem.id] == nil {
            self.item = nil
        }
        
        reset()
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


