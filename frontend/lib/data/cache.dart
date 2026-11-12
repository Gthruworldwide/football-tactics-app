import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import '../logic/matches_bloc.dart';
import '../logic/user_preferences.dart';

// Open Hive boxes for local storage
final _matchBox = Hive.box<MatchCache>('matches_box');

// No custom AppHydratedStorage - using default HydratedStorage

/// Extension for DateTime formatting in local timezone
extension DateTimeExtension on DateTime {
  String get localTimezoneFormatted {
    return DateFormat('HH:mm:ss', 'local').format(this);
  }

  String get formattedDate {
    return DateFormat('yyyy-MM-dd', 'local').format(this);
  }

  String get dayOfWeek {
    return DateFormat.EEEE('local').format(this);
  }
}