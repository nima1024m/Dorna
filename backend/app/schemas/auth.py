from pydantic import BaseModel, EmailStr, Field


class PreAuthReq(BaseModel):
    device_nonce: str | None = None


class PreAuthRes(BaseModel):
    status: str = "OK"
    token: str


class SignReq(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)



class SignInRes(BaseModel):
    status: str = "OK"
    access_token: str
    refresh_token: str


class SignUpRes(BaseModel):
    status: str = "OK"


class RefreshReq(BaseModel):
    refresh_token: str


class RefreshRes(BaseModel):
    status: str = "OK"
    access_token: str
    refresh_token: str


class LogoutReq(BaseModel):
    refresh_token: str


class ForgotReq(BaseModel):
    email: EmailStr


class ForgotRes(BaseModel):
    status: str = "OK"


class VerifyResetTokenReq(BaseModel):
    email: EmailStr
    code: str = Field(min_length=5, max_length=5)


class VerifyResetTokenRes(BaseModel):
    status: str = "OK"
    token: str


class ResetWithCodeReq(BaseModel):
    email: EmailStr
    new_password: str = Field(min_length=8)


class ResetRes(BaseModel):
    status: str = "OK"
    access_token: str
    refresh_token: str

class ResetNeedsActivationRes(BaseModel):
    status: str = "OK"
    message: str = "Please verify your email before logging in."

class GoogleSignInReq(BaseModel):
    id_token: str


class GoogleSignRes(BaseModel):
    status: str = "OK"
    access_token: str
    refresh_token: str


class AppleSignInReq(BaseModel):
    identity_token: str


class AppleSignInRes(BaseModel):
    status: str = "OK"
    access_token: str
    refresh_token: str


class ResendActivationReq(BaseModel):
    email: EmailStr


class ResendActivationRes(BaseModel):
    status: str = "OK"
