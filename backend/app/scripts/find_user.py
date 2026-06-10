import asyncio
from sqlalchemy import select
from app.core.database import AsyncSessionLocal
from app.models import User

async def find_user_by_name(name_query: str):
    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(User).where(User.full_name.ilike(f"%{name_query}%"))
        )
        users = result.scalars().all()
        for u in users:
            print(f"ID: {u.id} | Email: {u.email} | Name: {u.full_name}")

if __name__ == "__main__":
    import sys
    query = sys.argv[1] if len(sys.argv) > 1 else "مهناز"
    asyncio.run(find_user_by_name(query))
