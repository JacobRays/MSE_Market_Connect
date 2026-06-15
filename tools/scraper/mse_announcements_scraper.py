import os, json, requests, datetime as dt
from bs4 import BeautifulSoup

def main():
    url = "https://mse.co.mw/announcements/market"
    headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36'}
    
    try:
        r = requests.get(url, headers=headers, timeout=30)
        soup = BeautifulSoup(r.text, "html.parser")
    except: return

    rows = []
    for a in soup.find_all("a", href=True):
        href = a['href']
        title = a.get_text(strip=True)
        if "/announcements/" in href and len(title) > 15:
            full_link = href if href.startswith("http") else "https://mse.co.mw" + href
            rows.append({
                "title": title, "excerpt": "Market Announcement", "category": "MSE",
                "published_at": dt.datetime.utcnow().isoformat() + "Z",
                "source_url": full_link
            })

    if rows:
        sb_headers = {
            "apikey": os.environ["SUPABASE_SERVICE_ROLE_KEY"],
            "Authorization": "Bearer " + os.environ["SUPABASE_SERVICE_ROLE_KEY"],
            "Content-Type": "application/json",
            "Prefer": "resolution=merge-duplicates"
        }
        requests.post(f"{os.environ['SUPABASE_URL']}/rest/v1/news?on_conflict=source_url", 
                      headers=sb_headers, data=json.dumps(rows))
        print(f"News Status: Updated")

if __name__ == "__main__": main()
