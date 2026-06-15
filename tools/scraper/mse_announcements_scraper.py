import os, json, requests, datetime as dt
from bs4 import BeautifulSoup

def main():
    url = "https://mse.co.mw/announcements/market"
    headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'}
    
    print(f"Requesting {url}...")
    r = requests.get(url, headers=headers, timeout=30)
    soup = BeautifulSoup(r.text, "lxml")
    
    rows = []
    # MSE usually puts announcements in a table or list
    for tr in soup.find_all("tr")[1:]:
        tds = tr.find_all("td")
        if len(tds) < 2: continue
        
        title = tds[1].get_text(strip=True)
        link_tag = tds[1].find("a")
        
        if link_tag and len(title) > 5:
            href = link_tag['href']
            full_link = href if href.startswith("http") else "https://mse.co.mw" + href
            rows.append({
                "title": title, "excerpt": "Market Announcement", "category": "MSE",
                "published_at": dt.datetime.utcnow().isoformat() + "Z",
                "source_url": full_link
            })

    if not rows: 
        print("No news found. Checking generic links...")
        for a in soup.find_all("a", href=True):
            if "/announcements/" in a['href'] and len(a.text) > 20:
                rows.append({
                    "title": a.text.strip(), "excerpt": "Market Announcement", "category": "MSE",
                    "published_at": dt.datetime.utcnow().isoformat() + "Z",
                    "source_url": "https://mse.co.mw" + a['href']
                })

    sb_headers = {
        "apikey": os.environ["SUPABASE_SERVICE_ROLE_KEY"],
        "Authorization": "Bearer " + os.environ["SUPABASE_SERVICE_ROLE_KEY"],
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates"
    }
    res = requests.post(f"{os.environ['SUPABASE_URL']}/rest/v1/news?on_conflict=source_url", 
                  headers=sb_headers, data=json.dumps(rows))
    print(f"Supabase Status: {res.status_code}")

if __name__ == "__main__": main()
