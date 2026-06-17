"""Topic & Content management service."""
from __future__ import annotations
from typing import Optional, List, Tuple, Dict, Any
from datetime import datetime

from sqlalchemy import select, update, func, delete
from sqlalchemy.ext.asyncio import AsyncSession

import json
import httpx
from google.genai import types

from app.core.config import settings
from app.core.agents.genai_client import make_genai_client
from app.models import NewsTopic, NewsItem, TopicPodcastScript, TopicArticle
from app.services.token_usage import TokenUsageService


class TopicManagementService:
    """Service for managing news topics and content."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    # ==========================================
    # TOPIC LISTING
    # ==========================================
    
    async def list_topics(
        self,
        page: int = 1,
        page_size: int = 20,
        search: Optional[str] = None,
        is_active: Optional[bool] = None,
        category: Optional[str] = None,
        geo_code: Optional[str] = None,
        language: Optional[str] = None,
        sort_by: str = "priority",
        sort_order: str = "desc",
    ) -> Tuple[List[NewsTopic], int]:
        """List topics with filtering."""
        
        query = select(NewsTopic)
        
        # Search
        if search:
            pattern = f"%{search}%"
            query = query.where(
                NewsTopic.title.ilike(pattern) | 
                NewsTopic.description.ilike(pattern) |
                NewsTopic.topic_id.ilike(pattern)
            )
        
        # Filters
        if is_active is not None:
            query = query.where(NewsTopic.is_active == is_active)
        
        if language:
            query = query.where(NewsTopic.language == language)
        
        if geo_code:
            # JSON array contains
            query = query.where(NewsTopic.geo_codes.contains([geo_code]))
        
        if category:
            query = query.where(NewsTopic.tags.contains([category]))
        
        # Count
        count_query = select(func.count()).select_from(query.subquery())
        total = await self.db.scalar(count_query) or 0
        
        # Sort
        sort_col = getattr(NewsTopic, sort_by, NewsTopic.priority)
        query = query.order_by(sort_col.desc() if sort_order == "desc" else sort_col.asc())
        
        # Paginate
        offset = (page - 1) * page_size
        query = query.offset(offset).limit(page_size)
        
        result = await self.db.execute(query)
        topics = list(result.scalars().all())
        
        return topics, total
    
    async def get_topic_by_id(self, topic_id: str) -> Optional[NewsTopic]:
        """Get a single topic."""
        result = await self.db.execute(
            select(NewsTopic).where(NewsTopic.topic_id == topic_id)
        )
        return result.scalar_one_or_none()
    
    # ==========================================
    # TOPIC CRUD
    # ==========================================
    
    async def create_topic(self, data: dict) -> NewsTopic:
        """Create a new topic."""
        topic = NewsTopic(
            topic_id=data["topic_id"],
            title=data["title"],
            description=data.get("description"),
            ai_search_prompt=data["ai_search_prompt"],
            tags=data.get("tags", []),
            geo_codes=data.get("geo_codes", []),
            update_minutes=data.get("update_minutes", 60),
            is_active=data.get("is_active", True),
            priority=data.get("priority", 0),
            language=data.get("language"),
        )
        self.db.add(topic)
        await self.db.commit()
        await self.db.refresh(topic)
        return topic
    
    async def update_topic(self, topic_id: str, updates: dict) -> Optional[NewsTopic]:
        """Update a topic."""
        allowed_fields = {
            "title", "description", "ai_search_prompt", "tags", 
            "geo_codes", "update_minutes", "is_active", "priority", "language"
        }
        safe_updates = {k: v for k, v in updates.items() if k in allowed_fields and v is not None}
        
        if not safe_updates:
            return await self.get_topic_by_id(topic_id)
        
        await self.db.execute(
            update(NewsTopic).where(NewsTopic.topic_id == topic_id).values(**safe_updates)
        )
        await self.db.commit()
        
        return await self.get_topic_by_id(topic_id)
    
    async def delete_topic(self, topic_id: str) -> bool:
        """Delete a topic and its news items."""
        # Delete news items first
        await self.db.execute(
            delete(NewsItem).where(NewsItem.topic_id == topic_id)
        )
        
        # Delete topic
        result = await self.db.execute(
            delete(NewsTopic).where(NewsTopic.topic_id == topic_id)
        )
        await self.db.commit()
        
        return result.rowcount > 0
    
    async def activate_topic(self, topic_id: str) -> bool:
        """Activate a topic."""
        await self.db.execute(
            update(NewsTopic).where(NewsTopic.topic_id == topic_id).values(is_active=True)
        )
        await self.db.commit()
        return True
    
    async def deactivate_topic(self, topic_id: str) -> bool:
        """Deactivate a topic."""
        await self.db.execute(
            update(NewsTopic).where(NewsTopic.topic_id == topic_id).values(is_active=False)
        )
        await self.db.commit()
        return True
    
    # ==========================================
    # REFERENCE DATA
    # ==========================================
    
    async def get_all_tags(self) -> List[dict]:
        """Get all unique tags with counts."""
        # This is a simplified version - in production, you'd use proper JSON aggregation
        result = await self.db.execute(select(NewsTopic.tags))
        all_tags = {}
        for row in result.scalars().all():
            for tag in (row or []):
                all_tags[tag] = all_tags.get(tag, 0) + 1
        
        return [{"tag": k, "count": v} for k, v in sorted(all_tags.items(), key=lambda x: -x[1])]
    
    async def get_all_geo_codes(self) -> List[dict]:
        """Get all unique geo codes."""
        # Predefined geo codes
        geo_codes = [
            {"code": "US", "name": "United States", "country": "US"},
            {"code": "CA", "name": "Canada", "country": "CA"},
            {"code": "BC", "name": "British Columbia", "country": "CA"},
            {"code": "ON", "name": "Ontario", "country": "CA"},
            {"code": "AB", "name": "Alberta", "country": "CA"},
            {"code": "QC", "name": "Quebec", "country": "CA"},
            {"code": "UK", "name": "United Kingdom", "country": "UK"},
            {"code": "AU", "name": "Australia", "country": "AU"},
        ]
        return geo_codes
    
    async def get_all_languages(self) -> List[str]:
        """Get all unique languages."""
        result = await self.db.execute(
            select(NewsTopic.language).distinct().where(NewsTopic.language.isnot(None))
        )
        return [lang for lang in result.scalars().all() if lang]
    
    async def get_news_item_count(self, topic_id: str) -> int:
        """Get count of news items for a topic."""
        count = await self.db.scalar(
            select(func.count()).select_from(NewsItem).where(NewsItem.topic_id == topic_id)
        )
        return count or 0

    async def get_podcast_status_map(self, topic_ids: List[str]) -> Dict[str, TopicPodcastScript]:
        if not topic_ids:
            return {}
        result = await self.db.execute(
            select(TopicPodcastScript).where(TopicPodcastScript.topic_id.in_(topic_ids))
        )
        records = result.scalars().all()
        return {r.topic_id: r for r in records}

    async def get_article_status_map(self, topic_ids: List[str]) -> Dict[str, TopicArticle]:
        if not topic_ids:
            return {}
        result = await self.db.execute(
            select(TopicArticle)
            .where(TopicArticle.topic_id.in_(topic_ids))
            .order_by(TopicArticle.topic_id, TopicArticle.published_at.desc())
        )
        records = result.scalars().all()
        latest = {}
        for r in records:
            if r.topic_id not in latest:
                latest[r.topic_id] = r
        return latest

    # ==========================================
    # PODCAST SCRIPT (ADMIN)
    # ==========================================

    async def get_topic_podcast(self, topic_id: str) -> Optional[TopicPodcastScript]:
        result = await self.db.execute(
            select(TopicPodcastScript).where(TopicPodcastScript.topic_id == topic_id)
        )
        return result.scalar_one_or_none()

    async def generate_topic_podcast(self, topic_id: str) -> TopicPodcastScript:
        topic = await self.get_topic_by_id(topic_id)
        if not topic:
            raise ValueError("Topic not found")

        prompt = f"""
          You are a podcast producer for a news show hosted by Alex (energetic, curious) and Sarah (calm, analytical).

          TASK: Search for the top 3 REAL breaking news stories about "{topic.title}" from the last 24-48 hours.

          Then create a natural podcast dialogue (6-8 turns) between Alex and Sarah discussing these news stories.

          STRUCTURE:
          1. Alex: Hook with the most exciting news headline
          2. Sarah: Provide key facts and context
          3. Alex: React with enthusiasm or surprise
          4. Sarah: Deep dive into implications
          5. Alex: Ask about real-world impact
          6. Sarah: Explain the broader context
          7. Alex: Mention another related story
          8. Sarah: Wrap up with final insights

          CRITICAL REQUIREMENTS:
          - Base the dialogue ONLY on real news from your search
          - Make it conversational and natural
          - Alex should be energetic and ask questions
          - Sarah should be calm and provide analysis
          - Keep each turn 2-4 sentences max

          Output JSON in this exact structure:
          {{
            "script": [
              {{ "speaker": "Alex", "text": "..." }},
              {{ "speaker": "Sarah", "text": "..." }}
            ]
          }}
        """

        client = make_genai_client(force_direct=True)  # Google Search grounding — gateway can't proxy it

        try:
            content = types.Content(parts=[types.Part(text=prompt)])
            response = client.models.generate_content(
                model="gemini-3-flash-preview",
                contents=content,
                config=types.GenerateContentConfig(
                    tools=[types.Tool(google_search=types.GoogleSearch())],
                    response_mime_type="application/json",
                    response_schema={
                        "type": "OBJECT",
                        "properties": {
                            "script": {
                                "type": "ARRAY",
                                "items": {
                                    "type": "OBJECT",
                                    "properties": {
                                        "speaker": {"type": "STRING"},
                                        "text": {"type": "STRING"}
                                    }
                                }
                            }
                        }
                    }
                )
            )

            data = json.loads(response.text)
            script = data.get("script", [])

            sources = []
            if response.candidates and response.candidates[0].grounding_metadata:
                chunks = response.candidates[0].grounding_metadata.grounding_chunks or []
                for c in chunks:
                    if c.web and c.web.uri and c.web.title:
                        sources.append({"title": c.web.title, "url": c.web.uri})

            unique_sources = list({s["url"]: s for s in sources}.values())

            existing = await self.get_topic_podcast(topic_id)
            if existing:
                existing.status = "READY"
                existing.script_json = script
                existing.sources_json = unique_sources[:5]
                existing.error_message = None
                self.db.add(existing)
                await self.db.commit()
                await self.db.refresh(existing)
                return existing

            record = TopicPodcastScript(
                topic_id=topic_id,
                status="READY",
                script_json=script,
                sources_json=unique_sources[:5],
            )
            self.db.add(record)
            await self.db.commit()
            await self.db.refresh(record)
            return record

        except Exception as exc:
            existing = await self.get_topic_podcast(topic_id)
            if existing:
                existing.status = "FAILED"
                existing.error_message = str(exc)
                self.db.add(existing)
                await self.db.commit()
                await self.db.refresh(existing)
                return existing

            record = TopicPodcastScript(
                topic_id=topic_id,
                status="FAILED",
                error_message=str(exc),
            )
            self.db.add(record)
            await self.db.commit()
            await self.db.refresh(record)
            return record

    # ==========================================
    # ARTICLE (ADMIN)
    # ==========================================

    @staticmethod
    def _get_curated_image(topic: str) -> str:
        topic_lower = topic.lower()
        category = "general"
        if any(x in topic_lower for x in ["travel", "passport", "tourism"]):
            category = "travel"
        elif any(x in topic_lower for x in ["tech", "ai", "future", "code", "digital"]):
            category = "tech"
        elif any(x in topic_lower for x in ["history", "ancient", "old"]):
            category = "history"
        elif any(x in topic_lower for x in ["money", "finance", "business"]):
            category = "money"
        elif any(x in topic_lower for x in ["news", "politics", "war", "crisis"]):
            category = "news"

        gallery = {
            "travel": [
                "https://images.unsplash.com/photo-1544717305-2782549b5136",
                "https://images.unsplash.com/photo-1436491865332-7a61a109cc05",
            ],
            "tech": [
                "https://images.unsplash.com/photo-1518770660439-4636190af475",
                "https://images.unsplash.com/photo-1620712943543-bcc4688e7485",
            ],
            "history": [
                "https://images.unsplash.com/photo-1461360370896-922624d12aa1",
                "https://images.unsplash.com/photo-1555677284-6a6f971638e0",
            ],
            "money": [
                "https://images.unsplash.com/photo-1611974765270-ca12586343bb",
                "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab",
            ],
            "news": [
                "https://images.unsplash.com/photo-1581093458791-9f3c3900df4b",
                "https://images.unsplash.com/photo-1504711434969-e33886168f5c",
            ],
            "general": [
                "https://images.unsplash.com/photo-1451187580459-43490279c0fa",
                "https://images.unsplash.com/photo-1506784983877-45594efa4cbe",
            ],
        }

        import random

        return random.choice(gallery[category]) + "?q=80&w=800&auto=format&fit=crop"

    async def _resolve_article_image(self, topic: str) -> str:
        primary = self._get_curated_image(topic)
        fallback = f"https://picsum.photos/seed/{topic.replace(' ', '-')}/800/450"
        try:
            async with httpx.AsyncClient(timeout=5.0, follow_redirects=True) as client:
                resp = await client.head(primary)
                if resp.status_code >= 400:
                    return fallback
                return primary
        except Exception:
            return fallback

    async def get_topic_article(self, topic_id: str) -> Optional[TopicArticle]:
        result = await self.db.execute(
            select(TopicArticle)
            .where(TopicArticle.topic_id == topic_id)
            .order_by(TopicArticle.published_at.desc())
        )
        return result.scalar_one_or_none()

    async def get_topic_articles(self, topic_id: str, limit: int = 10) -> List[TopicArticle]:
        result = await self.db.execute(
            select(TopicArticle)
            .where(TopicArticle.topic_id == topic_id)
            .order_by(TopicArticle.published_at.desc())
            .limit(limit)
        )
        return list(result.scalars().all())

    async def refresh_article_image(self, article_id: str) -> Optional[TopicArticle]:
        result = await self.db.execute(
            select(TopicArticle).where(TopicArticle.id == article_id)
        )
        record = result.scalar_one_or_none()
        if not record:
            return None
        record.image_url = await self._resolve_article_image(record.title)
        self.db.add(record)
        await self.db.commit()
        await self.db.refresh(record)
        return record

    async def generate_topic_articles(self, topic_id: str, count: int = 3) -> List[TopicArticle]:
        topic = await self.get_topic_by_id(topic_id)
        if not topic:
            raise ValueError("Topic not found")

        recent = await self.get_topic_articles(topic_id, limit=5)
        recent_titles = [r.title for r in recent if r.title]
        avoid_block = ""
        if recent_titles:
            quoted = "\n".join([f"- {t}" for t in recent_titles])
            avoid_block = f"\n\nAvoid these previously generated titles and stories:\n{quoted}\n"

        prompt = f"""
          You are a senior investigative journalist.

          TASK: Search for the top {count} REAL news stories about "{topic.title}"
          from the last 48 hours. For each story, write a complete, long-form article (500-700 words).
          {avoid_block}

          Return JSON in this exact structure:
          {{
            "articles": [
              {{
                "title": "Article title (max 10 words)",
                "published_at": "ISO-8601 date-time",
                "content": "Full article text with paragraph breaks"
              }}
            ]
          }}
        """

        client = make_genai_client(force_direct=True)  # Google Search grounding — gateway can't proxy it

        content = types.Content(parts=[types.Part(text=prompt)])
        response = client.models.generate_content(
            model="gemini-3-flash-preview",
            contents=content,
            config=types.GenerateContentConfig(
                tools=[types.Tool(google_search=types.GoogleSearch())],
                response_mime_type="application/json",
                response_schema={
                    "type": "OBJECT",
                    "properties": {
                        "articles": {
                            "type": "ARRAY",
                            "items": {
                                "type": "OBJECT",
                                "properties": {
                                    "title": {"type": "STRING"},
                                    "published_at": {"type": "STRING"},
                                    "content": {"type": "STRING"},
                                }
                            }
                        }
                    }
                }
            )
        )

        usage = getattr(response, "usage_metadata", None) or getattr(response, "usageMetadata", None)
        if usage:
            prompt_tokens = getattr(usage, "prompt_token_count", None) or getattr(usage, "promptTokenCount", None)
            completion_tokens = getattr(usage, "candidates_token_count", None) or getattr(usage, "candidatesTokenCount", None)
            total_tokens = getattr(usage, "total_token_count", None) or getattr(usage, "totalTokenCount", None)
            if total_tokens is None and (prompt_tokens is not None or completion_tokens is not None):
                total_tokens = (prompt_tokens or 0) + (completion_tokens or 0)
            if total_tokens is not None:
                await TokenUsageService.record_usage(
                    self.db,
                    user_id=None,
                    source="system",
                    model_name="gemini-3-flash-preview",
                    prompt_tokens=int(prompt_tokens or 0),
                    completion_tokens=int(completion_tokens or 0),
                    total_tokens=int(total_tokens or 0),
                )

        data = json.loads(response.text)
        articles = data.get("articles") or []

        sources = []
        if response.candidates and response.candidates[0].grounding_metadata:
            chunks = response.candidates[0].grounding_metadata.grounding_chunks or []
            for c in chunks:
                if c.web and c.web.uri and c.web.title:
                    sources.append({"title": c.web.title, "url": c.web.uri})

        unique_sources = list({s["url"]: s for s in sources}.values())
        image_url = await self._resolve_article_image(topic.title)

        from datetime import datetime

        created = []
        for item in articles:
            title = (item.get("title") or topic.title).strip()
            content_text = (item.get("content") or "").strip()
            published_at_raw = item.get("published_at") or ""
            try:
                published_at = datetime.fromisoformat(published_at_raw.replace("Z", "+00:00"))
            except Exception:
                published_at = datetime.utcnow()
            record = TopicArticle(
                topic_id=topic_id,
                title=title,
                published_at=published_at,
                content=content_text,
                image_url=image_url,
                sources_json=unique_sources[:5],
            )
            self.db.add(record)
            created.append(record)

        await self.db.commit()
        for record in created:
            await self.db.refresh(record)
        return created
