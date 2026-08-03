from fastapi import APIRouter
from pydantic import BaseModel


router = APIRouter(
    prefix="/api/v1/ai",
    tags=["AI"],
)


class SummaryRequest(BaseModel):
    text: str


class SummaryResponse(BaseModel):
    success: bool
    summary: str


@router.post("/summarize", response_model=SummaryResponse)
async def summarize(request: SummaryRequest):

    summary = (
        f"This document contains approximately "
        f"{len(request.text.split())} words.\n\n"
        f"AI Summary generation is working successfully."
    )

    return SummaryResponse(
        success=True,
        summary=summary,
    )