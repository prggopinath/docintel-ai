from fastapi import APIRouter

router = APIRouter(
    prefix="/api/v1/health",
    tags=["Health"],
)


@router.get("")
async def health():
    return {
        "status": "healthy",
        "service": "Docurator AI API",
        "version": "0.1.0",
    }