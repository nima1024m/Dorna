import asyncio
from pathlib import Path

from app.core.database import engine, Base
from app.services.news import parse_topics_csv, sync_topics_from_csv
import app.models  # noqa: F401


async def main():
    csv_path = Path("Newstopics.csv")
    if not csv_path.exists():
        raise SystemExit("Newstopics.csv not found")

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    rows = parse_topics_csv(str(csv_path))
    from sqlalchemy.ext.asyncio import AsyncSession
    from sqlalchemy.ext.asyncio import async_sessionmaker

    session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with session() as db:
        inserted, updated = await sync_topics_from_csv(db, rows)
        print(f"CSV sync completed: inserted={inserted} updated={updated} total={len(rows)}")


if __name__ == "__main__":
    asyncio.run(main())
