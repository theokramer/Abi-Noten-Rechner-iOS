//
//  ColorStore.swift
//  NotenRechner
//
//  Created by Theo Kramer on 12.09.25.
//

import SwiftUI
import Combine

class ColorStore: ObservableObject {
    @Published var mainColor: Color

    init() {
        if let uiColor = UserDefaults.standard.colorForKey("selectedColor") {
            self.mainColor = Color(uiColor)
        } else {
            self.mainColor = .orange
        }
    }

    func setColor(_ color: Color) {
        self.mainColor = color
        UserDefaults.standard.setColor(color: UIColor(color), forKey: "selectedColor")
    }
}

extension Color {
    static let modeColor = Color("modeColor")
    static let modeColorSwitch = Color("modeColorSwitch")
    static let mainColor2 = Color("Orange")
}

extension UserDefaults {
    func colorForKey(_ key: String) -> UIColor? {
        guard let data = self.data(forKey: key) else { return nil }
        return try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? UIColor
    }

    func setColor(color: UIColor?, forKey key: String) {
        var colorData: NSData?
        if let color = color {
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false) as NSData?
                colorData = data
            } catch {
                print("Error UserDefaults")
            }
        }
        set(colorData, forKey: key)
    }
}
