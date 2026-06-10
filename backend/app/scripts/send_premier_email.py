import asyncio
import os
import sys
import json
from datetime import datetime

# Add parent directory to sys.path to allow imports from app
sys.path.append(os.getcwd())

from app.core.agents.gemini import GeminiAgent
from app.core.email.brevo import send_html_email

async def send_premier_update(to_email: str):
    print(f"--- PREPARING PREMIER LEARNING UPDATE FOR {to_email} ---")
    
    # We use the vetted analysis data from our Mahnaz study as the standard for this "First Send"
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
            {"current": "Keyboard", "target": "Input device"},
            {"current": "available", "target": "accessible"},
            {"current": "3-daysjob", "target": "three-day assignment"},
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
            {"current": "good", "target": "effective"}
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
        "misspelled_words": [
            {"word": "cance", "correction": "cancellation"},
            {"word": "daysjob", "correction": "day job"}
        ],
        "overall_summary": "Your profile demonstrates a solid CLB 7 foundation. By adopting these 30 strategic vocabulary replacements and focusing on advanced tense usage, you will immediately project a highly professional CLB 8+ presence.",
        "last_reviewed_at": datetime.now().isoformat()
    }

    agent = GeminiAgent()
    try:
        # Generate the premium HTML content via Gemini
        email_content = await agent.generate_learning_email_content(profile_data, user_name="Hossein Asgari")
        
        # Send via Brevo
        send_html_email(
            to_email=to_email,
            subject=email_content["subject"],
            html_content=email_content["html_content"]
        )
        print(f"✅ Successfully sent to {to_email}")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    asyncio.run(send_premier_update("asgari.business@gmail.com"))
