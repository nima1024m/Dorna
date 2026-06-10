from fastapi import APIRouter, Depends, Request, HTTPException, Header, Path
from fastapi.responses import RedirectResponse
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.config import settings
from app.core.rate_limit import rate_limit_hit
from app.schemas.auth import (
    PreAuthReq, PreAuthRes, SignReq, SignInRes, SignUpRes, RefreshReq, RefreshRes, LogoutReq, ForgotReq, ForgotRes,
    ResetWithCodeReq, ResetRes, ResetNeedsActivationRes, VerifyResetTokenReq, VerifyResetTokenRes, GoogleSignInReq, GoogleSignRes,
    AppleSignInReq, AppleSignInRes, ResendActivationReq, ResendActivationRes
)
from app.services import auth
from typing import Union
router = APIRouter()


def _err(code: str, message: str, status: int = 400):
    raise HTTPException(status_code=status, detail={"status": "ERROR", "code": code, "message": message})


@router.post("/pre-auth", response_model=PreAuthRes)
async def pre_auth(req: Request, body: PreAuthReq, db: AsyncSession = Depends(get_db)):
    ip = req.client.host if req.client else "0.0.0.0"
    if not rate_limit_hit(f"preauth:ip:{ip}", settings.RATE_PRE_AUTH_PER_MIN):
        _err("rate_limited", "Too many requests", 429)
    token = await auth.create_pre_auth(db, device_nonce=body.device_nonce)
    return {"status": "OK", "token": token}


@router.post("/signup", response_model=SignUpRes)
async def signup(req: Request, body: SignReq, pre_auth_token: str = Header(None, alias="X-Preauth-Token"),
                 db: AsyncSession = Depends(get_db)):
    ip = req.client.host if req.client else "0.0.0.0"
    key = f"signup:ip:{ip}"
    if not rate_limit_hit(key, settings.RATE_SIGNUP_PER_MIN):
        _err("rate_limited", "Too many requests", 429)
    try:
        await auth.signup(db, body.email, body.password, pre_auth_token)
        return {"status": "OK"}
    except ValueError as e:
        code = str(e)
        if code == "email_exists":
            _err(code, "Email already registered", 409)
        if code in {"invalid_preauth", "used_preauth", "expired_preauth"}:
            _err(code, "Invalid preauth token", 400)
        _err(code, "Could not sign up", 400)


@router.get("/active/{activation_token}")
async def activation(activation_token: str = Path(...), db: AsyncSession = Depends(get_db)):
    try:
        access_token, refresh_token = await auth.active_user(db, activation_token)
        url = f"{settings.APP_BASE_URL}/?access_token={access_token}&refresh_token={refresh_token}"
    except ValueError as e:
        url = f"{settings.APP_BASE_URL}/?error_message=Invalid activation token"

    return RedirectResponse(url=url, status_code=307)


@router.post("/signin", response_model=SignInRes)
async def signin(req: Request, body: SignReq, pre_auth_token: str = Header(None, alias="X-Preauth-Token"),
                 db: AsyncSession = Depends(get_db)):
    ip = req.client.host if req.client else "0.0.0.0"
    key = f"signin:ip:{ip}"
    if not rate_limit_hit(key, settings.RATE_SIGNIN_PER_MIN):
        _err("rate_limited", "Too many requests", 429)
    try:
        access_token, refresh_token = await auth.signin(db, body.email, body.password, pre_auth_token)
        return {"status": "OK", "access_token": access_token, "refresh_token": refresh_token}
    except ValueError as e:
        code = str(e)
        print(f"signin error: {code}")
        if code in {"invalid_credentials"}:
            _err(code, "Invalid email or password", 401)
        if code in {"inactive_account"}:
            _err(code, "Account is not active", 401)
        if code in {"invalid_preauth", "used_preauth", "expired_preauth"}:
            _err(code, "Invalid preauth token", 400)
        _err("signin_failed", "Could not sign in", 400)


@router.post("/refresh", response_model=RefreshRes)
async def refresh(body: RefreshReq, db: AsyncSession = Depends(get_db)):
    try:
        access_token, refresh_token = await auth.refresh(db, body.refresh_token)
        return {"status": "OK", "access_token": access_token, "refresh_token": refresh_token}
    except ValueError as e:
        code = str(e)
        _err(code, "Invalid refresh token", 401)


@router.post("/logout")
async def logout(body: LogoutReq, db: AsyncSession = Depends(get_db)):
    await auth.logout(db, body.refresh_token)
    return {"status": "OK"}


@router.post("/forgot", response_model=ForgotRes)
async def forgot(body: ForgotReq, db: AsyncSession = Depends(get_db)):
    await auth.forgot_password_send_code(db, body.email)
    return {"status": "OK"}


@router.post("/resend-activation", response_model=ResendActivationRes)
async def resend_activation(req: Request, body: ResendActivationReq, db: AsyncSession = Depends(get_db)):
    ip = req.client.host if req.client else "0.0.0.0"
    if not rate_limit_hit(f"resend_activation:ip:{ip}", settings.RATE_RESEND_ACTIVE_PER_MIN):
        _err("rate_limited", "Too many requests", 429)
    await auth.resend_activation(db, body.email)
    return {"status": "OK"}


@router.post("/verify-reset", response_model=VerifyResetTokenRes)
async def verify_reset(body: VerifyResetTokenReq, db: AsyncSession = Depends(get_db)):
    try:
        verify_reset_token = await auth.verify_reset_password_token(db, body.email, body.code)
        return {"status": "OK", "token": verify_reset_token}
    except ValueError as e:
        code = str(e)
        if code in {"invalid_token", "expired_token"}:
            _err(code, "invalid or expired verify token", 400)
        _err("reset_failed", "could not reset password", 400)


@router.post("/reset", response_model=ResetRes | ResetNeedsActivationRes)
async def reset_password(body: ResetWithCodeReq, verify_token: str = Header(None, alias="X-Verify-Token"),
                         db: AsyncSession = Depends(get_db)):
    try:
        if not verify_token:
            _err("invalid_token", "missing reset verify token", 400)

        access_token, refresh_token = await auth.reset_password_with_code(
            db, body.email, body.new_password, verify_token)
        if access_token and refresh_token:
            return {"status": "OK", "access_token": access_token, "refresh_token": refresh_token}

        return {"status": "OK", "message": "Please verify your email before logging in."}
    except ValueError as e:
        code = str(e)
        if code in {
            "invalid_token",
            "invalid_verify_token",
            "used_verify_token",
            "expired_verify_token",
        }:
            _err(code, "invalid or expired reset token", 400)
        if code == "weak_password":
            _err(code, "password must be at least 8 characters", 400)
        _err("reset_failed", "could not reset password", 400)


@router.post("/google", response_model=GoogleSignRes)
async def google_login(req: Request, body: GoogleSignInReq, db: AsyncSession = Depends(get_db)):
    ip = req.client.host if req.client else "0.0.0.0"
    if not rate_limit_hit(f"google_signin:ip:{ip}", settings.RATE_SIGNIN_PER_MIN):
        _err("rate_limited", "Too many requests", 429)

    try:
        access_token, refresh_token = await auth.google_signin(db, body.id_token)
        return {"status": "OK", "access_token": access_token, "refresh_token": refresh_token}
    except ValueError as e:
        code = str(e)
        if code in {"invalid_google_token", "aud_mismatch"}:
            _err(code, "Invalid Google token", 401)
        if code == "email_not_verified":
            _err(code, "Google account email is not verified", 403)
        _err("signin_failed", "Could not sign in with Google", 400)


@router.post("/apple", response_model=AppleSignInRes)
async def apple_login(req: Request, body: AppleSignInReq, db: AsyncSession = Depends(get_db)):
    ip = req.client.host if req.client else "0.0.0.0"
    if not rate_limit_hit(f"apple_signin:ip:{ip}", settings.RATE_SIGNIN_PER_MIN):
        _err("rate_limited", "Too many requests", 429)

    try:
        access_token, refresh_token = await auth.apple_signin(db, body.identity_token)
        return {"status": "OK", "access_token": access_token, "refresh_token": refresh_token}
    except ValueError as e:
        code = str(e)
        if code == "invalid_apple_token":
            _err(code, "Invalid Apple token", 401)
        _err("signin_failed", "Could not sign in with Apple", 400)
