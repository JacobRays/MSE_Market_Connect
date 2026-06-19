import os, json, requests, datetime as dt
from bs4 import BeautifulSoup

def main():
    url = "https://www.nyasatimes.com/category/business/"
    headers = {'User-Agent': 'Mozilla/5.0'}
    
    print(f"Fetching news from {url}...")
    r = requests.get(url, headers=headers, timeout=30)
    soup = BeautifulSoup(r.text, "html.parser")
    
    rows = []
    # Targeting Nyasa Times Business headlines
    for a in soup.select('h3.entry-title a'):
        title = a.get_text(strip=True)
        link = a['href']
        
        if len(title) > 15:
            rows.append({
                "title": title, 
                "excerpt": "Latest Malawi business update.", 
                "category": "Business",
                "published_at": dt.datetime.utcnow().isoformat() + "Z",
                "source_url": link
            })

    if not rows:
        print("No news found.")
        return

    headers = {
        "apikey": os.environ["SUPABASE_SERVICE_ROLE_KEY"],
        "Authorization": "Bearer " + os.environ["SUPABASE_SERVICE_ROLE_KEY"],
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates"
    }
    res = requests.post(f"{os.environ['SUPABASE_URL']}/rest/v1/news?on_conflict=source_url", 
                  headers=headers, data=json.dumps(rows))
    print(f"News Status: {res.status_code}")

if __name__ == "__main__": main()
