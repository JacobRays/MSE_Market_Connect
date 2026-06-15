import os, re, json, requests, datetime as dt
from bs4 import BeautifulSoup

def _to_num(t):
    try:
        clean = re.sub(r"[^0-9.\-]", "", t.replace(",",""))
        return float(clean) if clean else 0.0
    except: return 0.0

def main():
    url = "https://mse.co.mw/market/mainboard"
    headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36'}
    
    print(f"DEBUG: Starting request to {url}")
    try:
        r = requests.get(url, headers=headers, timeout=30)
        r.raise_for_status()
    except Exception as e:
        print(f"DEBUG: Request failed: {e}")
        return

    soup = BeautifulSoup(r.text, "html.parser")
    target_table = None
    
    # Look for any table containing AIRTEL or Symbol
    for table in soup.find_all("table"):
        if "AIRTEL" in table.text or "Symbol" in table.text:
            target_table = table
            break

    if target_table is None:
        print("DEBUG: Table not found. HTML snippet:")
        print(r.text[:500])
        return

    rows = []
    # This is line 34 now, not 17.
    for tr in target_table.find_all("tr"):
        tds = [td.get_text(strip=True) for td in tr.find_all("td")]
        if len(tds) < 3: continue
        
        symbol = tds[0].upper()
        if not re.match(r"^[A-Z0-9]{2,10}$", symbol): continue
        
        price = _to_num(tds[2])
        change = _to_num(tds[3]) if len(tds) > 3 else 0.0
        vol = int(_to_num(tds[4])) if len(tds) > 4 else 0
        
        print(f"Parsed: {symbol} @ {price}")
        rows.append({
            "symbol": symbol, "price": price, "change_percent": change,
            "volume": vol, "updated_at": dt.datetime.utcnow().isoformat() + "Z"
        })
    
    if rows:
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
