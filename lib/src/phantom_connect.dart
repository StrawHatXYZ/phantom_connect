import 'dart:convert';
import 'package:pinenacl/x25519.dart';
import 'package:solana/base58.dart';
import 'package:solana/solana.dart';

class PhantomConnect {
  String urlApp = "domain";
  String scheme = "https";
  String host = "phantom.app";

  String? sessionToken;

  // App Keypair for encryption and decryption
  late PrivateKey dAppSecretKey;
  late PublicKey dAppPublicKey;

  // App Url
  String appUrl;

  // User's public key
  late String userPublicKey;

  // deeplink uri
  String deepLink;

  Box? sharedSecret;

  PhantomConnect({required this.appUrl, required this.deepLink}) {
    dAppSecretKey = PrivateKey.generate();
    dAppPublicKey = dAppSecretKey.publicKey;
  }

  Uri generateConnectUri({required String cluster}) {
    Uri url = Uri(
      scheme: 'https',
      host: 'phantom.app',
      path: '/ul/v1/connect',
      queryParameters: {
        'dapp_encryption_public_key': base58encode(dAppPublicKey.asTypedList),
        'cluster': cluster,
        'app_url': appUrl,
        'redirect_link': "$deepLink/connected",
      },
    );
    return url;
  }

  Uri generateSignAndSendTransactionUri({required String transaction}) {
    var payload = {
      "session": sessionToken,
      "transaction": base58encode(
        Uint8List.fromList(
          base64.decode(transaction),
        ),
      ),
    };
    var encryptedPayload = encryptPayload(payload);

    return Uri(
      scheme: 'https',
      host: 'phantom.app',
      path: '/ul/v1/signAndSendTransaction',
      queryParameters: {
        "dapp_encryption_public_key": base58encode(dAppPublicKey.asTypedList),
        "nonce": base58encode(encryptedPayload["nonce"]),
        'redirect_link': "$deepLink/signAndSendTransaction",
        'payload': base58encode(encryptedPayload["encryptedPayload"])
      },
    );
  }

  Uri generateDisconectUri() {
    var payLoad = {
      "session": sessionToken,
    };
    var encryptedPayload = encryptPayload(payLoad);

    Uri launchUri = Uri(
      scheme: 'https',
      host: 'phantom.app',
      path: '/ul/v1/disconnect',
      queryParameters: {
        "dapp_encryption_public_key": base58encode(dAppPublicKey.asTypedList),
        "nonce": base58encode(encryptedPayload["nonce"]),
        'redirect_link': "$deepLink/disconnect",
        "payload": base58encode(encryptedPayload["encryptedPayload"]),
      },
    );
    sharedSecret = null;
    return launchUri;
  }

  Uri generateSignTransactionUri({required String transaction}) {
    var payload = {
      "transaction": base58encode(
        Uint8List.fromList(
          base64.decode(transaction),
        ),
      ),
      "session": sessionToken,
    };
    var encryptedPayload = encryptPayload(payload);

    return Uri(
      scheme: 'https',
      host: 'phantom.app',
      path: '/ul/v1/signTransaction',
      queryParameters: {
        "dapp_encryption_public_key": base58encode(dAppPublicKey.asTypedList),
        "nonce": base58encode(encryptedPayload["nonce"]),
        'redirect_link': "$deepLink/signTransaction",
        'payload': base58encode(encryptedPayload["encryptedPayload"])
      },
    );
  }

  Uri generateSignMessageUri({required Uint8List nonce}) {
    var message =
        "Sign this message for authenticating with your wallet. Nonce: ${base58encode(nonce)}";
    var payload = {
      "session": sessionToken,
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
        "redirect_link": "$deepLink/onSignMessage",
        "payload": base58encode(encrypt["encryptedPayload"]),
      },
    );
  }

  bool createSession(Map<String, String> params) {
    try {
      createSharedSecret(Uint8List.fromList(
          base58decode(params["phantom_encryption_public_key"]!)));
      var dataDecrypted =
          decryptPayload(data: params["data"]!, nonce: params["nonce"]!);
      sessionToken = dataDecrypted["session"];
      userPublicKey = dataDecrypted["public_key"];
    } catch (e) {
      return false;
    }
    return true;
  }

  Future<bool> isValidSignature(String signature, Uint8List nonce) async {
    var message =
        "Sign this message for authenticating with your wallet. Nonce: ${base58encode(nonce)}";
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

  void createSharedSecret(Uint8List remotePubKey) async {
    sharedSecret = Box(
      myPrivateKey: dAppSecretKey,
      theirPublicKey: PublicKey(remotePubKey),
    );
  }

  Map<dynamic, dynamic> decryptPayload(
      {required String data, required String nonce}) {
    if (sharedSecret == null) {
      return <String, String>{};
    }

    final decryptedData = sharedSecret?.decrypt(
      ByteList(base58decode(data)),
      nonce: Uint8List.fromList(base58decode(nonce)),
    );

    Map payload =
        const JsonDecoder().convert(String.fromCharCodes(decryptedData!));
    return payload;
  }

  Map<String, dynamic> encryptPayload(Map<String, dynamic> data) {
    if (sharedSecret == null) {
      return <String, String>{};
    }
    var nonce = PineNaClUtils.randombytes(24);
    var payload = jsonEncode(data).codeUnits;
    var encryptedPayload =
        sharedSecret?.encrypt(payload.toUint8List(), nonce: nonce).cipherText;
    return {"encryptedPayload": encryptedPayload?.asTypedList, "nonce": nonce};
  }
}
