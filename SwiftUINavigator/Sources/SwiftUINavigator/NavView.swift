//
// Created by Shaban Kamel on 25/12/2021.
//

import SwiftUI

/// The alternative of SwiftUI NavigationView implementing
/// stack-based navigation with mote control and flexibility in handling
/// the navigation
public struct NavView<Root>: View where Root: View {
    private let navView: NavViewContent<Root>
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
        navView = NavViewContent(
                transition: transition,
                easeAnimation: easeAnimation,
                showDefaultNavBar: showDefaultNavBar,
                rootView: rootView)
    }

    init(
            navigator: Navigator,
            showDefaultNavBar: Bool,
            @ViewBuilder rootView: () -> Root) {
        navView = NavViewContent(
                navigator: navigator,
                showDefaultNavBar: showDefaultNavBar,
                rootView: rootView)
    }

    public var body: some View {
        navView
    }
}

struct NavViewContent<Root>: View where Root: View {
    @ObservedObject private var manager: NavManager
    private var navigator: Navigator
    private let rootView: Root

    /// Creates a NavigatorView.
    /// - Parameters:
    ///   - transition: The type of transition to apply between views in every push and pop operation.
    ///   - easeAnimation: The easing function to apply to every push and pop operation.
    ///   - showDefaultNavBar: if false, no nav bar will be displayed.
    ///   - rootView: The very first view in the Navigation.
    init(
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

    var body: some View {
        Content()
                .bottomSheet(
                        isPresented: $manager.sheetManager.presentFixedHeightSheet,
                        height: manager.sheetManager.sheetArgs.height,
                        isDismissable: manager.sheetManager.sheetArgs.isDismissable) {
                    manager.sheetManager.sheet?.lazyView
                }
                .sheet(
                        isPresented: $manager.sheetManager.presentSheet) {
                    manager.sheetManager.sheet?.lazyView.frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .modifier(
                        FullScreenCoverModifier(isPresented: $manager.sheetManager.presentFullSheet) {
                            manager.sheetManager.sheet?.eraseToAnyView()
                        }
                )
                .modifier(
                        ConfirmationDialogModifier(
                                manager.confirmationDialogManager.titleKey,
                                isPresented: $manager.confirmationDialogManager.isPresented,
                                titleVisibility: manager.confirmationDialogManager.titleVisibility,
                                actions: {
                                    manager.confirmationDialogManager.content?.eraseToAnyView()
                                }
                        ))
                #if os(iOS)
                .modifier(
                        ActionSheetModifier(
                                isPresented: $manager.actionSheetManager.isPresented,
                                sheet: { manager.actionSheetManager.sheet }
                        ))
                #endif
                .modifier(AlertModifier(
                        isPresented: $manager.alertManager.isPresented,
                        alert: { manager.alertManager.alert }
                ))
                .dialog(isPresented: $manager.dialogManager.isPresented,
                        dismissOnTouchOutside: manager.dialogManager.dismissOnTouchOutside,
                        dialogContent: { manager.dialogManager.view })
                .environmentObject(navigator)
    }


    private func Content() -> some View {
        Group {
            if let item = manager.stackItems.last {
                item.wrappedElement
                        .id(item.id)
                        .background(Color.white.edgesIgnoringSafeArea(.all))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else {
                rootView.id("ROOT")
            }
        }
                .transition(manager.lastNavigationType == .push ?
                        manager.transition.transition.push :
                        manager.transition.transition.pop)
    }

}