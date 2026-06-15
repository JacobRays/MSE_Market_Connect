import os, re, json, requests, datetime as dt
from bs4 import BeautifulSoup

def _to_num(t):
    try: return float(re.sub(r"[^0-9.\-]", "", t.replace(",","")))
    except: return None

def main():
    url = "https://mse.co.mw/market/mainboard"
    r = requests.get(url, timeout=30)
    soup = BeautifulSoup(r.text, "lxml")
    rows = []
    for tr in soup.find_all("tr")[1:]:
        tds = [td.get_text(strip=True) for td in tr.find_all("td")]
        if len(tds) < 5: continue
        rows.append({
            "symbol": tds[0], "company_name": tds[1],
            "price": _to_num(tds[2]), "change_percent": _to_num(tds[4]),
            "volume": int(_to_num(tds[3]) or 0), "is_active": True,
            "updated_at": dt.datetime.utcnow().isoformat() + "Z"
        })
    
    # Upsert to Supabase via REST
    headers = {
        "apikey": os.environ["SUPABASE_SERVICE_ROLE_KEY"],
        "Authorization": "Bearer " + os.environ["SUPABASE_SERVICE_ROLE_KEY"],
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates"
    }
    requests.post(f"{os.environ['SUPABASE_URL']}/rest/v1/stocks?on_conflict=symbol", 
                  headers=headers, data=json.dumps(rows))
    print(f"Updated {len(rows)} stocks.")

if __name__ == "__main__": main()
