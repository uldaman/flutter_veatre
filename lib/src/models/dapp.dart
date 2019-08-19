class DApp {
  String name;
  String url;
  String logo;

  DApp({
    this.name,
    this.url,
    this.logo,
  });

  factory DApp.fromJSON(Map<String, dynamic> parsedJSON) {
    return DApp(
      name: parsedJSON['name'],
      url: parsedJSON['href'],
      logo:
          "https://raw.githubusercontent.com/vechain/app-hub/master/apps/${parsedJSON['id']}/logo.png",
    );
  }
}
