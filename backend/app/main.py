"""FastAPI entry point for the Football Tactics Analytics Engine."""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import knowledge, sync, tactics, v1
from app.core.config import settings
from app.core.database import init_db


@asynccontextmanager
async def lifespan(_: FastAPI):
    init_db()
    yield


app = FastAPI(
    title="Football Tactics Analytics Engine",
    description="Minimalist SPA backend for football analysts and tacticians",
    version="1.0.0",
    lifespan=lifespan,
)

origins = settings.cors_origins_list
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials="*" not in origins,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(v1.router)
app.include_router(knowledge.router)
app.include_router(tactics.router)
app.include_router(sync.router)


@app.get("/", tags=["health"])
def root():
    return {"status": "online", "service": "Football Tactics Analytics API"}


@app.get("/health", tags=["health"])
async def health():
    return {"status": "healthy"}
