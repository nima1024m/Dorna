import asyncio
import json
import csv
import re
from typing import List, Dict
from datetime import datetime
from app.core.agents.gemini import GeminiAgent

async def combined_demo_analysis(email: str, csv_path: str):
    print(f"--- FETCHING DATA FOR {email} ---")
    
    corrections = []
    with open(csv_path, mode='r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row.get('email') == email:
                corrections.append({
                    "original": row.get('user_text'),
                    "corrected": row.get('corrected_text'),
                    "explanation": row.get('error_type'),
                    "timestamp": row.get('test_date')
                })

    if not corrections:
        print(f"No data found for {email}")
        return

    # 1. SIMULATE INTERNAL ANALYTICS LAYER (Raw Data)
    unique_corrections = {}
    for c in corrections:
        unique_corrections[c['original']] = c
    final_list = list(unique_corrections.values())

    raw_grammar_counts = {}
    raw_spelling_all = {}
    
    # Simple inclusive spelling extractor for "Internal Stats"
    for c in final_list:
        expl = (c['explanation'] or "").lower()
        cats = [x.strip() for x in expl.split(",")]
        for cat in cats:
            if not any(k in cat for k in ["spelling", "typo"]):
                raw_grammar_counts[cat] = raw_grammar_counts.get(cat, 0) + 1
        
        # Capture raw spelling entries
        matches = re.finditer(r"<wrong>(.*?)</wrong><correct>(.*?)</correct>", c['corrected'])
        for m in matches:
            raw_spelling_all[m.group(1).strip()] = m.group(2).strip()

    internal_analytics = {
        "user": email,
        "raw_stats": {
            "total_processed_events": len(corrections),
            "unique_events": len(final_list),
            "error_frequency": raw_grammar_counts,
            "all_misspellings_detected": raw_spelling_all
        }
    }

    # 2. SIMULATE PERSONALIZED LEARNING LAYER (Filtered & Interpreted)
    agent = GeminiAgent()
    sample_for_ai = final_list[-15:]
    ai_output = await agent.extract_linguistic_patterns(sample_for_ai)
    
    # Filter spelling for Learning Profile
    EXCLUDED_SLANG = {"u": "you", "r": "are", "ur": "your", "y": "why", "n": "and"}
    filtered_spelling = {}
    for w, r in raw_spelling_all.items():
        w_l, r_l = w.lower(), r.lower()
        if EXCLUDED_SLANG.get(w_l) == r_l or w_l in EXCLUDED_SLANG: continue
        if len(r_l) > 3 and abs(len(w_l) - len(r_l)) <= 1 and w_l in r_l: continue
        filtered_spelling[w] = r

    personalized_profile = {
        "estimated_clb_level": ai_output.get("estimated_clb_level", "CLB 5"),
        "misspelled_words": ai_output.get("misspelled_words", {}),
        "linguistic_profile": ai_output.get("patterns", []),
        "language_development_grammar": ai_output.get("language_development_grammar", []),
        "vocabulary_improvement": ai_output.get("vocabulary_improvement", []),
        "overall_summary": ai_output.get("summary", "Keep practicing!"),
        "last_reviewed_at": datetime.now().isoformat()
    }

    print("\n" + "#" * 30)
    print("OUTPUT 1: INTERNAL ANALYTICS (Data Layer)")
    print("#" * 30)
    print(json.dumps(internal_analytics, indent=2))

    print("\n" + "#" * 30)
    print("OUTPUT 2: PERSONALIZED LEARNING PROFILE (Content Layer)")
    print("#" * 30)
    print(json.dumps(personalized_profile, indent=2))

if __name__ == "__main__":
    asyncio.run(combined_demo_analysis("aveeje@gmail.com", "data-1768261622154.csv"))
