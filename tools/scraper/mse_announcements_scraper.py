import os, json, requests, datetime as dt
from bs4 import BeautifulSoup

def main():
    url = "https://mse.co.mw/announcements/market"
    print(f"Fetching news from {url}...")
    r = requests.get(url, timeout=30)
    soup = BeautifulSoup(r.text, "lxml")
    
    rows = []
    # Find all links that contain 'announcements' in the URL
    links = soup.find_all("a", href=True)
    
    for a in links:
        href = a['href']
        title = a.get_text(strip=True)
        
        if "/announcements/" in href and len(title) > 15:
            full_link = href if href.startswith("http") else "https://mse.co.mw" + href
            
            print(f"Found News: {title[:30]}...")
            rows.append({
                "title": title, 
                "excerpt": "Click to read the full announcement on MSE.", 
                "category": "MSE Announcements",
                "published_at": dt.datetime.utcnow().isoformat() + "Z",
                "source_url": full_link
            })

    if not rows:
        print("No news items found!")
        return

    headers = {
        "apikey": os.environ["SUPABASE_SERVICE_ROLE_KEY"],
        "Authorization": "Bearer " + os.environ["SUPABASE_SERVICE_ROLE_KEY"],
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates"
    }
    res = requests.post(f"{os.environ['SUPABASE_URL']}/rest/v1/news?on_conflict=source_url", 
                  headers=headers, data=json.dumps(rows))
    print(f"Supabase Response: {res.status_code}")
    print(f"Successfully updated {len(rows)} news items.")

if __name__ == "__main__": main()
