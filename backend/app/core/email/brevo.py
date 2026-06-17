"""Brevo transactional email helpers.

Targets brevo-python 4.x, which is a ground-up SDK rewrite vs 1.x: a single
``Brevo`` client with resource namespaces (``client.transactional_emails``),
keyword-only request fields, typed request models, and ``brevo.core.ApiError``
in place of the old ``brevo_python`` / ``ApiException`` surface.

These are fire-and-forget notifications (password reset, signup verification,
learning summary). A send failure must never break the calling flow, so every
send swallows and logs — matching the previous behaviour, but broadened to the
new SDK's error surface (ApiError, parsing errors, pydantic validation, and
transport errors all degrade gracefully).
"""
import logging

import brevo
from brevo import SendTransacEmailRequestSender, SendTransacEmailRequestToItem

from app.core.config import settings

logger = logging.getLogger("email")


def _client() -> brevo.Brevo:
    return brevo.Brevo(api_key=settings.BREVO_API_KEY)


def send_reset_code_email(to_email: str, code: str) -> None:
    try:
        _client().transactional_emails.send_transac_email(
            to=[SendTransacEmailRequestToItem(email=to_email)],
            template_id=int(settings.BREVO_DORNA_FORGET_PASS_TEMPLATE_ID),
            params={"RESET_CODE": code},
        )
    except Exception as e:
        logger.warning("brevo_send_failed to=%s err=%s", to_email, e)


def send_signup_token_email(to_email: str, signup_token: str) -> None:
    try:
        _client().transactional_emails.send_transac_email(
            to=[SendTransacEmailRequestToItem(email=to_email)],
            template_id=int(settings.BREVO_DORNA_SIGNUP_TEMPLATE_ID),
            params={"VERIFICATION_LINK": f"{settings.API_BASE_URL}/v1/auth/active/{signup_token}"},
        )
    except Exception as e:
        logger.warning("brevo_send_failed to=%s err=%s", to_email, e)


def send_html_email(to_email: str, subject: str, html_content: str) -> None:
    try:
        _client().transactional_emails.send_transac_email(
            to=[SendTransacEmailRequestToItem(email=to_email)],
            subject=subject,
            html_content=html_content,
            sender=SendTransacEmailRequestSender(name="Dorna AI", email="support@dorna.ai"),
        )
    except Exception as e:
        logger.warning("brevo_send_failed to=%s err=%s", to_email, e)
