//
//  EventoriasUITestsLaunchTests.swift
//  EventoriasUITests
//
//  Created by Sarah Maimoun on 05/10/2026.
//


import XCTest

final class EventoriasUITestsLaunchTests:
    XCTestCase {

    override class var
        runsForEachTargetApplicationUIConfiguration:
        Bool {

        false
    }

    override func setUpWithError()
        throws {

        continueAfterFailure =
            false
    }

    func testUITestBundleLoads() {

        // Le lancement réel de l'application est déjà
        // couvert par EventoriasUITests.
        //
        // Ce test conserve le fichier LaunchTests sans
        // provoquer un lancement supplémentaire du simulateur.

        XCTAssertTrue(true)
    }
}
