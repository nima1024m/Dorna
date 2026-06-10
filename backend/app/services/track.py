from datetime import datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import *
from app.models.grammar_corrections import ActionStatus

from app.schemas.track import TrackGrammarIn, TrackTranslateIn, TrackToneIn


class TrackService:
    @staticmethod
    async def action_grammar(db: AsyncSession, data: TrackGrammarIn) -> dict:
        try:
            q = (
                select(GrammarCorrection)
                .join(GrammarSuggestion, GrammarSuggestion.id == GrammarCorrection.grammar_id)
                .where(GrammarCorrection.id == data.correction_id, GrammarSuggestion.user_id == data.user_id)
            )
            correction = (await db.execute(q)).scalar_one_or_none()
            if not correction:
                raise ValueError("correction not found")
            correction.user_action = ActionStatus.APPROVED if data.action == 'approved' else ActionStatus.REJECTED
            correction.user_action_timestamp = datetime.now()
            await db.commit()
            return {'status': 'OK', 'message': 'Action successfully applied.'}
        except Exception as e:
            return {'status': 'ERROR', 'message': f'Error {str(e)}'}

    @staticmethod
    async def action_translate(db: AsyncSession, data: TrackTranslateIn) -> dict:
        try:
            q = (
                select(TranslateTexts)
                .where(TranslateTexts.id == data.translate_id, TranslateTexts.user_id == data.user_id)
            )
            correction = (await db.execute(q)).scalar_one_or_none()
            if not correction:
                raise ValueError("correction not found")
            correction.user_action = ActionStatus.APPROVED if data.action == 'approved' else ActionStatus.REJECTED
            correction.user_action_timestamp = datetime.now()
            await db.commit()
            return {'status': 'OK', 'message': 'Action successfully applied.'}
        except Exception as e:
            return {'status': 'ERROR', 'message': f'Error {str(e)}'}

    @staticmethod
    async def action_tone(db: AsyncSession, data: TrackToneIn) -> dict:
        try:
            q = (
                select(ToneAdjustments)
                .where(ToneAdjustments.id == data.tone_id, ToneAdjustments.user_id == data.user_id)
            )
            correction = (await db.execute(q)).scalar_one_or_none()
            if not correction:
                raise ValueError("correction not found")
            correction.user_action = ActionStatus.APPROVED if data.action == 'approved' else ActionStatus.REJECTED
            correction.user_action_timestamp = datetime.now()
            await db.commit()
            return {'status': 'OK', 'message': 'Action successfully applied.'}
        except Exception as e:
            return {'status': 'ERROR', 'message': f'Error {str(e)}'}
