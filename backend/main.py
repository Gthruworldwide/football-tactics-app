from fastapi import FastAPI
from sync_router import router as sync_router

app = FastAPI(title="Football Tactics Analytics API")
app.include_router(sync_router)

@app.get("/")
def root():
    return {"status": "online", "service": "Football Tactics Analytics API"}
