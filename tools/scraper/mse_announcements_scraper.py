import os, json, requests, datetime as dt
from bs4 import BeautifulSoup

def main():
    url = "https://mse.co.mw/announcements/market"
    r = requests.get(url, timeout=30)
    soup = BeautifulSoup(r.text, "lxml")
    rows = []
    
    # Targeting the table rows for announcements
    for tr in soup.find_all("tr")[1:]:
        tds = tr.find_all("td")
        if len(tds) < 2: continue
        
        title = tds[1].get_text(strip=True)
        link_tag = tds[1].find("a")
        
        if link_tag and len(title) > 5:
            href = link_tag['href']
            full_link = href if href.startswith("http") else "https://mse.co.mw" + href
            print(f"Found News: {title[:40]}...")
            rows.append({
                "title": title, "excerpt": "New MSE Announcement", "category": "MSE Announcements",
                "published_at": dt.datetime.utcnow().isoformat() + "Z",
                "source_url": full_link
            })

    headers = {
        "apikey": os.environ["SUPABASE_SERVICE_ROLE_KEY"],
        "Authorization": "Bearer " + os.environ["SUPABASE_SERVICE_ROLE_KEY"],
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates"
    }
    res = requests.post(f"{os.environ['SUPABASE_URL']}/rest/v1/news?on_conflict=source_url", 
                  headers=headers, data=json.dumps(rows))
    print(f"Supabase News Response: {res.status_code}")
    if res.status_code >= 400: print(f"Error Details: {res.text}")

if __name__ == "__main__": main()
