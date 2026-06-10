import csv
from collections import Counter

def list_unique_users_with_counts(csv_path: str):
    user_counts = Counter()
    user_info = {}
    
    try:
        with open(csv_path, mode='r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                email = row.get('email')
                if email:
                    user_counts[email] += 1
                    if email not in user_info:
                        user_info[email] = {
                            "full_name": row.get('full_name'),
                            "user_id": row.get('user_id')
                        }
        
        # Sort by count descending
        sorted_users = sorted(user_counts.items(), key=lambda x: x[1], reverse=True)
        
        print(f"{'Email':<30} | {'Messages':<10} | {'Full Name':<20} | {'User ID':<10}")
        print("-" * 75)
        for email, count in sorted_users:
            info = user_info[email]
            print(f"{email:<30} | {count:<10} | {str(info['full_name']):<20} | {str(info['user_id']):<10}")
            
        print(f"\nTotal unique users found: {len(user_counts)}")
        print(f"Total messages analyzed: {sum(user_counts.values())}")
    except Exception as e:
        print(f"Error reading CSV: {e}")

if __name__ == "__main__":
    list_unique_users_with_counts("data-1768261622154.csv")
