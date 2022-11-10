//
// Created by Shaban Kamel on 25/12/2021.
//

import SwiftUI

/// The alternative of SwiftUI NavigationView implementing
/// stack-based navigation with mote control and flexibility in handling
/// the navigation
///
@available(*, deprecated, renamed: "NavView")
public struct NavigatorView<Root>: View where Root: View {
    private let navView: NavView<Root>
    /// Creates a NavigatorView.
    /// - Parameters:
    ///   - transition: The type of transition to apply between views in every push and pop operation.
    ///   - easeAnimation: The easing function to apply to every push and pop operation.
    ///   - showDefaultNavBar: if false, no nav bar will be displayed.
    ///   - rootView: The very first view in the Navigation.
    public init(
            transition: NavTransition = .default,
            easeAnimation: Animation = .easeOut(duration: 0.2),
            showDefaultNavBar: Bool = true,
            @ViewBuilder rootView: () -> Root) {
        navView = NavView(
                transition: transition,
                easeAnimation: easeAnimation,
                showDefaultNavBar: showDefaultNavBar,
                rootView: rootView)
    }

    public var body: some View {
        navView
    }
}

public struct NavView<Root>: View where Root: View {
    @ObservedObject private var manager: NavManager
    private var navigator: Navigator
    private let rootView: Root

    /// Creates a NavigatorView.
    /// - Parameters:
    ///   - transition: The type of transition to apply between views in every push and pop operation.
    ///   - easeAnimation: The easing function to apply to every push and pop operation.
    ///   - showDefaultNavBar: if false, no nav bar will be displayed.
    ///   - rootView: The very first view in the Navigation.
    public init(
            transition: NavTransition = .default,
            easeAnimation: Animation = .easeOut(duration: 0.01),
            showDefaultNavBar: Bool = true,
            @ViewBuilder rootView: () -> Root) {
        let navigator = Navigator.instance(
                easeAnimation: easeAnimation,
                showDefaultNavBar: showDefaultNavBar,
                transition: transition)
        self.init(navigator: navigator,
                showDefaultNavBar: showDefaultNavBar,
                rootView: rootView)
    }

    init(
            navigator: Navigator,
            showDefaultNavBar: Bool,
            @ViewBuilder rootView: () -> Root) {
        self.navigator = navigator
        manager = navigator.manager
        self.rootView = rootView()
    }

    public var body: some View {
        ZStack {
            BodyContent()
        }
                .modifier(
                        ConfirmationDialogModifier(
                                manager.confirmationDialogManager.titleKey,
                                isPresented: $manager.confirmationDialogManager.isPresented,
                                titleVisibility: manager.confirmationDialogManager.titleVisibility,
                                actions: {
                                    manager.confirmationDialogManager.content?.eraseToAnyView()
                                }
                        ))
                .modifier(
                        ActionSheetModifier(
                                isPresented: $manager.actionSheetManager.isPresented,
                                sheet: { manager.actionSheetManager.sheet }
                        ))
                .environmentObject(navigator)
    }

    private func BodyContent() -> some View {
        Group {
            #if os(macOS)
            SheetView()
            #else
            if #available(iOS 14.0, *) {
                SheetView()
                        .fullScreenCover(
                                isPresented: $manager.sheetManager.presentFullSheet,
                                onDismiss: {
                                    onDismissSheet()
                                }) {
                            LazyView(manager.sheetManager.sheet)
                        }
            } else {
                SheetView()
            }
            #endif
        }
    }

    private func SheetView() -> some View {
        Content()
                .bottomSheet(
                        isPresented: $manager.sheetManager.presentFixedHeightSheet,
                        height: manager.sheetManager.sheetArgs.height,
                        isDismissable: manager.sheetManager.sheetArgs.isDismissable,
                        onDismiss: {
                            onDismissSheet()
                        }) {
                    LazyView(manager.sheetManager.sheet)
                }
                .sheet(
                        isPresented: $manager.sheetManager.presentSheet,
                        onDismiss: {
                            onDismissSheet()
                        }) {
                    manager.sheetManager.sheet.frame(maxWidth: .infinity, maxHeight: .infinity)
                }
    }

    private func Content() -> some View {
        Group {
            if let item = manager.stackItems.last {
                item.wrappedElement
                        .id(item.id)
                        .zIndex(1)
                        .background(Color.white.edgesIgnoringSafeArea(.all))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else {
                RootView()
            }
        }
                .transition(manager.lastNavigationType == .push ?
                        manager.transition.transition.push :
                        manager.transition.transition.pop)
    }

    private func RootView() -> some View {
        rootView.id("ROOT")
    }

    private func CurrentView(_ view: BackStackElement) -> some View {
        view.wrappedElement.id(view.id)
    }

}

extension NavView {

    private func onDismissSheet() {
        manager.sheetManager.onDismissSheet?()
        manager.sheetManager.onDismissSheet = nil
    }

}