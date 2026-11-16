import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class KnowledgeEntity {
  const KnowledgeEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.sourceUri,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String type;
  final String sourceUri;
  final String createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'source_uri': sourceUri,
    'created_at': createdAt,
  };

  factory KnowledgeEntity.fromJson(Map<String, dynamic> json) =>
      KnowledgeEntity(
        id: _requiredString(json, 'id'),
        name: _requiredString(json, 'name'),
        type: _requiredString(json, 'type'),
        sourceUri: _requiredString(json, 'source_uri'),
        createdAt: _requiredString(json, 'created_at'),
      );
}

class KnowledgeFact {
  const KnowledgeFact({
    required this.id,
    required this.entityId,
    required this.property,
    required this.value,
    required this.sourceUri,
    required this.retrievedAt,
    this.validFrom,
    this.validTo,
  });

  final String id;
  final String entityId;
  final String property;
  final String value;
  final String sourceUri;
  final String retrievedAt;
  final String? validFrom;
  final String? validTo;

  Map<String, Object?> toJson() => {
    'id': id,
    'entity_id': entityId,
    'property': property,
    'value': value,
    'source_uri': sourceUri,
    'retrieved_at': retrievedAt,
    'valid_from': validFrom,
    'valid_to': validTo,
  };

  factory KnowledgeFact.fromJson(Map<String, dynamic> json) => KnowledgeFact(
    id: _requiredString(json, 'id'),
    entityId: _requiredString(json, 'entity_id'),
    property: _requiredString(json, 'property'),
    value: _requiredString(json, 'value'),
    sourceUri: _requiredString(json, 'source_uri'),
    retrievedAt: _requiredString(json, 'retrieved_at'),
    validFrom: json['valid_from'] as String?,
    validTo: json['valid_to'] as String?,
  );
}

class KnowledgeRelationship {
  const KnowledgeRelationship({
    required this.id,
    required this.subjectId,
    required this.predicate,
    required this.objectId,
    required this.sourceUri,
    required this.retrievedAt,
    this.validFrom,
    this.validTo,
  });

  final String id;
  final String subjectId;
  final String predicate;
  final String objectId;
  final String sourceUri;
  final String retrievedAt;
  final String? validFrom;
  final String? validTo;

  Map<String, Object?> toJson() => {
    'id': id,
    'subject_id': subjectId,
    'predicate': predicate,
    'object_id': objectId,
    'source_uri': sourceUri,
    'retrieved_at': retrievedAt,
    'valid_from': validFrom,
    'valid_to': validTo,
  };

  factory KnowledgeRelationship.fromJson(Map<String, dynamic> json) =>
      KnowledgeRelationship(
        id: _requiredString(json, 'id'),
        subjectId: _requiredString(json, 'subject_id'),
        predicate: _requiredString(json, 'predicate'),
        objectId: _requiredString(json, 'object_id'),
        sourceUri: _requiredString(json, 'source_uri'),
        retrievedAt: _requiredString(json, 'retrieved_at'),
        validFrom: json['valid_from'] as String?,
        validTo: json['valid_to'] as String?,
      );
}

class KnowledgeGraph {
  const KnowledgeGraph({
    required this.entities,
    required this.facts,
    required this.relationships,
  });

  const KnowledgeGraph.empty()
    : entities = const [],
      facts = const [],
      relationships = const [];

  final List<KnowledgeEntity> entities;
  final List<KnowledgeFact> facts;
  final List<KnowledgeRelationship> relationships;

  factory KnowledgeGraph.fromJson(Map<String, dynamic> json) => KnowledgeGraph(
    entities: _readList(json, 'entities', KnowledgeEntity.fromJson),
    facts: _readList(json, 'facts', KnowledgeFact.fromJson),
    relationships: _readList(
      json,
      'relationships',
      KnowledgeRelationship.fromJson,
    ),
  );

  Map<String, Object?> toJson() => {
    'entities': entities.map((item) => item.toJson()).toList(),
    'facts': facts.map((item) => item.toJson()).toList(),
    'relationships': relationships.map((item) => item.toJson()).toList(),
  };
}

class KnowledgeStore {
  KnowledgeStore._();

  static final instance = KnowledgeStore._();
  static const _storageKey = 'wasl_graph_v1';
  final _random = Random.secure();

  Future<KnowledgeGraph> load() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_storageKey);
    if (encoded == null) return const KnowledgeGraph.empty();
    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Stored knowledge graph is invalid.');
    }
    return KnowledgeGraph.fromJson(decoded);
  }

  Future<List<KnowledgeEntity>> search(String query) async {
    final normalized = query.trim().toLowerCase();
    final graph = await load();
    return graph.entities
        .where(
          (entity) =>
              normalized.isEmpty ||
              entity.name.toLowerCase().contains(normalized) ||
              entity.type.toLowerCase().contains(normalized),
        )
        .toList();
  }

  Future<KnowledgeEntity> addEntity({
    required String name,
    required String type,
    required String sourceUri,
  }) async {
    final entity = KnowledgeEntity(
      id: _newId(),
      name: _requiredInput(name, 'Name'),
      type: _requiredInput(type, 'Type'),
      sourceUri: _validatedUri(sourceUri),
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
    final graph = await load();
    await _save(
      KnowledgeGraph(
        entities: [...graph.entities, entity],
        facts: graph.facts,
        relationships: graph.relationships,
      ),
    );
    return entity;
  }

  Future<KnowledgeFact> addFact({
    required String entityId,
    required String property,
    required String value,
    required String sourceUri,
    String? validFrom,
    String? validTo,
  }) async {
    final graph = await load();
    _requireEntity(graph, entityId);
    final fact = KnowledgeFact(
      id: _newId(),
      entityId: entityId,
      property: _requiredInput(property, 'Property'),
      value: _requiredInput(value, 'Value'),
      sourceUri: _validatedUri(sourceUri),
      retrievedAt: DateTime.now().toUtc().toIso8601String(),
      validFrom: _optionalInput(validFrom),
      validTo: _optionalInput(validTo),
    );
    await _save(
      KnowledgeGraph(
        entities: graph.entities,
        facts: [...graph.facts, fact],
        relationships: graph.relationships,
      ),
    );
    return fact;
  }

  Future<KnowledgeRelationship> addRelationship({
    required String subjectId,
    required String predicate,
    required String objectId,
    required String sourceUri,
    String? validFrom,
    String? validTo,
  }) async {
    final graph = await load();
    _requireEntity(graph, subjectId);
    _requireEntity(graph, objectId);
    final relationship = KnowledgeRelationship(
      id: _newId(),
      subjectId: subjectId,
      predicate: _requiredInput(predicate, 'Relationship'),
      objectId: objectId,
      sourceUri: _validatedUri(sourceUri),
      retrievedAt: DateTime.now().toUtc().toIso8601String(),
      validFrom: _optionalInput(validFrom),
      validTo: _optionalInput(validTo),
    );
    await _save(
      KnowledgeGraph(
        entities: graph.entities,
        facts: graph.facts,
        relationships: [...graph.relationships, relationship],
      ),
    );
    return relationship;
  }

  String _newId() =>
      'wasl_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(1 << 32).toRadixString(16)}';

  Future<void> _save(KnowledgeGraph graph) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _storageKey,
      jsonEncode(graph.toJson()),
    );
    if (!saved) throw StateError('Unable to save the knowledge graph.');
  }
}

String _requiredInput(String value, String label) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ArgumentError('$label is required.');
  return normalized;
}

String? _optionalInput(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

String _validatedUri(String value) {
  final normalized = _requiredInput(value, 'Source URL');
  final uri = Uri.tryParse(normalized);
  if (uri == null ||
      !const {'http', 'https'}.contains(uri.scheme.toLowerCase()) ||
      uri.host.isEmpty) {
    throw ArgumentError('Source URL must be a valid http or https URL.');
  }
  return normalized;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Stored knowledge record is missing $key.');
  }
  return value;
}

List<T> _readList<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) decode,
) {
  final value = json[key];
  if (value is! List) {
    throw FormatException('Stored knowledge graph is missing $key.');
  }
  return value.map((item) {
    if (item is! Map<String, dynamic>) {
      throw FormatException('Stored knowledge graph has invalid $key.');
    }
    return decode(item);
  }).toList();
}

KnowledgeEntity _requireEntity(KnowledgeGraph graph, String id) {
  for (final entity in graph.entities) {
    if (entity.id == id) return entity;
  }
  throw StateError('Knowledge entity not found.');
}
