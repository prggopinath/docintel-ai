from openai import OpenAI

from app.core.config import OPENAI_API_KEY, OPENAI_MODEL


class OpenAIService:

    def __init__(self):
        self.client = OpenAI(api_key=OPENAI_API_KEY)
        self.model = OPENAI_MODEL

    def generate_summary(self, text: str):
        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {
                        "role": "system",
                        "content": (
                            "You are an expert document analyst. "
                            "Summarize documents in 3-5 concise bullet points."
                        ),
                    },
                    {
                        "role": "user",
                        "content": text,
                    },
                ],
                temperature=0.2,
                max_tokens=300,
            )

            return True, response.choices[0].message.content or ""

        except Exception as ex:
            return False, str(ex)