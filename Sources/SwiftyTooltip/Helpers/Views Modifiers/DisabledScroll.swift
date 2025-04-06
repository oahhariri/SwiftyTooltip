//
//  DisabledScroll.swift
//  SwiftyTooltip
//
//  Created by Abdulrahman Ameen Hariri on 06/04/2025.
//

import SwiftUIIntrospect
import SwiftUI

internal struct TabBarDisabledScroll : ViewModifier {
    
    @State var uiScrollViewDelagte:DisableScrollDelagte
    let isDisabled:Bool
    
    init(isDisabled:Bool = true) {
        self.isDisabled = isDisabled
        _uiScrollViewDelagte = .init(initialValue: .init(isDisabled: isDisabled))
    }
    
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .scrollDisabled(isDisabled)
            
        } else {
            content
                .introspect(.scrollView, on: .iOS(.v15))  { scrollview in
                    scrollview.isScrollEnabled = !isDisabled
                    scrollview.alwaysBounceVertical = false
                    scrollview.alwaysBounceHorizontal = false
                    scrollview.delegate = uiScrollViewDelagte
                }
        }
    }
}

internal struct DisabledView: ViewModifier {
    let disabled:Bool
    func body(content: Content) -> some View {
        if #available(iOS 16.3, *) {
            content
                .disabled(disabled)
        } else {
            content
                .allowsHitTesting(!disabled)
        }
    }
}

internal extension View {
    func disabledScroll(isDisabled:Bool = true) -> some View {
        modifier(TabBarDisabledScroll(isDisabled:isDisabled))
    }
    
    func disabledView(_ disabled:Bool = true) -> some View {
        VStack(spacing: 0) {
            self.modifier(DisabledView(disabled: disabled))
        }
    }
}

internal class DisableScrollDelagte:NSObject {
    let isDisabled:Bool
    
    init(isDisabled: Bool) {
        self.isDisabled = isDisabled
        super.init()
        
    }
}

extension DisableScrollDelagte: UIScrollViewDelegate {
    
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollView.isScrollEnabled = !isDisabled
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        scrollView.isScrollEnabled = !isDisabled
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.isScrollEnabled = !isDisabled
        
    }
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        scrollView.isScrollEnabled = !isDisabled
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        scrollView.isScrollEnabled = !isDisabled
    }
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return !isDisabled
    }
    
    func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        scrollView.isScrollEnabled = !isDisabled
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollView.isScrollEnabled = !isDisabled
    }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollView.isScrollEnabled = !isDisabled
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollView.isScrollEnabled = !isDisabled
    }
    
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollView.isScrollEnabled = !isDisabled
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        scrollView.isScrollEnabled = !isDisabled
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollView.isScrollEnabled = !isDisabled
    }
}


