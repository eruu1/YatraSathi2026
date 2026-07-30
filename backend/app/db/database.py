"""
Database connection and session management.
"""
from sqlalchemy import create_engine, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from backend.app.config.settings import settings

# Create database engine
engine = create_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
)

# Register pgvector type adapter so SQLAlchemy can read/write Vector columns.
# Must happen after engine creation, before any ORM session uses the engine.
try:
    from pgvector.sqlalchemy import Vector  # noqa: F401 — triggers adapter registration
    import pgvector
    # register_vector is available in pgvector >= 0.1.8
    if hasattr(pgvector, "psycopg2"):
        # older API
        from pgvector.psycopg2 import register_vector
        with engine.connect() as _conn:
            register_vector(_conn.connection)
    # For newer pgvector releases the Vector() column type self-registers
    # when imported; no explicit call needed.
except Exception as _e:
    print(f"[db] pgvector registration warning (non-fatal): {_e}")

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base class for models
Base = declarative_base()


def get_db() -> Session:
    """Dependency for getting database sessions."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def _ensure_pgvector_extension() -> None:
    """Create the pgvector extension in Postgres if it does not already exist."""
    try:
        with engine.connect() as conn:
            conn.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
            conn.commit()
    except Exception as e:
        print(f"[db] Could not create pgvector extension (non-fatal): {e}")


def _create_tables_individually() -> None:
    """
    Fall-back: attempt to CREATE each table independently so that a failure
    on one (e.g. embeddings needing pgvector) does not block the rest.
    """
    for table in Base.metadata.sorted_tables:
        try:
            table.create(bind=engine, checkfirst=True)
        except Exception as e:
            print(f"[db] Could not create table '{table.name}' (non-fatal): {e}")


def init_db() -> None:
    """
    Initialize database tables.

    Ensures the pgvector extension exists first so the `vector` column type
    is recognised by Postgres before CREATE TABLE is issued.
    """
    _ensure_pgvector_extension()

    from backend.app.models import (  # noqa: F401 — side-effect imports register models
        user,
        itinerary,
        session as session_model,
        place,
        embedding,
        workspace,
        saved_place,
    )
    try:
        Base.metadata.create_all(bind=engine)
    except Exception as e:
        print(f"[db] Table creation warning (non-fatal): {e}")
        # create_all may fail on the embeddings (vector) table if pgvector is
        # not installed.  Create the remaining tables individually so that
        # tables like saved_places are never skipped.
        _create_tables_individually()


# Aliases for ETL compatibility
def init_database() -> None:
    init_db()


def create_tables() -> None:
    init_db()
