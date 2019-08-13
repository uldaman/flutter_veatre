class Dapp {
  String name;
  String url;
  String logo;

  Dapp({
    this.name,
    this.url,
    this.logo,
  });

  factory Dapp.fromJSON(Map<String, dynamic> parsedJSON) {
    return Dapp(
      name: parsedJSON['name'],
      url: parsedJSON['href'],
      logo:
          "https://raw.githubusercontent.com/vechain/app-hub/master/apps/${parsedJSON['id']}/logo.png",
    );
  }
}
