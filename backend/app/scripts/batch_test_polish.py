"""
Batch-test the polish feature via the tone_adjustment pipeline.

Usage:
    python -m app.scripts.batch_test_polish
"""
import asyncio
import json

from app.core.agents.gemini import GeminiAgent


TEST_INPUTS = [
    "When you reach work? everyone here waiting.",
    "hi i am go to park tomorrow with my friends do you want come?",
    "i really really need this file now!! pleaase sent it.",
    "I'm gonna be there in 5.",
    "im sorry i dont know nothing about it.",
    "she dont like the movie but i think its really good.",
    "can you helping me with this project its very important for my grade.",
]


async def run():
    agent = GeminiAgent()

    for text in TEST_INPUTS:
        print(f"\n{'='*60}")
        print(f"INPUT:  {text}")
        try:
            result = await agent.tone_adjustment(
                user_input=text,
                target_tone="polish",
                parent_tones=[],
                user_approved_tones=[],
            )
            print(f"STATUS: {result.get('status')}")
            print(f"OUTPUT: {result.get('adjusted')}")
            if result.get("_usage"):
                usage = result["_usage"]
                print(f"TOKENS: prompt={usage.get('prompt_tokens', 0)} "
                      f"completion={usage.get('completion_tokens', 0)} "
                      f"total={usage.get('total_tokens', 0)}")
        except Exception as e:
            print(f"ERROR:  {e}")

    print(f"\n{'='*60}")
    print("Done.")


if __name__ == "__main__":
    asyncio.run(run())
