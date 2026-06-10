import asyncio
import json
import csv
import re
from typing import List, Dict
from app.core.agents.gemini import GeminiAgent

async def analyze_from_csv(email: str, csv_path: str):
    print(f"Reading data for {email} from CSV...")
    
    corrections = []
    with open(csv_path, mode='r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        # Note: Depending on CSV format, keys might be different. Let's assume the headers from first row.
        # IDs: user_id, full_name, email, user_text, corrected_text, error_type, test_date
        for row in reader:
            if row.get('email') == email:
                corrections.append({
                    "original": row.get('user_text'),
                    "corrected": row.get('corrected_text'),
                    "explanation": row.get('error_type')
                })

    if not corrections:
        print(f"No data found for {email}")
        return

    print(f"Found {len(corrections)} entries. Deduplicating and analyzing...")
    
    # Deduplicate by original text
    unique_corrections = {}
    for c in corrections:
        unique_corrections[c['original']] = c
    
    final_list = list(unique_corrections.values())
    print(f"Unique entries: {len(final_list)}")

    # Aggregated Grammar Issues for the summary
    grammar_counts = {}
    misspelled_words = {}

    # Simple spelling extractor for the demo
    def extract_spells(text, expl):
        res = {}
        if not expl or not text: return res
        EXCLUDED_SLANG = {"u": "you", "r": "are", "ur": "your", "y": "why", "n": "and"}
        
        if any(k in expl.lower() for k in ["spelling", "typo", "misspell"]):
            matches = re.finditer(r"<wrong>(.*?)</wrong><correct>(.*?)</correct>", text)
            for m in matches:
                wrong = m.group(1).strip().lower()
                correct = m.group(2).strip().lower()
                
                # Filter slang
                if EXCLUDED_SLANG.get(wrong) == correct or wrong in EXCLUDED_SLANG:
                    continue
                # Filter minor typos
                if len(correct) > 3:
                    if abs(len(wrong) - len(correct)) <= 1 and wrong in correct:
                        continue

                if len(wrong.split()) == 1:
                    res[wrong] = correct
        return res

    for c in final_list:
        p = [x.strip().lower() for x in (c['explanation'] or "").split(",")]
        for pattern in p:
            if not any(k in pattern for k in ["spelling", "typo"]):
                grammar_counts[pattern] = grammar_counts.get(pattern, 0) + 1
        
        sp = extract_spells(c['corrected'], c['explanation'])
        misspelled_words.update(sp)

    print("\nCalling AI for Deep Linguistic Profiling...")
    agent = GeminiAgent()
    
    # Take a sample of 15 for deep pattern analysis
    sample_for_patterns = final_list[-15:]
    profile = await agent.extract_linguistic_patterns(sample_for_patterns)
    
    # Get top grammar and spelling for summary
    top_grammar = dict(sorted(grammar_counts.items(), key=lambda x: x[1], reverse=True)[:10])
    sample_spelling = dict(list(misspelled_words.items())[-20:])
    
    summary_res = await agent.user_learning_summary(top_grammar, sample_spelling)

    output = {
        "user_email": email,
        "total_errors_analyzed": len(final_list),
        "clb_level": profile.get("clb_level", 0),
        "top_grammar_issues": top_grammar,
        "misspelled_words": misspelled_words,
        "linguistic_profile": profile.get("patterns", []),
        "learning_path": profile.get("learning_path", []),
        "overall_summary": summary_res.get("summary") if not profile.get("summary") else profile.get("summary")
    }

    print("\n" + "="*50)
    print("FINAL ANALYSIS OUTPUT (JSON)")
    print("="*50)
    print(json.dumps(output, indent=2, ensure_ascii=False))

if __name__ == "__main__":
    asyncio.run(analyze_from_csv("asgari@thepersa.com", "data-1768261622154.csv"))
