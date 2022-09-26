# Phantom Connect

## Features

This package has all these provider methods implemented for easy to use:

* Connect
* Disconnect
* SignAndSendTransaction
* SignAllTransactions
* SignTransaction
* SignMessage

## Getting Started

We need to have deeplink for our application for handling returned data from phantom.

A few resources to get you started:

* [How to add deeplinks](https://docs.flutter.dev/development/ui/navigation/deep-linking)

## Usage

First and foremost, import the widget.

```dart
import 'package:phantom_connect/phantom_connect.dart';
```

Initialise the object with required Parameters.

* `appUrl` A url used to fetch app metadata i.e. title, icon.
* `deepLink` The URI where Phantom should redirect the user upon connection. Deep Link we used in our application.

```dart
  final PhantomConnect phantomConnect = PhantomConnect(
    appUrl: "https://solana.com", 
    deepLink: "samepl://exampledeeplink.io",
  );
```

## Example

* A full example application will be released soon.
