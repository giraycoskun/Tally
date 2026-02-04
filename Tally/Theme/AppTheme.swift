//
//  AppTheme.swift
//  Tally
//

import SwiftUI
import Combine

enum ThemeColor: String, CaseIterable, Identifiable {
    case purple = "Purple"
    case blue = "Blue"
    case green = "Green"
    case orange = "Orange"
    case teal = "Teal"
    
    var id: String { rawValue }
    
    var surfaceBackground: Color {
        switch self {
        case .purple: return Color(hex: "#1F1B2E") ?? .black
        case .blue: return Color(hex: "#1B1F2E") ?? .black
        case .green: return Color(hex: "#1B2E1F") ?? .black
        case .orange: return Color(hex: "#2E251B") ?? .black
        case .teal: return Color(hex: "#1B2E2E") ?? .black
        }
    }
    
    var darkColor: Color {
        switch self {
        case .purple: return Color(hex: "#2A2438") ?? .black
        case .blue: return Color(hex: "#242A38") ?? .black
        case .green: return Color(hex: "#24382A") ?? .black
        case .orange: return Color(hex: "#382E24") ?? .black
        case .teal: return Color(hex: "#243838") ?? .black
        }
    }
    
    var cardBackground: Color {
        switch self {
        case .purple: return Color(hex: "#352F44") ?? .black.opacity(0.8)
        case .blue: return Color(hex: "#2F3544") ?? .black.opacity(0.8)
        case .green: return Color(hex: "#2F4435") ?? .black.opacity(0.8)
        case .orange: return Color(hex: "#443B2F") ?? .black.opacity(0.8)
        case .teal: return Color(hex: "#2F4444") ?? .black.opacity(0.8)
        }
    }
    
    var mediumColor: Color {
        switch self {
        case .purple: return Color(hex: "#3D3552") ?? .purple.opacity(0.3)
        case .blue: return Color(hex: "#353D52") ?? .blue.opacity(0.3)
        case .green: return Color(hex: "#35523D") ?? .green.opacity(0.3)
        case .orange: return Color(hex: "#524535") ?? .orange.opacity(0.3)
        case .teal: return Color(hex: "#355252") ?? .teal.opacity(0.3)
        }
    }
    
    var lightColor: Color {
        switch self {
        case .purple: return Color(hex: "#B8A9D9") ?? .purple.opacity(0.6)
        case .blue: return Color(hex: "#A9B8D9") ?? .blue.opacity(0.6)
        case .green: return Color(hex: "#A9D9B8") ?? .green.opacity(0.6)
        case .orange: return Color(hex: "#D9C4A9") ?? .orange.opacity(0.6)
        case .teal: return Color(hex: "#A9D9D9") ?? .teal.opacity(0.6)
        }
    }
    
    var accentColor: Color {
        switch self {
        case .purple: return Color(hex: "#C4B5E0") ?? .purple.opacity(0.8)
        case .blue: return Color(hex: "#B5C4E0") ?? .blue.opacity(0.8)
        case .green: return Color(hex: "#B5E0C4") ?? .green.opacity(0.8)
        case .orange: return Color(hex: "#E0D1B5") ?? .orange.opacity(0.8)
        case .teal: return Color(hex: "#B5E0E0") ?? .teal.opacity(0.8)
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .purple: return Color(hex: "#9B8AC4") ?? .purple
        case .blue: return Color(hex: "#8A9BC4") ?? .blue
        case .green: return Color(hex: "#8AC49B") ?? .green
        case .orange: return Color(hex: "#C4B08A") ?? .orange
        case .teal: return Color(hex: "#8AC4C4") ?? .teal
        }
    }
    
    var previewColor: Color {
        primaryColor
    }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = ThemeColor.purple.rawValue
    
    var selectedTheme: ThemeColor {
        get { ThemeColor(rawValue: selectedThemeRaw) ?? .purple }
        set {
            selectedThemeRaw = newValue.rawValue
            objectWillChange.send()
        }
    }
}

struct AppTheme {
    static var current: ThemeColor {
        ThemeManager.shared.selectedTheme
    }
    
    // Dynamic colors based on selected theme
    static var primaryPurple: Color { current.primaryColor }
    static var darkPurple: Color { current.darkColor }
    static var mediumPurple: Color { current.mediumColor }
    static var lightPurple: Color { current.lightColor }
    static var accentPurple: Color { current.accentColor }
    
    static var cardBackground: Color { current.cardBackground }
    static var surfaceBackground: Color { current.surfaceBackground }
}
