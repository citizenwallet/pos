import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:web3dart/crypto.dart';

import 'package:web3dart/web3dart.dart';

class AccountContract {
  final int chainId;
  final Web3Client client;
  final String addr;
  late DeployedContract rcontract;
  late DeployedContract mcontract;

  AccountContract(this.chainId, this.client, this.addr);

  Future<void> init() async {
    String rawAbi = await rootBundle.loadString(
        'packages/smartcontracts/contracts/accounts/Account.abi.json');

    final cabi = ContractAbi.fromJson(rawAbi, 'Account');

    rcontract = DeployedContract(cabi, EthereumAddress.fromHex(addr));

    rawAbi = await rootBundle.loadString('assets/contracts/ModuleManager.json');

    final mabi = ContractAbi.fromJson(rawAbi, 'ModuleManager');

    mcontract = DeployedContract(mabi, EthereumAddress.fromHex(addr));
  }

  Uint8List executeCallData(String dest, BigInt amount, Uint8List calldata) {
    final function = rcontract.function('execute');

    return function
        .encodeCall([EthereumAddress.fromHex(dest), amount, calldata]);
  }

  Uint8List executeBatchCallData(
    List<String> dest,
    List<Uint8List> calldata,
  ) {
    final function = rcontract.function('executeBatch');

    return function.encodeCall([
      dest.map((d) => EthereumAddress.fromHex(d)).toList(),
      calldata,
    ]);
  }

  // SAFE
  Uint8List execTransactionFromModuleCallData(
    String dest,
    BigInt amount,
    Uint8List calldata,
  ) {
    final function = mcontract.function('execTransactionFromModule');

    return function.encodeCall([
      EthereumAddress.fromHex(dest),
      amount,
      calldata,
      BigInt.zero,
    ]);
  }

  Uint8List transferOwnershipCallData(String newOwner) {
    final function = rcontract.function('transferOwnership');

    return function.encodeCall([EthereumAddress.fromHex(newOwner)]);
  }

  Uint8List upgradeToCallData(String implementation) {
    final function = rcontract.function('upgradeTo');

    return function.encodeCall([EthereumAddress.fromHex(implementation)]);
  }
}
