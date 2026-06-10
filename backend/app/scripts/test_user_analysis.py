import asyncio
import json
from sqlalchemy import select
from app.core.database import AsyncSessionLocal
from app.models.user import User
from app.services.learning import LearningService

async def test_real_analysis():
    async with AsyncSessionLocal() as db:
        # Find user by email
        result = await db.execute(select(User).where(User.email == "asgari@thepersa.com"))
        user = result.scalar_one_or_none()
        
        if not user:
            print("User asgari@thepersa.com not found in DB.")
            return

        print(f"Found User ID: {user.id}. Running analysis...")
        
        # Run the analysis service
        insights = await LearningService.analyze_user_progress(db, user.id)
        
        print("\n=== LEARNING INSIGHTS ANALYSIS ===")
        print(f"Last Processed: {insights.last_processed_at}")
        print("\n--- Top Grammar Issues ---")
        print(json.dumps(insights.grammar_issues, indent=2))
        
        print("\n--- Misspelled Words ---")
        print(json.dumps(insights.misspelled_words, indent=2))
        
        print("\n--- Deep Linguistic Profile ---")
        print(json.dumps(insights.linguistic_profile, indent=2))
        
        print("\n--- AI Summary ---")
        print(insights.overall_summary)

if __name__ == "__main__":
    asyncio.run(test_real_analysis())
