import os, re, json, requests, datetime as dt
from bs4 import BeautifulSoup

def _to_num(t):
    try:
        clean = re.sub(r"[^0-9.\-]", "", t.replace(",",""))
        return float(clean) if clean else 0.0
    except: return 0.0

def main():
    url = "https://mse.co.mw/market/mainboard"
    print(f"Fetching prices from {url}...")
    r = requests.get(url, timeout=30)
    soup = BeautifulSoup(r.text, "lxml")
    
    rows = []
    table = soup.find("table")
    if not table:
        print("Error: No table found on MSE page!")
        return

    for tr in table.find_all("tr")[1:]:
        tds = [td.get_text(strip=True) for td in tr.find_all("td")]
        if len(tds) < 5: continue
        
        symbol = tds[0].upper()
        price = _to_num(tds[2]) # Close Price column
        change = _to_num(tds[3]) # % Change column
        vol = int(_to_num(tds[4])) # Volume column
        
        print(f"Parsed: {symbol} - {price}")
        rows.append({
            "symbol": symbol,
            "price": price,
            "change_percent": change,
            "volume": vol,
            "updated_at": dt.datetime.utcnow().isoformat() + "Z"
        })
    
    if not rows:
        print("No stock data parsed!")
        return

    headers = {
        "apikey": os.environ["SUPABASE_SERVICE_ROLE_KEY"],
        "Authorization": "Bearer " + os.environ["SUPABASE_SERVICE_ROLE_KEY"],
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates"
    }
    res = requests.post(f"{os.environ['SUPABASE_URL']}/rest/v1/stocks?on_conflict=symbol", 
                  headers=headers, data=json.dumps(rows))
    print(f"Supabase Response: {res.status_code}")
    print(f"Successfully updated {len(rows)} stocks.")

if __name__ == "__main__": main()
