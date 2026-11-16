"""Persistence helpers for the source-backed knowledge graph."""

import json
import uuid
from collections import deque
from datetime import datetime, timezone
from typing import Any


def _id() -> str:
    return str(uuid.uuid4())


def _json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"), sort_keys=True)


def _source(
    conn,
    provider: str,
    record_type: str,
    record_id: Any,
    source_uri: str,
    season: int | None,
) -> str:
    record_id = str(record_id)
    row = conn.execute(
        """
        SELECT id FROM knowledge_sources
        WHERE provider = ? AND record_type = ? AND record_id = ?
          AND source_uri = ? AND season IS ?
        """,
        (provider, record_type, record_id, source_uri, season),
    ).fetchone()
    retrieved_at = datetime.now(timezone.utc).isoformat()
    if row:
        conn.execute(
            "UPDATE knowledge_sources SET retrieved_at = ? WHERE id = ?",
            (retrieved_at, row["id"]),
        )
        return row["id"]
    source_id = _id()
    conn.execute(
        """
        INSERT INTO knowledge_sources
            (id, provider, record_type, record_id, source_uri, retrieved_at, season)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
        (source_id, provider, record_type, record_id, source_uri, retrieved_at, season),
    )
    return source_id


def _entity(
    conn,
    source: str,
    entity_type: str,
    external_id: Any,
    name: Any,
    attributes: dict[str, Any] | None = None,
) -> str | None:
    if external_id is None or name is None or not str(name).strip():
        return None
    external_id = str(external_id)
    row = conn.execute(
        """
        SELECT entity_id FROM knowledge_identities
        WHERE source = ? AND entity_type = ? AND external_id = ?
        """,
        (source, entity_type, external_id),
    ).fetchone()
    entity_attributes = {k: v for k, v in (attributes or {}).items() if v is not None}
    if row:
        conn.execute(
            """
            UPDATE knowledge_entities
            SET name = ?, attributes_json = ?, updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
            """,
            (str(name).strip(), _json(entity_attributes), row["entity_id"]),
        )
        return row["entity_id"]

    entity_id = _id()
    conn.execute(
        """
        INSERT INTO knowledge_entities (id, entity_type, name, attributes_json)
        VALUES (?, ?, ?, ?)
        """,
        (entity_id, entity_type, str(name).strip(), _json(entity_attributes)),
    )
    conn.execute(
        """
        INSERT INTO knowledge_identities (entity_id, source, entity_type, external_id)
        VALUES (?, ?, ?, ?)
        """,
        (entity_id, source, entity_type, external_id),
    )
    return entity_id


def _fact(
    conn,
    entity_id: str | None,
    predicate: str,
    value: Any,
    source_id: str,
    *,
    valid_from: str | None = None,
    valid_to: str | None = None,
    attributes: dict[str, Any] | None = None,
) -> None:
    if entity_id is None or value is None:
        return
    row = conn.execute(
        """
        SELECT id FROM knowledge_facts
        WHERE entity_id = ? AND predicate = ? AND source_id = ?
          AND valid_from IS ? AND valid_to IS ?
        """,
        (entity_id, predicate, source_id, valid_from, valid_to),
    ).fetchone()
    values = (entity_id, predicate, _json(value), valid_from, valid_to, source_id, _json(attributes or {}))
    if row:
        conn.execute(
            """
            UPDATE knowledge_facts
            SET value_json = ?, attributes_json = ?
            WHERE id = ?
            """,
            (_json(value), _json(attributes or {}), row["id"]),
        )
        return
    conn.execute(
        """
        INSERT INTO knowledge_facts
            (id, entity_id, predicate, value_json, valid_from, valid_to, source_id, attributes_json)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (_id(), *values),
    )


def _relationship(
    conn,
    subject_id: str | None,
    predicate: str,
    object_id: str | None,
    source_id: str,
    *,
    valid_from: str | None = None,
    valid_to: str | None = None,
    attributes: dict[str, Any] | None = None,
) -> None:
    if subject_id is None or object_id is None:
        return
    existing = conn.execute(
        """
        SELECT id FROM knowledge_relationships
        WHERE subject_id = ? AND predicate = ? AND object_id = ? AND source_id = ?
        """,
        (subject_id, predicate, object_id, source_id),
    ).fetchone()
    if existing:
        conn.execute(
            """
            UPDATE knowledge_relationships
            SET valid_from = ?, valid_to = ?, attributes_json = ?
            WHERE id = ?
            """,
            (valid_from, valid_to, _json(attributes or {}), existing["id"]),
        )
        return
    conn.execute(
        """
        INSERT INTO knowledge_relationships
            (id, subject_id, predicate, object_id, valid_from, valid_to, source_id, attributes_json)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (_id(), subject_id, predicate, object_id, valid_from, valid_to, source_id, _json(attributes or {})),
    )


def _season_attributes(season: int | None) -> dict[str, Any]:
    return {"season": season} if season is not None else {}


def persist_matches(
    conn, matches: list[dict[str, Any]], provider: str, season: int, source_uri: str
) -> None:
    for match in matches:
        fixture = match.get("fixture") or {}
        league = match.get("league") or {}
        teams = match.get("teams") or {}
        fixture_id = fixture.get("id")
        if fixture_id is None:
            continue
        match_source_id = _source(
            conn, provider, "match", fixture_id, source_uri, season
        )
        match_id = _entity(
            conn, provider, "match", fixture_id,
            f"{(teams.get('home') or {}).get('name', 'Home')} vs "
            f"{(teams.get('away') or {}).get('name', 'Away')}",
            {"date": fixture.get("date"), "status": (fixture.get("status") or {}).get("short")},
        )
        date = fixture.get("date")
        _fact(conn, match_id, "kickoff", date, match_source_id, valid_from=date, valid_to=date)
        goals = match.get("goals") or {}
        _fact(conn, match_id, "score", goals, match_source_id, valid_from=date, valid_to=date)
        competition_id = league.get("id")
        competition_id_entity = _entity(
            conn, provider, "competition", competition_id, league.get("name"),
            {"country": league.get("country"), "season": league.get("season") or season},
        )
        for side in ("home", "away"):
            team = teams.get(side) or {}
            team_id = _entity(
                conn, provider, "club", team.get("id"), team.get("name"),
                {"logo": team.get("logo")},
            )
            _relationship(
                conn, match_id, f"{side}_team", team_id, match_source_id,
                valid_from=date, valid_to=date,
                attributes=_season_attributes(season),
            )
            _relationship(
                conn, team_id, "competes_in", competition_id_entity, match_source_id,
                attributes=_season_attributes(season),
            )


def persist_standings(
    conn, standings: list[dict[str, Any]], provider: str, season: int,
    league_code: str, source_uri: str,
) -> None:
    for row in standings:
        team = row.get("team") or {}
        team_id = _entity(
            conn, provider, "club", team.get("id"), team.get("name"),
            {"logo": team.get("logo")},
        )
        if team_id is None:
            continue
        record_id = f"{league_code}:{season}:{team['id']}"
        source_id = _source(conn, provider, "standing", record_id, source_uri, season)
        attributes = _season_attributes(season)
        for predicate, value in (("league_position", row.get("rank")), ("points", row.get("points"))):
            _fact(conn, team_id, predicate, value, source_id, attributes=attributes)


def persist_scorers(
    conn, players: list[dict[str, Any]], provider: str, season: int,
    league_code: str, source_uri: str,
) -> None:
    for player in players:
        player_id = _entity(
            conn, provider, "person", player.get("id"), player.get("player_name"),
            {"position": player.get("position")},
        )
        if player_id is None:
            continue
        source_id = _source(conn, provider, "player_statistics", player["id"], source_uri, season)
        attributes = _season_attributes(season)
        for predicate, value in (
            ("goals", player.get("goals")),
            ("assists", player.get("assists")),
            ("appearances", player.get("games")),
        ):
            _fact(conn, player_id, predicate, value, source_id, attributes=attributes)

        club = _entity(
            conn, provider, "club", player.get("team_id"), player.get("team_name")
        )
        _relationship(
            conn, player_id, "plays_for", club, source_id,
            attributes={**attributes, "competition": league_code},
        )


def _decode(value: str) -> Any:
    return json.loads(value)


def _source_dict(row) -> dict[str, Any]:
    return {
        "provider": row["provider"],
        "record_type": row["record_type"],
        "record_id": row["record_id"],
        "source_uri": row["source_uri"],
        "retrieved_at": row["retrieved_at"],
        "season": row["season"],
    }


def search_entities(
    conn, query: str, entity_type: str | None = None, limit: int = 30
) -> list[dict[str, Any]]:
    sql = "SELECT id, entity_type, name, attributes_json FROM knowledge_entities WHERE name LIKE ?"
    params: list[Any] = [f"%{query}%"]
    if entity_type:
        sql += " AND entity_type = ?"
        params.append(entity_type)
    sql += " ORDER BY name COLLATE NOCASE, entity_type LIMIT ?"
    params.append(limit)
    return [
        {
            "id": row["id"],
            "entity_type": row["entity_type"],
            "name": row["name"],
            "attributes": _decode(row["attributes_json"]),
        }
        for row in conn.execute(sql, params).fetchall()
    ]


def entity_profile(conn, entity_id: str) -> dict[str, Any] | None:
    entity = conn.execute(
        "SELECT * FROM knowledge_entities WHERE id = ?", (entity_id,)
    ).fetchone()
    if entity is None:
        return None
    identity_rows = conn.execute(
        """
        SELECT source, entity_type, external_id FROM knowledge_identities
        WHERE entity_id = ? ORDER BY source, external_id
        """,
        (entity_id,),
    ).fetchall()
    fact_rows = conn.execute(
        """
        SELECT f.*, s.provider, s.record_type, s.record_id, s.source_uri,
               s.retrieved_at, s.season
        FROM knowledge_facts f JOIN knowledge_sources s ON s.id = f.source_id
        WHERE f.entity_id = ? ORDER BY f.predicate, s.season DESC
        """,
        (entity_id,),
    ).fetchall()
    relationship_rows = conn.execute(
        """
        SELECT r.*, s.provider, s.record_type, s.record_id, s.source_uri,
               s.retrieved_at, s.season, e.id AS related_id,
               e.entity_type AS related_type, e.name AS related_name,
               e.attributes_json AS related_attributes
        FROM knowledge_relationships r
        JOIN knowledge_sources s ON s.id = r.source_id
        JOIN knowledge_entities e
          ON e.id = CASE WHEN r.subject_id = ? THEN r.object_id ELSE r.subject_id END
        WHERE r.subject_id = ? OR r.object_id = ?
        ORDER BY s.season DESC, e.name COLLATE NOCASE
        """,
        (entity_id, entity_id, entity_id),
    ).fetchall()
    return {
        "id": entity["id"],
        "entity_type": entity["entity_type"],
        "name": entity["name"],
        "attributes": _decode(entity["attributes_json"]),
        "identities": [dict(row) for row in identity_rows],
        "facts": [
            {
                "predicate": row["predicate"],
                "value": _decode(row["value_json"]),
                "valid_from": row["valid_from"],
                "valid_to": row["valid_to"],
                "attributes": _decode(row["attributes_json"]),
                "source": _source_dict(row),
            }
            for row in fact_rows
        ],
        "relationships": [
            {
                "predicate": row["predicate"],
                "direction": "outgoing" if row["subject_id"] == entity_id else "incoming",
                "related_entity": {
                    "id": row["related_id"],
                    "entity_type": row["related_type"],
                    "name": row["related_name"],
                    "attributes": _decode(row["related_attributes"]),
                },
                "valid_from": row["valid_from"],
                "valid_to": row["valid_to"],
                "attributes": _decode(row["attributes_json"]),
                "source": _source_dict(row),
            }
            for row in relationship_rows
        ],
    }


def find_paths(
    conn, source_id: str, target_id: str, max_depth: int = 4
) -> dict[str, Any]:
    if (
        entity_profile(conn, source_id) is None
        or entity_profile(conn, target_id) is None
        or source_id == target_id
    ):
        return []

    paths = []
    queue = deque([(source_id, [source_id], [])])
    shortest_depth: int | None = None
    explored = 0
    truncated = False
    while queue:
        if explored >= 10000 or len(paths) >= 20:
            truncated = True
            break
        current, entity_ids, edges = queue.popleft()
        explored += 1
        depth = len(edges)
        if shortest_depth is not None and depth >= shortest_depth:
            continue
        if depth >= max_depth:
            continue
        rows = conn.execute(
            """
            SELECT r.*, s.provider, s.record_type, s.record_id, s.source_uri,
                   s.retrieved_at, s.season, a.name AS subject_name,
                   b.name AS object_name, a.entity_type AS subject_type,
                   b.entity_type AS object_type
            FROM knowledge_relationships r
            JOIN knowledge_sources s ON s.id = r.source_id
            JOIN knowledge_entities a ON a.id = r.subject_id
            JOIN knowledge_entities b ON b.id = r.object_id
            WHERE r.subject_id = ? OR r.object_id = ?
            """,
            (current, current),
        ).fetchall()
        for row in rows:
            neighbor = row["object_id"] if row["subject_id"] == current else row["subject_id"]
            if neighbor in entity_ids:
                continue
            edge = {
                "predicate": row["predicate"],
                "subject_id": row["subject_id"],
                "subject_name": row["subject_name"],
                "object_id": row["object_id"],
                "object_name": row["object_name"],
                "valid_from": row["valid_from"],
                "valid_to": row["valid_to"],
                "attributes": _decode(row["attributes_json"]),
                "source": _source_dict(row),
            }
            next_edges = [*edges, edge]
            if neighbor == target_id:
                shortest_depth = len(next_edges)
                paths.append({"entity_ids": [*entity_ids, neighbor], "relationships": next_edges})
            else:
                queue.append((neighbor, [*entity_ids, neighbor], next_edges))

    return {"paths": paths, "truncated": truncated}
