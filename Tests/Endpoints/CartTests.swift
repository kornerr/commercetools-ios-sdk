//
// Copyright (c) 2016 Commercetools. All rights reserved.
//

import XCTest
@testable import Commercetools

class CartTests: XCTestCase {

    override func setUp() {
        super.setUp()

        setupTestConfiguration()
    }

    override func tearDown() {
        cleanPersistedTokens()
        super.tearDown()
    }

    func testRetrieveActiveCart() {
        let activeCartExpectation = expectation(description: "active cart expectation")

        let username = "swift.sdk.test.user2@commercetools.com"
        let password = "password"

        AuthManager.sharedInstance.loginCustomer(username: username, password: password, completionHandler: { _ in})

        Cart.create(["currency": "EUR"], result: { result in
            if let response = result.json, let cartState = response["cartState"] as? String, let id = response["id"] as? String {
                XCTAssert(result.isSuccess)
                XCTAssertEqual(cartState, "Active")
                Cart.active(result: { result in
                    if let response = result.json, let activeCartId = response["id"] as? String {
                        XCTAssert(result.isSuccess)
                        XCTAssertEqual(activeCartId, id)
                        activeCartExpectation.fulfill()
                    }
                })
            }
        })

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testCartCreation() {
        let cartCreationExpectation = expectation(description: "cart creation expectation")

        let username = "swift.sdk.test.user2@commercetools.com"
        let password = "password"

        AuthManager.sharedInstance.loginCustomer(username: username, password: password, completionHandler: { _ in})

        sampleLineItemDraft { lineItemDraft in
            let cartDraft = CartDraft(currency: "EUR", lineItems: [lineItemDraft])

            Cart.create(cartDraft, result: { result in
                if let cart = result.model {
                    XCTAssert(result.isSuccess)
                    XCTAssertEqual(cart.cartState, .active)
                    cartCreationExpectation.fulfill()
                }
            })
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testCartCreationWithLineItemsBySku() {
        let addBySkuExpectation = expectation(description: "add by sku expectation")

        let username = "swift.sdk.test.user2@commercetools.com"
        let password = "password"

        AuthManager.sharedInstance.loginCustomer(username: username, password: password, completionHandler: { _ in})

        sampleProduct { product in
            let cartDraft = CartDraft(currency: "EUR", lineItems: [LineItemDraft(productVariantSelection: .sku(sku: product.masterVariant.sku!), quantity: 3)])

            Cart.create(cartDraft, result: { result in
                if let cart = result.model {
                    XCTAssert(result.isSuccess)
                    XCTAssertEqual(cart.lineItems.first?.variant.sku, product.masterVariant.sku)
                    addBySkuExpectation.fulfill()
                }
            })
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testOrderCreation() {
        let orderCreationExpectation = expectation(description: "draft creation expectation")

        let username = "swift.sdk.test.user2@commercetools.com"
        let password = "password"

        AuthManager.sharedInstance.loginCustomer(username: username, password: password, completionHandler: { _ in})

        sampleLineItemDraft { lineItemDraft in
            let cartDraft = CartDraft(currency: "EUR", lineItems: [lineItemDraft], shippingAddress: Address(country: "DE"))

            Cart.create(cartDraft, result: { result in
                if let cart = result.model, result.isSuccess {
                    let orderDraft = OrderDraft(id: cart.id, version: cart.version)
                    Order.create(orderDraft, result: { result in
                        if let order = result.model {
                            XCTAssert(result.isSuccess)
                            XCTAssertEqual(order.cart?.id, cart.id)
                            orderCreationExpectation.fulfill()
                        }
                    })
                }
            })
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testUpdateEndpointWithModelAction() {
        let updateExpectation = expectation(description: "update expectation")

        let username = "swift.sdk.test.user2@commercetools.com"
        let password = "password"

        AuthManager.sharedInstance.loginCustomer(username: username, password: password, completionHandler: { _ in})

        let cartDraft = CartDraft(currency: "EUR")

        Cart.create(cartDraft, result: { result in
            if let cart = result.model, result.isSuccess {
                ProductProjection.query(limit:1, result: { result in
                    if let product = result.model?.results.first, result.isSuccess {                        
                        let updateActions = UpdateActions<CartUpdateAction>(version: cart.version, actions: [.addLineItem(lineItemDraft:
                            LineItemDraft(productVariantSelection: .productVariant(productId: product.id, variantId: product.masterVariant.id)))])

                        Cart.update(cart.id, actions: updateActions, result: { result in
                            if let cart = result.model {
                                XCTAssert(result.isSuccess)
                                XCTAssertEqual(cart.lineItems.count, 1)
                                XCTAssertNotNil(cart.lineItems.first?.productType?.id)
                                updateExpectation.fulfill()
                            }
                        })
                    }
                })
            }
        })

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testTaxModeChangeToDisabled() {
        let cartTaxModeExpectation = expectation(description: "cart tax mode expectation")

        let username = "swift.sdk.test.user2@commercetools.com"
        let password = "password"

        AuthManager.sharedInstance.loginCustomer(username: username, password: password, completionHandler: { _ in})

        sampleLineItemDraft { lineItemDraft in
            let cartDraft = CartDraft(currency: "EUR", taxMode: .external, lineItems: [lineItemDraft])

            Cart.create(cartDraft, result: { result in
                if let cart = result.model {
                    XCTAssert(result.isSuccess)
                    XCTAssertEqual(cart.taxMode, .external)

                    let updateActions = UpdateActions<CartUpdateAction>(version: cart.version, actions: [.changeTaxMode(taxMode: .disabled)])
                    Cart.update(cart.id, actions: updateActions, result: { result in
                        if let error = result.errors?.first as? CTError, case .generalError(let reason) = error {
                            XCTAssert(result.isFailure)
                            XCTAssertEqual(reason?.message, "Disabled tax mode is not allowed on my cart.")
                            cartTaxModeExpectation.fulfill()
                        }
                    })
                }
            })
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testTaxModeChange() {
        let cartTaxModeExpectation = expectation(description: "cart tax mode expectation")

        let username = "swift.sdk.test.user2@commercetools.com"
        let password = "password"

        AuthManager.sharedInstance.loginCustomer(username: username, password: password, completionHandler: { _ in})

        sampleLineItemDraft { lineItemDraft in
            let cartDraft = CartDraft(currency: "EUR", taxMode: .external, lineItems: [lineItemDraft])

            Cart.create(cartDraft, result: { result in
                if let cart = result.model {
                    XCTAssert(result.isSuccess)
                    XCTAssertEqual(cart.taxMode, .external)

                    let updateActions = UpdateActions<CartUpdateAction>(version: cart.version, actions: [.changeTaxMode(taxMode: .platform)])
                    Cart.update(cart.id, actions: updateActions, result: { result in
                        if let cart = result.model {
                            XCTAssert(result.isSuccess)
                            XCTAssertEqual(cart.taxMode, .platform)
                            cartTaxModeExpectation.fulfill()
                        }
                    })
                }
            })
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testDeleteDaysAfterLastModification() {
        let cartDeleteExpectation = expectation(description: "cart delete if not modified expectation")

        let username = "swift.sdk.test.user2@commercetools.com"
        let password = "password"

        AuthManager.sharedInstance.loginCustomer(username: username, password: password, completionHandler: { _ in})

        sampleLineItemDraft { lineItemDraft in
            let cartDraft = CartDraft(currency: "EUR", lineItems: [lineItemDraft], deleteDaysAfterLastModification: 3)

            Cart.create(cartDraft, result: { result in
                if let cart = result.model {
                    XCTAssert(result.isSuccess)
                    XCTAssertEqual(cart.deleteDaysAfterLastModification, 3)

                    let updateActions = UpdateActions<CartUpdateAction>(version: cart.version, actions: [.setDeleteDaysAfterLastModification(deleteDaysAfterLastModification: 8)])
                    Cart.update(cart.id, actions: updateActions, result: { result in
                        if let cart = result.model {
                            XCTAssert(result.isSuccess)
                            XCTAssertEqual(cart.deleteDaysAfterLastModification, 8)
                            cartDeleteExpectation.fulfill()
                        }
                    })
                }
            })
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testCustomShippingMethodNotAvailable() {
        let cartExpectation = expectation(description: "cart expectation")

        let username = "swift.sdk.test.user2@commercetools.com"
        let password = "password"

        AuthManager.sharedInstance.loginCustomer(username: username, password: password, completionHandler: { _ in})

        sampleLineItemDraft { lineItemDraft in
            let cartDraft = CartDraft(currency: "EUR", lineItems: [lineItemDraft], deleteDaysAfterLastModification: 3)

            Cart.create(cartDraft, result: { result in
                if let cart = result.model {
                    XCTAssert(result.isSuccess)
                    XCTAssertEqual(cart.deleteDaysAfterLastModification, 3)

                    Cart.update(cart.id, version: cart.version, actions: [["action": "setCustomShippingMethod", "shippingMethodName": "test",
                                                                           "shippingRate": ["currencyCode": "EUR", "centAmount": 8000]]], result: { result in
                        XCTAssert(result.isFailure)
                        XCTAssert(result.errors!.first!.localizedDescription.contains("Invalid json input occurred\nRequest body does not contain valid JSON.: actions: Invalid type value \'setCustomShippingMethod\'"))
                        cartExpectation.fulfill()
                    })
                }
            })
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testDiscountCodeCustomFields() {
        let discountCodeExpectation = expectation(description: "update expectation")

        let username = "swift.sdk.test.user2@commercetools.com"
        let password = "password"

        AuthManager.sharedInstance.loginCustomer(username: username, password: password, completionHandler: { _ in})

        let cartDraft = CartDraft(currency: "EUR")

        Cart.create(cartDraft, result: { result in
            if let cart = result.model, result.isSuccess {
                let updateActions = UpdateActions<CartUpdateAction>(version: cart.version, actions: [.addDiscountCode(code: "testCode")])

                Cart.update(cart.id, actions: updateActions, expansion: ["discountCodes[0].discountCode"], result: { result in
                    if let cart = result.model {
                        let discountCode = cart.discountCodes.first!.discountCode.obj!
                        XCTAssert(result.isSuccess)
                        XCTAssertEqual(discountCode.custom?.dictionary?["fields"]?.dictionary?["testField"]?.string, "testValue")
                        discountCodeExpectation.fulfill()
                    }
                })
            }
        })

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testItemShippingAddresses() {
        let itemAddressExpectation = expectation(description: "item shipping addresses expectation")

        let username = "swift.sdk.test.user2@commercetools.com"
        let password = "password"

        AuthManager.sharedInstance.loginCustomer(username: username, password: password, completionHandler: { _ in})

        sampleLineItemDraft { lineItemDraft in
            lineItemDraft.shippingDetails = ItemShippingDetailsDraft(targets: [ItemShippingTarget(addressKey: "test-key-1", quantity: 1), ItemShippingTarget(addressKey: "test-key-2", quantity: 1)])
            lineItemDraft.quantity = 2
            let cartDraft = CartDraft(currency: "EUR", lineItems: [lineItemDraft], itemShippingAddresses: [Address(key: "test-key-1", country: "DE"), Address(key: "test-key-2", country: "DE")])

            Cart.create(cartDraft, result: { result in
                if let cart = result.model {
                    XCTAssert(result.isSuccess)
                    XCTAssertEqual(cart.itemShippingAddresses.count, 2)
                    XCTAssertEqual(cart.lineItems.first!.shippingDetails!.targets[0].quantity, 1)
                    XCTAssertEqual(cart.lineItems.first!.shippingDetails!.targets[1].quantity, 1)
                    Cart.update(cart.id, actions: UpdateActions(version: cart.version, actions: [.applyDeltaToLineItemShippingDetailsTargets(lineItemId: cart.lineItems.first!.id, targetsDelta: [ItemShippingTarget(addressKey: "test-key-1", quantity: 1), ItemShippingTarget(addressKey: "test-key-2", quantity: -1)])]), result: { result in
                        if let cart = result.model, result.isSuccess {
                            XCTAssert(result.isSuccess)
                            XCTAssertEqual(cart.itemShippingAddresses.count, 2)
                            XCTAssertEqual(cart.lineItems.first!.shippingDetails!.targets.count, 1)
                            XCTAssertEqual(cart.lineItems.first!.shippingDetails!.targets.first(where: { $0.addressKey == "test-key-1" })!.quantity, 2)
                            itemAddressExpectation.fulfill()
                        }
                    })
                }
            })
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    private func sampleLineItemDraft(_ completion: @escaping (LineItemDraft) -> Void) {
        ProductProjection.query(limit:1, result: { result in
            if let product = result.model?.results.first, result.isSuccess {
                let lineItemDraft = LineItemDraft(productVariantSelection: .productVariant(productId: product.id, variantId: product.masterVariant.id), quantity: 3)
                completion(lineItemDraft)
            }
        })
    }

    private func sampleProduct(_ completion: @escaping (ProductProjection) -> Void) {
        ProductProjection.query(limit:1, result: { result in
            if let product = result.model?.results.first, result.isSuccess {
                completion(product)
            }
        })
    }
}
