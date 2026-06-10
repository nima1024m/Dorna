import asyncio
import os
import sys

# Add parent directory to sys.path to allow imports from app
sys.path.append(os.getcwd())

from app.core.database import AsyncSessionLocal
from app.services.learning import LearningExperienceService

async def send_email_for_mahnaz():
    user_id = 55
    print(f"--- STARTING EMAIL GENERATION FOR USER ID: {user_id} (Mahnaz Sohrabi) ---")
    
    async with AsyncSessionLocal() as db:
        try:
            await LearningExperienceService.send_personalized_learning_email(db, user_id)
            print(f"✅ Successfully generated and sent personalized email to Mahnaz Sohrabi.")
        except Exception as e:
            print(f"❌ Error during email service execution: {e}")

if __name__ == "__main__":
    asyncio.run(send_email_for_mahnaz())
