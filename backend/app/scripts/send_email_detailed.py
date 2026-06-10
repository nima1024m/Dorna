import asyncio
import os
import sys

sys.path.append(os.getcwd())

from app.core.database import AsyncSessionLocal
from app.services.learning import LearningExperienceService, MistakeTrackerService
from app.core.agents.gemini import GeminiAgent
from app.core.email.brevo import send_html_email
from sqlalchemy import select
from app.models import User

async def send_email_step_by_step():
    user_id = 55
    print("=" * 80)
    print(f"STARTING PERSONALIZED EMAIL GENERATION FOR USER ID: {user_id}")
    print("=" * 80)
    
    async with AsyncSessionLocal() as db:
        # Step 1: Get user info
        print("\n[STEP 1] Fetching user information...")
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        
        if not user:
            print(f"❌ User with ID {user_id} not found!")
            return
            
        print(f"✅ Found user: {user.full_name or 'No Name'} ({user.email})")
        
        # Step 2: Process mistakes and generate insights
        print("\n[STEP 2] Processing user mistakes and generating linguistic insights...")
        try:
            insights = await MistakeTrackerService.process_user_mistakes(db, user_id)
            print(f"✅ Insights generated successfully")
            print(f"   - CLB Level: {insights.estimated_clb_level}")
            print(f"   - Grammar Issues: {len(insights.grammar_issues)} patterns")
            print(f"   - Vocabulary Suggestions: {len(insights.vocabulary_improvement)} words")
        except Exception as e:
            print(f"⚠️  Error processing mistakes: {e}")
            print("   Continuing with existing insights...")
        
        # Step 3: Get personalized learning profile
        print("\n[STEP 3] Building personalized learning profile...")
        try:
            profile = await LearningExperienceService.get_personalized_profile(db, user_id)
            print(f"✅ Profile built successfully")
            print(f"   - Estimated CLB: {profile.get('estimated_clb_level', 'N/A')}")
            print(f"   - Power Words: {len(profile.get('vocabulary_improvement', []))}")
        except Exception as e:
            print(f"❌ Error building profile: {e}")
            return
        
        # Step 4: Generate email content via Gemini
        print("\n[STEP 4] Generating premium email content via Gemini AI...")
        try:
            agent = GeminiAgent()
            email_data = await agent.generate_learning_email_content(
                profile, 
                user_name=user.full_name or "Dorna Achiever"
            )
            print(f"✅ Email content generated")
            print(f"   - Subject: {email_data['subject'][:60]}...")
            print(f"   - HTML Length: {len(email_data['html_content'])} characters")
        except Exception as e:
            print(f"❌ Error generating email: {e}")
            return
        
        # Step 5: Send email via Brevo
        print("\n[STEP 5] Sending email via Brevo...")
        try:
            send_html_email(
                to_email=user.email,
                subject=email_data["subject"],
                html_content=email_data["html_content"]
            )
            print(f"✅ Email sent successfully to {user.email}")
        except Exception as e:
            print(f"❌ Error sending email: {e}")
            return
    
    print("\n" + "=" * 80)
    print("✅ PROCESS COMPLETED SUCCESSFULLY!")
    print("=" * 80)

if __name__ == "__main__":
    asyncio.run(send_email_step_by_step())
