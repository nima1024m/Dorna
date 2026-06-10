from __future__ import annotations

from typing import List, Optional
from pydantic import BaseModel, Field, model_validator


# =============================================================================
# ONBOARDING - Topic categories & learning goals
# =============================================================================

class TopicCategoryOut(BaseModel):
    id: str = Field(
        ...,
        description="Stable category ID (lookup table PK)",
        examples=["internet"],
    )
    label: str = Field(
        ...,
        description="Human readable category label",
        examples=["Internet Mysteries"],
    )


class TopicCategoryListResponse(BaseModel):
    categories: List[TopicCategoryOut]


class LearningGoalOut(BaseModel):
    id: int = Field(..., description="Learning goal ID", examples=[1])
    key: str = Field(..., description="Stable goal key", examples=["fluency"])
    title: str = Field(..., description="Goal title", examples=["Improve fluency"])
    description: str = Field(..., description="Goal description")


class LearningGoalListResponse(BaseModel):
    goals: List[LearningGoalOut]


# =============================================================================
# ONBOARDING - User preferences upsert & response
# =============================================================================

class OnboardingUpsertRequest(BaseModel):
    language_level: int = Field(
        ...,
        ge=4,
        le=9,
        description="User language level (CLB scale 4-9)",
        examples=[6],
    )
    # Frontend-friendly shape (preferred): [{id, label}, ...]
    categories: List[TopicCategoryOut] = Field(
        default_factory=list,
        description="Selected topic categories (id/label objects). Only id is persisted; label is display-only.",
        examples=[[{"id": "internet", "label": "Internet Mysteries"}]],
    )
    # Back-compat shape: ["internet", ...]
    category_ids: List[str] = Field(
        default_factory=list,
        description="Selected topic category IDs",
        examples=[["tech", "business", "science"]],
    )

    category_labels: List[str] = Field(
        default_factory=list,
        description="Selected topic category labels",
        examples=["Technology", "Business", "Science"],
    )
    goal_ids: List[int] = Field(
        default_factory=list,
        description="Selected learning goal IDs",
        examples=[[1, 5]],
    )

    @model_validator(mode="before")
    @classmethod
    def _normalize_categories(cls, data):
        """
        Accept both:
        - categories: [{id, label}, ...]
        - category_ids: ["id", ...] (+ optional category_labels)
        Normalize into category_ids for persistence/validation.
        """
        if not isinstance(data, dict):
            return data

        categories = data.get("categories")
        category_ids = data.get("category_ids")

        if categories and (not category_ids):
            try:
                data["category_ids"] = [
                    (c.get("id") if isinstance(c, dict) else getattr(c, "id", None))
                    for c in categories
                ]
            except Exception:
                # Let pydantic surface the correct validation error
                return data

        return data


class OnboardingPreferencesResponse(BaseModel):
    language_level: Optional[int] = Field(
        None,
        description="User language level (CLB scale 4-9). Null if preferences not set.",
        examples=[6],
    )
    categories: List[TopicCategoryOut] = Field(
        default_factory=list,
        description="Selected categories (id/label objects).",
    )
    goal_ids: List[int] = Field(
        default_factory=list,
        description="Selected learning goal IDs.",
        examples=[[1, 5]],
    )
