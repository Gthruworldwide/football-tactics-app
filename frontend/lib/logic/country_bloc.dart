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
  List<String> get allCountries =>
      [...permanentCountries, geoIPCountry, userSelectableCountry].toSet().toList();

  /// Check if a country is in the allowed filter list
  bool isAllowed(String country) =>
      allCountries.any((c) => c.toLowerCase() == country.toLowerCase());

  @override
  List<Object?> get props => [permanentCountries, geoIPCountry, userSelectableCountry];
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