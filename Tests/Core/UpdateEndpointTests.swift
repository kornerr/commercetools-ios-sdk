//
// Copyright (c) 2016 Commercetools. All rights reserved.
//

import XCTest
@testable import Commercetools

class UpdateEndpointTests: XCTestCase {

    private class TestCart: UpdateEndpoint, CreateEndpoint {
        static let path = "me/carts"
    }

    private class TestProductProjections: QueryEndpoint {
        static let path = "product-projections"
    }

    override func setUp() {
        super.setUp()

        setupTestConfiguration()
    }

    override func tearDown() {
        cleanPersistedTokens()
        super.tearDown()
    }

    func testUpdateEndpoint() {

        let updateExpectation = expectationWithDescription("update expectation")

        let username = "swift.sdk.test.user2@commercetools.com"
        let password = "password"

        AuthManager.sharedInstance.loginUser(username, password: password, completionHandler: {_ in})

        TestProductProjections.query(limit: 1, result: { result in
            if let response = result.response, results = response["results"] as? [[String: AnyObject]],
            productId = results.first?["id"] as? String where result.isSuccess {

                let addLineItemAction: [String: AnyObject] = ["action": "addLineItem", "productId": productId, "variantId": 1]

                TestCart.create(["currency": "EUR"], result: { result in
                    if let response = result.response, id = response["id"] as? String, version = response["version"] as? UInt
                            where result.isSuccess {
                        TestCart.update(id, version: version, actions: [addLineItemAction], result: { result in
                            if let response = result.response, updatedId = response["id"] as? String,
                                    newVersion = response["version"] as? UInt where result.isSuccess  && updatedId == id
                                    && newVersion > version {
                                updateExpectation.fulfill()
                            }
                        })
                    }
                })
            }
        })

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testConcurrentModification() {

        let updateExpectation = expectationWithDescription("update expectation")

        let username = "swift.sdk.test.user2@commercetools.com"
        let password = "password"

        AuthManager.sharedInstance.loginUser(username, password: password, completionHandler: {_ in})

        TestProductProjections.query(limit: 1, result: { result in
            if let response = result.response, results = response["results"] as? [[String: AnyObject]],
                    productId = results.first?["id"] as? String where result.isSuccess {

                let addLineItemAction: [String: AnyObject] = ["action": "addLineItem", "productId": productId, "variantId": 1]

                TestCart.create(["currency": "EUR"], result: { result in
                    if let response = result.response, id = response["id"] as? String, version = response["version"] as? UInt
                            where result.isSuccess {
                        TestCart.update(id, version: version + 1, actions: [addLineItemAction], result: { result in
                            if let error = result.errors?.first, errorReason = error.userInfo[NSLocalizedFailureReasonErrorKey] as? String
                                    where errorReason == "Object \(id) has a different version than expected. Expected: 2 - Actual: 1." &&
                                    error.code == Error.Code.ConcurrentModificationError.rawValue && result.statusCode == 409 {
                                updateExpectation.fulfill()
                            }
                        })
                    }
                })
            }
        })

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testUpdateEndpointError() {

        let updateExpectation = expectationWithDescription("update expectation")

        let username = "swift.sdk.test.user2@commercetools.com"
        let password = "password"

        AuthManager.sharedInstance.loginUser(username, password: password, completionHandler: {_ in})

        TestCart.update("cddddddd-ffff-4b44-b5b0-004e7d4bc2dd", version: 1, actions: [], result: { result in
            if let error = result.errors?.first, errorReason = error.userInfo[NSLocalizedFailureReasonErrorKey] as? String
            where errorReason == "The Cart with ID 'cddddddd-ffff-4b44-b5b0-004e7d4bc2dd' was not found." &&
                    error.code == Error.Code.ResourceNotFoundError.rawValue && result.statusCode == 404 {
                updateExpectation.fulfill()
            }
        })

        waitForExpectationsWithTimeout(10, handler: nil)
    }

}
