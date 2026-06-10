from pydantic import BaseModel, Field


from typing import List, Optional

class UpdateProfileReq(BaseModel):
    full_name: Optional[str] = Field(None, min_length=2, max_length=100)
    age: Optional[int] = Field(None, ge=0, le=120)
    nationality: Optional[str] = Field(None, max_length=100)
    profession: Optional[str] = Field(None, max_length=255)
    interests: Optional[List[str]] = Field(None)
    learning_goal: Optional[str] = Field(None, max_length=255)
    onboarding_completed: Optional[bool] = Field(None)
    initial_clb_level: Optional[str] = Field(None, max_length=20)


class MeRes(BaseModel):
    id: str
    email: str
    full_name: str | None
    avatar_exist: bool
    age: int | None = None
    nationality: str | None = None
    profession: str | None = None
    interests: List[str] | None = None
    learning_goal: str | None = None
    onboarding_completed: bool = False
    initial_clb_level: str | None = None


class PatchMeRes(BaseModel):
    id: str
    email: str
    full_name: str | None = None
    age: int | None = None
    nationality: str | None = None
    profession: str | None = None
    interests: List[str] | None = None
    learning_goal: str | None = None
    onboarding_completed: bool | None = None
    initial_clb_level: str | None = None


class AvatarUploadRes(BaseModel):
    avatar_url: str


class AvatarDeleteRes(BaseModel):
    status: str = "OK"


class ChangePasswordReq(BaseModel):
    old_password: str = Field(min_length=8)
    new_password: str = Field(min_length=8)


class ChangePasswordRes(BaseModel):
    status: str = "OK"


class UserDeleteRes(BaseModel):
    status: str = "OK"


class DataDeleteRes(BaseModel):
    status: str = "OK"
