import os, re, json, requests, datetime as dt
from bs4 import BeautifulSoup

def _to_num(t):
    try:
        clean = re.sub(r"[^0-9.\-]", "", t.replace(",",""))
        return float(clean) if clean else 0.0
    except: return 0.0

def main():
    url = "https://mse.co.mw/market/mainboard"
    r = requests.get(url, timeout=30)
    soup = BeautifulSoup(r.text, "lxml")
    rows = []
    
    table = soup.find("table")
    for tr in table.find_all("tr")[1:]:
        tds = [td.get_text(strip=True) for td in tr.find_all("td")]
        if len(tds) < 5: continue
        
        symbol = tds[0].upper()
        # Based on your screenshot: Index 2 is Close Price, Index 3 is % Change, Index 4 is Vol
        price = _to_num(tds[2]) 
        change = _to_num(tds[3])
        vol = int(_to_num(tds[4]))
        
        print(f"Parsed: {symbol} @ {price}")
        rows.append({
            "symbol": symbol, "price": price, "change_percent": change,
            "volume": vol, "updated_at": dt.datetime.utcnow().isoformat() + "Z"
        })
    
    headers = {
        "apikey": os.environ["SUPABASE_SERVICE_ROLE_KEY"],
        "Authorization": "Bearer " + os.environ["SUPABASE_SERVICE_ROLE_KEY"],
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates"
    }
    res = requests.post(f"{os.environ['SUPABASE_URL']}/rest/v1/stocks?on_conflict=symbol", 
                  headers=headers, data=json.dumps(rows))
    print(f"Supabase Price Response: {res.status_code}")
    if res.status_code >= 400: print(f"Error Details: {res.text}")

if __name__ == "__main__": main()
