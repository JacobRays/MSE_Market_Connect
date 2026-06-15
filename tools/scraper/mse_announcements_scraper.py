import os, json, requests, datetime as dt
from bs4 import BeautifulSoup

def main():
    url = "https://mse.co.mw/announcements/market"
    r = requests.get(url, timeout=30)
    soup = BeautifulSoup(r.text, "lxml")
    rows = []
    for a in soup.select("a[href*='announcements']")[:20]:
        title = a.get_text(strip=True)
        link = a["href"]
        if len(title) < 10: continue
        if link.startswith("/"): link = "https://mse.co.mw" + link
        rows.append({
            "title": title, "excerpt": title, "category": "MSE Announcements",
            "published_at": dt.datetime.utcnow().isoformat() + "Z",
            "source_url": link
        })

    headers = {
        "apikey": os.environ["SUPABASE_SERVICE_ROLE_KEY"],
        "Authorization": "Bearer " + os.environ["SUPABASE_SERVICE_ROLE_KEY"],
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates"
    }
    requests.post(f"{os.environ['SUPABASE_URL']}/rest/v1/news?on_conflict=source_url", 
                  headers=headers, data=json.dumps(rows))
    print(f"Updated {len(rows)} news items.")

if __name__ == "__main__": main()
