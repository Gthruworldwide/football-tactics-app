String localizedDataError(
  Object error, {
  required bool isArabic,
  required String fallback,
}) {
  final message = error.toString().toLowerCase();

  if (message.contains('not included in the current') ||
      message.contains('top-scorer data')) {
    return isArabic
        ? 'خطة مزوّد البيانات لا تشمل إحصاءات الهدافين. المباريات والترتيب منفصلان عن هذه الميزة.'
        : 'The current data-provider plan does not include top-scorer statistics. Matches and standings are separate features.';
  }
  if (message.contains('http 429') || message.contains('rate limit')) {
    return isArabic
        ? 'تم بلوغ حد الطلبات لدى مزوّد البيانات. حاول التحديث بعد قليل.'
        : 'The data provider request limit was reached. Please retry shortly.';
  }
  if (message.contains('http 401') || message.contains('http 403')) {
    return isArabic
        ? 'المفتاح أو الخطة لا تسمح بطلب هذه البيانات. راجع إعدادات مزوّد البيانات.'
        : 'The API key or plan does not allow this data request. Check provider settings.';
  }
  if (message.contains('no fixtures were returned')) {
    return isArabic
        ? 'لم يُرجع مزوّد البيانات مباريات لهذا الدوري والموسم.'
        : 'The data provider returned no fixtures for this league and season.';
  }
  if (message.contains('no standings table was returned')) {
    return isArabic
        ? 'جدول الترتيب غير متاح لهذا الدوري والموسم لدى مزوّد البيانات.'
        : 'The standings table is unavailable for this league and season.';
  }
  if (message.contains('socketexception') ||
      message.contains('failed host lookup') ||
      message.contains('connection refused') ||
      message.contains('timed out')) {
    return isArabic
        ? 'تعذر الاتصال بالخادم. تأكد من تشغيله واتصال الهاتف بالشبكة نفسها.'
        : 'Could not reach the backend. Check that it is running and your phone is on the same network.';
  }
  return fallback;
}
