import asyncio
from datetime import datetime, timezone

from sqlalchemy import select

from app.core.database import AsyncSessionLocal
from app.models import User, TokenUsageDaily
from app.schemas.assistant import SuggestTranslateIn, SuggestToneIn
from app.services.assistant import AssistantService


TEST_USER_COUNT = 5


async def _get_or_create_user(db, email: str) -> User:
    existing = (await db.execute(select(User).where(User.email == email))).scalar_one_or_none()
    if existing:
        return existing

    user = User(
        email=email,
        password="test_password_hash",
        full_name="Token Test User",
        is_active=True,
        is_deleted=False,
        created_timestamp=datetime.now(timezone.utc),
        updated_timestamp=datetime.now(timezone.utc),
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


async def run():
    async with AsyncSessionLocal() as db:
        users = []
        for i in range(TEST_USER_COUNT):
            email = f"token.test.{i}@example.com"
            users.append(await _get_or_create_user(db, email))

        for user in users:
            user_id = user.id
            try:
                translate_req = SuggestTranslateIn(content="Hello world", target_lang="en")
                translate_req.user_id = user_id
                res = await AssistantService.translate_text(db, translate_req)
                if res.get("status") == "ERROR":
                    print(f"translate failed for user_id={user_id}: {res.get('message')}")
                    await db.rollback()
                    continue
            except Exception as exc:
                print(f"translate exception for user_id={user_id}: {exc}")
                await db.rollback()
                continue

            try:
                polish_req = SuggestToneIn(content="this is a test to polish.", target_tone="polish")
                polish_req.user_id = user_id
                res = await AssistantService.tone_adjustment(db, polish_req)
                if res.get("status") == "ERROR":
                    print(f"polish failed for user_id={user_id}: {res.get('message')}")
                    await db.rollback()
            except Exception as exc:
                print(f"polish exception for user_id={user_id}: {exc}")
                await db.rollback()

        rows = await db.execute(
            select(
                TokenUsageDaily.user_id,
                TokenUsageDaily.source,
                TokenUsageDaily.total_tokens,
                TokenUsageDaily.cost_cents,
            )
            .order_by(TokenUsageDaily.user_id.asc())
        )

        print("Token usage rows:")
        for row in rows.all():
            print(
                f"user_id={row.user_id} source={row.source} "
                f"tokens={row.total_tokens} cost_cents={row.cost_cents}"
            )


if __name__ == "__main__":
    asyncio.run(run())
