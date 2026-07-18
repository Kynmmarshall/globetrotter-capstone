class YaoundeSpot {
  const YaoundeSpot({
    required this.name,
    required this.description,
    required this.location,
    required this.imageAsset,
  });

  final String name;
  final String description;
  final String location;
  final String imageAsset;
}

const List<YaoundeSpot> yaoundeSpots = [
  YaoundeSpot(
    name: 'Monument de la Réunification',
    description:
        'A striking bronze monument commemorating the 1961 reunification of French and British Cameroon, set on a hilltop with sweeping views over the city.',
    location: 'Avenue du 27 Août, Yaoundé',
    imageAsset: 'assets/destinations/reunification_monument.png',
  ),
  YaoundeSpot(
    name: 'Palais des Congrès',
    description:
        "Yaoundé's landmark conference centre, topped by a spiral bronze sculpture, and the city's main venue for major national and international events.",
    location: 'Tsinga, Yaoundé',
    imageAsset: 'assets/destinations/palais_des_congres.png',
  ),
  YaoundeSpot(
    name: 'Basilique Marie-Reine-des-Apôtres',
    description:
        'A dramatic triangular basilica overlooking the city, known for its soaring stained-glass windows and grand staircase entrance.',
    location: 'Tsinga, Yaoundé',
    imageAsset: 'assets/destinations/basilica.png',
  ),
  YaoundeSpot(
    name: 'National Museum of Yaoundé',
    description:
        "Housed in a grand colonial-era palace, this museum traces Cameroon's history and cultures through art, artefacts and photography.",
    location: 'Place Ahmadou Ahidjo, Yaoundé',
    imageAsset: 'assets/destinations/national_museum.png',
  ),
];
