from fastapi import APIRouter

router = APIRouter(prefix="/api/v1", tags=["players"])

@router.get("/players/{player_id}", tags=["players"])
async def get_player_stats(player_id: int, season: str = "2026") -> dict:
    """Get player statistics combined with tactical role evaluation."""
    return {
        "player_id": player_id,
        "season": season,
        "tactical_analysis": {
            "role_classification": "Ball-Playing Defender",
            "strengths": ["High pass completion under pressure", "Aerial dominance"],
            "areas_for_improvement": ["Recovery speed against counter-attacks"],
        },
    }