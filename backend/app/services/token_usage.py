"""Token Usage Tracking Service.

Tracks AI token consumption per user/source/model with cost estimation.
Used by: Learning Insights, Podcast, TTS, Admin Topic Service.
"""
from __future__ import annotations

from datetime import date
from typing import Optional

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.agents.usage import TokenUsage
from app.models import TokenUsageDaily


class TokenUsageService:
    @staticmethod
    async def record(
        db: AsyncSession,
        usage: Optional[TokenUsage],
        *,
        user_id: Optional[int],
        source: str,
    ) -> None:
        """Record a typed :class:`TokenUsage`. No-op when ``usage`` is None.

        The single seam for charging an AI call: callers hand over the typed
        usage their agent returned instead of digging fields out of a payload.
        """
        if usage is None:
            return
        await TokenUsageService.record_usage(
            db,
            user_id=user_id,
            source=source,
            model_name=usage.model,
            prompt_tokens=usage.prompt_tokens,
            completion_tokens=usage.completion_tokens,
            total_tokens=usage.total_tokens,
        )

    @staticmethod
    def _estimate_cost_cents(source: str, total_tokens: int) -> int:
        if total_tokens <= 0:
            return 0

        rate_usd = None
        if source == "gemini":
            rate_usd = settings.GEMINI_COST_PER_1K_USD
        elif source == "tts":
            rate_usd = settings.TTS_COST_PER_1K_USD
        elif source == "system":
            rate_usd = settings.SYSTEM_COST_PER_1K_USD

        if not rate_usd:
            return 0

        return int(round((total_tokens / 1000.0) * float(rate_usd) * 100000))

    @staticmethod
    def _estimate_cost_cents_by_model(model_name: Optional[str], prompt_tokens: int, completion_tokens: int) -> int:
        pricing = settings.MODEL_PRICING or {}
        if not model_name or model_name not in pricing:
            return 0

        model_pricing = pricing.get(model_name) or {}
        input_rate = model_pricing.get("input")
        output_rate = model_pricing.get("output")

        if input_rate is None or output_rate is None:
            return 0

        cost_usd = (prompt_tokens / 1000.0) * float(input_rate)
        cost_usd += (completion_tokens / 1000.0) * float(output_rate)
        return int(round(cost_usd * 100000))

    @staticmethod
    async def record_usage(
        db: AsyncSession,
        *,
        user_id: Optional[int],
        source: str,
        model_name: Optional[str],
        prompt_tokens: int,
        completion_tokens: int,
        total_tokens: int,
        usage_date: Optional[date] = None,
        cost_cents: Optional[int] = None,
    ) -> None:
        usage_date = usage_date or date.today()
        total_tokens = max(int(total_tokens or 0), 0)
        prompt_tokens = max(int(prompt_tokens or 0), 0)
        completion_tokens = max(int(completion_tokens or 0), 0)

        if cost_cents is None:
            model_cost = TokenUsageService._estimate_cost_cents_by_model(
                model_name, prompt_tokens, completion_tokens
            )
            if model_cost:
                cost_cents = model_cost
            else:
                cost_cents = TokenUsageService._estimate_cost_cents(source, total_tokens)

        q = select(TokenUsageDaily).where(
            TokenUsageDaily.usage_date == usage_date,
            TokenUsageDaily.user_id == user_id,
            TokenUsageDaily.source == source,
            TokenUsageDaily.model_name == model_name,
        )
        existing = (await db.execute(q)).scalar_one_or_none()

        if existing:
            existing.prompt_tokens += prompt_tokens
            existing.completion_tokens += completion_tokens
            existing.total_tokens += total_tokens
            existing.cost_cents += cost_cents
            existing.updated_at = func.now()
        else:
            db.add(TokenUsageDaily(
                user_id=user_id,
                usage_date=usage_date,
                source=source,
                model_name=model_name,
                prompt_tokens=prompt_tokens,
                completion_tokens=completion_tokens,
                total_tokens=total_tokens,
                cost_cents=cost_cents,
            ))

        await db.commit()
