import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../core/constants.dart';

// Match cache model for Hive local storage
class MatchCache extends Equatable {
  final String matchId;
  final String homeTeam;
  final String awayTeam;
  final int? homeGoals;
  final int? awayGoals;
  final double? homeXG;
  final double? awayXG;
  final double? homeXA;
  final double? awayXA;
  final int? homePPDA;
  final int? awayPPDA;
  final String? homeFieldTilt;
  final String? awayFieldTilt;
  final int minute;
  final String channel;
  final String commentator;
  final String country;
  final DateTime matchDate;

  const MatchCache({
    required this.matchId,
    required this.homeTeam,
    required this.awayTeam,
    this.homeGoals,
    this.awayGoals,
    this.homeXG,
    this.awayXG,
    this.homeXA,
    this.awayXA,
    this.homePPDA,
    this.awayPPDA,
    this.homeFieldTilt,
    this.awayFieldTilt,
    required this.minute,
    required this.channel,
    required this.commentator,
    required this.country,
    required this.matchDate,
  });

  @override
  List<Object?> get props => [
    matchId,
    homeTeam,
    awayTeam,
    homeGoals,
    awayGoals,
    homeXG,
    awayXG,
    homeXA,
    awayXA,
    homePPDA,
    awayPPDA,
    homeFieldTilt,
    awayFieldTilt,
    minute,
    channel,
    commentator,
    country,
    matchDate,
  ];

  MatchCache copyWith({
    String? matchId,
    String? homeTeam,
    String? awayTeam,
    int? homeGoals,
    int? awayGoals,
    double? homeXG,
    double? awayXG,
    double? homeXA,
    double? awayXA,
    int? homePPDA,
    int? awayPPDA,
    String? homeFieldTilt,
    String? awayFieldTilt,
    int? minute,
    String? channel,
    String? commentator,
    String? country,
    DateTime? matchDate,
  }) {
    return MatchCache(
      matchId: matchId ?? this.matchId,
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      homeGoals: homeGoals ?? this.homeGoals,
      awayGoals: awayGoals ?? this.awayGoals,
      homeXG: homeXG ?? this.homeXG,
      awayXG: awayXG ?? this.awayXG,
      homeXA: homeXA ?? this.homeXA,
      awayXA: awayXA ?? this.awayXA,
      homePPDA: homePPDA ?? this.homePPDA,
      awayPPDA: awayPPDA ?? this.awayPPDA,
      homeFieldTilt: homeFieldTilt ?? this.homeFieldTilt,
      awayFieldTilt: awayFieldTilt ?? this.awayFieldTilt,
      minute: minute ?? this.minute,
      channel: channel ?? this.channel,
      commentator: commentator ?? this.commentator,
      country: country ?? this.country,
      matchDate: matchDate ?? this.matchDate,
    );
  }

  factory MatchCache.fromMap(Map<String, dynamic> map) {
    return MatchCache(
      matchId: map['matchId'] as String? ?? '',
      homeTeam: map['homeTeam'] as String? ?? '',
      awayTeam: map['awayTeam'] as String? ?? '',
      homeGoals: map['homeGoals'] as int?,
      awayGoals: map['awayGoals'] as int?,
      homeXG: (map['homeXG'] as num?)?.toDouble(),
      awayXG: (map['awayXG'] as num?)?.toDouble(),
      homeXA: (map['homeXA'] as num?)?.toDouble(),
      awayXA: (map['awayXA'] as num?)?.toDouble(),
      homePPDA: map['homePPDA'] as int?,
      awayPPDA: map['awayPPDA'] as int?,
      homeFieldTilt: map['homeFieldTilt'] as String?,
      awayFieldTilt: map['awayFieldTilt'] as String?,
      minute: map['minute'] as int? ?? 0,
      channel: map['channel'] as String? ?? '',
      commentator: map['commentator'] as String? ?? '',
      country: map['country'] as String? ?? '',
      matchDate: map['matchDate'] as DateTime? ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'matchId': matchId,
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'homeGoals': homeGoals,
      'awayGoals': awayGoals,
      'homeXG': homeXG,
      'awayXG': awayXG,
      'homeXA': homeXA,
      'awayXA': awayXA,
      'homePPDA': homePPDA,
      'awayPPDA': awayPPDA,
      'homeFieldTilt': homeFieldTilt,
      'awayFieldTilt': awayFieldTilt,
      'minute': minute,
      'channel': channel,
      'commentator': commentator,
      'country': country,
      'matchDate': matchDate.toIso8601String(),
    };
  }
}

// BLoC state for matches management
abstract class MatchesState extends Equatable {
  final Status status;
  final List<MatchCache> matches;
  final String? selectedMatchId;
  final String? errorMessage;
  final bool hasReachedMax;

  const MatchesState({
    this.status = Status.initial,
    this.matches = const [],
    this.selectedMatchId,
    this.errorMessage,
    this.hasReachedMax = false,
  });

  @override
  List<Object?> get props => [
    status,
    ...?matches,
    selectedMatchId,
    errorMessage,
    hasReachedMax,
  ];
}

class MatchesInitial extends MatchesState {
  MatchesInitial();
}

class MatchesLoading extends MatchesState {
  MatchesLoading([List<String>? allowedCountries])
      : super(status: Status.loading);
}

class MatchesLoaded extends MatchesState {
  final List<MatchCache> matches;
  final bool hasReachedMax;

  MatchesLoaded({required this.matches, required this.hasReachedMax, String? selectedMatchId})
      : super(
    status: Status.loaded,
    matches: matches,
    selectedMatchId: selectedMatchId,
    hasReachedMax: hasReachedMax,
  );
}

class MatchesError extends MatchesState {
  final String error;

  MatchesError({required this.error, String? selectedMatchId})
      : super(status: Status.error, errorMessage: error, selectedMatchId: selectedMatchId);
}

enum Status { initial, loading, loaded, error }

// BLoC event for matches management
abstract class MatchesEvent extends Equatable {
  const MatchesEvent();

  @override
  List<Object?> get props => [];
}

class MatchesInitialLoad extends MatchesEvent {}

class MatchesLoadCountry extends MatchesEvent {
  final String country;
  MatchesLoadCountry({required this.country});
}

class MatchesAdd extends MatchesEvent {
  final List<MatchCache> matches;
  MatchesAdd({required this.matches});
}

class MatchesClear extends MatchesEvent {}

class MatchesToggleCountry extends MatchesEvent {}

class MatchesSetDetectedCountry extends MatchesEvent {
  final String country;
  MatchesSetDetectedCountry({required this.country});
}

class MatchesToggleFavorite extends MatchesEvent {
  final String matchId;
  MatchesToggleFavorite({required this.matchId});
}

class MatchesMatchSelected extends MatchesEvent {
  final String matchId;
  MatchesMatchSelected({required this.matchId});
}

class MatchesCompetitionFilterChanged extends MatchesEvent {
  final String competitionId;
  MatchesCompetitionFilterChanged({required this.competitionId});
}

class MatchesStatusFilterChanged extends MatchesEvent {
  final String status;
  MatchesStatusFilterChanged({required this.status});
}

class MatchesTimeFilterChanged extends MatchesEvent {
  final String time;
  MatchesTimeFilterChanged({required this.time});
}

class MatchesRefresh extends MatchesEvent {}

class MatchesLoadMore extends MatchesEvent {
  final String country;
  MatchesLoadMore({required this.country});
}

class MatchesReloadAfterGeoIP extends MatchesEvent {}