//
// Created by Shaban Kamel on 25/12/2021.
//

import SwiftUI

public enum NavType {
    /// Regular navigation type.
    /// id: pass a custom ID to use when navigate back.
    /// addToBackStack: if false, the view won't be added to the back stack
    /// and won't be displayed when dismissing the view.
    case push(id: String? = nil, addToBackStack: Bool = true)
    /// Present a sheet
    // TODO: add onDismiss
    case sheet(type: SheetType)
}