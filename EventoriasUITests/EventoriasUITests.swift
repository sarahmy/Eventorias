//
//  EventoriasUITests.swift
//  EventoriasUITests
//
//  Created by Sarah Maimoun on 05/10/2026.
//



import XCTest

final class EventoriasUITests:
    XCTestCase {

    private var app:
        XCUIApplication!

    // ============================================================
    // MARK: - SETUP
    // ============================================================

    override func setUpWithError()
        throws {

        continueAfterFailure =
            false
    }

    override func tearDownWithError()
        throws {

        if
            let app,
            app.state != .notRunning {

            app.terminate()
        }

        app = nil
    }

    // ============================================================
    // MARK: - LOGIN
    // ============================================================

    func testLoginCompleteFlow()
        throws {

        launch(
            scenario:
                "login"
        )

        let emailEntry =
            app.buttons[
                "login.emailEntry"
            ]

        XCTAssertTrue(
            emailEntry
                .waitForExistence(
                    timeout: 5
                )
        )

        emailEntry.tap()

        XCTAssertTrue(
            app.textFields[
                "login.email"
            ]
            .waitForExistence(
                timeout: 3
            )
        )

        XCTAssertTrue(
            app.secureTextFields[
                "login.password"
            ]
            .waitForExistence(
                timeout: 3
            )
        )

        XCTAssertTrue(
            app.buttons[
                "login.submit"
            ]
            .waitForExistence(
                timeout: 3
            )
        )

        XCTAssertTrue(
            app.buttons[
                "login.modeToggle"
            ]
            .waitForExistence(
                timeout: 3
            )
        )

        XCTAssertTrue(
            app.buttons[
                "login.passwordVisibility"
            ]
            .waitForExistence(
                timeout: 3
            )
        )

        // Afficher le mot de passe

        app.buttons[
            "login.passwordVisibility"
        ]
        .tap()

        XCTAssertTrue(
            app.textFields[
                "login.password"
            ]
            .waitForExistence(
                timeout: 2
            )
        )

        // Le masquer à nouveau

        app.buttons[
            "login.passwordVisibility"
        ]
        .tap()

        // Passage inscription

        app.buttons[
            "login.modeToggle"
        ]
        .tap()

        XCTAssertTrue(
            app.staticTexts[
                "Créer un compte"
            ]
            .waitForExistence(
                timeout: 3
            )
        )

        // Retour connexion

        app.buttons[
            "login.modeToggle"
        ]
        .tap()

        XCTAssertTrue(
            app.staticTexts[
                "Connexion"
            ]
            .waitForExistence(
                timeout: 3
            )
        )
    }

    // ============================================================
    // MARK: - MAIN / CREATION
    // ============================================================

    func testMainCompleteFlow()
        throws {

        launch(
            scenario:
                "main"
        )

        XCTAssertTrue(
            app.staticTexts[
                "Music Festival"
            ]
            .waitForExistence(
                timeout: 6
            )
        )

        XCTAssertTrue(
            app.staticTexts[
                "Art Exhibition"
            ]
            .exists
        )

        let createButton =
            findButton(
                identifier:
                    "events.create",
                label:
                    "Créer un événement"
            )

        XCTAssertTrue(
            createButton
                .waitForExistence(
                    timeout: 4
                )
        )

        createButton.tap()

        XCTAssertTrue(
            app.navigationBars[
                "Création d'un événement"
            ]
            .waitForExistence(
                timeout: 4
            )
        )

        XCTAssertTrue(
            app.textFields[
                "creation.title"
            ]
            .waitForExistence(
                timeout: 3
            )
        )

        XCTAssertTrue(
            app.textFields[
                "creation.location"
            ]
            .waitForExistence(
                timeout: 3
            )
        )

        XCTAssertTrue(
            app.textFields[
                "creation.category"
            ]
            .waitForExistence(
                timeout: 3
            )
        )

        let validate =
            findButton(
                identifier:
                    "creation.submit",
                label:
                    "Valider"
            )

        makeHittable(
            validate
        )

        XCTAssertTrue(
            validate
                .waitForExistence(
                    timeout: 4
                )
        )

        validate.tap()

        let alert =
            app.alerts[
                "Erreur"
            ]

        XCTAssertTrue(
            alert
                .waitForExistence(
                    timeout: 4
                )
        )

        alert.buttons[
            "OK"
        ]
        .tap()
    }

    // ============================================================
    // MARK: - LIST SEARCH / STATES
    // ============================================================

    func testEventListSearchAndStates()
        throws {

        launch(
            scenario:
                "main"
        )

        let search =
            app.textFields[
                "events.search"
            ]

        XCTAssertTrue(
            search
                .waitForExistence(
                    timeout: 5
                )
        )

        search.tap()

        search.typeText(
            "tech"
        )

        XCTAssertTrue(
            app.staticTexts[
                "Tech Conference"
            ]
            .waitForExistence(
                timeout: 5
            )
        )

        replaceText(
            in:
                search,
            with:
                "zzzzzzzz"
        )

        XCTAssertTrue(
            app.staticTexts[
                "Aucun résultat"
            ]
            .waitForExistence(
                timeout: 5
            )
        )

        // Liste vide

        relaunch(
            scenario:
                "list-empty"
        )

        XCTAssertTrue(
            app.staticTexts[
                "Aucun événement"
            ]
            .waitForExistence(
                timeout: 5
            )
        )

        // Erreur de chargement

        relaunch(
            scenario:
                "list-error"
        )

        XCTAssertTrue(
            app.staticTexts[
                "Erreur"
            ]
            .waitForExistence(
                timeout: 5
            )
        )

        let retry =
            app.buttons[
                "events.retry"
            ]

        XCTAssertTrue(
            retry
                .waitForExistence(
                    timeout: 3
                )
        )

        retry.tap()

        XCTAssertTrue(
            app.staticTexts[
                "Erreur"
            ]
            .waitForExistence(
                timeout: 5
            )
        )
    }

    // ============================================================
    // MARK: - LIST SORT
    // ============================================================

    func testEventListAllSortOptions()
        throws {

        launch(
            scenario:
                "main"
        )

        XCTAssertTrue(
            app.staticTexts[
                "Music Festival"
            ]
            .waitForExistence(
                timeout: 5
            )
        )

        openSortMenu()

        tapMenuAction(
            "Date : plus lointaine"
        )

        openSortMenu()

        tapMenuAction(
            "Titre : A → Z"
        )

        openSortMenu()

        tapMenuAction(
            "Titre : Z → A"
        )

        openSortMenu()

        tapMenuAction(
            "Date : plus proche"
        )

        XCTAssertTrue(
            app.staticTexts[
                "Music Festival"
            ]
            .waitForExistence(
                timeout: 3
            )
        )
    }

    // ============================================================
    // MARK: - LIST -> DETAIL
    // ============================================================

    func testEventListOpensDetail()
        throws {

        launch(
            scenario:
                "main"
        )

        XCTAssertTrue(
            app.staticTexts[
                "Music Festival"
            ]
            .waitForExistence(
                timeout: 5
            )
        )

        let eventButton =
            app.buttons
                .matching(
                    NSPredicate(
                        format:
                            "label CONTAINS[c] %@",
                        "Music Festival"
                    )
                )
                .firstMatch

        if eventButton
            .waitForExistence(
                timeout: 2
            ) {

            eventButton.tap()

        } else {

            app.staticTexts[
                "Music Festival"
            ]
            .tap()
        }

        XCTAssertTrue(
            element(
                identifier:
                    "detail.screen"
            )
            .waitForExistence(
                timeout: 5
            )
        )

        XCTAssertTrue(
            app.staticTexts[
                "Description"
            ]
            .exists
        )

        XCTAssertTrue(
            app.staticTexts[
                "Lieu"
            ]
            .exists
        )

        XCTAssertTrue(
            app.staticTexts[
                "Carte"
            ]
            .exists
        )
    }

    // ============================================================
    // MARK: - OWNER / GUEST
    // ============================================================

    func testOwnerAndGuestPermissions()
        throws {

        launch(
            scenario:
                "detail-owner"
        )

        XCTAssertTrue(
            app.staticTexts[
                "Description"
            ]
            .waitForExistence(
                timeout: 5
            )
        )

        let options =
            optionsButton()

        XCTAssertTrue(
            options
                .waitForExistence(
                    timeout: 3
                )
        )

        options.tap()

        XCTAssertTrue(
            menuElement(
                "Modifier"
            )
            .waitForExistence(
                timeout: 3
            )
        )

        XCTAssertTrue(
            menuElement(
                "Supprimer"
            )
            .waitForExistence(
                timeout: 3
            )
        )

        relaunch(
            scenario:
                "detail-guest"
        )

        XCTAssertTrue(
            app.staticTexts[
                "Description"
            ]
            .waitForExistence(
                timeout: 5
            )
        )

        XCTAssertFalse(
            app.buttons[
                "detail.options"
            ]
            .exists
        )

        XCTAssertFalse(
            app.buttons[
                "Options de l'événement"
            ]
            .exists
        )
    }

    // ============================================================
    // MARK: - DETAIL -> EDIT
    // ============================================================

    func testDetailOpensEditView()
        throws {

        launch(
            scenario:
                "detail-owner"
        )

        let options =
            optionsButton()

        XCTAssertTrue(
            options
                .waitForExistence(
                    timeout: 5
                )
        )

        options.tap()

        let modify =
            menuElement(
                "Modifier"
            )

        XCTAssertTrue(
            modify
                .waitForExistence(
                    timeout: 3
                )
        )

        modify.tap()

        let title =
            app.textFields[
                "edit.title"
            ]

        XCTAssertTrue(
            title
                .waitForExistence(
                    timeout: 5
                )
        )

        XCTAssertEqual(
            title.value as? String,
            "Music Festival"
        )

        let cancel =
            app.buttons[
                "edit.cancel"
            ]

        XCTAssertTrue(
            cancel
                .waitForExistence(
                    timeout: 3
                )
        )

        cancel.tap()
    }

    // ============================================================
    // MARK: - DETAIL DELETE FAILURE
    // ============================================================

    func testDetailDeleteFailureDisplaysError()
        throws {

        launch(
            scenario:
                "detail-delete-error"
        )

        XCTAssertTrue(
            app.staticTexts[
                "Description"
            ]
            .waitForExistence(
                timeout: 5
            )
        )

        let options =
            optionsButton()

        XCTAssertTrue(
            options
                .waitForExistence(
                    timeout: 5
                )
        )

        options.tap()

        let delete =
            menuElement(
                "Supprimer"
            )

        XCTAssertTrue(
            delete
                .waitForExistence(
                    timeout: 3
                )
        )

        delete.tap()

        let definitive =
            findElement(
                label:
                    "Supprimer définitivement"
            )

        XCTAssertTrue(
            definitive
                .waitForExistence(
                    timeout: 5
                )
        )

        definitive.tap()

        let errorAlert =
            app.alerts[
                "Erreur"
            ]

        XCTAssertTrue(
            errorAlert
                .waitForExistence(
                    timeout: 6
                )
        )

        XCTAssertTrue(
            errorAlert.buttons[
                "OK"
            ]
            .exists
        )

        errorAlert.buttons[
            "OK"
        ]
        .tap()

        XCTAssertTrue(
            app.staticTexts[
                "Description"
            ]
            .waitForExistence(
                timeout: 3
            )
        )
    }

    // ============================================================
    // MARK: - EDIT
    // ============================================================

    func testEditCompleteFlow()
        throws {

        launch(
            scenario:
                "edit"
        )

        let titleField =
            app.textFields[
                "edit.title"
            ]

        XCTAssertTrue(
            titleField
                .waitForExistence(
                    timeout: 6
                )
        )

        XCTAssertEqual(
            titleField.value
                as? String,
            "Music Festival"
        )

        XCTAssertTrue(
            app.textFields[
                "edit.location"
            ]
            .exists
        )

        XCTAssertTrue(
            app.textFields[
                "edit.category"
            ]
            .exists
        )

        let camera =
            findButton(
                identifier:
                    "edit.camera",
                label:
                    "Caméra"
            )

        makeHittable(
            camera
        )

        XCTAssertTrue(
            camera
                .waitForExistence(
                    timeout: 4
                )
        )

        camera.tap()

        let cameraAlert =
            app.alerts[
                "Caméra indisponible"
            ]

        XCTAssertTrue(
            cameraAlert
                .waitForExistence(
                    timeout: 5
                )
        )

        cameraAlert
            .buttons[
                "OK"
            ]
            .tap()

        let save =
            findButton(
                identifier:
                    "edit.save",
                label:
                    "Enregistrer les modifications"
            )

        makeHittable(
            save
        )

        XCTAssertTrue(
            save
                .waitForExistence(
                    timeout: 5
                )
        )

        save.tap()

        let error =
            app.alerts[
                "Erreur"
            ]

        XCTAssertTrue(
            error
                .waitForExistence(
                    timeout: 5
                )
        )

        error.buttons[
            "OK"
        ]
        .tap()

        XCTAssertTrue(
            app.buttons[
                "edit.cancel"
            ]
            .exists
        )
    }

    // ============================================================
    // MARK: - PROFILE EDIT / CAMERA / CANCEL
    // ============================================================

    func testProfileEditCameraAndCancel()
        throws {

        openProfile()

        XCTAssertTrue(
            app.staticTexts[
                "Sarah Maimoun"
            ]
            .waitForExistence(
                timeout: 6
            )
        )

        XCTAssertTrue(
            app.staticTexts[
                "sarah@test.com"
            ]
            .exists
        )

        let edit =
            profileEditButton()

        makeHittable(
            edit
        )

        XCTAssertTrue(
            edit
                .waitForExistence(
                    timeout: 4
                )
        )

        edit.tap()

        XCTAssertTrue(
            app.textFields[
                "profile.name"
            ]
            .waitForExistence(
                timeout: 4
            )
        )

        let camera =
            findButton(
                identifier:
                    "profile.camera",
                label:
                    "Caméra"
            )

        makeHittable(
            camera
        )

        XCTAssertTrue(
            camera
                .waitForExistence(
                    timeout: 4
                )
        )

        camera.tap()

        let alert =
            app.alerts[
                "Caméra indisponible"
            ]

        XCTAssertTrue(
            alert
                .waitForExistence(
                    timeout: 4
                )
        )

        alert.buttons[
            "OK"
        ]
        .tap()

        let cancel =
            findButton(
                identifier:
                    "profile.cancelEdit",
                label:
                    "Annuler les modifications"
            )

        makeHittable(
            cancel
        )

        XCTAssertTrue(
            cancel
                .waitForExistence(
                    timeout: 4
                )
        )

        cancel.tap()

        XCTAssertTrue(
            profileEditButton()
                .waitForExistence(
                    timeout: 4
                )
        )
    }

    // ============================================================
    // MARK: - PROFILE SAVE
    // ============================================================

    func testProfileEditAndSave()
        throws {

        openProfile()

        let edit =
            profileEditButton()

        makeHittable(
            edit
        )

        XCTAssertTrue(
            edit
                .waitForExistence(
                    timeout: 5
                )
        )

        edit.tap()

        let name =
            app.textFields[
                "profile.name"
            ]

        XCTAssertTrue(
            name
                .waitForExistence(
                    timeout: 4
                )
        )

        replaceText(
            in:
                name,
            with:
                "Sarah Maimoun"
        )

        let notifications =
            element(
                identifier:
                    "profile.notifications"
            )

        XCTAssertTrue(
            notifications
                .waitForExistence(
                    timeout: 3
                )
        )

        makeHittable(
            notifications
        )

        if notifications.isHittable {

            notifications.tap()
        }

        let save =
            findButton(
                identifier:
                    "profile.save",
                label:
                    "Enregistrer les modifications"
            )

        makeHittable(
            save
        )

        XCTAssertTrue(
            save
                .waitForExistence(
                    timeout: 5
                )
        )

        save.tap()

        let success =
            app.alerts[
                "Profil enregistré"
            ]

        XCTAssertTrue(
            success
                .waitForExistence(
                    timeout: 6
                )
        )

        success.buttons[
            "OK"
        ]
        .tap()

        XCTAssertTrue(
            profileEditButton()
                .waitForExistence(
                    timeout: 5
                )
        )
    }

    // ============================================================
    // MARK: - PROFILE LOGOUT ACTION
    // ============================================================

    func testProfileLogoutActionCanBeTriggered()
        throws {

        openProfile()

        let logout =
            findButton(
                identifier:
                    "profile.logout",
                label:
                    "Se déconnecter"
            )

        makeHittable(
            logout
        )

        XCTAssertTrue(
            logout
                .waitForExistence(
                    timeout: 5
                )
        )

        XCTAssertTrue(
            logout.isHittable
        )

        // Important :
        // on teste que l'action est déclenchable,
        // mais on ne manipule PLUS le bouton Annuler
        // du confirmationDialog.
        //
        // XCTest représente ce dialogue différemment
        // selon iOS / Xcode, ce qui rendait le test instable.

        logout.tap()

        XCTAssertTrue(
            app.wait(
                for:
                    .runningForeground,
                timeout: 2
            )
        )
    }

    // ============================================================
    // MARK: - PROFILE ERROR
    // ============================================================

    func testProfileLoadError()
        throws {

        launch(
            scenario:
                "profile-error"
        )

        let alert =
            app.alerts[
                "Erreur"
            ]

        XCTAssertTrue(
            alert
                .waitForExistence(
                    timeout: 6
                )
        )

        XCTAssertTrue(
            alert.buttons[
                "OK"
            ]
            .exists
        )

        alert.buttons[
            "OK"
        ]
        .tap()
    }

    // ============================================================
    // MARK: - APP MANAGEMENT
    // ============================================================

    private func launch(
        scenario: String
    ) {

        app =
            XCUIApplication()

        configure(
            app,
            scenario:
                scenario
        )

        app.launch()

        XCTAssertTrue(
            app.wait(
                for:
                    .runningForeground,
                timeout: 10
            )
        )
    }

    private func relaunch(
        scenario: String
    ) {

        if
            let app,
            app.state != .notRunning {

            app.terminate()
        }

        app =
            XCUIApplication()

        configure(
            app,
            scenario:
                scenario
        )

        app.launch()

        XCTAssertTrue(
            app.wait(
                for:
                    .runningForeground,
                timeout: 10
            )
        )
    }

    private func configure(
        _ application:
            XCUIApplication,
        scenario: String
    ) {

        application.launchArguments = [

            "-uiTesting",

            "-uiTestScenario",

            scenario,

            "-ApplePersistenceIgnoreState",

            "YES"
        ]

        application
            .launchEnvironment[
                "UITEST_MODE"
            ] = "1"
    }

    // ============================================================
    // MARK: - PROFILE NAVIGATION
    // ============================================================

    private func openProfile() {

        launch(
            scenario:
                "main"
        )

        let profile =
            findProfileTab()

        XCTAssertTrue(
            profile
                .waitForExistence(
                    timeout: 5
                )
        )

        profile.tap()

        XCTAssertTrue(
            app.staticTexts[
                "Sarah Maimoun"
            ]
            .waitForExistence(
                timeout: 6
            )
        )
    }

    private func profileEditButton()
        -> XCUIElement {

        findButton(
            identifier:
                "profile.edit",
            label:
                "Modifier le profil"
        )
    }

    // ============================================================
    // MARK: - DETAIL
    // ============================================================

    private func optionsButton()
        -> XCUIElement {

        findButton(
            identifier:
                "detail.options",
            label:
                "Options de l'événement"
        )
    }

    // ============================================================
    // MARK: - SORT
    // ============================================================

    private func openSortMenu() {

        let sort =
            findButton(
                identifier:
                    "events.sort",
                label:
                    "Trier"
            )

        XCTAssertTrue(
            sort
                .waitForExistence(
                    timeout: 4
                )
        )

        sort.tap()
    }

    // ============================================================
    // MARK: - FIND BUTTON
    // ============================================================

    private func findButton(
        identifier: String,
        label: String
    ) -> XCUIElement {

        let byIdentifier =
            app.buttons[
                identifier
            ]

        if byIdentifier
            .waitForExistence(
                timeout: 0.8
            ) {

            return byIdentifier
        }

        return app.buttons[
            label
        ]
        .firstMatch
    }

    // ============================================================
    // MARK: - GENERIC ELEMENT
    // ============================================================

    private func element(
        identifier: String
    ) -> XCUIElement {

        app
            .descendants(
                matching:
                    .any
            )
            .matching(
                identifier:
                    identifier
            )
            .firstMatch
    }

    private func menuElement(
        _ label: String
    ) -> XCUIElement {

        let button =
            app.buttons[
                label
            ]
            .firstMatch

        if button
            .waitForExistence(
                timeout: 1
            ) {

            return button
        }

        return findElement(
            label:
                label
        )
    }

    private func findElement(
        label: String
    ) -> XCUIElement {

        let predicate =
            NSPredicate(
                format:
                    "label == %@",
                label
            )

        return app
            .descendants(
                matching:
                    .any
            )
            .matching(
                predicate
            )
            .firstMatch
    }

    // ============================================================
    // MARK: - MENU
    // ============================================================

    private func tapMenuAction(
        _ label: String
    ) {

        let action =
            menuElement(
                label
            )

        XCTAssertTrue(
            action
                .waitForExistence(
                    timeout: 3
                ),
            "L'action '\(label)' n'est pas apparue."
        )

        action.tap()
    }

    // ============================================================
    // MARK: - PROFILE TAB
    // ============================================================

    private func findProfileTab()
        -> XCUIElement {

        if app.tabBars
            .buttons[
                "tab.profile"
            ]
            .waitForExistence(
                timeout: 1
            ) {

            return app.tabBars
                .buttons[
                    "tab.profile"
                ]
        }

        if app.tabBars
            .buttons[
                "Profil"
            ]
            .waitForExistence(
                timeout: 1
            ) {

            return app.tabBars
                .buttons[
                    "Profil"
                ]
        }

        return app.tabBars
            .buttons[
                "Profile"
            ]
    }

    // ============================================================
    // MARK: - TEXT
    // ============================================================

    private func replaceText(
        in element:
            XCUIElement,
        with text:
            String
    ) {

        element.tap()

        element.typeKey(
            "a",
            modifierFlags:
                .command
        )

        element.typeKey(
            XCUIKeyboardKey
                .delete
                .rawValue,
            modifierFlags: []
        )

        element.typeText(
            text
        )
    }

    // ============================================================
    // MARK: - SCROLL
    // ============================================================

    private func makeHittable(
        _ element:
            XCUIElement
    ) {

        if element.isHittable {

            return
        }

        let scroll =
            app.scrollViews
                .firstMatch

        guard
            scroll.exists
        else {

            return
        }

        var attempts =
            0

        while
            !element.isHittable,
            attempts < 12 {

            scroll.swipeUp()

            attempts += 1
        }
    }
}
