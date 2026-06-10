import os
import brevo_python
from brevo_python.rest import ApiException
from app.core.config import settings


def _client():
    cfg = brevo_python.Configuration()
    cfg.api_key['api-key'] = settings.BREVO_API_KEY
    return brevo_python.TransactionalEmailsApi(brevo_python.ApiClient(cfg))


def send_reset_code_email(to_email: str, code: str) -> None:
    api = _client()
    email = brevo_python.SendSmtpEmail(
        to=[{"email": to_email}],
        template_id=int(settings.BREVO_DORNA_FORGET_PASS_TEMPLATE_ID),
        params={"RESET_CODE": code},
    )
    try:
        api.send_transac_email(email)
    except ApiException as e:
        import logging
        logging.getLogger("email").warning("brevo_send_failed to=%s err=%s", to_email, e)


def send_signup_token_email(to_email: str, signup_token: str) -> None:
    api = _client()
    email = brevo_python.SendSmtpEmail(
        to=[{"email": to_email}],
        template_id=int(settings.BREVO_DORNA_SIGNUP_TEMPLATE_ID),
        params={"VERIFICATION_LINK": f"{settings.API_BASE_URL}/v1/auth/active/{signup_token}"},
    )
    try:
        api.send_transac_email(email)
    except ApiException as e:
        import logging
        logging.getLogger("email").warning("brevo_send_failed to=%s err=%s", to_email, e)


def send_html_email(to_email: str, subject: str, html_content: str) -> None:
    api = _client()
    email = brevo_python.SendSmtpEmail(
        to=[{"email": to_email}],
        subject=subject,
        html_content=html_content,
        sender={"name": "Dorna AI", "email": "support@dorna.ai"}
    )
    try:
        api.send_transac_email(email)
    except ApiException as e:
        import logging
        logging.getLogger("email").warning("brevo_send_failed to=%s err=%s", to_email, e)