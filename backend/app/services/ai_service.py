from app.services.openai_service import OpenAIService


class AIService:

    def __init__(self):
        self.provider = OpenAIService()

    def summarize(self, text: str):
        return self.provider.generate_summary(text)