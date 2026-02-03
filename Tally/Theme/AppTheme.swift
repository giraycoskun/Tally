//
//  AppTheme.swift
//  Tally
//

import SwiftUI

struct AppTheme {
    // Lighter, matte purple palette
    static let primaryPurple = Color(hex: "#9B8AC4") ?? .purple
    static let darkPurple = Color(hex: "#2A2438") ?? .black
    static let mediumPurple = Color(hex: "#3D3552") ?? .purple.opacity(0.3)
    static let lightPurple = Color(hex: "#B8A9D9") ?? .purple.opacity(0.6)
    static let accentPurple = Color(hex: "#C4B5E0") ?? .purple.opacity(0.8)
    
    static let cardBackground = Color(hex: "#352F44") ?? .black.opacity(0.8)
    static let surfaceBackground = Color(hex: "#1F1B2E") ?? .black
}
