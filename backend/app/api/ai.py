from fastapi import APIRouter
from pydantic import BaseModel
from app.services.ai_service import AIService


router = APIRouter(
    prefix="/api/v1/ai",
    tags=["AI"],
)

service = AIService()
class SummaryRequest(BaseModel):
    text: str


class SummaryResponse(BaseModel):
    success: bool
    summary: str


@router.post("/summarize", response_model=SummaryResponse)
async def summarize(request: SummaryRequest):

    #summary = (
    #    f"This document contains approximately "
    #    f"{len(request.text.split())} words.\n\n"
    #    f"AI Summary generation is working successfully."
    #)

    success, result = service.summarize(request.text)

    return SummaryResponse(
        success=success,
        summary=result if success else "",
        error=None if success else result,
    )