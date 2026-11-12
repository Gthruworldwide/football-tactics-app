# معمارية تخصيص تجربة المستخدم (Personalized Tactical Workspace UX)

## 1. الرؤية المعمارية لتخصيص تجربة المستخدم (Personalized UX Architecture)
لتحويل التطبيق من عرض قوائم عامة إلى مساحة عمل تكتيكية مخصصة بالكامل (**Personalized Tactical Workspace**)، يتم إعادة هيكلة تجربة المستخدم (UX) لتدور حول **"تفضيلات المحلل" (Analyst Preferences)** المخزنة محلياً في قاعدة بيانات **Hive** (`user_prefs_box`)، وتطبيق نظام **Dynamic Filtering & Pinning** بناءً على اختيارات المستخدم الفعلية:

1. **الدوريات المثبتة (Pinned Leagues):** يختار المستخدم الدوريات التي تهمه فقط (مثل الدوري المصري `EG`، الإنجليزي `ENG`، الإسباني `ESP`، الإيطالي `ITA`، أو الألماني `GER`)، فتظهر حصرياً في شريط الفلترة العلوي، ويتم جلب المباريات وجداول الترتيب (`Standings`) وإحصائياتها فقط.
2. **الفرق المتابعة (Tracked Clubs):** عند تحديد أندية معينة، يتم تمييز مبارياتها تلقائياً بعلامة تكتيكية (`TRACKED`) وتثبيتها في أعلى القائمة، وتظليل صفوفها في جدول الترتيب (`Standings`) بإطار نيون مع أيقونة نجمة.
3. **عدسة المؤشرات المفضلة (Custom Tactical Telemetry Lens):** اختيار زاوية التحليل التي يركز عليها المحلل في البطاقات والجداول (الاستحواذ `Possession`، الهجوم `Offensive (xG)`، أو الضغط الدفاعي `Defensive (PPDA)`).

---

## 2. العناصر التكتيكية المفقودة المقترح إضافتها (Missing Tactical Elements)
لرفع القيمة التحليلية للتطبيق وجعله يضاهي منصات التحليل الاحترافية، تُضاف العناصر التالية:

* **مؤشر الزخم الهجومي (Match Momentum / Pressure Index):** شريط مصغر يوضح أي فريق يفرض سيطرته الميدانية في آخر 15 دقيقة.
* **فورمة آخر 5 مباريات (5-Match Form Pills) في جدول الترتيب:** مربعات ملونة مصغرة (`W` أخضر، `D` رمادي، `L` أحمر) بجانب كل فريق في جدول الترتيب، مع فارق الأهداف (`GD`) والنقاط (`PTS`) بأرقام جدولية ثابتة العرض (`tabularFigures`).
* **مقارنة تكتيكية ثنائية (Head-to-Head Player Comparison):** إمكانية اختيار لاعبين اثنين ودمجهما في نفس مخطط الرادار (`RadarChart`) للمقارنة المباشرة.
* **التلخيص التكتيكي الفوري (AI Tactical Brief):** زر داخل تفاصيل المباراة يستدعي مسار `POST /api/v1/tactical/summary` لاستخراج نقاط القوة والضعف في التشكيل.

---

## 3. الكود المعماري للتنفيذ (Implementation Blueprint)

### أولاً: مدير التفضيلات الشخصية (`frontend/lib/core/services/user_prefs_service.dart`)
مسؤول عن حفظ واسترجاع اختيارات المحلل محلياً في صندوق `user_prefs_box`:

```dart
import 'package:hive_flutter/hive_flutter.dart';

class UserPrefsService {
  static const String _boxName = 'user_prefs_box';

  static Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  // 1. الدوريات المختارة من المستخدم
  static Future<List<String>> getSelectedLeagues() async {
    final box = await _getBox();
    final saved = box.get('selected_leagues');
    if (saved == null) return ['EG', 'ENG', 'ESP']; // الافتراضي
    return List<String>.from(saved);
  }

  static Future<void> toggleLeague(String code) async {
    final box = await _getBox();
    final current = await getSelectedLeagues();
    if (current.contains(code)) {
      if (current.length > 1) current.remove(code); // إبقاء دوري واحد على الأقل
    } else {
      current.add(code);
    }
    await box.put('selected_leagues', current);
  }

  // 2. الفرق المفضلة لتمييزها في الجداول والمباريات
  static Future<List<String>> getFavoriteTeams() async {
    final box = await _getBox();
    final saved = box.get('favorite_teams');
    if (saved == null) return ['FC Barcelona', 'Al Ahly', 'Liverpool FC'];
    return List<String>.from(saved);
  }

  static Future<void> toggleFavoriteTeam(String teamName) async {
    final box = await _getBox();
    final current = await getFavoriteTeams();
    current.contains(teamName) ? current.remove(teamName) : current.add(teamName);
    await box.put('favorite_teams', current);
  }

  // 3. عدسة التحليل (Possession / Offensive / Defensive)
  static Future<String> getTacticalLens() async {
    final box = await _getBox();
    return box.get('tactical_lens', defaultValue: 'Possession');
  }

  static Future<void> setTacticalLens(String lens) async {
    final box = await _getBox();
    await box.put('tactical_lens', lens);
  }
}