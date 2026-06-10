import asyncio
import os
import sys
from datetime import datetime

sys.path.append(os.getcwd())

from app.core.agents.gemini import GeminiAgent
from app.core.email.brevo import send_html_email

async def send_email_with_mock_data():
    print("=" * 80)
    print("SENDING PERSONALIZED EMAIL FOR MAHNAZ SOHRABI")
    print("=" * 80)
    
    # User info from the CSV data we have
    user_email = "aveeje@gmail.com"
    user_name = "Mahnaz Sohrabi"
    
    # Mock learning profile based on typical user data
    # This would normally come from the database
    profile_data = {
        "estimated_clb_level": "CLB 7",
        "vocabulary_improvement": [
            {"current": "Hey team", "target": "Dear Colleagues"},
            {"current": "job", "target": "assignment"},
            {"current": "starting on", "target": "commencing on"},
            {"current": "cancellation", "target": "rescheduling"},
            {"current": "have", "target": "possess"},
            {"current": "for", "target": "regarding"},
            {"current": "i", "target": "I"},
            {"current": "Jan", "target": "January"},
            {"current": "3-day", "target": "three-day"},
            {"current": "cante", "target": "cancellation"},
            {"current": "Hii", "target": "Hello"},
            {"current": "having", "target": "experiencing"},
            {"current": "further", "target": "additional"},
            {"current": "specific", "target": "particular"},
            {"current": "available", "target": "accessible"},
            {"current": "check", "target": "verify"},
            {"current": "tell", "target": "inform"},
            {"current": "ask", "target": "inquire"},
            {"current": "give", "target": "provide"},
            {"current": "make", "target": "create"},
            {"current": "do", "target": "execute"},
            {"current": "go", "target": "proceed"},
            {"current": "see", "target": "observe"},
            {"current": "help", "target": "assist"},
            {"current": "fix", "target": "rectify"},
            {"current": "problem", "target": "issue"},
            {"current": "important", "target": "critical"},
            {"current": "good", "target": "effective"},
            {"current": "need", "target": "require"},
            {"current": "want", "target": "desire"}
        ],
        "language_development_grammar": [
            {
                "topic": "Future Perfect Continuous Tense",
                "rationale": "To express actions that will continue up until a certain point in the future, projecting professional precision."
            },
            {
                "topic": "Modal Verbs for Speculation",
                "rationale": "To convey degrees of certainty and possibility, enhancing nuanced professional communication."
            }
        ],
        "overall_summary": "Your profile demonstrates a solid CLB 7 foundation. By adopting these 30 strategic vocabulary replacements and focusing on advanced tense usage, you will immediately project a highly professional CLB 8+ presence.",
        "last_reviewed_at": datetime.now().isoformat()
    }
    
    print(f"\n[STEP 1] User Information:")
    print(f"   - Name: {user_name}")
    print(f"   - Email: {user_email}")
    print(f"   - CLB Level: {profile_data['estimated_clb_level']}")
    
    print(f"\n[STEP 2] Generating email content via Gemini AI...")
    try:
        agent = GeminiAgent()
        email_data = await agent.generate_learning_email_content(
            profile_data, 
            user_name=user_name
        )
        print(f"✅ Email content generated successfully")
        print(f"   - Subject: {email_data['subject']}")
        print(f"   - HTML Length: {len(email_data['html_content'])} characters")
    except Exception as e:
        print(f"❌ Error generating email: {e}")
        import traceback
        traceback.print_exc()
        return
    
    print(f"\n[STEP 3] Sending email via Brevo...")
    try:
        send_html_email(
            to_email=user_email,
            subject=email_data["subject"],
            html_content=email_data["html_content"]
        )
        print(f"✅ Email sent successfully to {user_email}")
    except Exception as e:
        print(f"❌ Error sending email: {e}")
        import traceback
        traceback.print_exc()
        return
    
    print("\n" + "=" * 80)
    print("✅ PROCESS COMPLETED SUCCESSFULLY!")
    print("=" * 80)

if __name__ == "__main__":
    asyncio.run(send_email_with_mock_data())
