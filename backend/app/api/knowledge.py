"""Read-only search and graph traversal for source-backed knowledge records."""

from fastapi import APIRouter, HTTPException, Query

from app.core.database import db
from app.services.knowledge_graph import entity_profile, find_paths, search_entities

router = APIRouter(prefix="/api/v1/knowledge", tags=["knowledge"])


@router.get("/search")
def search(
    q: str = Query("", max_length=120),
    entity_type: str | None = Query(None, min_length=1, max_length=40),
    limit: int = Query(30, ge=1, le=100),
):
    if not q.strip():
        return {"query": q, "entities": []}
    with db() as conn:
        entities = search_entities(conn, q.strip(), entity_type, limit)
    return {"query": q, "entities": entities}


@router.get("/entities/{entity_id}")
def get_entity(entity_id: str):
    with db() as conn:
        profile = entity_profile(conn, entity_id)
    if profile is None:
        raise HTTPException(status_code=404, detail="Knowledge entity not found.")
    return profile


@router.get("/paths")
def get_paths(
    from_entity_id: str = Query(..., min_length=1),
    to_entity_id: str = Query(..., min_length=1),
    max_depth: int = Query(4, ge=1, le=6),
):
    with db() as conn:
        result = find_paths(conn, from_entity_id, to_entity_id, max_depth)
    return {
        "from_entity_id": from_entity_id,
        "to_entity_id": to_entity_id,
        "max_depth": max_depth,
        **result,
    }
