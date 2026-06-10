import asyncio

from sqlalchemy import select

from app.core.database import AsyncSessionLocal
from app.models import TokenUsageDaily
from app.services.token_usage import TokenUsageService


async def run():
    async with AsyncSessionLocal() as db:
        rows = await db.execute(select(TokenUsageDaily))
        items = rows.scalars().all()

        for item in items:
            item.cost_cents = TokenUsageService._estimate_cost_cents_by_model(
                item.model_name,
                item.prompt_tokens or 0,
                item.completion_tokens or 0,
            ) or TokenUsageService._estimate_cost_cents(item.source, item.total_tokens or 0)

        await db.commit()
        print(f"Backfilled {len(items)} token usage rows.")


if __name__ == "__main__":
    asyncio.run(run())
