import asyncio
import secrets
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.core.database import engine
from app.core.security import hash_password
from apps.admin.models.admin_user import AdminUser, AdminRole
import app.models  # noqa: F401
import apps.admin.models  # noqa: F401


async def main():
    # Schema is owned by Alembic — run `alembic upgrade head` before seeding.
    # (Previously this script called Base.metadata.create_all, which bypassed
    # migrations and was a source of schema drift.)

    email = "admin@dorna.local"
    password = f"DornaAdmin-{secrets.token_hex(4)}"

    session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with session() as db:
        existing = await db.execute(select(AdminUser).where(AdminUser.email == email))
        admin = existing.scalar_one_or_none()
        if admin:
            print(f"Admin already exists: {email}")
            return

        admin = AdminUser(
            email=email,
            password_hash=hash_password(password),
            full_name="Dorna Admin",
            role=AdminRole.SUPER_ADMIN.value,
            is_active=True,
            is_locked=False,
            password_changed_at=datetime.now(timezone.utc),
        )
        db.add(admin)
        await db.commit()

    print("Admin created")
    print(f"Email: {email}")
    print(f"Password: {password}")


if __name__ == "__main__":
    asyncio.run(main())
