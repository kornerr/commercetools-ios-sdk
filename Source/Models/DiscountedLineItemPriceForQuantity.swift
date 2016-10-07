//
// Copyright (c) 2016 Commercetools. All rights reserved.
//

import ObjectMapper

public struct DiscountedLineItemPriceForQuantity: Mappable {

    // MARK: - Properties

    var quantity: Int?
    var discountedPrice: DiscountedLineItemPrice?

    public init?(map: Map) {}

    // MARK: - Mappable

    mutating public func mapping(map: Map) {
        quantity         <- map["quantity"]
        discountedPrice  <- map["discountedPrice"]
    }

}