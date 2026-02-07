//
//  ThemeColorTests.swift
//  TallyTests
//

import Testing
import SwiftUI
@testable import Tally

@Suite
struct ThemeColorTests {
    
    @Test func allCasesExist() {
        #expect(ThemeColor.allCases.count == 5)
        #expect(ThemeColor.allCases.contains(.purple))
        #expect(ThemeColor.allCases.contains(.blue))
        #expect(ThemeColor.allCases.contains(.green))
        #expect(ThemeColor.allCases.contains(.orange))
        #expect(ThemeColor.allCases.contains(.teal))
    }
    
    @Test func idMatchesRawValue() {
        for theme in ThemeColor.allCases {
            #expect(theme.id == theme.rawValue)
        }
    }
    
    @Test func allColorsReturnValidColors() {
        for theme in ThemeColor.allCases {
            #expect(theme.surfaceBackground != Color.clear)
            #expect(theme.darkColor != Color.clear)
            #expect(theme.cardBackground != Color.clear)
            #expect(theme.primaryColor != Color.clear)
        }
    }
    
    @Test func previewColorMatchesPrimaryColor() {
        for theme in ThemeColor.allCases {
            #expect(theme.previewColor == theme.primaryColor)
        }
    }
    
    @Test func initFromRawValue() {
        #expect(ThemeColor(rawValue: "Purple") == .purple)
        #expect(ThemeColor(rawValue: "Invalid") == nil)
    }
}
