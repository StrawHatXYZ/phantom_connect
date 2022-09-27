# Phantom Connect

- Phantom Connect is a package that allows users to connect to Phantom Wallet from their Application.
- This package is used to generate deeplink urls for Phantom Wallet to connect to your application.
- This package was in active development.

## Features

This package has all these provider methods implemented for easy to use:

- [Connect](https://docs.phantom.app/integrating/deeplinks-ios-and-android/provider-methods/connect)
- [Disconnect](https://docs.phantom.app/integrating/deeplinks-ios-and-android/provider-methods/disconnect)
- [SignAndSendTransaction](https://docs.phantom.app/integrating/deeplinks-ios-and-android/provider-methods/signandsendtransaction)
- [SignAllTransactions](https://docs.phantom.app/integrating/deeplinks-ios-and-android/provider-methods/signalltransactions)
- [SignTransaction](https://docs.phantom.app/integrating/deeplinks-ios-and-android/provider-methods/signtransaction)
- [SignMessage](https://docs.phantom.app/integrating/deeplinks-ios-and-android/provider-methods/signmessage)

## Getting Started

We need to have deeplink for our application for handling returned data from phantom.

A few resources to get you started:

- [How to add deeplinks](https://docs.flutter.dev/development/ui/navigation/deep-linking)

## Usage

To use this plugin, add [`phantom_connect`](https://pub.dev/packages/phantom_connect) as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).

First and foremost, import the widget.

```dart
import 'package:phantom_connect/phantom_connect.dart';
```

Initialise the object with required Parameters.

- `appUrl` A url used to fetch app metadata i.e. title, icon.
- `deepLink` The URI where Phantom should redirect the user upon connection. Deep Link we used in our application.

```dart
  final PhantomConnect phantomConnect = PhantomConnect(
    appUrl: "https://solana.com", 
    deepLink: "dapp://exampledeeplink.io",
  );
```

## Example

- An example of how to use this package can be found [here](https://github.com/StrawHatXYZ/flutter-phantom-demo).
