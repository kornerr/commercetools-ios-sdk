# Commercetools iOS SDK

![SPHERE.IO icon](https://admin.sphere.io/assets/images/sphere_logo_rgb_long.png)

[![][travis img]][travis]
[![][cocoapods img]][cocoapods]
[![][license img]][license]

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 0.39.0+ is required to build CommercetoolsSDK.

To integrate CommercetoolsSDK into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

pod 'Commercetools', '~> 0.0'
```

Then, run the following command:

```bash
$ pod install
```

## Getting Started

The Commercetools SDK uses a `.plist` configuration file named `CommercetoolsConfig.plist` to gather all information needed to communicate with the commercetools platform.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>projectKey</key>
	<string>Your Project Key</string>
	<key>clientId</key>
	<string>Your Client ID</string>
	<key>clientSecret</key>
	<string>Your Client Secret</string>
	<key>scope</key>
	<string>Your Client Scope</string>
	<key>authUrl</key>
	<string>https://auth.sphere.io/</string>
	<key>apiUrl</key>
	<string>https://api.sphere.io</string>
</dict>
</plist> 
```

Alternatively, you can specify a path to different `.plist` file containing these properties.

Before using any methods from the Commercetools SDK, please make sure you have previously set the desired configuration.
```swift
import Commercetools

// Default configuration initializer reads from CommercetoolsConfig.plist file from your app bundle
if let configuration = Config() {
    
    // You can also specify custom logging level
    // configuration.logLevel = .Error
    
    // Or completely disable all log messages from Commercetools SDK
    // configuration.loggingEnabled = false
    
    // Finally, you need set your configuration before using the SDK
    Commercetools.config = configuration
    
} else {
    // There are some errors in your .plist file, check log messages for more information
}
```

## Authenticated and Anonymous Usage

Endpoints from the Commercetools services can be consumed by both anonymous and authenticated users. After you specify the configuration, all further interactions with the Commercetools platform will be performed with anonymous user token.

If at some point you wish to login the user, that can be achieved using `AuthManager` `loginUser` method:

```swift
let authManager = AuthManager.sharedInstance

let username = "swift.sdk.test.user@commercetools.com"
let password = "password"

authManager.loginUser(username, password: password, completionHandler: { error in
    if let error = error {
        // Handle error, and possibly get some more information from error.userInfo[NSLocalizedFailureReasonErrorKey]
    }
})
```

Similarly, after logging out, all further interactions continue to use new anonymous user token.

```swift
AuthManager.sharedInstance.logoutUser()
```

Access and refresh tokens are being preserved across app launches by the `AuthManager`. In order to inspect whether it's currently handling authenticated or anonymous user, `state` property should be used:

```swift
if authManager.state == .PlainToken {
    // Present login form or other logic
}
```

## Consuming Commercetools Endpoints

Consuming and managing resources provided through available endpoints is very easy for any of the available endpoint classes.

Depending on the capabilities of the resource, you can retrieve by specific UUID, use more detailed query options, and also perform create or update operations.

All of these functionalities are provided by static methods for any specific supported endpoint. For an example, you can creating shopping cart using provided `Cart` class:
```swift
let createDraft = ["currency": "EUR"]

Cart.create(createDraft, result: { result in
	if let response = result.response where result.isSuccess {
		// Do any work with response dictionary containing created `Cart` resource, i.e:
		if let cartState = response["cartState"] as? String where cartState == "Active" {
			// Our cart is active!
		}
	}
})
```

In case you need resources from an endpoint which hasn't been implemented in our SDK yet, you can easily create class representing that endpoint, and conform to appropriate protocols which take care of abstract endpoint implementations for many common use cases.

The following list represents currently supported abstract endpoints. For each protocol, there is a default extension provided, which will almost always cover your needs:

* Create endpoint - `create(object: [String: AnyObject], expansion: [String]?, result: (Result<[String: AnyObject], NSError>) -> Void)`
* Update endpoint - `update(id: String, version: UInt, actions: [[String: AnyObject]], expansion: [String]?, result: (Result<[String: AnyObject], NSError>) -> Void)`
* Update by key endpoint - `updateByKey(key: String, version: UInt, actions: [[String: AnyObject]], expansion: [String]?, result: (Result<[String: AnyObject], NSError>) -> Void)`
* Query endpoint - `query(predicates predicates: [String]?, sort: [String]?, expansion: [String]?, limit: UInt?, offset: UInt?, result: (Result<[String: AnyObject], NSError>) -> Void)`
* Retrieve resource by ID endpoint - `byId(id: String, expansion: [String]?, result: (Result<[String: AnyObject], NSError>) -> Void)`
* Retrieve resource by key endpoint - `byKey(key: String, expansion: [String]?, result: (Result<[String: AnyObject], NSError>) -> Void)`
* Delete endpoint - `delete(id: String, version: UInt, expansion: [String]?, result: (Result<[String: AnyObject], NSError>) -> Void)`

### Currently Supported Endpoints

#### Customer

Customer endpoint offers you several possible actions to use from your iOS app:
- Retrieve user profile (user must be logged in)
```swift
Customer.profile { result in
    if let response = result.response, firstName = response["firstName"] as? String,
            lastName = response["lastName"] as? String where result.isSuccess {
        // E.g present user profile details
    }
}
```
- Sign up for a new account (anonymous user is being handled by `AuthManager`)
```swift
let username = "new.swift.sdk.test.user@commercetools.com"
let signupDraft = ["email": username, "password": "password"]

Customer.signup(signupDraft, result: { result in
    if let response = result.response, customer = response["customer"] as? [String: AnyObject],
    		version = customer["version"] as? UInt where result.isSuccess {
        // User has been successfully signed up.
        // Now, you'd probably want to present the login form, or simply
        // use AuthManager to login user automatically
    }
})
```
- Update customer account (user must be logged in)
```swift
var setFirstNameAction: [String: AnyObject] = ["action": "setFirstName", "firstName": "newName"]

Customer.update(version: version, actions: [setFirstNameAction], result: { result in
    if let response = result.response, version = response["version"] as? UInt where result.isSuccess {
    	// User profile successfully updated
    }
})
```
- Delete customer account (user must be logged in)
```swift
var setFirstNameAction: [String: AnyObject] = ["action": "setFirstName", "firstName": "newName"]

Customer.delete(version: version, result: { result in
    if let response = result.response where result.isSuccess {
        // Customer was successfully deleted
    }
})
```
- Change password (user must be logged in)
```swift
let  version = 1 // Set the appropriate current version

Customer.changePassword(currentPassword: "password", newPassword: "newPassword", version: version, result: { result in
    if let response = result.response where result.isSuccess {
    	// Password has been changed, and now AuthManager has automatically obtained new access token
    }
})
```
- Reset password with token (anonymous user is being handled by `AuthManager`)
```swift
let token = "" // Usually this token is retrieved from the password reset link, in case your app does support universal links

Customer.resetPassword(token: token, newPassword: "password", result: { result in
    if let response = result.response, email = response["email"] as? String where result.isSuccess {
        // Password has been successfully reset, now would be a good time to present the login screen
    }
})
```
- Verify email with token (user must be logged in)
```swift
let token = "" // Usually this token is retrieved from the activation link, in case your app does support universal links

Customer.verifyEmail(token: token, result: { result in
    if let response = result.response, email = response["email"] as? String where result.isSuccess {
        // Email has been successfully verified, probably show UIAlertController with this info
    }
})
```

## Handling Results

In order to check whether any action with Commercetools services was successfully executed, you should use `isSuccess` or `isFailure` property of the result in question. For all successful operations, `response` property contains values returned from the server.

For all failed operations, `errors` property should be used from the result in question to present or handle specific issues. `NSError` instances with domain equal to `com.commercetools.error` usually contain descriptive information about the error, returned by the API. Those can be found by `NSLocalizedFailureReasonErrorKey` for general issue cause, and by `NSLocalizedDescriptionKey` for more detailed description, where applicable.

[](definitions for the top badges)

[travis]:https://travis-ci.org/sphereio/commercetools-ios-sdk
[travis img]:https://travis-ci.org/sphereio/commercetools-ios-sdk.svg?branch=master

[cocoapods]:https://cocoapods.org/pods/Commercetools
[cocoapods img]:https://img.shields.io/cocoapods/v/Commercetools.svg

[license]:LICENSE
[license img]:https://img.shields.io/badge/License-Apache%202-blue.svg