//
//  LoaderTests.swift
//  ImageLoader
//
//  Created by Hirohisa Kawasaki on 11/30/15.
//  Copyright © 2015 Hirohisa Kawasaki. All rights reserved.
//

import XCTest

class LoaderTests: ImageLoaderTests {

    func testLoad() {

        let expectation = self.expectation(description: "wait until loader complete")

        var url: URL!
        url = URL(string: "http://test/path")

        let manager = Manager()
        let loader = manager.load(url)

        XCTAssert(loader.state == .running, loader.state.toString())
        let _ = loader.completionHandler { completedUrl, image, error, cacheType in

            XCTAssertEqual(url, completedUrl)
            XCTAssert(manager.state == .running, manager.state.toString())
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
        }
    }

    func testRemoveAfterRunning() {

        let expectation = self.expectation(description: "wait until loader complete")

        var url: URL!
        url = URL(string: "http://test/remove")

        let manager = Manager()
        let loader = manager.load(url)

        XCTAssert(loader.state == .running, loader.state.toString())

        let _ = loader.completionHandler { completedUrl, image, error, cacheType in

            let time  = DispatchTime.now() + Double(Int64(0.1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.after(when: time, execute: { 
                XCTAssertNil(manager.delegate[url], "loader did not remove from delegate")
                expectation.fulfill()
            })
        }

        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
        }
    }

    func testSomeLoad() {

        var url: URL!
        url = URL(string: "http://test/path")

        let manager = Manager()
        let loader1 = manager.load(url)

        url = URL(string: "http://test/path2")
        let loader2 = manager.load(url)

        XCTAssert(loader1.state == .running, loader1.state.toString())
        XCTAssert(loader2.state == .running, loader2.state.toString())
        XCTAssert(loader1 !== loader2)

    }


    func testSomeLoadSameURL() {

        var url: URL!
        url = URL(string: "http://test/path")

        let manager = Manager()
        let loader1 = manager.load(url)

        url = URL(string: "http://test/path")
        let loader2 = manager.load(url)

        XCTAssert(loader1.state == .running, loader1.state.toString())
        XCTAssert(loader2.state == .running, loader2.state.toString())
        XCTAssert(loader1 === loader2)

    }

    func testLoadResponseCode404() {

        let expectation = self.expectation(description: "wait until loader complete")

        let url = URL(string: "http://test/404")!

        let manager = Manager()
        let loader = manager.load(url)

        XCTAssert(loader.state == .running, loader.state.toString())
        let _ = loader.completionHandler { _, image, _, _ in

            XCTAssertNil(image)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
        }
    }

    func testCancelAfterLoading() {

        let url = URL(string: "http://test/path")!

        let manager: Manager = Manager()

        XCTAssert(manager.state == .ready, manager.state.toString())

        let _ = manager.load(url)
        manager.cancel(url, block: nil)

        let loader: Loader? = manager.delegate[url]
        XCTAssertNil(loader)

    }

    func testUseShouldKeepLoader() {
        let url = URL(string: "http://test/path")!

        let keepingManager = Manager()
        keepingManager.shouldKeepLoader = true
        let notkeepingManager = Manager()
        notkeepingManager.shouldKeepLoader = false

        let _ = keepingManager.load(url)
        let _ = notkeepingManager.load(url)

        keepingManager.cancel(url)
        notkeepingManager.cancel(url)

        let keepingLoader: Loader? = keepingManager.delegate[url]
        let notkeepingLoader: Loader? = notkeepingManager.delegate[url]
        XCTAssertNotNil(keepingLoader)
        XCTAssertNil(notkeepingLoader)
    }
}
