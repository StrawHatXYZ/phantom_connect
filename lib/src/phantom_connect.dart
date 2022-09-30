import 'dart:convert';
import 'package:pinenacl/digests.dart';
import 'package:pinenacl/x25519.dart';
import 'package:solana/base58.dart';
import 'package:solana/solana.dart';

/// Phantom Connect is a package that allows users to connect to Phantom Wallet from Mobile apps.
///
/// - This package need deeplinking to work, so you need to add your own deeplink to your app.
/// - You can find more information about deeplinking from [here](https://docs.flutter.dev/development/ui/navigation/deep-linking)
class PhantomConnect {
  /// The scheme of the app that will be opened i.e Phantom.
  final String scheme = "https";

  /// The scheme of the app that will be opened i.e Phantom.
  final String host = "phantom.app";

  /// [_sessionToken] is string encoded in base58. This should be treated as opaque by the connecting app, as it only needs to be passed alongside other parameters.
  ///
  /// When a user connects to Phantom for the first time, Phantom will return a session param that represents the user's connection.
  /// The app should pass this session param back to Phantom on all subsequent Provider Methods.
  /// Sessions do not expire. Once a user has connected with Phantom, the corresponding app can indefinitely make requests such as `SignAndSendTransaction` and `SignMessage` without prompting the user to re-connect with Phantom.
  /// Apps will still need to re-connect to Phantom after a Disconnect event we can use [generateDisconnectUri] for that.
  String? _sessionToken;

  /// [dAppPublicKey] and [_dAppSecretKey] Keypair for encryption and decryption
  ///
  /// Unique for each session and destroyed after the session is over.
  late PrivateKey _dAppSecretKey;
  late PublicKey dAppPublicKey;

  /// [appUrl] is used to fetch app metadata (i.e. title, icon) using the
  /// same properties found in Displaying Your App.
  String appUrl;

  /// [userPublicKey] once session is established with Phantom Wallet (i.e. user has approved the connection) we get user's Publickey.
  late String userPublicKey;

  /// [deepLink] uri is used to open the app from Phantom Wallet i.e our app's deeplink.
  String deepLink;

  /// [_sharedSecret] is used to encrypt and decrypt the session token and other data.
  Box? _sharedSecret;

  /// We need to provide [appUrl] and [deepLink] as parameters to create new [PhantomConnect] object.
  ///
  /// - [appUrl] is used to fetch app metadata (i.e. title, icon) using the same properties found in Displaying Your App.
  /// - [deepLink] uri is used to open the app from Phantom Wallet i.e our app's deeplink.
  /// - Also here we generate a new [dAppPublicKey] and [_dAppSecretKey] Keypair for encryption and decryption
  /// - These are unique for each session and destroyed after the session is over.
  /// - [dAppPublicKey] and [_dAppSecretKey] Keypair for encryption and decryption
  PhantomConnect({required this.appUrl, required this.deepLink}) {
    _dAppSecretKey = PrivateKey.generate();
    dAppPublicKey = _dAppSecretKey.publicKey;
  }

  /// Generate an URL to connect to Solana [cluster] with Phantom Wallet.
  ///
  /// - In order to start interacting with Phantom, an app must first establish a connection.
  /// - This connection request will prompt the user for permission to share their public key, indicating that they are willing to interact further.
  /// - It returns a url which will be used to send to Phantom Wallet `/connect` endpoint.
  /// - Once approved It redirects user to [redirect] with `phantom_encryption_public_key`, `nonce` and encrypted `data` as query parameters.
  /// - If the user denies the connection request, Phantom will redirect the user to [redirect] with `errorCode` and `errorMessage` as query parameter.
  /// - Refer to [Errors](https://docs.phantom.app/integrating/errors) for a full list of possible error codes.
  Uri generateConnectUri({required String cluster, required String redirect}) {
    return Uri(
      scheme: scheme,
      host: host,
      path: '/ul/v1/connect',
      queryParameters: {
        'dapp_encryption_public_key': base58encode(dAppPublicKey.asTypedList),
        'cluster': cluster,
        'app_url': appUrl,
        'redirect_link': "$deepLink$redirect",
      },
    );
  }

  /// Generate an URL with given [transaction] to signAndSend transaction with Phantom Wallet.
  ///
  /// - Returns URL which will be used to send to Phantom Wallet signAndSendTransaction endpoint.
  /// - Refer to [](https://github.com/cryptoplease/cryptoplease-dart/issues/291#issuecomment-1153153453) for creating compiled transaction without signing in flutter/dart.
  /// - Also it redirects user to [redirect] with `nonce` and encrypted `data` as query parameters.
  /// - Encrypted `data` contains `signature` and can be decrypted using [decryptPayload] method.
  Uri generateSignAndSendTransactionUri(
      {required String transaction, required String redirect}) {
    var payload = {
      "session": _sessionToken,
      "transaction": base58encode(
        Uint8List.fromList(
          base64.decode(transaction),
        ),
      ),
    };
    var encryptedPayload = encryptPayload(payload);

    return Uri(
      scheme: scheme,
      host: host,
      path: '/ul/v1/signAndSendTransaction',
      queryParameters: {
        "dapp_encryption_public_key": base58encode(dAppPublicKey.asTypedList),
        "nonce": base58encode(encryptedPayload["nonce"]),
        'redirect_link': "$deepLink$redirect",
        'payload': base58encode(encryptedPayload["encryptedPayload"])
      },
    );
  }

  /// Generate an URL to disconnect from Phantom Wallet and destroy the session.
  ///
  /// - Returns URL which will be used to send to Phantom Wallet `/disconnect` endpoint.
  /// - It redirects user to [redirect].
  /// - [_sessionToken] and [_sharedSecret] was destroyed after the session is over.
  /// - Once the session is destroyed, the app will need to re-connect to Phantom before making any further requests.
  Uri generateDisconnectUri({required String redirect}) {
    var payLoad = {
      "session": _sessionToken,
    };
    var encryptedPayload = encryptPayload(payLoad);

    Uri launchUri = Uri(
      scheme: scheme,
      host: host,
      path: '/ul/v1/disconnect',
      queryParameters: {
        "dapp_encryption_public_key": base58encode(dAppPublicKey.asTypedList),
        "nonce": base58encode(encryptedPayload["nonce"]),
        'redirect_link': "$deepLink$redirect",
        "payload": base58encode(encryptedPayload["encryptedPayload"]),
      },
    );
    _sharedSecret = null;
    return launchUri;
  }

  /// Generate an URL with given [transaction] to sign transaction with Phantom Wallet.
  ///
  /// - Returns URL which will be used to send to Phantom Wallet `/signTransaction` endpoint.
  /// - It redirects user to [redirect] with `nonce` and encrypted `data` as query parameters.
  /// - Encrypted `data` contains `signedTransaction` and `base58 encoded serialized transaction` that can be decrypted using [decryptPayload] method.
  Uri generateSignTransactionUri(
      {required String transaction, required String redirect}) {
    var payload = {
      "transaction": base58encode(
        Uint8List.fromList(
          base64.decode(transaction),
        ),
      ),
      "session": _sessionToken,
    };
    var encryptedPayload = encryptPayload(payload);

    return Uri(
      scheme: scheme,
      host: host,
      path: '/ul/v1/signTransaction',
      queryParameters: {
        "dapp_encryption_public_key": base58encode(dAppPublicKey.asTypedList),
        "nonce": base58encode(encryptedPayload["nonce"]),
        'redirect_link': "$deepLink$redirect",
        'payload': base58encode(encryptedPayload["encryptedPayload"])
      },
    );
  }

  /// Generate an URL with given [transactions] to sign all transaction with Phantom Wallet.
  ///
  /// - Returns URL which will be used to send to Phantom Wallet `/signAllTransactions` endpoint.
  /// - It redirects user to [redirect] with `nonce` and encrypted `data` as query parameters.
  /// - Encrypted `data` contains `signedTransaction` and `base58 encoded serialized transaction` that can be decrypted using [decryptPayload] method.
  Uri generateUriSignAllTransactions(
      {required List<String> transactions, required String redirect}) {
    var payload = {
      "transactions": transactions
          .map((e) => base58encode(
                Uint8List.fromList(
                  base64.decode(e),
                ),
              ))
          .toList(),
      "session": _sessionToken,
    };
    var encryptedPayload = encryptPayload(payload);

    return Uri(
      scheme: 'https',
      host: 'phantom.app',
      path: '/ul/v1/signAllTransactions',
      queryParameters: {
        "dapp_encryption_public_key": base58encode(dAppPublicKey.asTypedList),
        "nonce": base58encode(encryptedPayload["nonce"]),
        'redirect_link': "$deepLink$redirect",
        'payload': base58encode(encryptedPayload["encryptedPayload"])
      },
    );
  }

  /// Generates an URL with given [nonce] to be signed by Phantom Wallet to verify the ownership of the wallet.
  ///
  /// - [nonce] will be generated on server side and sent to Phantom Wallet.
  /// - [nonce] will be hashed before sent to Phantom Wallet.
  /// - Returns URL which will be used to send to Phantom Wallet /signMessage endpoint.
  /// - It redirects user to [redirect] with [nonce] and encrypted [data] as query parameters.
  /// - Encrypted [data] contains [signature] and can be decrypted using [decryptPayload] method.
  /// - We can use this signed message to verify the user with [isValidSignature] method.
  Uri generateSignMessageUri(
      {required Uint8List nonce, required String redirect}) {
    /// Hash the nonce so that it is not exposed to the user
    Uint8List hashedNonce = Hash.sha256(nonce);

    var message =
        "Sign this message for authenticating with your wallet. Nonce: ${base58encode(hashedNonce)}";
    var payload = {
      "session": _sessionToken,
      "message": base58encode(message.codeUnits.toUint8List()),
    };

    var encrypt = encryptPayload(payload);

    return Uri(
      scheme: scheme,
      host: host,
      path: 'ul/v1/signMessage',
      queryParameters: {
        "dapp_encryption_public_key":
            base58encode(Uint8List.fromList(dAppPublicKey)),
        "nonce": base58encode(encrypt["nonce"]),
        "redirect_link": "$deepLink$redirect",
        "payload": base58encode(encrypt["encryptedPayload"]),
      },
    );
  }

  /// Creates [_sharedSecret] using [_dAppSecretKey] and [phantom_encryption_public_key].
  ///
  /// Once [_sharedSecret] is created, it can be used to encrypt and decrypt data.
  /// Here we decrypt the [data] using [_sharedSecret] and [nonce] to get [_sessionToken] and [userPublicKey].
  /// Refer to (Encryption)[https://docs.phantom.app/integrating/deeplinks-ios-and-android/encryption] to learn how apps can decrypt data using a shared secret. Encrypted bytes are encoded in base58.
  bool createSession(Map<String, String> params) {
    try {
      createSharedSecret(Uint8List.fromList(
          base58decode(params["phantom_encryption_public_key"]!)));
      var dataDecrypted =
          decryptPayload(data: params["data"]!, nonce: params["nonce"]!);
      _sessionToken = dataDecrypted["session"];
      userPublicKey = dataDecrypted["public_key"];
    } catch (e) {
      return false;
    }
    return true;
  }

  /// Verifies the [signature] returned by Phantom Wallet.
  ///
  /// - We will verify the [signature] with [nonce] and [userPublicKey].
  Future<bool> isValidSignature(String signature, Uint8List nonce) async {
    Uint8List hashedNonce = Hash.sha256(nonce);
    var message =
        "Sign this message for authenticating with your wallet. Nonce: ${base58encode(hashedNonce)}";
    var messageBytes = message.codeUnits.toUint8List();
    var signatureBytes = base58decode(signature);
    bool verify = await verifySignature(
      message: messageBytes,
      signature: signatureBytes,
      publicKey: Ed25519HDPublicKey.fromBase58(userPublicKey),
    );
    nonce = Uint8List(0);
    return verify;
  }

  /// Created a shared secret between Phantom Wallet and our DApp using our [_dAppSecretKey] and [phantom_encryption_public_key].
  ///
  /// - `phantom_encryption_public_key` is the public key of Phantom Wallet.
  void createSharedSecret(Uint8List remotePubKey) async {
    _sharedSecret = Box(
      myPrivateKey: _dAppSecretKey,
      theirPublicKey: PublicKey(remotePubKey),
    );
  }

  /// Decrypts the [data] payload returned by Phantom Wallet
  ///
  /// - Using [nonce] we generated on server side and [_dAppSecretKey] we decrypt the encrypted data.
  /// - Returns the decrypted `payload` as a `Map<dynamic, dynamic>`.
  Map<dynamic, dynamic> decryptPayload({
    required String data,
    required String nonce,
  }) {
    if (_sharedSecret == null) {
      return <String, String>{};
    }

    final decryptedData = _sharedSecret?.decrypt(
      ByteList(base58decode(data)),
      nonce: Uint8List.fromList(base58decode(nonce)),
    );

    Map payload =
        const JsonDecoder().convert(String.fromCharCodes(decryptedData!));
    return payload;
  }

  /// Encrypts the data payload to be sent to Phantom Wallet.
  ///
  /// - Returns the encrypted `payload` and `nonce`.
  Map<String, dynamic> encryptPayload(Map<String, dynamic> data) {
    if (_sharedSecret == null) {
      return <String, String>{};
    }
    var nonce = PineNaClUtils.randombytes(24);
    var payload = jsonEncode(data).codeUnits;
    var encryptedPayload =
        _sharedSecret?.encrypt(payload.toUint8List(), nonce: nonce).cipherText;
    return {"encryptedPayload": encryptedPayload?.asTypedList, "nonce": nonce};
  }
}
