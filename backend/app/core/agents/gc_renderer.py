import json
from app.core.config import settings

from jinja2 import Environment, FileSystemLoader

_cred_env = Environment(
    loader=FileSystemLoader("app/files"),
    autoescape=False,
    trim_blocks=True,
    lstrip_blocks=True,
)
_cred_env.filters.setdefault("tojson", lambda value: json.dumps(value if value is not None else "", ensure_ascii=False))

def render_service_account_json() -> dict:
    # Fix private key: convert escaped \n (literal backslash-n) to actual newlines
    # This is necessary because environment variables often store PEM keys with escaped newlines
    private_key = settings.GOOGLE_APPLICATION_CREDENTIALS_PRIVATE_KEY or ""
    if "\\n" in private_key:
        private_key = private_key.replace("\\n", "\n")
    elif "\\\\n" in private_key:
        private_key = private_key.replace("\\\\n", "\n")
    
    creds = {
        "type": settings.GOOGLE_APPLICATION_CREDENTIALS_TYPE,
        "project_id": settings.GOOGLE_APPLICATION_CREDENTIALS_PROJECT_ID,
        "private_key_id": settings.GOOGLE_APPLICATION_CREDENTIALS_PRIVATE_KEY_ID,
        "private_key": private_key,
        "client_email": settings.GOOGLE_APPLICATION_CREDENTIALS_CLIENT_EMAIL,
        "client_id": settings.GOOGLE_APPLICATION_CREDENTIALS_CLIENT_ID,
        "auth_uri": settings.GOOGLE_APPLICATION_CREDENTIALS_AUTH_URI,
        "token_uri": settings.GOOGLE_APPLICATION_CREDENTIALS_TOKEN_URI,
        "auth_provider_x509_cert_url": settings.GOOGLE_APPLICATION_CREDENTIALS_AUTH_PROVIDER_X509_CERT_URL,
        "client_x509_cert_url": settings.GOOGLE_APPLICATION_CREDENTIALS_CLIENT_X509_CERT_URL,
        "universe_domain": settings.GOOGLE_APPLICATION_CREDENTIALS_UNIVERSE_DOMAIN,
    }
    template = _cred_env.get_template("sbody-tracker-beba7-074bea142d20.json.j2")
    context = {
        "type": creds["type"],
        "project_id": creds["project_id"],
        "private_key_id": creds["private_key_id"],
        "private_key": creds["private_key"],
        "client_email": creds["client_email"],
        "client_id": creds["client_id"],
        "auth_uri": creds["auth_uri"],
        "token_uri": creds["token_uri"],
        "auth_provider_x509_cert_url": creds["auth_provider_x509_cert_url"],
        "client_x509_cert_url": creds["client_x509_cert_url"],
        "universe_domain": creds["universe_domain"],
    }
    rendered = template.render(**context)
    return json.loads(rendered)