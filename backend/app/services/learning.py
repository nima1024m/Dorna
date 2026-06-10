import re
from datetime import datetime, timezone
from typing import List, Dict, Set, Optional
from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.learning_insights import UserLearningInsights
from app.models.grammar_suggestions import GrammarSuggestion
from app.models.grammar_corrections import GrammarCorrection
from app.models.user import User
from app.core.agents.gemini import GeminiAgent
from app.core.email.brevo import send_html_email
from app.services.token_usage import TokenUsageService

class MistakeTrackerService:
    @staticmethod
    async def get_or_create_insights(db: AsyncSession, user_id: int) -> UserLearningInsights:
        result = await db.execute(
            select(UserLearningInsights).where(UserLearningInsights.user_id == user_id)
        )
        insights = result.scalar_one_or_none()
        if not insights:
            insights = UserLearningInsights(user_id=user_id, last_processed_at=datetime.min.replace(tzinfo=timezone.utc))
            db.add(insights)
            await db.commit()
            await db.refresh(insights)
        return insights

    @staticmethod
    def parse_mistakes(corrected_text: str) -> List[Dict[str, str]]:
        """Extracts <wrong>/<correct> pairs."""
        pattern = r"<wrong>(.*?)</wrong><correct>(.*?)</correct>"
        matches = re.finditer(pattern, corrected_text)
        return [{"wrong": m.group(1), "correct": m.group(2)} for m in matches]

    @staticmethod
    async def process_user_mistakes(db: AsyncSession, user_id: int) -> UserLearningInsights:
        """Processes new grammar-correction events and updates the user profile."""
        insights = await MistakeTrackerService.get_or_create_insights(db, user_id)
        
        # 1. Fetch new events since last_processed_at
        query = (
            select(GrammarCorrection, GrammarSuggestion.created_timestamp)
            .join(GrammarSuggestion, GrammarSuggestion.id == GrammarCorrection.grammar_id)
            .where(
                and_(
                    GrammarSuggestion.user_id == user_id,
                    GrammarSuggestion.created_timestamp > insights.last_processed_at,
                    GrammarCorrection.changed == True
                )
            )
            .order_by(GrammarSuggestion.created_timestamp.asc())
        )
        
        result = await db.execute(query)
        new_events = result.all()
        
        if not new_events:
            return insights

        current_misspelled = dict(insights.misspelled_words or {})
        current_grammar = dict(insights.grammar_issues or {})
        processed_keys: Set[str] = set()
        
        has_new_data = False
        # Ensure latest_ts is timezone-aware for comparison
        latest_ts = insights.last_processed_at
        if latest_ts.tzinfo is None:
            latest_ts = latest_ts.replace(tzinfo=timezone.utc)
        
        # Track new potential misspellings to be vetted by AI
        new_potential_misspellings: Dict[str, str] = {}

        for corr, timestamp in new_events:
            # Idempotency/Deduplication check
            event_key = f"{corr.original}_{timestamp.isoformat()}"
            if event_key in processed_keys:
                continue
            processed_keys.add(event_key)
            has_new_data = True
            
            # Map categories
            categories = [t.strip().lower() for t in (corr.explanation or "general").split(",")]
            mistakes = MistakeTrackerService.parse_mistakes(corr.suggestion)

            EXCLUDED_SLANG = {"u": "you", "r": "are", "ur": "your", "y": "why", "n": "and"}
            for m in mistakes:
                wrong = m["wrong"].strip().lower()
                correct = m["correct"].strip().lower()
                
                # Update aggregated stats
                if any(c in ["spelling", "typo", "misspell"] for c in categories):
                    # 1. Skip single-letter abbreviations/slang
                    if EXCLUDED_SLANG.get(wrong) == correct or wrong in EXCLUDED_SLANG:
                        continue
                    
                    # 2. Skip minor one-letter missing typos (e.g., abou -> about)
                    if len(correct) > 3:
                        diff_len = abs(len(wrong) - len(correct))
                        if diff_len <= 1 and wrong in correct:
                            continue

                    if len(wrong.split()) == 1: # Only single word misspellings
                        new_potential_misspellings[wrong] = correct
                
                for cat in categories:
                    if cat not in ["spelling", "typo", "misspell"]:
                        current_grammar[cat] = current_grammar.get(cat, 0) + 1
            
            if timestamp > latest_ts:
                latest_ts = timestamp

        if has_new_data:
            # Trigger AI analysis for deep patterns/summary if needed
            # (Keeping the AI logic integrated as per previous requirements)
            agent = GeminiAgent()
            
            # Sample of recent corrections for pattern analysis
            pattern_data = [
                {"original": c.original, "corrected": c.suggestion, "explanation": c.explanation}
                for c, ts in new_events[-20:]
            ]
            
            try:
                if pattern_data:
                    pattern_res = await agent.extract_linguistic_patterns(pattern_data)
                    if isinstance(pattern_res, dict) and pattern_res.get("_usage"):
                        await TokenUsageService.record_usage(
                            db,
                            user_id=user_id,
                            source="gemini",
                            model_name=pattern_res["_usage"].get("model"),
                            prompt_tokens=pattern_res["_usage"].get("prompt_tokens", 0),
                            completion_tokens=pattern_res["_usage"].get("completion_tokens", 0),
                            total_tokens=pattern_res["_usage"].get("total_tokens", 0),
                        )
                    insights.estimated_clb_level = pattern_res.get("estimated_clb_level", "CLB 5")
                    insights.linguistic_profile = pattern_res.get("patterns", [])
                    insights.language_development_grammar = pattern_res.get("language_development_grammar", [])
                    insights.vocabulary_improvement = pattern_res.get("vocabulary_improvement", [])
                    
                    # AI-vetted misspellings (filtering noise like keyboard slips)
                    # We only add misspellings that the AI confirms as genuine patterns
                    ai_words_list = pattern_res.get("misspelled_words", [])
                    ai_words = {item["word"]: item["correction"] for item in ai_words_list if "word" in item}
                    
                    # Merge AI confirmed words into history
                    current_misspelled.update(ai_words)

                    # If the AI returned a summary in this JSON, we can use it
                    if pattern_res.get("summary"):
                        insights.overall_summary = pattern_res.get("summary")
                    else:
                        # Fallback
                        top_grammar = dict(sorted(current_grammar.items(), key=lambda x: x[1], reverse=True)[:10])
                        # Pass only AI-vetted words for the summary
                        ai_res = await agent.user_learning_summary(top_grammar, ai_words)
                        insights.overall_summary = ai_res.get("summary")
                        if isinstance(ai_res, dict) and ai_res.get("_usage"):
                            await TokenUsageService.record_usage(
                                db,
                                user_id=user_id,
                                source="gemini",
                                model_name=ai_res["_usage"].get("model"),
                                prompt_tokens=ai_res["_usage"].get("prompt_tokens", 0),
                                completion_tokens=ai_res["_usage"].get("completion_tokens", 0),
                                total_tokens=ai_res["_usage"].get("total_tokens", 0),
                            )
            except Exception:
                if not insights.overall_summary:
                    insights.overall_summary = "Learning profile in progress..."

            insights.last_processed_at = latest_ts
            insights.misspelled_words = current_misspelled
            insights.grammar_issues = current_grammar
            
            await db.commit()
            await db.refresh(insights)

        return insights

    @staticmethod
    async def get_insights_by_email(db: AsyncSession, email: str) -> Optional[UserLearningInsights]:
        """Retrieves insights for a user by their email."""
        user_result = await db.execute(select(User).where(User.email == email))
        user = user_result.scalar_one_or_none()
        if not user:
            return None
            
        result = await db.execute(
            select(UserLearningInsights).where(UserLearningInsights.user_id == user.id)
        )
        return result.scalar_one_or_none()

class LearningExperienceService:
    @staticmethod
    async def get_personalized_profile(db: AsyncSession, user_id: int) -> Dict:
        """
        Retrieves and prepares the final user-facing Learning Profile.
        This is the INTERPRETED layer for content generation.
        """
        # Ensure data is up to date
        insights = await MistakeTrackerService.process_user_mistakes(db, user_id)
        
        # Return ONLY the fields needed for the Learning Layer
        return {
            "estimated_clb_level": insights.estimated_clb_level or "CLB 5",
            "misspelled_words": insights.misspelled_words,
            "linguistic_profile": insights.linguistic_profile,
            "language_development_grammar": insights.language_development_grammar,
            "vocabulary_improvement": insights.vocabulary_improvement,
            "overall_summary": insights.overall_summary or "Ready to start your learning journey!",
            "last_reviewed_at": insights.last_processed_at or datetime.now(timezone.utc)
        }

    @staticmethod
    async def send_personalized_learning_email(db: AsyncSession, user_id: int) -> bool:
        """
        Generates a premium HTML email using Gemini based on the user's profile and sends it.
        """
        # 1. Get the profile
        profile = await LearningExperienceService.get_personalized_profile(db, user_id)
        
        # 2. Get user email
        user_result = await db.execute(select(User).where(User.id == user_id))
        user = user_result.scalar_one_or_none()
        if not user or not user.email:
            return False

        # 3. Generate email content via Gemini
        agent = GeminiAgent()
        email_data = await agent.generate_learning_email_content(
            profile, 
            user_name=user.full_name or "Dorna Achiever"
        )
        if isinstance(email_data, dict) and email_data.get("_usage"):
            await TokenUsageService.record_usage(
                db,
                user_id=user_id,
                source="gemini",
                model_name=email_data["_usage"].get("model"),
                prompt_tokens=email_data["_usage"].get("prompt_tokens", 0),
                completion_tokens=email_data["_usage"].get("completion_tokens", 0),
                total_tokens=email_data["_usage"].get("total_tokens", 0),
            )
        
        # 4. Send via Brevo
        send_html_email(
            to_email=user.email,
            subject=email_data["subject"],
            html_content=email_data["html_content"]
        )
        
        return True
