import asyncio
import json
from unittest.mock import AsyncMock, MagicMock
from datetime import datetime
from app.services.learning import LearningService
from app.models.learning_insights import UserLearningInsights

async def dry_run_simulation():
    print("Starting Dry Run Simulation for user asgari@thepersa.com...")
    
    # Mock some corrections from the CSV
    mock_corrections = [
        MagicMock(
            original="If we can set up the meeting soon, I can use the upcoming holidaypush a lot of the operational work ahead.",
            suggestion="If we can set up the meeting soon, I can use the upcoming holiday<wrong>push</wrong><correct>to push</correct> a lot of the operational work ahead.",
            explanation="word form",
            changed=True
        ),
        MagicMock(
            original="I was understanding the project.",
            suggestion="I <wrong>was understanding</wrong><correct>understood</correct> the project.",
            explanation="verb tense, state verbs",
            changed=True
        ),
        MagicMock(
            original="I have a crat meeting.",
            suggestion="I have a <wrong>crat</wrong><correct>great</correct> meeting.",
            explanation="spelling",
            changed=True
        )
    ]

    fake_db = AsyncMock()
    
    # Simulate insights state
    insights = UserLearningInsights(
        user_id=27,
        last_processed_at=datetime(2025, 1, 1),
        misspelled_words={},
        grammar_issues={},
        linguistic_profile=[]
    )
    
    # 1. Test Spelling Extraction
    for corr in mock_corrections:
        spells = LearningService.extract_misspellings(corr.suggestion, corr.explanation)
        if spells:
            print(f"Extracted Spelling: {spells}")
            insights.misspelled_words.update(spells)

    # 2. Test AI Pattern Logic (Mocked)
    print("\nSimulating AI Pattern Extraction...")
    mock_patterns = [
        {
            "structure": "Infinitive of Purpose",
            "observation": "Omits 'to' before verbs expressing purpose (e.g., 'holiday push' instead of 'holiday to push').",
            "impact": "Medium",
            "example_original": "holidaypush a lot of the operational work"
        },
        {
            "structure": "State Verbs",
            "observation": "Uses continuous tense with verbs like 'understand' which don't usually take -ing.",
            "impact": "Medium",
            "example_original": "I was understanding the project"
        }
    ]
    insights.linguistic_profile = mock_patterns
    
    insights.overall_summary = "You have a solid foundation but tend to struggle with verb forms and state verbs. Focus on using 'to' for purpose and avoiding -ing with verbs of understanding."

    print("\n=== SIMULATED OUTPUT FOR ASGARI@THEPERSA.COM ===")
    print(f"User ID: {insights.user_id}")
    print(f"Spelling Issues: {insights.misspelled_words}")
    print(f"Linguistic Profile: {json.dumps(insights.linguistic_profile, indent=2)}")
    print(f"AI Summary: {insights.overall_summary}")

if __name__ == "__main__":
    asyncio.run(dry_run_simulation())
