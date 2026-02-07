//
//  ColorExtensionTests.swift
//  TallyTests
//

import Testing
import SwiftUI
@testable import Tally

@Suite
struct ColorExtensionTests {
    
    @Test func initWithValidHex() {
        #expect(Color(hex: "#FF0000") != nil)
        #expect(Color(hex: "00FF00") != nil)
        #expect(Color(hex: "#abcdef") != nil)
    }
    
    @Test func initWithInvalidHex() {
        #expect(Color(hex: "#GGGGGG") == nil)
        #expect(Color(hex: "") == nil)
    }
    
    @Test func initWithWhitespaceIsTrimmed() {
        #expect(Color(hex: "  #FF0000  ") != nil)
    }
    
    @Test func commonHabitColors() {
        #expect(Color(hex: "#4CAF50") != nil)
        #expect(Color(hex: "#9B8AC4") != nil)
        #expect(Color(hex: "#2196F3") != nil)
    }
}
