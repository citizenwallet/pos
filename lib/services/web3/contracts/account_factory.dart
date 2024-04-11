import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:smartcontracts/accounts.dart';

class AccountFactoryContract {
  final int chainId;
  final Web3Client client;
  final String addr;
  late AccountFactory contract;
  late DeployedContract rcontract;

  AccountFactoryContract(this.chainId, this.client, this.addr)
      : contract = AccountFactory(
          address: EthereumAddress.fromHex(addr),
          chainId: chainId,
          client: client,
        );

  Future<void> init() async {
    final rawAbi = await rootBundle.loadString(
        'packages/smartcontracts/contracts/accounts/AccountFactory.abi.json');

    final cabi = ContractAbi.fromJson(rawAbi, 'AccountFactory');

    rcontract = DeployedContract(cabi, EthereumAddress.fromHex(addr));
  }

  Future<EthereumAddress> getAddress(String owner) {
    print('owner: $owner');
    return contract.getAddress(EthereumAddress.fromHex(owner), BigInt.zero);
  }

  Future<Uint8List> createAccountInitCode(String owner, BigInt amount) async {
    final function = rcontract.function('createAccount');

    final callData =
        function.encodeCall([EthereumAddress.fromHex(owner), BigInt.from(0)]);

    return hexToBytes('$addr${bytesToHex(callData)}');
  }
}
