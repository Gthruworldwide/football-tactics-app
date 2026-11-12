import 'dart:developer' as dev;
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../core/constants.dart';

// Tactical cache model for Hive local storage
class TacticalCache extends Equatable {
  final String matchId;
  final double homeXG;
  final double awayXG;
  final double homeXA;
  final double awayXA;
  final int homePPDA;
  final int awayPPDA;
  final String homeFieldTilt;
  final String awayFieldTilt;
  final double homeFieldTiltPercentage;
  final double awayFieldTiltPercentage;
  final String momentum;
  final String homeCommentary;
  final String awayCommentary;
  final DateTime timestamp;

  const TacticalCache({
    required this.matchId,
    required this.homeXG,
    required this.awayXG,
    required this.homeXA,
    required this.awayXA,
    required this.homePPDA,
    required this.awayPPDA,
    required this.homeFieldTilt,
    required this.awayFieldTilt,
    required this.homeFieldTiltPercentage,
    required this.awayFieldTiltPercentage,
    required this.momentum,
    this.homeCommentary = '',
    this.awayCommentary = '',
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
    matchId,
    homeXG,
    awayXG,
    homeXA,
    awayXA,
    homePPDA,
    awayPPDA,
    homeFieldTilt,
    awayFieldTilt,
    homeFieldTiltPercentage,
    awayFieldTiltPercentage,
    momentum,
    homeCommentary,
    awayCommentary,
    timestamp,
  ];

  TacticalCache copyWith({
    String? matchId,
    double? homeXG,
    double? awayXG,
    double? homeXA,
    double? awayXA,
    int? homePPDA,
    int? awayPPDA,
    String? homeFieldTilt,
    String? awayFieldTilt,
    double? homeFieldTiltPercentage,
    double? awayFieldTiltPercentage,
    String? momentum,
    String? homeCommentary,
    String? awayCommentary,
    DateTime? timestamp,
  }) {
    return TacticalCache(
      matchId: matchId ?? this.matchId,
      homeXG: homeXG ?? this.homeXG,
      awayXG: awayXG ?? this.awayXG,
      homeXA: homeXA ?? this.homeXA,
      awayXA: awayXA ?? this.awayXA,
      homePPDA: homePPDA ?? this.homePPDA,
      awayPPDA: awayPPDA ?? this.awayPPDA,
      homeFieldTilt: homeFieldTilt ?? this.homeFieldTilt,
      awayFieldTilt: awayFieldTilt ?? this.awayFieldTilt,
      homeFieldTiltPercentage: homeFieldTiltPercentage ?? this.homeFieldTiltPercentage,
      awayFieldTiltPercentage: awayFieldTiltPercentage ?? this.awayFieldTiltPercentage,
      momentum: momentum ?? this.momentum,
      homeCommentary: homeCommentary ?? this.homeCommentary,
      awayCommentary: awayCommentary ?? this.awayCommentary,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory TacticalCache.fromMap(Map<String, dynamic> map) {
    return TacticalCache(
      matchId: map['matchId'] as String? ?? '',
      homeXG: (map['homeXG'] as num?)?.toDouble() ?? 0.0,
      awayXG: (map['awayXG'] as num?)?.toDouble() ?? 0.0,
      homeXA: (map['homeXA'] as num?)?.toDouble() ?? 0.0,
      awayXA: (map['awayXA'] as num?)?.toDouble() ?? 0.0,
      homePPDA: map['homePPDA'] as int? ?? 0,
      awayPPDA: map['awayPPDA'] as int? ?? 0,
      homeFieldTilt: map['homeFieldTilt'] as String? ?? '0%',
      awayFieldTilt: map['awayFieldTilt'] as String? ?? '0%',
      homeFieldTiltPercentage: (map['homeFieldTiltPercentage'] as num?)?.toDouble() ?? 0.0,
      awayFieldTiltPercentage: (map['awayFieldTiltPercentage'] as num?)?.toDouble() ?? 0.0,
      momentum: map['momentum'] as String? ?? 'Balanced',
      homeCommentary: map['homeCommentary'] as String? ?? '',
      awayCommentary: map['awayCommentary'] as String? ?? '',
      timestamp: map['timestamp'] as DateTime? ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'matchId': matchId,
      'homeXG': homeXG,
      'awayXG': awayXG,
      'homeXA': homeXA,
      'awayXA': awayXA,
      'homePPDA': homePPDA,
      'awayPPDA': awayPPDA,
      'homeFieldTilt': homeFieldTilt,
      'awayFieldTilt': awayFieldTilt,
      'homeFieldTiltPercentage': homeFieldTiltPercentage,
      'awayFieldTiltPercentage': awayFieldTiltPercentage,
      'momentum': momentum,
      'homeCommentary': homeCommentary,
      'awayCommentary': awayCommentary,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

// BLoC state for tactical analytics
abstract class TacticalState extends Equatable {
  final TacticalCache? tacticalCache;
  final Status status;
  final String? errorMessage;
  final String? selectedMatchId;

  const TacticalState({
    this.tacticalCache,
    this.status = Status.initial,
    this.errorMessage,
    this.selectedMatchId,
  });

  @override
  List<Object?> get props => [
    tacticalCache,
    status,
    errorMessage,
    selectedMatchId,
  ];
}

class TacticalInitial extends TacticalState {
  TacticalInitial() : super();
}

class TacticalLoading extends TacticalState {
  TacticalLoading() : super(status: Status.loading);
}

class TacticalLoaded extends TacticalState {
  final TacticalCache tacticalCache;

  TacticalLoaded({required this.tacticalCache}) : super(tacticalCache: tacticalCache);
}

class TacticalError extends TacticalState {
  final String error;

  TacticalError({required this.error, String? selectedMatchId})
      : super(errorMessage: error, selectedMatchId: selectedMatchId);
}

enum Status { initial, loading, loaded, error }

// BLoC event for tactical analytics
abstract class TacticalEvent extends Equatable {
  const TacticalEvent();

  @override
  List<Object?> get props => [];
}

class RefreshTacticalData extends TacticalEvent {
  final String matchId;
  RefreshTacticalData({required this.matchId});
}

class MatchSelected extends TacticalEvent {
  final String matchId;
  final double homeXG;
  final double awayXG;
  final double homeXA;
  final double awayXA;
  final int homePPDA;
  final int awayPPDA;
  final String homeFieldTilt;
  final String awayFieldTilt;
  final String momentum;

  MatchSelected({
    required this.matchId,
    required this.homeXG,
    required this.awayXG,
    required this.homeXA,
    required this.awayXA,
    required this.homePPDA,
    required this.awayPPDA,
    required this.homeFieldTilt,
    required this.awayFieldTilt,
    required this.momentum,
  });
}

class GenerateAISummary extends TacticalEvent {
  final String matchId;
  GenerateAISummary({required this.matchId});
}

class PPDAUpdate extends TacticalEvent {
  final String matchId;
  final int homePPDA;
  final int awayPPDA;

  PPDAUpdate({required this.matchId, required this.homePPDA, required this.awayPPDA});
}

class FieldTiltUpdate extends TacticalEvent {
  final String matchId;
  final String homeFieldTilt;
  final String awayFieldTilt;

  FieldTiltUpdate({required this.matchId, required this.homeFieldTilt, required this.awayFieldTilt});
}

class MomentumUpdate extends TacticalEvent {
  final String matchId;
  final String momentum;

  MomentumUpdate({required this.matchId, required this.momentum});
}

class CommentaryUpdate extends TacticalEvent {
  final String matchId;
  final String? homeCommentary;
  final String? awayCommentary;

  CommentaryUpdate({
    required this.matchId,
    this.homeCommentary,
    this.awayCommentary,
  });
}

class TacticalStatusFilterChanged extends TacticalEvent {
  final String status;

  TacticalStatusFilterChanged({required this.status});
}