import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wasl_app/data/knowledge_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('starts empty and keeps same-name entities separate', () async {
    final store = KnowledgeStore.instance;

    expect(await store.search(''), isEmpty);

    final first = await store.addEntity(
      name: 'Alex Rivera',
      type: 'person',
      sourceUri: 'https://example.test/people/alex',
    );
    final second = await store.addEntity(
      name: 'Alex Rivera',
      type: 'person',
      sourceUri: 'https://example.test/people/alex-2',
    );

    expect(first.id, isNot(second.id));
    expect(await store.search('alex'), hasLength(2));
  });

  test('stores facts and relationships with sources and valid time', () async {
    final store = KnowledgeStore.instance;
    final person = await store.addEntity(
      name: 'Alex Rivera',
      type: 'person',
      sourceUri: 'https://example.test/people/alex',
    );
    final organization = await store.addEntity(
      name: 'Northstar Lab',
      type: 'organization',
      sourceUri: 'https://example.test/orgs/northstar',
    );

    await store.addFact(
      entityId: person.id,
      property: 'profession',
      value: 'Researcher',
      sourceUri: 'https://example.test/people/alex#bio',
      validFrom: '2024-01-01',
    );
    await store.addRelationship(
      subjectId: person.id,
      predicate: 'works_with',
      objectId: organization.id,
      sourceUri: 'https://example.test/reports/2025',
      validFrom: '2025-01-01',
      validTo: '2025-12-31',
    );

    final graph = await store.load();
    expect(graph.entities, hasLength(2));
    expect(graph.facts.single.sourceUri, contains('#bio'));
    expect(graph.facts.single.validFrom, '2024-01-01');
    expect(graph.facts.single.retrievedAt, isNotEmpty);
    expect(graph.relationships.single.validTo, '2025-12-31');
    expect(graph.relationships.single.sourceUri, contains('/reports/2025'));
  });

  test('rejects unsupported or malformed source URLs', () async {
    expect(
      () => KnowledgeStore.instance.addEntity(
        name: 'Example',
        type: 'website',
        sourceUri: 'javascript:alert(1)',
      ),
      throwsArgumentError,
    );
  });
}
