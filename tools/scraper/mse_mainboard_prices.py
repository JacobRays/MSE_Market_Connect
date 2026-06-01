import os
import re
import json
import datetime as dt
import requests
from bs4 import BeautifulSoup

MSE_URL = "https://mse.co.mw/market/mainboard"

SUPABASE_URL = os.environ["SUPABASE_URL"].rstrip("/")
SUPABASE_SERVICE_ROLE_KEY = os.environ["SUPABASE_SERVICE_ROLE_KEY"]

def _to_number(text: str):
    if text is None:
        return None
    t = text.strip()
    if t == "" or t in ("-", "—", "N/A"):
        return None
    t = t.replace(",", "")
    t = re.sub(r"[^0-9.\-]", "", t)
    if t == "" or t == "." or t == "-" or t == "-.":
        return None
    try:
        return float(t)
    except ValueError:
        return None

def _to_int(text: str):
    n = _to_number(text)
    if n is None:
        return None
    return int(n)

def fetch_mainboard_html():
    headers = {
        "User-Agent": "MSEMarketConnectBot/1.0 (contact: support@premiumrays.mw)"
    }
    r = requests.get(MSE_URL, headers=headers, timeout=30)
    r.raise_for_status()
    return r.text

def parse_prices(html: str):
    soup = BeautifulSoup(html, "lxml")

    # Heuristic: pick the table that contains a header with "Symbol"
    tables = soup.find_all("table")
    if not tables:
        raise RuntimeError("No tables found on mainboard page (site HTML may have changed).")

    chosen = None
    for tbl in tables:
        th_text = " ".join([th.get_text(" ", strip=True).lower() for th in tbl.find_all("th")])
        if "symbol" in th_text and ("price" in th_text or "last" in th_text):
            chosen = tbl
            break

    if chosen is None:
        # fallback to first table
        chosen = tables[0]

    # Build header -> index map
    headers = [th.get_text(" ", strip=True) for th in chosen.find_all("th")]
    headers_l = [h.lower() for h in headers]

    def idx_of(*names):
        for n in names:
            n = n.lower()
            for i, h in enumerate(headers_l):
                if n in h:
                    return i
        return None

    i_symbol = idx_of("symbol")
    i_company = idx_of("company", "security")
    i_price = idx_of("price", "last")
    i_change = idx_of("change %", "change%","% change","change percent")
    i_volume = idx_of("volume")
    i_open = idx_of("open")
    i_turnover = idx_of("turnover")

    rows = []
    for tr in chosen.find_all("tr"):
        tds = tr.find_all("td")
        if not tds:
            continue

        # If headers missing, assume common ordering; but prefer header indices when available
        def safe_get(i):
            if i is None:
                return None
            if i < 0 or i >= len(tds):
                return None
            return tds[i].get_text(" ", strip=True)

        symbol = safe_get(i_symbol) or (tds[0].get_text(" ", strip=True) if len(tds) > 0 else None)
        if not symbol:
            continue

        symbol = symbol.strip().upper()
        # Skip weird rows
        if len(symbol) > 10:
            continue

        company = safe_get(i_company)
        price = _to_number(safe_get(i_price))
        change_percent = _to_number(safe_get(i_change))
        volume = _to_int(safe_get(i_volume))
        open_price = _to_number(safe_get(i_open))
        turnover_mwk = _to_number(safe_get(i_turnover))

        rows.append({
            "symbol": symbol,
            "company_name": company,
            "price": price,
            "change_percent": change_percent,
            "volume": volume,
            "open_price": open_price,
            "turnover_mwk": turnover_mwk,
            "is_active": True,
            "updated_at": dt.datetime.utcnow().isoformat() + "Z",
        })

    # Filter out junk rows with no price at all
    rows = [r for r in rows if r["price"] is not None]
    return rows

def upsert_to_supabase(rows):
    if not rows:
        print("No rows parsed; nothing to upsert.")
        return

    endpoint = f"{SUPABASE_URL}/rest/v1/stocks?on_conflict=symbol"
    headers = {
        "apikey": SUPABASE_SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates,return=minimal",
    }

    # Keep payload small-ish
    r = requests.post(endpoint, headers=headers, data=json.dumps(rows), timeout=30)
    if r.status_code >= 400:
        raise RuntimeError(f"Supabase upsert failed: {r.status_code} {r.text}")

    print(f"Upserted {len(rows)} rows into stocks.")

def main():
    html = fetch_mainboard_html()
    rows = parse_prices(html)
    print(f"Parsed {len(rows)} stock rows.")
    # Uncomment to debug quickly:
    # print(json.dumps(rows[:3], indent=2))
    upsert_to_supabase(rows)

if __name__ == "__main__":
    main()
