import 'package:hive/hive.dart';

class PlayerStatsModel extends HiveObject {
  // All fields with unique numbers 0-61 (62 fields total)
  final int id;
  final String? name;
  final String? firstName;
  final String? lastName;
  final int? age;
  final String? birthDate;
  final String? birthPlace;
  final String? birthCountry;
  final String? nationality;
  final String? height;
  final String? weight;
  final bool? injured;
  final String? photo;
  final int? teamId;
  final String? teamName;
  final String? teamLogo;
  final int? leagueId;
  final String? leagueName;
  final String? leagueCountry;
  final String? leagueLogo;
  final String? leagueFlag;
  final String? leagueSeason;
  final int? gamesAppearances;
  final int? gamesLineups;
  final int? gamesMinutes;
  final int? gamesNumber;
  final String? gamesPosition;
  final double? gamesRating;
  final bool? gamesCaptain;
  final int? substitutesIn;
  final int? substitutesOut;
  final int? substitutesBench;
  final int? shotsTotal;
  final int? shotsOn;
  final int? goalsTotal;
  final int? goalsConceded;
  final int? goalsAssists;
  final int? goalsSaves;
  final int? passesTotal;
  final int? passesKey;
  final int? passesAccuracy;
  final int? tacklesTotal;
  final int? tacklesBlocks;
  final int? tacklesInterceptions;
  final int? duelsTotal;
  final int? duelsWon;
  final int? dribblesAttempts;
  final int? dribblesSuccess;
  final int? dribblesPast;
  final int? foulsDrawn;
  final int? foulsCommitted;
  final int? cardsYellow;
  final int? cardsYellowRed;
  final int? cardsRed;
  final int? penaltyWon;
  final int? penaltyCommitted;
  final int? penaltyScored;
  final int? penaltyMissed;
  final int? penaltySaved;

  PlayerStatsModel({
    required this.id,
    this.name,
    this.firstName,
    this.lastName,
    this.age,
    this.birthDate,
    this.birthPlace,
    this.birthCountry,
    this.nationality,
    this.height,
    this.weight,
    this.injured,
    this.photo,
    this.teamId,
    this.teamName,
    this.teamLogo,
    this.leagueId,
    this.leagueName,
    this.leagueCountry,
    this.leagueLogo,
    this.leagueFlag,
    this.leagueSeason,
    this.gamesAppearances,
    this.gamesLineups,
    this.gamesMinutes,
    this.gamesNumber,
    this.gamesPosition,
    this.gamesRating,
    this.gamesCaptain,
    this.substitutesIn,
    this.substitutesOut,
    this.substitutesBench,
    this.shotsTotal,
    this.shotsOn,
    this.goalsTotal,
    this.goalsConceded,
    this.goalsAssists,
    this.goalsSaves,
    this.passesTotal,
    this.passesKey,
    this.passesAccuracy,
    this.tacklesTotal,
    this.tacklesBlocks,
    this.tacklesInterceptions,
    this.duelsTotal,
    this.duelsWon,
    this.dribblesAttempts,
    this.dribblesSuccess,
    this.dribblesPast,
    this.foulsDrawn,
    this.foulsCommitted,
    this.cardsYellow,
    this.cardsYellowRed,
    this.cardsRed,
    this.penaltyWon,
    this.penaltyCommitted,
    this.penaltyScored,
    this.penaltyMissed,
    this.penaltySaved,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'firstName': firstName,
        'lastName': lastName,
        'age': age,
        'birthDate': birthDate,
        'birthPlace': birthPlace,
        'birthCountry': birthCountry,
        'nationality': nationality,
        'height': height,
        'weight': weight,
        'injured': injured,
        'photo': photo,
        'teamId': teamId,
        'teamName': teamName,
        'teamLogo': teamLogo,
        'leagueId': leagueId,
        'leagueName': leagueName,
        'leagueCountry': leagueCountry,
        'leagueLogo': leagueLogo,
        'leagueFlag': leagueFlag,
        'leagueSeason': leagueSeason,
        'gamesAppearances': gamesAppearances,
        'gamesLineups': gamesLineups,
        'gamesMinutes': gamesMinutes,
        'gamesNumber': gamesNumber,
        'gamesPosition': gamesPosition,
        'gamesRating': gamesRating,
        'gamesCaptain': gamesCaptain,
        'substitutesIn': substitutesIn,
        'substitutesOut': substitutesOut,
        'substitutesBench': substitutesBench,
        'shotsTotal': shotsTotal,
        'shotsOn': shotsOn,
        'goalsTotal': goalsTotal,
        'goalsConceded': goalsConceded,
        'goalsAssists': goalsAssists,
        'goalsSaves': goalsSaves,
        'passesTotal': passesTotal,
        'passesKey': passesKey,
        'passesAccuracy': passesAccuracy,
        'tacklesTotal': tacklesTotal,
        'tacklesBlocks': tacklesBlocks,
        'tacklesInterceptions': tacklesInterceptions,
        'duelsTotal': duelsTotal,
        'duelsWon': duelsWon,
        'dribblesAttempts': dribblesAttempts,
        'dribblesSuccess': dribblesSuccess,
        'dribblesPast': dribblesPast,
        'foulsDrawn': foulsDrawn,
        'foulsCommitted': foulsCommitted,
        'cardsYellow': cardsYellow,
        'cardsYellowRed': cardsYellowRed,
        'cardsRed': cardsRed,
        'penaltyWon': penaltyWon,
        'penaltyCommitted': penaltyCommitted,
        'penaltyScored': penaltyScored,
        'penaltyMissed': penaltyMissed,
        'penaltySaved': penaltySaved,
      };

  factory PlayerStatsModel.fromJson(Map<String, dynamic> json) => PlayerStatsModel(
        id: json['id'] as int,
        name: json['name'] as String?,
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        age: json['age'] as int?,
        birthDate: json['birthDate'] as String?,
        birthPlace: json['birthPlace'] as String?,
        birthCountry: json['birthCountry'] as String?,
        nationality: json['nationality'] as String?,
        height: json['height'] as String?,
        weight: json['weight'] as String?,
        injured: json['injured'] as bool?,
        photo: json['photo'] as String?,
        teamId: json['teamId'] as int?,
        teamName: json['teamName'] as String?,
        teamLogo: json['teamLogo'] as String?,
        leagueId: json['leagueId'] as int?,
        leagueName: json['leagueName'] as String?,
        leagueCountry: json['leagueCountry'] as String?,
        leagueLogo: json['leagueLogo'] as String?,
        leagueFlag: json['leagueFlag'] as String?,
        leagueSeason: json['leagueSeason'] as String?,
        gamesAppearances: json['gamesAppearances'] as int?,
        gamesLineups: json['gamesLineups'] as int?,
        gamesMinutes: json['gamesMinutes'] as int?,
        gamesNumber: json['gamesNumber'] as int?,
        gamesPosition: json['gamesPosition'] as String?,
        gamesRating: json['gamesRating'] as double?,
        gamesCaptain: json['gamesCaptain'] as bool?,
        substitutesIn: json['substitutesIn'] as int?,
        substitutesOut: json['substitutesOut'] as int?,
        substitutesBench: json['substitutesBench'] as int?,
        shotsTotal: json['shotsTotal'] as int?,
        shotsOn: json['shotsOn'] as int?,
        goalsTotal: json['goalsTotal'] as int?,
        goalsConceded: json['goalsConceded'] as int?,
        goalsAssists: json['goalsAssists'] as int?,
        goalsSaves: json['goalsSaves'] as int?,
        passesTotal: json['passesTotal'] as int?,
        passesKey: json['passesKey'] as int?,
        passesAccuracy: json['passesAccuracy'] as int?,
        tacklesTotal: json['tacklesTotal'] as int?,
        tacklesBlocks: json['tacklesBlocks'] as int?,
        tacklesInterceptions: json['tacklesInterceptions'] as int?,
        duelsTotal: json['duelsTotal'] as int?,
        duelsWon: json['duelsWon'] as int?,
        dribblesAttempts: json['dribblesAttempts'] as int?,
        dribblesSuccess: json['dribblesSuccess'] as int?,
        dribblesPast: json['dribblesPast'] as int?,
        foulsDrawn: json['foulsDrawn'] as int?,
        foulsCommitted: json['foulsCommitted'] as int?,
        cardsYellow: json['cardsYellow'] as int?,
        cardsYellowRed: json['cardsYellowRed'] as int?,
        cardsRed: json['cardsRed'] as int?,
        penaltyWon: json['penaltyWon'] as int?,
        penaltyCommitted: json['penaltyCommitted'] as int?,
        penaltyScored: json['penaltyScored'] as int?,
        penaltyMissed: json['penaltyMissed'] as int?,
        penaltySaved: json['penaltySaved'] as int?,
      );
}

// Use Hive's built-in serialization via HydratedStorage or Box storage
// The fromJson factory method is used for JSON deserialization
// Hive automatic serialization is enabled via @HiveField annotations or build_runner
// For manual TypeAdapter, ensure Hive.registerAdapter() is called before opening boxes

class PlayerStatsAdapter extends TypeAdapter<PlayerStatsModel> {
  @override
  final int typeId = 1;

  @override
  PlayerStatsModel read(BinaryReader reader) {
    return PlayerStatsModel(
      id: reader.readInt(),
      name: reader.readString(),
      firstName: reader.readString(),
      lastName: reader.readString(),
      age: reader.readInt(),
      birthDate: reader.readString(),
      birthPlace: reader.readString(),
      birthCountry: reader.readString(),
      nationality: reader.readString(),
      height: reader.readString(),
      weight: reader.readString(),
      injured: reader.readBool(),
      photo: reader.readString(),
      teamId: reader.readInt(),
      teamName: reader.readString(),
      teamLogo: reader.readString(),
      leagueId: reader.readInt(),
      leagueName: reader.readString(),
      leagueCountry: reader.readString(),
      leagueLogo: reader.readString(),
      leagueFlag: reader.readString(),
      leagueSeason: reader.readString(),
      gamesAppearances: reader.readInt(),
      gamesLineups: reader.readInt(),
      gamesMinutes: reader.readInt(),
      gamesNumber: reader.readInt(),
      gamesPosition: reader.readString(),
      gamesRating: reader.readDouble(),
      gamesCaptain: reader.readBool(),
      substitutesIn: reader.readInt(),
      substitutesOut: reader.readInt(),
      substitutesBench: reader.readInt(),
      shotsTotal: reader.readInt(),
      shotsOn: reader.readInt(),
      goalsTotal: reader.readInt(),
      goalsConceded: reader.readInt(),
      goalsAssists: reader.readInt(),
      goalsSaves: reader.readInt(),
      passesTotal: reader.readInt(),
      passesKey: reader.readInt(),
      passesAccuracy: reader.readInt(),
      tacklesTotal: reader.readInt(),
      tacklesBlocks: reader.readInt(),
      tacklesInterceptions: reader.readInt(),
      duelsTotal: reader.readInt(),
      duelsWon: reader.readInt(),
      dribblesAttempts: reader.readInt(),
      dribblesSuccess: reader.readInt(),
      dribblesPast: reader.readInt(),
      foulsDrawn: reader.readInt(),
      foulsCommitted: reader.readInt(),
      cardsYellow: reader.readInt(),
      cardsYellowRed: reader.readInt(),
      cardsRed: reader.readInt(),
      penaltyWon: reader.readInt(),
      penaltyCommitted: reader.readInt(),
      penaltyScored: reader.readInt(),
      penaltyMissed: reader.readInt(),
      penaltySaved: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, PlayerStatsModel obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.name ?? '');
    writer.writeString(obj.firstName ?? '');
    writer.writeString(obj.lastName ?? '');
    writer.writeInt(obj.age ?? 0);
    writer.writeString(obj.birthDate ?? '');
    writer.writeString(obj.birthPlace ?? '');
    writer.writeString(obj.birthCountry ?? '');
    writer.writeString(obj.nationality ?? '');
    writer.writeString(obj.height ?? '');
    writer.writeString(obj.weight ?? '');
    writer.writeBool(obj.injured ?? false);
    writer.writeString(obj.photo ?? '');
    writer.writeInt(obj.teamId ?? 0);
    writer.writeString(obj.teamName ?? '');
    writer.writeString(obj.teamLogo ?? '');
    writer.writeInt(obj.leagueId ?? 0);
    writer.writeString(obj.leagueName ?? '');
    writer.writeString(obj.leagueCountry ?? '');
    writer.writeString(obj.leagueLogo ?? '');
    writer.writeString(obj.leagueFlag ?? '');
    writer.writeString(obj.leagueSeason ?? '');
    writer.writeInt(obj.gamesAppearances ?? 0);
    writer.writeInt(obj.gamesLineups ?? 0);
    writer.writeInt(obj.gamesMinutes ?? 0);
    writer.writeInt(obj.gamesNumber ?? 0);
    writer.writeString(obj.gamesPosition ?? '');
    writer.writeDouble(obj.gamesRating ?? 0.0);
    writer.writeBool(obj.gamesCaptain ?? false);
    writer.writeInt(obj.substitutesIn ?? 0);
    writer.writeInt(obj.substitutesOut ?? 0);
    writer.writeInt(obj.substitutesBench ?? 0);
    writer.writeInt(obj.shotsTotal ?? 0);
    writer.writeInt(obj.shotsOn ?? 0);
    writer.writeInt(obj.goalsTotal ?? 0);
    writer.writeInt(obj.goalsConceded ?? 0);
    writer.writeInt(obj.goalsAssists ?? 0);
    writer.writeInt(obj.goalsSaves ?? 0);
    writer.writeInt(obj.passesTotal ?? 0);
    writer.writeInt(obj.passesKey ?? 0);
    writer.writeInt(obj.passesAccuracy ?? 0);
    writer.writeInt(obj.tacklesTotal ?? 0);
    writer.writeInt(obj.tacklesBlocks ?? 0);
    writer.writeInt(obj.tacklesInterceptions ?? 0);
    writer.writeInt(obj.duelsTotal ?? 0);
    writer.writeInt(obj.duelsWon ?? 0);
    writer.writeInt(obj.dribblesAttempts ?? 0);
    writer.writeInt(obj.dribblesSuccess ?? 0);
    writer.writeInt(obj.dribblesPast ?? 0);
    writer.writeInt(obj.foulsDrawn ?? 0);
    writer.writeInt(obj.foulsCommitted ?? 0);
    writer.writeInt(obj.cardsYellow ?? 0);
    writer.writeInt(obj.cardsYellowRed ?? 0);
    writer.writeInt(obj.cardsRed ?? 0);
    writer.writeInt(obj.penaltyWon ?? 0);
    writer.writeInt(obj.penaltyCommitted ?? 0);
    writer.writeInt(obj.penaltyScored ?? 0);
    writer.writeInt(obj.penaltyMissed ?? 0);
    writer.writeInt(obj.penaltySaved ?? 0);
  }
}