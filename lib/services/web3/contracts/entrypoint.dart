import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:scanner/services/web3/userop.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class TokenEntryPointContract {
  final int chainId;
  final Web3Client client;
  final String addr;
  late DeployedContract rcontract;

  TokenEntryPointContract(this.chainId, this.client, this.addr);

  Future<void> init() async {
    final rawAbi = await rootBundle.loadString(
        'packages/smartcontracts/contracts/accounts/TokenEntryPoint.abi.json');

    final cabi = ContractAbi.fromJson(rawAbi, 'TokenEntryPoint');

    rcontract = DeployedContract(cabi, EthereumAddress.fromHex(addr));
  }

  Future<BigInt> getNonce(String addr) async {
    final function = rcontract.function('getNonce');

    final result = await client.call(
      contract: rcontract,
      function: function,
      params: [EthereumAddress.fromHex(addr), BigInt.from(0)],
    );

    return result[0] as BigInt;
  }

  Future<Uint8List> getUserOpHash(UserOp userop) async {
    final function = rcontract.function("getUserOpHash");

    final result = await client.call(
        contract: rcontract, function: function, params: [userop.toParams()]);

    return result[0];
  }
}
