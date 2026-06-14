"""Initialize database with admin account."""

import asyncio
from app.database import engine, AsyncSessionLocal, Base
from app.models.user import User, generate_user_id
from app.services.auth import hash_password
from app.config import settings


async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with AsyncSessionLocal() as session:
        from sqlalchemy import select
        result = await session.execute(
            select(User).where(User.is_admin == True)
        )
        if not result.scalar_one_or_none():
            admin = User(
                user_id=generate_user_id(),
                phone="admin",
                country_code="+86",
                is_admin=True,
                hashed_password=hash_password(settings.ADMIN_PASSWORD),
            )
            session.add(admin)
            await session.commit()
            print(f"Admin user created: {settings.ADMIN_USERNAME}")

    print("Database initialized successfully")


if __name__ == "__main__":
    asyncio.run(init_db())
