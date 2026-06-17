import uuid

from sqlalchemy import select, and_, desc
from sqlalchemy.ext.asyncio import AsyncSession

import app.core.ai as AI
from app.core.agents.usage import pop_usages
from app.core.config import settings
from app.core.database import AIStatus, ActionStatus
from app.models import GrammarSuggestion, GrammarCorrection, ToneAdjustments, TranslateTexts
from app.services.token_usage import TokenUsageService

from app.schemas.assistant import SuggestGrammarIn, SuggestTranslateIn, SuggestToneIn


class AssistantService:
    @staticmethod
    def _finalize(task: str, payload: dict) -> dict:
        if "status" not in payload:
            payload["status"] = "OK"
        payload["query_id"] = str(uuid.uuid4())
        payload["task"] = task
        return payload

    @staticmethod
    async def _record_usage(db: AsyncSession, user_id: int, source: str, payload: dict) -> None:
        await TokenUsageService.record_all(db, pop_usages(payload), user_id=user_id, source=source)

    @staticmethod
    async def grammar_correction(db: AsyncSession, data: SuggestGrammarIn) -> dict:
        try:
            llm_res = await AI.grammar_correction(data.content)
            llm_res = AssistantService._finalize("grammar", llm_res)

            db.add(GrammarSuggestion(
                id=llm_res['query_id'], user_id=data.user_id,
                status=AIStatus.OK if llm_res['status'] == 'OK' else AIStatus.ERROR
            ))

            await db.commit()

            await AssistantService._record_usage(db, data.user_id, "gemini", llm_res)

            for idx, correction in enumerate(llm_res.get('corrections', [])):
                correction_id = str(uuid.uuid4())
                llm_res['corrections'][idx]['correction_id'] = correction_id
                db.add(GrammarCorrection(
                    id=correction_id, grammar_id=llm_res['query_id'], changed=correction['changed'],
                    suggestion=correction['suggestion'], explanation=correction['explanation'],
                    original=correction['original']
                ))
            await db.commit()


            # the reason im doing this here is because i want to record the original user input inside the grammar_corrections table
            # and doing this because of the UI
            for correction in llm_res.get('corrections', []):
                correction['original'] = correction['original'].replace('\n', '')
                llm_res['original'] = correction['original']
                
            
            return llm_res
        except Exception as e:
            return AssistantService._finalize("grammar", {
                "status": "ERROR",
                "message": f"grammar correction failed: {e}"
            })

    @staticmethod
    async def translate_text(db: AsyncSession, data: SuggestTranslateIn) -> dict:
        try:
            llm_res = await AI.translate_text(data.content, data.target_lang)
            llm_res = AssistantService._finalize("translate", llm_res)

            if llm_res['status'] != 'OK':
                raise Exception(llm_res.get('message', 'An error occurred'))

            db.add(TranslateTexts(
                id=llm_res['query_id'], user_id=data.user_id, input_text=data.content, translated=llm_res['translated'],
                target_lang=data.target_lang, status=AIStatus.OK if llm_res['status'] == 'OK' else AIStatus.ERROR
            ))
            await db.commit()

            await AssistantService._record_usage(db, data.user_id, "gemini", llm_res)

            return llm_res
        except Exception as e:
            return AssistantService._finalize("translate", {
                "status": "ERROR",
                "message": f"translate text failed: {e}"
            })

    @staticmethod
    async def get_parent_tones(db: AsyncSession, parent_tones: list[str], parent_tone_id: str) -> list:
        q = select(ToneAdjustments).where(ToneAdjustments.id == parent_tone_id)
        tone = (await db.execute(q)).scalar_one_or_none()
        if not tone:
            return parent_tones

        parent_tones.append(str(tone.id))

        if tone.parent_tone_id is None:
            return parent_tones

        return await AssistantService.get_parent_tones(db, parent_tones, tone.parent_tone_id)

    @staticmethod
    async def tone_adjustment(db: AsyncSession, data: SuggestToneIn) -> dict:
        try:
            parent_tones = []
            if data.parent_tone_id is not None:
                parent_tones = await AssistantService.get_parent_tones(db, [data.parent_tone_id], data.parent_tone_id)

            q = select(ToneAdjustments.adjusted).where(ToneAdjustments.id.in_(parent_tones))
            parent_tones = (await db.execute(q)).all()
            data.parent_tones = [p.adjusted for p in parent_tones]

            q = select(ToneAdjustments.input_text, ToneAdjustments.adjusted).where(and_(
                ToneAdjustments.user_action == ActionStatus.APPROVED,
                ToneAdjustments.target_tone == data.target_tone,
                ToneAdjustments.user_id == data.user_id)).order_by(desc(
                ToneAdjustments.created_timestamp)).limit(settings.USER_APPROVED_TONE_LIMIT)
            user_approved_tones = (await db.execute(q)).all()
            data.user_approved_tones = [{
                'input_text': uat.input_text, 'adjusted': uat.adjusted
            } for uat in user_approved_tones]

            llm_res = await AI.tone_adjustment(
                data.content, data.target_tone, data.parent_tones, data.user_approved_tones)
            llm_res = AssistantService._finalize("tone", llm_res)

            if llm_res['status'] != 'OK':
                raise Exception(llm_res.get('message', 'An error occurred'))

            db.add(ToneAdjustments(
                id=llm_res['query_id'], user_id=data.user_id, input_text=data.content, adjusted=llm_res['adjusted'],
                target_tone=data.target_tone, status=AIStatus.OK if llm_res['status'] == 'OK' else AIStatus.ERROR,
                parent_tone_id=data.parent_tone_id if data.parent_tone_id else None
            ))
            await db.commit()

            await AssistantService._record_usage(db, data.user_id, "gemini", llm_res)

            return llm_res
        except Exception as e:
            return AssistantService._finalize("tone", {
                "status": "ERROR",
                "message": f"tone adjustment failed: {e}"
            })
