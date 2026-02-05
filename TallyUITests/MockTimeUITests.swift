//
//  MockTimeUITests.swift
//  TallyUITests
//
//  UI Tests with mocked time for manual testing of day boundary feature.
//  
//  HOW TO USE:
//  1. Run any test from Xcode's Test Navigator (⌘6)
//  2. The app launches with a frozen mock time
//  3. Go to Settings > Day Boundary to change when a new day starts
//  4. Complete habits and observe how they're tracked based on the mock time and boundary
//  5. The test waits 5 minutes for you to interact
//

import XCTest

final class MockTimeUITests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    /// Launches the app with a mocked time at 1:30 AM.
    /// Go to Settings to change the day boundary and see how it affects habit tracking.
    /// - With boundary at 2 AM or later: 1:30 AM counts as PREVIOUS day
    /// - With boundary at 1 AM or earlier: 1:30 AM counts as CURRENT day
    @MainActor
    func testMockTimeAt0130AM() throws {
        let app = XCUIApplication()
        
        // Only set mock time - user can change day boundary in Settings
        app.launchArguments = ["-mockTime", "2026-02-05T01:30:00"]
        
        app.launch()
        
        print("═══════════════════════════════════════════════════════════")
        print("🕐 Mock time: 1:30 AM on Feb 5, 2026")
        print("═══════════════════════════════════════════════════════════")
        print("📱 Go to Settings > Day Boundary to test different settings:")
        print("   • Midnight (12 AM): 1:30 AM = Feb 5th")
        print("   • 1:00 AM: 1:30 AM = Feb 5th")
        print("   • 2:00 AM: 1:30 AM = Feb 4th (previous day)")
        print("   • 3:00 AM: 1:30 AM = Feb 4th (previous day)")
        print("═══════════════════════════════════════════════════════════")
        print("⏳ Waiting 5 minutes for manual testing...")
        
        let waitExpectation = expectation(description: "Wait for manual testing")
        waitExpectation.isInverted = true
        wait(for: [waitExpectation], timeout: 300)
    }
    
    /// Launches the app with a mocked time at 2:30 AM.
    /// This is useful for testing the boundary edge case.
    @MainActor
    func testMockTimeAt0230AM() throws {
        let app = XCUIApplication()
        
        app.launchArguments = ["-mockTime", "2026-02-05T02:30:00"]
        
        app.launch()
        
        print("═══════════════════════════════════════════════════════════")
        print("🕐 Mock time: 2:30 AM on Feb 5, 2026")
        print("═══════════════════════════════════════════════════════════")
        print("📱 Go to Settings > Day Boundary to test different settings:")
        print("   • Midnight - 2 AM: 2:30 AM = Feb 5th")
        print("   • 3:00 AM or later: 2:30 AM = Feb 4th (previous day)")
        print("═══════════════════════════════════════════════════════════")
        print("⏳ Waiting 5 minutes for manual testing...")
        
        let waitExpectation = expectation(description: "Wait for manual testing")
        waitExpectation.isInverted = true
        wait(for: [waitExpectation], timeout: 300)
    }
    
    /// Launches the app with a mocked time at 4:00 AM.
    /// This time is after all possible boundaries (max 6 AM), so it always counts as Feb 5th.
    @MainActor
    func testMockTimeAt0400AM() throws {
        let app = XCUIApplication()
        
        app.launchArguments = ["-mockTime", "2026-02-05T04:00:00"]
        
        app.launch()
        
        print("═══════════════════════════════════════════════════════════")
        print("🕐 Mock time: 4:00 AM on Feb 5, 2026")
        print("═══════════════════════════════════════════════════════════")
        print("📱 Go to Settings > Day Boundary to test different settings:")
        print("   • Midnight - 4 AM: 4:00 AM = Feb 5th")
        print("   • 5:00 AM or 6:00 AM: 4:00 AM = Feb 4th (previous day)")
        print("═══════════════════════════════════════════════════════════")
        print("⏳ Waiting 5 minutes for manual testing...")
        
        let waitExpectation = expectation(description: "Wait for manual testing")
        waitExpectation.isInverted = true
        wait(for: [waitExpectation], timeout: 300)
    }
    
    /// Launches the app at 11:30 PM to test late night habit completion.
    /// This time is always after any boundary, so it always counts as the current day.
    @MainActor
    func testMockTimeAt1130PM() throws {
        let app = XCUIApplication()
        
        app.launchArguments = ["-mockTime", "2026-02-04T23:30:00"]
        
        app.launch()
        
        print("═══════════════════════════════════════════════════════════")
        print("🕐 Mock time: 11:30 PM on Feb 4, 2026")
        print("═══════════════════════════════════════════════════════════")
        print("📱 This time always counts as Feb 4th regardless of boundary")
        print("   (boundary only affects times between midnight and 6 AM)")
        print("═══════════════════════════════════════════════════════════")
        print("⏳ Waiting 5 minutes for manual testing...")
        
        let waitExpectation = expectation(description: "Wait for manual testing")
        waitExpectation.isInverted = true
        wait(for: [waitExpectation], timeout: 300)
    }
}
