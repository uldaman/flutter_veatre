import 'dart:core';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_biopass/flutter_biopass.dart' show BioPass;
import 'package:veatre/src/models/dapp.dart';
import 'package:veatre/src/models/block.dart';
import 'package:veatre/src/storage/bookmarkStorage.dart';
import 'package:veatre/src/storage/configStorage.dart';
import 'package:veatre/src/utils/common.dart';

enum TabStage {
  Created,
  Coverred,
  SelectedAlive,
  SelectedInAlive,
  Removed,
  RemoveAll,
}

class TabControllerValue {
  int id;
  String tabKey;
  TabStage stage;
  Network network;
  String url;

  TabControllerValue({
    this.id,
    this.tabKey,
    this.stage,
    this.network,
    this.url,
  });
}

class TabController extends ValueNotifier<TabControllerValue> {
  TabController(TabControllerValue value) : super(value);
}

class AppearanceController extends ValueNotifier<Appearance> {
  AppearanceController(Appearance value) : super(value);
}

class NetworkController extends ValueNotifier<Network> {
  NetworkController(Network value) : super(value);
}

class BlockHeadController extends ValueNotifier<BlockHeadForNetwork> {
  BlockHeadController(BlockHeadForNetwork value) : super(value);
}

class BookmarkController extends ValueNotifier<Bookmark> {
  BookmarkController(Bookmark value) : super(value);
}

class BlockHeadForNetwork {
  Network network;
  BlockHead head;

  BlockHeadForNetwork({this.network, this.head});
}

class Globals {
  static final bioPass = BioPass();

  static Uint8List _masterPasscodes = Uint8List.fromList([]);

  static final Block mainNetGenesis = Block.fromJSON({
    "number": 0,
    "id": "0x00000000851caf3cfdb6e899cf5958bfb1ac3413d346d43539627e6be7ec1b4a",
    "size": 170,
    "parentID":
        "0xffffffff53616c757465202620526573706563742c20457468657265756d2100",
    "timestamp": 1530316800,
    "gasLimit": 10000000,
    "beneficiary": "0x0000000000000000000000000000000000000000",
    "gasUsed": 0,
    "totalScore": 0,
    "txsRoot":
        "0x45b0cfc220ceec5b7c1c62c4d4193d38e4eba48e8815729ce75f9c0ab0e4c1c0",
    "txsFeatures": 0,
    "stateRoot":
        "0x09bfdf9e24dd5cd5b63f3c1b5d58b97ff02ca0490214a021ed7d99b93867839c",
    "receiptsRoot":
        "0x45b0cfc220ceec5b7c1c62c4d4193d38e4eba48e8815729ce75f9c0ab0e4c1c0",
    "signer": "0x0000000000000000000000000000000000000000",
    "isTrunk": true,
    "transactions": []
  });

  static final Block testNetGenesis = Block.fromJSON({
    "number": 0,
    "id": "0x000000000b2bce3c70bc649a02749e8687721b09ed2e15997f466536b20bb127",
    "size": 170,
    "parentID":
        "0xffffffff00000000000000000000000000000000000000000000000000000000",
    "timestamp": 1530014400,
    "gasLimit": 10000000,
    "beneficiary": "0x0000000000000000000000000000000000000000",
    "gasUsed": 0,
    "totalScore": 0,
    "txsRoot":
        "0x45b0cfc220ceec5b7c1c62c4d4193d38e4eba48e8815729ce75f9c0ab0e4c1c0",
    "txsFeatures": 0,
    "stateRoot":
        "0x4ec3af0acbad1ae467ad569337d2fe8576fe303928d35b8cdd91de47e9ac84bb",
    "receiptsRoot":
        "0x45b0cfc220ceec5b7c1c62c4d4193d38e4eba48e8815729ce75f9c0ab0e4c1c0",
    "signer": "0x0000000000000000000000000000000000000000",
    "isTrunk": true,
    "transactions": []
  });

  static final initialURL = 'about:blank';

  static List<DApp> apps = [];

  static BlockHead _mainNetHead;
  static BlockHead _testNetHead;

  static String connexJS;

  static TabController _tabController = TabController(TabControllerValue());

  static AppearanceController _appearanceController =
      AppearanceController(Appearance.light);

  static NetworkController _networkController =
      NetworkController(Network.MainNet);

  static BlockHeadController _blockHeadController =
      BlockHeadController(BlockHeadForNetwork());

  static BookmarkController _bookmarkController =
      BookmarkController(Bookmark());

  static void addTabHandler(void Function() handler) {
    _tabController.addListener(handler);
  }

  static void updateTabValue(TabControllerValue tabControllerValue) {
    _tabController.value = tabControllerValue;
  }

  static void removeTabHandler(void Function() handler) {
    _tabController.removeListener(handler);
  }

  static TabControllerValue get tabValue => _tabController.value;

  static void addAppearanceHandler(void Function() handler) {
    _appearanceController.addListener(handler);
  }

  static void updateAppearance(Appearance appearance) {
    _appearanceController.value = appearance;
  }

  static void removeAppearanceHandler(void Function() handler) {
    _appearanceController.removeListener(handler);
  }

  static Appearance get appearance => _appearanceController.value;

  static void addBlockHeadHandler(void Function() handler) {
    _blockHeadController.addListener(handler);
  }

  static void updateBlockHead(BlockHeadForNetwork blockHeadForNetwork) {
    Globals.setHead(blockHeadForNetwork);
    _blockHeadController.value = blockHeadForNetwork;
  }

  static void removeBlockHeadHandler(void Function() handler) {
    _blockHeadController.removeListener(handler);
  }

  static BlockHeadForNetwork get blockHeadForNetwork =>
      _blockHeadController.value;

  static void addNetworkHandler(void Function() handler) {
    _networkController.addListener(handler);
  }

  static void updateNetwork(Network network) {
    _networkController.value = network;
  }

  static void removeNetworkHandler(void Function() handler) {
    _networkController.removeListener(handler);
  }

  static Network get network => _networkController.value;

  static Bookmark get bookmark => _bookmarkController.value;

  static void addBookmarkHandler(void Function() handler) {
    _bookmarkController.addListener(handler);
  }

  static void updateBookmark(Bookmark bookmark) {
    _bookmarkController.value = bookmark;
  }

  static void removeBookmarkHandler(void Function() handler) {
    _bookmarkController.removeListener(handler);
  }

  static Block genesis(Network network) {
    if (network == Network.MainNet) {
      return mainNetGenesis;
    }
    return testNetGenesis;
  }

  static BlockHead head({Network network}) {
    if (network == null) {
      network = Globals.network;
    }
    if (network == Network.MainNet) {
      return _mainNetHead;
    }
    return _testNetHead;
  }

  static void setHead(BlockHeadForNetwork blockHeadForNetwork) {
    if (blockHeadForNetwork.network == Network.MainNet) {
      _mainNetHead = blockHeadForNetwork.head;
    } else {
      _testNetHead = blockHeadForNetwork.head;
    }
  }

  static Timer periodic(
    int seconds,
    Future<void> Function(Timer timer) action,
  ) {
    return Timer.periodic(
      Duration(seconds: seconds),
      (timer) async {
        await action(timer);
      },
    );
  }

  static void updateMasterPasscodes(String passcodes) {
    _masterPasscodes = Uint8List.fromList(sha256(passcodes));
  }

  static void clearMasterPasscodes() {
    _masterPasscodes = Uint8List.fromList([]);
  }

  static Uint8List get masterPasscodes {
    return _masterPasscodes;
  }

  static void destroy() {
    _appearanceController.dispose();
    _blockHeadController.dispose();
    _tabController.dispose();
    _networkController.dispose();
  }
}
