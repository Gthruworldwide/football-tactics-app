import 'dart:developer' as dev;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../core/constants.dart';

// BLoC state for the 5-country geographic filter
abstract class CountryState extends Equatable {
  /// The 3 permanent core countries (non-removable)
  final List<String> permanentCountries;

  /// The dynamically detected Geo-IP country
  final String geoIPCountry;

  /// The user-selectable country
  final String userSelectableCountry;

  const CountryState({
    this.permanentCountries = const ['England', 'Spain', 'Italy'],
    this.geoIPCountry = 'Egypt',
    this.userSelectableCountry = 'Netherlands',
  });

  /// Get all 5 countries in the filter
  List<String> get allCountries => [
    ...permanentCountries,
    geoIPCountry,
    userSelectableCountry,
  ].toSet().toList();

  /// Check if a country is in the allowed filter list
  bool isAllowed(String country) =>
      allCountries.any((c) => c.toLowerCase() == country.toLowerCase());

  @override
  List<Object?> get props => [
    permanentCountries,
    geoIPCountry,
    userSelectableCountry,
  ];
}

class CountryStateImpl extends CountryState {
  const CountryStateImpl({
    super.permanentCountries = const ['England', 'Spain', 'Italy'],
    super.geoIPCountry = 'Egypt',
    super.userSelectableCountry = 'Netherlands',
  });
}

// BLoC event for the 5-country geographic filter
abstract class CountryEvent extends Equatable {
  const CountryEvent();

  @override
  List<Object?> get props => [];
}

/// Initial load event
class CountryLoaded extends CountryEvent {
  final String country;

  CountryLoaded(this.country);
}

/// Set Geo-IP country event
class SetGeoIPCountry extends CountryEvent {
  final String country;
  SetGeoIPCountry({required this.country});
}

/// Set user-selectable country event
class SetUserCountry extends CountryEvent {
  final String country;
  SetUserCountry({required this.country});
}

/// Reset countries event
class ResetCountries extends CountryEvent {}

/// Country BLoC implementation
class CountryBloc extends Bloc<CountryEvent, CountryState> {
  CountryBloc() : super(const CountryStateImpl()) {
    on<CountryLoaded>(_onLoaded);
    on<SetGeoIPCountry>(_onSetGeoIPCountry);
    on<SetUserCountry>(_onSetUserCountry);
    on<ResetCountries>(_onReset);
  }

  Future<void> _onLoaded(
    CountryLoaded event,
    Emitter<CountryState> emit,
  ) async {
    // In real implementation, load from Hive storage
    emit(
      CountryStateImpl(
        permanentCountries: const ['England', 'Spain', 'Italy'],
        geoIPCountry: 'Egypt',
        userSelectableCountry: event.country,
      ),
    );
  }

  Future<void> _onSetGeoIPCountry(
    SetGeoIPCountry event,
    Emitter<CountryState> emit,
  ) async {
    final current = state as CountryStateImpl;
    emit(
      CountryStateImpl(
        permanentCountries: current.permanentCountries,
        geoIPCountry: event.country,
        userSelectableCountry: current.userSelectableCountry,
      ),
    );
  }

  Future<void> _onSetUserCountry(
    SetUserCountry event,
    Emitter<CountryState> emit,
  ) async {
    final current = state as CountryStateImpl;
    emit(
      CountryStateImpl(
        permanentCountries: current.permanentCountries,
        geoIPCountry: current.geoIPCountry,
        userSelectableCountry: event.country,
      ),
    );
    // In real implementation, persist to Hive
  }

  Future<void> _onReset(
    ResetCountries event,
    Emitter<CountryState> emit,
  ) async {
    emit(const CountryStateImpl());
  }
}

/// Available countries for user selection (mapped to API-Football league IDs)
const Map<String, String> availableCountries = {
  'Netherlands': 'NED',
  'Germany': 'GER',
  'France': 'FRA',
  'Portugal': 'POR',
  'Belgium': 'BEL',
  'Turkey': 'TUR',
  'Greece': 'GRE',
  'Austria': 'AUT',
  'Switzerland': 'SUI',
  'Denmark': 'DEN',
  'Scotland': 'SCO',
  'Norway': 'NOR',
  'Sweden': 'SWE',
  'Poland': 'POL',
  'Russia': 'RUS',
  'Ukraine': 'UKR',
  'Serbia': 'SRB',
  'Croatia': 'CRO',
  'Czech Republic': 'CZE',
  'Romania': 'ROU',
  'Saudi Arabia': 'SAU',
  'Qatar': 'QAT',
  'UAE': 'UAE',
  'Japan': 'JPN',
  'South Korea': 'KOR',
  'USA': 'USA',
  'Mexico': 'MEX',
  'Brazil': 'BRA',
  'Argentina': 'ARG',
};
