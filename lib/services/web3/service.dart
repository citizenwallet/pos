import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:scanner/services/api/api.dart';
import 'package:scanner/services/indexer/signed_request.dart';
import 'package:scanner/services/preferences/service.dart';
import 'package:scanner/services/web3/contracts/account.dart';
import 'package:scanner/services/web3/contracts/account_factory.dart';
import 'package:scanner/services/web3/contracts/card_manager.dart';
import 'package:scanner/services/web3/contracts/entrypoint.dart';
import 'package:scanner/services/web3/contracts/erc20.dart';
import 'package:scanner/services/web3/contracts/profile.dart';
import 'package:scanner/services/web3/gas.dart';
import 'package:scanner/services/web3/json_rpc.dart';
import 'package:scanner/services/web3/paymaster_data.dart';
import 'package:scanner/services/web3/transfer_data.dart';
import 'package:scanner/services/web3/userop.dart';
import 'package:scanner/services/web3/utils.dart';
import 'package:scanner/utils/delay.dart';
import 'package:scanner/utils/uint8.dart';
import 'package:web3dart/crypto.dart';

import 'package:web3dart/web3dart.dart';

class Web3Service {
  static final Web3Service _instance = Web3Service._internal();

  factory Web3Service() {
    return _instance;
  }

  Web3Service._internal() {
    _client = Client();
  }

  final PreferencesService _prefs = PreferencesService();

  BigInt? _chainId;

  final String _indexerKey = 'x';
  late String _tokenStandard;

  late Client _client;
  late String _url;
  late String _ipfsUrl;
  late Web3Client _ethClient;

  APIService? _rpc;
  APIService? _ipfs;
  APIService? _indexer;
  APIService? _indexerIPFS;
  APIService? _bundlerRPC;
  APIService? _paymasterRPC;

  EthereumAddress? _account;
  EthPrivateKey? _credentials;

  ERC20Contract? _contractToken;
  CardManagerContract? _cardManager;
  AccountFactoryContract? _accountFactory;
  TokenEntryPointContract? _entryPoint;
  AccountContract? _contractAccount;
  ProfileContract? _contractProfile;

  EIP1559GasPriceEstimator? _gasPriceEstimator;

  Future<void> init(
    String tokenStandard,
    String? rpcUrl,
    String? ipfsUrl,
    String? bundlerUrl,
    String? indexerUrl,
    String? indexerIPFSUrl,
    String? paymasterUrl,
    String? paymasterAddress,
    String? cardManagerAddress,
    String? accountFactoryAddress,
    String? entryPointAddress,
    String? tokenAddress,
    String? profileAddress,
    [String? invoiceUrl]
  ) async {
    _tokenStandard = tokenStandard;
    if (_tokenStandard == "erc20") {
      _url = rpcUrl!;
      _ethClient = Web3Client(_url, _client);
      _rpc = APIService(baseURL: _url);
      if (ipfsUrl != null) {
        _ipfsUrl = ipfsUrl;
        _ipfs = APIService(baseURL: ipfsUrl);        
      }
      _indexer = indexerUrl != null ? APIService(baseURL: indexerUrl) : null;
      _indexerIPFS = APIService(baseURL: indexerIPFSUrl!);
      _bundlerRPC = APIService(baseURL: '$bundlerUrl/$paymasterAddress');
      _paymasterRPC = APIService(baseURL: '$paymasterUrl/$paymasterAddress');

      _gasPriceEstimator = EIP1559GasPriceEstimator(
        _rpc!,
        _ethClient,
      );

      _chainId = await _ethClient.getChainId();

      if (_chainId == null) {
        throw Exception('Could not get chain id');
      }

      final key = _prefs.key;
      if (key == null) {
        final credentials = EthPrivateKey.createRandom(Random.secure());

        await _prefs.setKey(bytesToHex(credentials.privateKey));

        _credentials = credentials;
      } else {
        _credentials = EthPrivateKey.fromHex(key);
      }

      _contractToken = ERC20Contract(
        _chainId!.toInt(),
        _ethClient,
        tokenAddress!,
      );

      await _contractToken!.init();

      _cardManager = CardManagerContract(
        _chainId!.toInt(),
        _ethClient,
        cardManagerAddress!,
      );

      await _cardManager!.init();

      _accountFactory = AccountFactoryContract(
        _chainId!.toInt(),
        _ethClient,
        accountFactoryAddress!,
      );

      await _accountFactory!.init();

      _account = await _accountFactory!.getAddress(_credentials!.address.hexEip55);

      _entryPoint = TokenEntryPointContract(
        _chainId!.toInt(),
        _ethClient,
        entryPointAddress!,
      );

      await _entryPoint!.init();

      _contractAccount = AccountContract(
        _chainId!.toInt(),
        _ethClient,
        _account!.hexEip55,
      );

      await _contractAccount!.init();

      _contractProfile = ProfileContract(
        _chainId!.toInt(),
        _ethClient,
        profileAddress!,
      );

      await _contractProfile!.init();
    } else if (_tokenStandard == "eosio") {
      // TODO make API wrapper for invoiceUrl
    }
  }
  Future<Uint8List> getCardHash(String serial, {bool local = true}) async {
    return _cardManager!.getCardHash(serial, local: local);
  }

  Future<EthereumAddress> getCardAddress(Uint8List hash) async {
    return _cardManager!.getCardAddress(hash);
  }

  EthereumAddress get account => _account!;
  EthereumAddress get tokenAddress => _contractToken!.rcontract.address;
  EthereumAddress get entrypointAddress => _entryPoint!.rcontract.address;
  EthereumAddress get cardManagerAddress => _cardManager!.rcontract.address;
  String get profileAddress => _contractProfile!.addr;

  Future<BigInt> getNonce(String addr) async {
    return _entryPoint!.getNonce(addr);
  }

  /// check if an account exists
  Future<bool> accountExists({
    String? account,
  }) async {
    try {
      final url = '/accounts/${account ?? _account!.hexEip55}/exists';

      await _indexer!.get(
        url: url,
        headers: {
          'Authorization': 'Bearer $_indexerKey',
        },
      );

      return true;
    } catch (_) {}

    return false;
  }

  Future<BigInt> getBalance(String addr) async {
    return _contractToken!.getBalance(addr);
  }

  /// create an account
  Future<bool> createAccount({
    EthPrivateKey? customCredentials,
  }) async {
    try {
      final exists = await accountExists();
      if (exists) {
        return true;
      }

      final calldata = _contractAccount!.transferOwnershipCallData(
        _credentials!.address.hexEip55,
      );

      final (_, userop) = await prepareUserop(
        [_account!.hexEip55],
        [calldata],
      );

      final txHash = await submitUserop(
        userop,
      );
      if (txHash == null) {
        throw Exception('failed to submit user op');
      }

      final success = await waitForTxSuccess(txHash);
      if (!success) {
        throw Exception('transaction failed');
      }

      return true;
    } catch (_) {}

    return false;
  }

  /// set profile data
  Future<String?> setProfile(
    ProfileRequest profile, {
    required List<int> image,
    required String fileType,
  }) async {
    try {
      final url = '/profiles/v2/$profileAddress/${_account!.hexEip55}';

      final json = jsonEncode(
        profile.toJson(),
      );

      final body = SignedRequest(convertBytesToUint8List(utf8.encode(json)));

      final sig = await compute(
          generateSignature, (jsonEncode(body.toJson()), _credentials!));

      final resp = await _indexerIPFS!.filePut(
        url: url,
        file: image,
        fileType: fileType,
        headers: {
          'Authorization': 'Bearer $_indexerKey',
          'X-Signature': sig,
          'X-Address': _account!.hexEip55,
        },
        body: body.toJson(),
      );

      final String profileUrl = resp['object']['ipfs_url'];

      final calldata = _contractProfile!.setCallData(
          _account!.hexEip55, profile.username, profileUrl);

      final (_, userop) = await prepareUserop([profileAddress], [calldata]);

      final txHash = await submitUserop(userop);
      if (txHash == null) {
        throw Exception('profile update failed');
      }

      final success = await waitForTxSuccess(txHash);
      if (!success) {
        throw Exception('transaction failed');
      }

      return profileUrl;
    } catch (_) {}

    return null;
  }

  /// update profile data
  Future<String?> updateProfile(ProfileV1 profile) async {
    try {
      final url = '/profiles/v2/$profileAddress/${_account!.hexEip55}';

      final json = jsonEncode(
        profile.toJson(),
      );

      final body = SignedRequest(convertBytesToUint8List(utf8.encode(json)));

      final sig = await compute(
          generateSignature, (jsonEncode(body.toJson()), _credentials!));

      final resp = await _indexerIPFS!.patch(
        url: url,
        headers: {
          'Authorization': 'Bearer $_indexerKey',
          'X-Signature': sig,
          'X-Address': _account!.hexEip55,
        },
        body: body.toJson(),
      );

      final String profileUrl = resp['object']['ipfs_url'];

      final calldata = _contractProfile!.setCallData(
          _account!.hexEip55, profile.username, profileUrl);

      final (_, userop) = await prepareUserop([profileAddress], [calldata]);

      final txHash = await submitUserop(userop);
      if (txHash == null) {
        throw Exception('profile update failed');
      }

      final success = await waitForTxSuccess(txHash);
      if (!success) {
        throw Exception('transaction failed');
      }

      return profileUrl;
    } catch (_) {}

    return null;
  }

  /// set profile data
  Future<bool> unpinCurrentProfile() async {
    try {
      final url = '/profiles/v2/$profileAddress/${_account!.hexEip55}';

      final encoded = jsonEncode(
        {
          'account': _account!.hexEip55,
          'date': DateTime.now().toUtc().toIso8601String(),
        },
      );

      final body = SignedRequest(convertStringToUint8List(encoded));

      final sig = await compute(
          generateSignature, (jsonEncode(body.toJson()), _credentials!));

      await _indexerIPFS!.delete(
        url: url,
        headers: {
          'Authorization': 'Bearer $_indexerKey',
          'X-Signature': sig,
          'X-Address': _account!.hexEip55,
        },
        body: body.toJson(),
      );

      return true;
    } catch (_) {}

    return false;
  }

  /// get profile data
  Future<ProfileV1?> getProfile(String addr) async {
    try {
      final url = await _contractProfile!.getURL(addr);

      final profileData = await _ipfs!.get(url: '/$url');

      final profile = ProfileV1.fromJson(profileData);

      profile.parseIPFSImageURLs(_ipfsUrl);

      return profile;
    } catch (exception) {
      //
    }

    return null;
  }

  /// get profile data
  Future<ProfileV1?> getProfileFromUrl(String url) async {
    try {
      final profileData = await _ipfs!.get(url: '/$url');

      final profile = ProfileV1.fromJson(profileData);

      profile.parseIPFSImageURLs(_ipfsUrl);

      return profile;
    } catch (exception) {
      //
    }

    return null;
  }

  /// get profile data by username
  Future<ProfileV1?> getProfileByUsername(String username) async {
    try {
      final url = await _contractProfile!.getURLFromUsername(username);

      final profileData = await _ipfs!.get(url: '/$url');

      final profile = ProfileV1.fromJson(profileData);

      profile.parseIPFSImageURLs(_ipfsUrl);

      return profile;
    } catch (exception) {
      //
    }

    return null;
  }

  /// profileExists checks whether there is a profile for this username
  Future<bool> profileExists(String username) async {
    try {
      final url = await _contractProfile!.getURLFromUsername(username);

      return url != '';
    } catch (exception) {
      //
    }

    return false;
  }

  /// construct withdraw call data
  Uint8List erc20TransferCallData(
    String to,
    BigInt amount,
  ) {
    return _contractToken!.transferCallData(
      to,
      amount,
    );
  }

  /// construct withdraw call data
  Uint8List withdrawCallData(
    Uint8List hash,
    BigInt amount,
  ) {
    return _cardManager!.withdrawCallData(
      hash,
      _contractToken!.addr,
      _account!.hexEip55,
      amount,
    );
  }

  /// construct withdraw call data
  Uint8List createCardCallData(
    Uint8List cardHash,
  ) {
    return _cardManager!.createAccountCallData(cardHash);
  }

  /// given a tx hash, waits for the tx to be mined
  Future<bool> waitForTxSuccess(
    String txHash, {
    int retryCount = 0,
    int maxRetries = 20,
  }) async {
    if (retryCount >= maxRetries) {
      return false;
    }

    final receipt = await _ethClient.getTransactionReceipt(txHash);
    if (receipt?.status != true) {
      // there is either no receipt or the tx is still not confirmed

      // increment the retry count
      final nextRetryCount = retryCount + 1;

      // wait for a bit before retrying
      await delay(Duration(milliseconds: 250 * (nextRetryCount)));

      // retry
      return waitForTxSuccess(
        txHash,
        retryCount: nextRetryCount,
        maxRetries: maxRetries,
      );
    }

    return true;
  }

  /// makes a jsonrpc request from this wallet
  Future<SUJSONRPCResponse> _requestPaymaster(
    SUJSONRPCRequest body, {
    bool legacy = false,
  }) async {
    final rawResponse = await _paymasterRPC!.post(
      body: body,
    );

    final response = SUJSONRPCResponse.fromJson(rawResponse);

    if (response.error != null) {
      throw Exception(response.error!.message);
    }

    return response;
  }

  /// return paymaster data for constructing a user op
  Future<(PaymasterData?, Exception?)> _getPaymasterData(
    UserOp userop,
    String eaddr,
    String ptype, {
    bool legacy = false,
  }) async {
    final body = SUJSONRPCRequest(
      method: 'pm_sponsorUserOperation',
      params: [
        userop.toJson(),
        eaddr,
        {'type': ptype},
      ],
    );

    try {
      final response = await _requestPaymaster(body, legacy: legacy);

      return (PaymasterData.fromJson(response.result), null);
    } catch (exception, s) {
      final strerr = exception.toString();

      if (strerr.contains(gasFeeErrorMessage)) {
        return (null, NetworkCongestedException());
      }

      if (strerr.contains(invalidBalanceErrorMessage)) {
        return (null, NetworkInvalidBalanceException());
      }
    }

    return (null, NetworkUnknownException());
  }

  /// return paymaster data for constructing a user op
  Future<(List<PaymasterData>, Exception?)> _getPaymasterOOData(
    UserOp userop,
    String eaddr,
    String ptype, {
    bool legacy = false,
    int count = 1,
  }) async {
    final body = SUJSONRPCRequest(
      method: 'pm_ooSponsorUserOperation',
      params: [
        userop.toJson(),
        eaddr,
        {'type': ptype},
        count,
      ],
    );

    try {
      final response = await _requestPaymaster(body, legacy: legacy);

      final List<dynamic> data = response.result;
      if (data.isEmpty) {
        throw Exception('empty paymaster data');
      }

      if (data.length != count) {
        throw Exception('invalid paymaster data');
      }

      return (data.map((item) => PaymasterData.fromJson(item)).toList(), null);
    } catch (exception) {
      final strerr = exception.toString();

      if (strerr.contains(gasFeeErrorMessage)) {
        return (<PaymasterData>[], NetworkCongestedException());
      }

      if (strerr.contains(invalidBalanceErrorMessage)) {
        return (<PaymasterData>[], NetworkInvalidBalanceException());
      }
    }

    return (<PaymasterData>[], NetworkUnknownException());
  }

  /// prepare a userop for with calldata
  Future<(String, UserOp)> prepareUserop(
      List<String> dest, List<Uint8List> calldata) async {
    try {
      EthereumAddress acc =
          await _accountFactory!.getAddress(_credentials!.address.hexEip55);

      // instantiate user op with default values
      final userop = UserOp.defaultUserOp();

      // use the account hex as the sender
      userop.sender = acc.hexEip55;

      // determine the appropriate nonce
      userop.nonce = await _entryPoint!.getNonce(acc.hexEip55);

      // if it's the first user op from this account, we need to deploy the account contract
      if (userop.nonce == BigInt.zero) {
        // construct the init code to deploy the account
        userop.initCode = await _accountFactory!.createAccountInitCode(
          _credentials!.address.hexEip55,
          BigInt.zero,
        );
      }

      // set the appropriate call data for the transfer
      // we need to call account.execute which will call token.transfer
      userop.callData = dest.length > 1 && calldata.length > 1
          ? _contractAccount!.executeBatchCallData(
              dest,
              calldata,
            )
          : _contractAccount!.executeCallData(
              dest[0],
              BigInt.zero,
              calldata[0],
            );

      // set the appropriate gas fees based on network
      final fees = await _gasPriceEstimator!.estimate;
      if (fees == null) {
        throw Exception('unable to estimate fees');
      }

      userop.maxPriorityFeePerGas =
          fees.maxPriorityFeePerGas * BigInt.from(calldata.length);
      userop.maxFeePerGas = fees.maxFeePerGas * BigInt.from(calldata.length);

      // submit the user op to the paymaster in order to receive information to complete the user op
      List<PaymasterData> paymasterOOData = [];
      Exception? paymasterErr;
      final useAccountNonce = userop.nonce == BigInt.zero;
      if (useAccountNonce) {
        // if it's the first user op, we should use a normal paymaster signature
        PaymasterData? paymasterData;
        (paymasterData, paymasterErr) = await _getPaymasterData(
          userop,
          _entryPoint!.addr,
          'cw',
        );

        if (paymasterData != null) {
          paymasterOOData.add(paymasterData);
        }
      } else {
        // if it's not the first user op, we should use an out of order paymaster signature
        (paymasterOOData, paymasterErr) = await _getPaymasterOOData(
          userop,
          _entryPoint!.addr,
          'cw',
        );
      }

      if (paymasterErr != null) {
        throw paymasterErr;
      }

      if (paymasterOOData.isEmpty) {
        throw Exception('unable to get paymaster data');
      }

      final paymasterData = paymasterOOData.first;
      if (!useAccountNonce) {
        // use the nonce received from the paymaster
        userop.nonce = paymasterData.nonce;
      }

      // add the received data to the user op
      userop.paymasterAndData = paymasterData.paymasterAndData;
      userop.preVerificationGas = paymasterData.preVerificationGas;
      userop.verificationGasLimit = paymasterData.verificationGasLimit;
      userop.callGasLimit = paymasterData.callGasLimit;

      // get the hash of the user op
      final hash = await _entryPoint!.getUserOpHash(userop);

      // now we can sign the user op
      userop.generateSignature(_credentials!, hash);

      return (bytesToHex(hash, include0x: true), userop);
    } catch (_) {
      rethrow;
    }
  }

  /// makes a jsonrpc request from this wallet
  Future<SUJSONRPCResponse> _requestBundler(SUJSONRPCRequest body) async {
    final rawResponse = await _bundlerRPC!.post(
      body: body,
    );

    final response = SUJSONRPCResponse.fromJson(rawResponse);

    if (response.error != null) {
      throw Exception(response.error!.message);
    }

    return response;
  }

  /// Submits a user operation to the Ethereum network.
  ///
  /// This function sends a JSON-RPC request to the ERC4337 bundler. The entrypoint is specified by the
  /// [eaddr] parameter, with the [eth_sendUserOperation] method and the given
  /// [userop] parameter. If the request is successful, the function returns a
  /// tuple containing the transaction hash as a string and `null`. If the request
  /// fails, the function returns a tuple containing `null` and an exception
  /// object representing the type of error that occurred.
  ///
  /// If the request fails due to a network congestion error, the function returns
  /// a [NetworkCongestedException] object. If the request fails due to an invalid
  /// balance error, the function returns a [NetworkInvalidBalanceException]
  /// object. If the request fails for any other reason, the function returns a
  /// [NetworkUnknownException] object.
  ///
  /// [userop] The user operation to submit to the Ethereum network.
  /// [eaddr] The Ethereum address of the node to send the request to.
  /// A tuple containing the transaction hash as a string and [null] if
  ///         the request was successful, or [null] and an exception object if the
  ///         request failed.
  Future<(String?, Exception?)> _submitUserOp(
    UserOp userop,
    String eaddr, {
    TransferData? data,
  }) async {
    final params = [userop.toJson(), eaddr];
    if (data != null) {
      params.add(data.toJson());
    }

    final body = SUJSONRPCRequest(
      method: 'eth_sendUserOperation',
      params: params,
    );

    try {
      final response = await _requestBundler(body);

      return (response.result as String, null);
    } catch (exception) {
      final strerr = exception.toString();

      if (strerr.contains(gasFeeErrorMessage)) {
        return (null, NetworkCongestedException());
      }

      if (strerr.contains(invalidBalanceErrorMessage)) {
        return (null, NetworkInvalidBalanceException());
      }
    }

    return (null, NetworkUnknownException());
  }

  /// submit a user op
  Future<String?> submitUserop(
    UserOp userop, {
    EthPrivateKey? customCredentials,
    TransferData? data,
  }) async {
    try {
      // send the user op
      final (txHash, useropErr) = await _submitUserOp(
        userop,
        _entryPoint!.addr,
        data: data,
      );
      if (useropErr != null) {
        throw useropErr;
      }

      return txHash;
    } catch (_) {
      rethrow;
    }
  }

}
