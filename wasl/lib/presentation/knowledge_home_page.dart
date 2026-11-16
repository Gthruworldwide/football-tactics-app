import 'package:flutter/material.dart';

import '../data/knowledge_store.dart';

class KnowledgeHomePage extends StatefulWidget {
  const KnowledgeHomePage({required this.onLocaleChanged, super.key});

  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<KnowledgeHomePage> createState() => _KnowledgeHomePageState();
}

class _KnowledgeHomePageState extends State<KnowledgeHomePage> {
  final _queryController = TextEditingController();
  List<KnowledgeEntity> _entities = [];
  String? _error;
  bool _loading = true;

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _reload([String query = '']) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entities = await KnowledgeStore.instance.search(query);
      if (!mounted) return;
      setState(() {
        _entities = entities;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _createEntity() async {
    final values = await _showFields(
      context,
      isArabic: _isArabic,
      title: _isArabic ? 'كيان جديد' : 'New entity',
      fields: [
        _FieldSpec('name', _isArabic ? 'الاسم' : 'Name'),
        _FieldSpec(
          'type',
          _isArabic ? 'النوع' : 'Type',
          hint: _isArabic
              ? 'شخص، منظمة، موقع، مكان...'
              : 'person, organization, website, place...',
        ),
        _FieldSpec(
          'source_uri',
          _isArabic ? 'رابط المصدر' : 'Source URL',
          hint: 'https://...',
        ),
      ],
    );
    if (values == null) return;
    try {
      final entity = await KnowledgeStore.instance.addEntity(
        name: values['name']!,
        type: values['type']!,
        sourceUri: values['source_uri']!,
      );
      await _reload();
      if (!mounted) return;
      await _openProfile(entity);
    } on Object catch (error) {
      _showError(error);
    }
  }

  Future<void> _openProfile(KnowledgeEntity entity) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => KnowledgeProfilePage(entityId: entity.id),
      ),
    );
    if (mounted) _reload(_queryController.text);
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error.toString())));
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = _isArabic;
    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'وصل' : 'Wasl'),
        actions: [
          IconButton(
            tooltip: isArabic ? 'English' : 'العربية',
            onPressed: () => widget.onLocaleChanged(
              isArabic ? const Locale('en') : const Locale('ar'),
            ),
            icon: const Icon(Icons.translate),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _queryController,
              onChanged: _reload,
              decoration: InputDecoration(
                hintText: isArabic ? 'ابحث في معرفتك' : 'Search your knowledge',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _queryController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: isArabic ? 'مسح البحث' : 'Clear search',
                        onPressed: () {
                          _queryController.clear();
                          _reload();
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(child: Center(child: Text(_error!)))
          else if (_entities.isEmpty)
            Expanded(
              child: _EmptyState(
                isArabic: isArabic,
                hasQuery: _queryController.text.trim().isNotEmpty,
                onCreate: _createEntity,
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                itemCount: _entities.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final entity = _entities[index];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.hub)),
                      title: Text(entity.name),
                      subtitle: Text(entity.type),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openProfile(entity),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createEntity,
        icon: const Icon(Icons.add),
        label: Text(isArabic ? 'إضافة كيان' : 'Add entity'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isArabic,
    required this.hasQuery,
    required this.onCreate,
  });

  final bool isArabic;
  final bool hasQuery;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hub_outlined, size: 64),
          const SizedBox(height: 16),
          Text(
            hasQuery
                ? (isArabic ? 'لا توجد نتائج' : 'No results found')
                : (isArabic
                      ? 'ابدأ مساحة معرفتك بإضافة أول كيان ومصدره.'
                      : 'Start your knowledge space by adding an entity and its source.'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (!hasQuery) ...[
            const SizedBox(height: 12),
            Text(
              isArabic
                  ? 'سيظل كل ما تضيفه على هذا الجهاز.'
                  : 'Everything you add stays on this device.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: Text(isArabic ? 'إضافة كيان' : 'Add entity'),
            ),
          ],
        ],
      ),
    ),
  );
}

class KnowledgeProfilePage extends StatefulWidget {
  const KnowledgeProfilePage({required this.entityId, super.key});

  final String entityId;

  @override
  State<KnowledgeProfilePage> createState() => _KnowledgeProfilePageState();
}

class _KnowledgeProfilePageState extends State<KnowledgeProfilePage> {
  KnowledgeGraph? _graph;
  String? _error;
  bool _loading = true;

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final graph = await KnowledgeStore.instance.load();
      if (!mounted) return;
      setState(() {
        _graph = graph;
        _loading = false;
        _error = null;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _addFact(KnowledgeEntity entity) async {
    final values = await _showFields(
      context,
      isArabic: _isArabic,
      title: _isArabic ? 'حقيقة موثقة' : 'Sourced fact',
      fields: [
        _FieldSpec('property', _isArabic ? 'الخاصية' : 'Property'),
        _FieldSpec('value', _isArabic ? 'القيمة' : 'Value'),
        _FieldSpec(
          'source_uri',
          _isArabic ? 'رابط المصدر' : 'Source URL',
          hint: 'https://...',
        ),
        _FieldSpec(
          'valid_from',
          _isArabic ? 'ساري من (اختياري)' : 'Valid from (optional)',
          required: false,
        ),
        _FieldSpec(
          'valid_to',
          _isArabic ? 'ساري حتى (اختياري)' : 'Valid to (optional)',
          required: false,
        ),
      ],
    );
    if (values == null) return;
    try {
      await KnowledgeStore.instance.addFact(
        entityId: entity.id,
        property: values['property']!,
        value: values['value']!,
        sourceUri: values['source_uri']!,
        validFrom: values['valid_from'],
        validTo: values['valid_to'],
      );
      await _reload();
    } on Object catch (error) {
      _showError(error);
    }
  }

  Future<void> _addRelationship(
    KnowledgeEntity entity,
    List<KnowledgeEntity> others,
  ) async {
    if (others.isEmpty) {
      _showError(
        StateError(
          _isArabic
              ? 'أضف كيانًا آخر أولًا لإنشاء علاقة.'
              : 'Add another entity before creating a relationship.',
        ),
      );
      return;
    }
    final values = await _showRelationshipForm(entity, others);
    if (values == null) return;
    try {
      await KnowledgeStore.instance.addRelationship(
        subjectId: entity.id,
        predicate: values.predicate,
        objectId: values.objectId,
        sourceUri: values.sourceUri,
        validFrom: values.validFrom,
        validTo: values.validTo,
      );
      await _reload();
    } on Object catch (error) {
      _showError(error);
    }
  }

  Future<_RelationshipForm?> _showRelationshipForm(
    KnowledgeEntity entity,
    List<KnowledgeEntity> others,
  ) async {
    final predicate = TextEditingController();
    final source = TextEditingController();
    final validFrom = TextEditingController();
    final validTo = TextEditingController();
    final key = GlobalKey<FormState>();
    var selectedId = others.first.id;
    final isArabic = _isArabic;
    final result = await showDialog<_RelationshipForm>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isArabic ? 'علاقة موثقة' : 'Sourced relationship'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Form(
                key: key,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedId,
                      decoration: InputDecoration(
                        labelText: isArabic ? 'يرتبط بـ' : 'Connected to',
                      ),
                      items: others
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text(item.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedId = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _formField(
                      controller: predicate,
                      label: isArabic ? 'نوع العلاقة' : 'Relationship',
                      required: true,
                    ),
                    _formField(
                      controller: source,
                      label: isArabic ? 'رابط المصدر' : 'Source URL',
                      hint: 'https://...',
                      required: true,
                      keyboardType: TextInputType.url,
                    ),
                    _formField(
                      controller: validFrom,
                      label: isArabic
                          ? 'ساري من (اختياري)'
                          : 'Valid from (optional)',
                      required: false,
                    ),
                    _formField(
                      controller: validTo,
                      label: isArabic
                          ? 'ساري حتى (اختياري)'
                          : 'Valid to (optional)',
                      required: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isArabic ? 'إلغاء' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!key.currentState!.validate()) return;
                Navigator.pop(
                  context,
                  _RelationshipForm(
                    predicate: predicate.text,
                    objectId: selectedId,
                    sourceUri: source.text,
                    validFrom: validFrom.text,
                    validTo: validTo.text,
                  ),
                );
              },
              child: Text(isArabic ? 'حفظ' : 'Save'),
            ),
          ],
        ),
      ),
    );
    predicate.dispose();
    source.dispose();
    validFrom.dispose();
    validTo.dispose();
    return result;
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error.toString())));
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = _isArabic;
    final graph = _graph;
    KnowledgeEntity? entity;
    if (graph != null) {
      for (final item in graph.entities) {
        if (item.id == widget.entityId) {
          entity = item;
          break;
        }
      }
    }
    final currentEntity = entity;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentEntity?.name ?? (isArabic ? 'الملف الشخصي' : 'Profile'),
        ),
        actions: currentEntity == null
            ? null
            : [
                IconButton(
                  tooltip: isArabic ? 'إضافة حقيقة' : 'Add fact',
                  onPressed: () => _addFact(currentEntity),
                  icon: const Icon(Icons.fact_check_outlined),
                ),
                IconButton(
                  tooltip: isArabic ? 'إضافة علاقة' : 'Add relationship',
                  onPressed: () => _addRelationship(
                    currentEntity,
                    graph!.entities
                        .where((item) => item.id != currentEntity.id)
                        .toList(),
                  ),
                  icon: const Icon(Icons.add_link),
                ),
              ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : currentEntity == null || graph == null
          ? Center(
              child: Text(
                isArabic ? 'لم يتم العثور على الكيان.' : 'Entity not found.',
              ),
            )
          : _buildProfile(currentEntity, graph, isArabic),
    );
  }

  Widget _buildProfile(
    KnowledgeEntity entity,
    KnowledgeGraph graph,
    bool isArabic,
  ) {
    final facts = graph.facts.where((fact) => fact.entityId == entity.id);
    final relationships = graph.relationships.where(
      (item) => item.subjectId == entity.id || item.objectId == entity.id,
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(entity.type, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        _SourceCard(
          label: isArabic ? 'مصدر الكيان' : 'Entity source',
          sourceUri: entity.sourceUri,
        ),
        const SizedBox(height: 20),
        _SectionTitle(isArabic ? 'الحقائق' : 'Facts'),
        if (facts.isEmpty)
          _NoRecords(isArabic ? 'لا توجد حقائق بعد.' : 'No facts yet.')
        else
          ...facts.map(
            (fact) => Card(
              child: ListTile(
                title: Text('${fact.property}: ${fact.value}'),
                subtitle: Text(
                  [
                    if (fact.validFrom != null || fact.validTo != null)
                      '${fact.validFrom ?? '?'} – ${fact.validTo ?? '?'}',
                    fact.sourceUri,
                  ].join('\n'),
                ),
                isThreeLine: fact.validFrom != null || fact.validTo != null,
              ),
            ),
          ),
        const SizedBox(height: 20),
        _SectionTitle(isArabic ? 'العلاقات' : 'Relationships'),
        if (relationships.isEmpty)
          _NoRecords(isArabic ? 'لا توجد علاقات بعد.' : 'No relationships yet.')
        else
          ...relationships.map((relationship) {
            final outgoing = relationship.subjectId == entity.id;
            final relatedId = outgoing
                ? relationship.objectId
                : relationship.subjectId;
            KnowledgeEntity? related;
            for (final candidate in graph.entities) {
              if (candidate.id == relatedId) {
                related = candidate;
                break;
              }
            }
            if (related == null) return const SizedBox.shrink();
            return Card(
              child: ListTile(
                leading: Icon(outgoing ? Icons.north_east : Icons.south_west),
                title: Text(
                  '${outgoing ? relationship.predicate : _reverse(relationship.predicate)} ${related.name}',
                ),
                subtitle: Text(
                  [
                    if (relationship.validFrom != null ||
                        relationship.validTo != null)
                      '${relationship.validFrom ?? '?'} – ${relationship.validTo ?? '?'}',
                    relationship.sourceUri,
                  ].join('\n'),
                ),
                isThreeLine:
                    relationship.validFrom != null ||
                    relationship.validTo != null,
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => KnowledgeProfilePage(entityId: related!.id),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  String _reverse(String predicate) =>
      _isArabic ? 'مرتبط عبر $predicate بـ' : 'related via $predicate to';
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.label, required this.sourceUri});

  final String label;
  final String sourceUri;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SelectableText(sourceUri),
        ],
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: Theme.of(context).textTheme.titleLarge),
  );
}

class _NoRecords extends StatelessWidget {
  const _NoRecords(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(text),
  );
}

class _FieldSpec {
  const _FieldSpec(this.key, this.label, {this.hint, this.required = true});

  final String key;
  final String label;
  final String? hint;
  final bool required;
}

Future<Map<String, String>?> _showFields(
  BuildContext context, {
  required bool isArabic,
  required String title,
  required List<_FieldSpec> fields,
}) async {
  final controllers = {
    for (final field in fields) field.key: TextEditingController(),
  };
  final formKey = GlobalKey<FormState>();
  final values = await showDialog<Map<String, String>>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final field in fields) ...[
                  _formField(
                    controller: controllers[field.key]!,
                    label: field.label,
                    hint: field.hint,
                    required: field.required,
                    keyboardType: field.key == 'source_uri'
                        ? TextInputType.url
                        : TextInputType.text,
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(isArabic ? 'إلغاء' : 'Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            Navigator.pop(context, {
              for (final entry in controllers.entries)
                entry.key: entry.value.text.trim(),
            });
          },
          child: Text(isArabic ? 'حفظ' : 'Save'),
        ),
      ],
    ),
  );
  for (final controller in controllers.values) {
    controller.dispose();
  }
  return values;
}

Widget _formField({
  required TextEditingController controller,
  required String label,
  required bool required,
  String? hint,
  TextInputType keyboardType = TextInputType.text,
}) => Padding(
  padding: const EdgeInsets.only(top: 12),
  child: TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    decoration: InputDecoration(labelText: label, hintText: hint),
    validator: (value) {
      if (required && (value == null || value.trim().isEmpty)) {
        return 'Required';
      }
      if (required &&
          keyboardType == TextInputType.url &&
          !_isHttpUrl(value!.trim())) {
        return 'Enter a valid http or https URL';
      }
      return null;
    },
  ),
);

bool _isHttpUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      const {'http', 'https'}.contains(uri.scheme.toLowerCase()) &&
      uri.host.isNotEmpty;
}

class _RelationshipForm {
  const _RelationshipForm({
    required this.predicate,
    required this.objectId,
    required this.sourceUri,
    required this.validFrom,
    required this.validTo,
  });

  final String predicate;
  final String objectId;
  final String sourceUri;
  final String validFrom;
  final String validTo;
}
