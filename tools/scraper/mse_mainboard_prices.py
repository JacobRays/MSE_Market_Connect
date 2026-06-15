import os, re, json, requests, datetime as dt
from bs4 import BeautifulSoup

def _to_num(t):
    try:
        clean = re.sub(r"[^0-9.\-]", "", t.replace(",",""))
        return float(clean) if clean else 0.0
    except: return 0.0

def main():
    url = "https://mse.co.mw/market/mainboard"
    headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'}
    
    print(f"Requesting {url}...")
    r = requests.get(url, headers=headers, timeout=30)
    soup = BeautifulSoup(r.text, "lxml")
    
    table = soup.find("table")
    if not table:
        print("Could not find table. Website might be blocking or layout changed.")
        print("HTML Snippet:", r.text[:500])
        return

    rows = []
    for tr in table.find_all("tr")[1:]:
        tds = [td.get_text(strip=True) for td in tr.find_all("td")]
        if len(tds) < 5: continue
        
        symbol = tds[0].upper()
        price = _to_num(tds[2]) 
        change = _to_num(tds[3])
        vol = int(_to_num(tds[4]))
        
        print(f"Parsed: {symbol} @ {price}")
        rows.append({
            "symbol": symbol, "price": price, "change_percent": change,
            "volume": vol, "updated_at": dt.datetime.utcnow().isoformat() + "Z"
        })
    
    if not rows: return

    sb_headers = {
        "apikey": os.environ["SUPABASE_SERVICE_ROLE_KEY"],
        "Authorization": "Bearer " + os.environ["SUPABASE_SERVICE_ROLE_KEY"],
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates"
    }
    res = requests.post(f"{os.environ['SUPABASE_URL']}/rest/v1/stocks?on_conflict=symbol", 
                  headers=sb_headers, data=json.dumps(rows))
    print(f"Supabase Status: {res.status_code}")

if __name__ == "__main__": main()
