//
//  TooltipItemView.swift
//
//
//  Created by Abdulrahman Ameen Hariri on 26/03/2025.
//

import SwiftUI

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
                
                assign(item: item, viewModel.context.id)
            }
            .onDisappear {
                reset()
            }
            .onFirstAppear {
                assign(item: item, viewModel.context.id)
            }
            .uiKitViewControllerLifeCycle { lifecycle in
                guard lifecycle == .onDeinit || lifecycle == .viewDidDisappear || lifecycle == .viewWillDisappear else { return }
                reset()
            }
            .overlayCover($viewModel.tooltipInfo) { tooltipInfo in
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
        Task {
            switch action {
            case .register(let context, id: let id, frame: let frame):
                await viewModel.registerTarget(context,id, frame: frame)
                assign(item: item, context)
            case .unregister(let context,id: let id):
                await viewModel.unregisterTarget(context,id)
                assign(item: item, context)
            }
        }
    }
}

extension TooltipItemView {
    private func reset() {
        viewModel.tooltipInfo = nil
        OverlayContainersHelper.dismiss(animated: true)
    }
    
    private func resetHelper(item: Item?, targets: [String : CGRect]) {
        if let invalidItem = viewModel.tooltipInfo?.item, invalidItem == item && targets[invalidItem.id] == nil {
            self.item = nil
        }
        
        reset()
    }
    
    private func assign(item: Item?, _ context: String) {
        guard let item,
              let frame = viewModel.targets[item.id], frame.size.isValidSize() else {
            resetHelper(item: item, targets: viewModel.targets)
            return
        }
        
        viewModel.assign(context, item: item, frame: frame)
    }
    
    func handelDismissToolTip() {
        DispatchQueue.main.async {
            reset()
        }
    }
}


