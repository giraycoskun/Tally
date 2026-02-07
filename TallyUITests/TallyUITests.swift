//
//  TallyUITests.swift
//  TallyUITests
//

import XCTest

final class TallyUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Tab Navigation Tests
    
    @MainActor
    func testTabNavigationExists() throws {
        XCTAssertTrue(app.tabBars.buttons["Habits"].exists)
        XCTAssertTrue(app.tabBars.buttons["Stats"].exists)
        XCTAssertTrue(app.tabBars.buttons["Settings"].exists)
    }
    
    @MainActor
    func testNavigateToStatsTab() throws {
        app.tabBars.buttons["Stats"].tap()
        XCTAssertTrue(app.navigationBars["Statistics"].waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testNavigateToSettingsTab() throws {
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testNavigateBackToHabitsTab() throws {
        app.tabBars.buttons["Settings"].tap()
        app.tabBars.buttons["Habits"].tap()
        XCTAssertTrue(app.navigationBars["Habits"].waitForExistence(timeout: 2))
    }
    
    // MARK: - Add Habit Tests
    
    @MainActor
    func testAddHabitButtonExists() throws {
        XCTAssertTrue(app.navigationBars.buttons["plus"].exists || 
                      app.buttons["Add Habit"].exists ||
                      app.navigationBars.buttons["Add"].exists)
    }
    
    @MainActor
    func testAddHabitFormOpens() throws {
        // Find and tap the add button
        if app.navigationBars.buttons["plus"].exists {
            app.navigationBars.buttons["plus"].tap()
        } else if app.buttons["Add Habit"].exists {
            app.buttons["Add Habit"].tap()
        }
        
        // Verify form appears
        XCTAssertTrue(app.navigationBars["New Habit"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.textFields["Habit name"].exists)
    }
    
    @MainActor
    func testAddHabitFormHasCancelButton() throws {
        if app.navigationBars.buttons["plus"].exists {
            app.navigationBars.buttons["plus"].tap()
        }
        
        XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testAddHabitFormHasSaveButton() throws {
        if app.navigationBars.buttons["plus"].exists {
            app.navigationBars.buttons["plus"].tap()
        }
        
        XCTAssertTrue(app.buttons["Save"].waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testAddHabitSaveDisabledWhenEmpty() throws {
        if app.navigationBars.buttons["plus"].exists {
            app.navigationBars.buttons["plus"].tap()
        }
        
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2))
        XCTAssertFalse(saveButton.isEnabled)
    }
    
    @MainActor
    func testAddHabitSaveEnabledAfterTypingName() throws {
        if app.navigationBars.buttons["plus"].exists {
            app.navigationBars.buttons["plus"].tap()
        }
        
        let textField = app.textFields["Habit name"]
        XCTAssertTrue(textField.waitForExistence(timeout: 2))
        textField.tap()
        textField.typeText("Test Habit")
        
        XCTAssertTrue(app.buttons["Save"].isEnabled)
    }
    
    @MainActor
    func testAddHabitCancelDismissesForm() throws {
        if app.navigationBars.buttons["plus"].exists {
            app.navigationBars.buttons["plus"].tap()
        }
        
        XCTAssertTrue(app.navigationBars["New Habit"].waitForExistence(timeout: 2))
        app.buttons["Cancel"].tap()
        
        XCTAssertTrue(app.navigationBars["Habits"].waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testCreateNewHabit() throws {
        if app.navigationBars.buttons["plus"].exists {
            app.navigationBars.buttons["plus"].tap()
        }
        
        let textField = app.textFields["Habit name"]
        XCTAssertTrue(textField.waitForExistence(timeout: 2))
        textField.tap()
        textField.typeText("UI Test Habit")
        
        app.buttons["Save"].tap()
        
        // Verify we're back on habits list
        XCTAssertTrue(app.navigationBars["Habits"].waitForExistence(timeout: 2))
        
        // Verify habit appears in list
        XCTAssertTrue(app.staticTexts["UI Test Habit"].waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testAddHabitFrequencyPicker() throws {
        if app.navigationBars.buttons["plus"].exists {
            app.navigationBars.buttons["plus"].tap()
        }
        
        XCTAssertTrue(app.buttons["Daily"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Weekly"].exists)
    }
    
    @MainActor
    func testAddHabitReminderToggle() throws {
        if app.navigationBars.buttons["plus"].exists {
            app.navigationBars.buttons["plus"].tap()
        }
        
        let toggle = app.switches["Enable Reminders"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 2))
    }
    
    // MARK: - Settings Tests
    
    @MainActor
    func testSettingsShowsVersion() throws {
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Version"].waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testSettingsShowsHabitsCount() throws {
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Habits"].waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testSettingsShowsTotalEntries() throws {
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Total Entries"].waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testSettingsShowsDayBoundaryPicker() throws {
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Day Starts At"].waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testSettingsShowsNotificationsToggle() throws {
        app.tabBars.buttons["Settings"].tap()
        let toggle = app.switches["Enable Reminders"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testSettingsShowsExportButton() throws {
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.buttons["Export as JSON"].waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testSettingsShowsResetButton() throws {
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.buttons["Reset All Data"].waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testSettingsResetShowsConfirmation() throws {
        app.tabBars.buttons["Settings"].tap()
        app.buttons["Reset All Data"].tap()
        
        XCTAssertTrue(app.alerts["Reset All Data?"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.alerts.buttons["Cancel"].exists)
        XCTAssertTrue(app.alerts.buttons["Reset"].exists)
    }
    
    @MainActor
    func testSettingsResetCancelDismissesAlert() throws {
        app.tabBars.buttons["Settings"].tap()
        app.buttons["Reset All Data"].tap()
        
        XCTAssertTrue(app.alerts["Reset All Data?"].waitForExistence(timeout: 2))
        app.alerts.buttons["Cancel"].tap()
        
        XCTAssertFalse(app.alerts["Reset All Data?"].exists)
    }
    
    @MainActor
    func testSettingsThemeColorSection() throws {
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Theme Color"].waitForExistence(timeout: 2))
    }
    
    // MARK: - Statistics Tests
    
    @MainActor
    func testStatisticsViewLoads() throws {
        app.tabBars.buttons["Stats"].tap()
        XCTAssertTrue(app.navigationBars["Statistics"].waitForExistence(timeout: 2))
    }
    
    // MARK: - Habit Detail Tests
    
    @MainActor
    func testTapHabitOpensDetail() throws {
        // First create a habit
        if app.navigationBars.buttons["plus"].exists {
            app.navigationBars.buttons["plus"].tap()
        }
        
        let textField = app.textFields["Habit name"]
        XCTAssertTrue(textField.waitForExistence(timeout: 2))
        textField.tap()
        textField.typeText("Detail Test Habit")
        app.buttons["Save"].tap()
        
        // Now tap on the habit to open detail
        XCTAssertTrue(app.staticTexts["Detail Test Habit"].waitForExistence(timeout: 2))
        app.staticTexts["Detail Test Habit"].tap()
        
        // Verify detail view opens
        XCTAssertTrue(app.navigationBars["Detail Test Habit"].waitForExistence(timeout: 2))
    }
    
    // MARK: - Edit Habit Tests
    
    @MainActor
    func testEditHabitFormOpens() throws {
        // First create a habit
        if app.navigationBars.buttons["plus"].exists {
            app.navigationBars.buttons["plus"].tap()
        }
        
        let textField = app.textFields["Habit name"]
        XCTAssertTrue(textField.waitForExistence(timeout: 2))
        textField.tap()
        textField.typeText("Edit Test Habit")
        app.buttons["Save"].tap()
        
        // Open habit detail
        XCTAssertTrue(app.staticTexts["Edit Test Habit"].waitForExistence(timeout: 2))
        app.staticTexts["Edit Test Habit"].tap()
        
        // Tap edit button
        if app.navigationBars.buttons["pencil"].exists {
            app.navigationBars.buttons["pencil"].tap()
        } else if app.buttons["Edit"].exists {
            app.buttons["Edit"].tap()
        }
        
        // Verify edit form opens
        XCTAssertTrue(app.navigationBars["Edit Habit"].waitForExistence(timeout: 2))
    }
}
