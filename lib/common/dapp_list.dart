import 'package:cached_network_image/cached_network_image.dart';

final dapps = <Map>[
  {
    "title": "Apphub",
    "icon": CachedNetworkImage(
      imageUrl: "https://apps.vechain.org/img/icons/favicon-32x32.png",
    ),
    "url": "http://apps.vechain.org/",
  },
  {
    "title": "Tokens",
    "icon": CachedNetworkImage(
      imageUrl:
          "https://apps.vechain.org/img/com.laalaguer.token-transfer.3be1b8d3.png",
    ),
    "url": "https://laalaguer.github.io/vechain-token-transfer/",
  },
  {
    "title": "Vepool",
    "icon": CachedNetworkImage(
      imageUrl: "https://apps.vechain.org/img/come.vepool.vepool.a07e2818.png",
    ),
    "url": "https://vepool.xyz/",
  },
  {
    "title": "Insight",
    "icon": CachedNetworkImage(
      imageUrl: "https://apps.vechain.org/img/com.vechain.insight.5b9cf491.png",
    ),
    "url": "https://insight.vecha.in/#/",
  },
];
