import os
import re
import argparse
from datetime import datetime, timezone

import requests
from bs4 import BeautifulSoup
from supabase import create_client

URL_DEFAULT = "https://mse.co.mw/market/mainboard"

def norm(s: str) -> str:
    return re.sub(r"\s+", " ", (s or "").strip().lower())

def num(s: str):
    if s is None:
        return None
    s = s.strip().replace(",", "")
    s = re.sub(r"[^\d\.\-\+]", "", s)  # remove MK, %, etc.
    if s in ("", "+", "-"):
        return None
    try:
        return float(s)
    except:
        return None

def find_col(headers, wanted):
    headers_n = [norm(h) for h in headers]
    for i, h in enumerate(headers_n):
        for w in wanted:
            if w in h:
                return i
    return None

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--url", default=URL_DEFAULT)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    r = requests.get(args.url, timeout=45, headers={"User-Agent": "Mozilla/5.0"})
    r.raise_for_status()

    soup = BeautifulSoup(r.text, "html.parser")
    table = soup.find("table")
    if not table:
        raise SystemExit("No <table> found on the page.")

    headers = [th.get_text(" ", strip=True) for th in table.find_all("th")]
    if not headers:
        raise SystemExit("Table found but no headers (<th>) found.")

    symbol_i = find_col(headers, ["symbol"])
    open_i   = find_col(headers, ["open price", "open"])
    close_i  = find_col(headers, ["close price", "close"])
    chg_i    = find_col(headers, ["% change", "change"])
    vol_i    = find_col(headers, ["volume"])
    turn_i   = find_col(headers, ["turnover"])

    if symbol_i is None or close_i is None:
        raise SystemExit(f"Could not detect required columns. Headers: {headers}")

    body = table.find("tbody") or table
    parsed = []
    for tr in body.find_all("tr"):
        tds = tr.find_all("td")
        if not tds:
            continue
        cols = [td.get_text(" ", strip=True) for td in tds]

        if symbol_i >= len(cols) or close_i >= len(cols):
            continue

        symbol = re.sub(r"[^A-Za-z0-9_-]", "", cols[symbol_i]).upper().strip()
        if not symbol:
            continue

        open_price = num(cols[open_i]) if open_i is not None and open_i < len(cols) else None
        close_price = num(cols[close_i])
        change_percent = num(cols[chg_i]) if chg_i is not None and chg_i < len(cols) else None
        volume = num(cols[vol_i]) if vol_i is not None and vol_i < len(cols) else None
        turnover = num(cols[turn_i]) if turn_i is not None and turn_i < len(cols) else None

        if close_price is None:
            continue

        parsed.append({
            "symbol": symbol,
            "open_price": round(open_price, 2) if open_price is not None else None,
            "price": round(close_price, 2),  # 'price' == close price in our DB
            "change_percent": round(change_percent, 2) if change_percent is not None else 0.0,
            "volume": int(volume) if volume is not None else 0,
            "turnover_mwk": round(turnover, 2) if turnover is not None else None,
        })

    if args.dry_run:
        for row in parsed:
            print(row)
        print(f"\nParsed rows: {len(parsed)}")
        return

    supabase_url = os.environ["SUPABASE_URL"]
    service_key = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
    sb = create_client(supabase_url, service_key)

    now_iso = datetime.now(timezone.utc).isoformat()

    # Upsert by symbol (updates prices daily)
    upserts = []
    for row in parsed:
        upserts.append({
            "symbol": row["symbol"],
            "open_price": row["open_price"],
            "price": row["price"],
            "change_percent": row["change_percent"],
            "volume": row["volume"],
            "turnover_mwk": row["turnover_mwk"],
            "updated_at": now_iso,
            "is_active": True,
        })

    sb.table("stocks").upsert(upserts, on_conflict="symbol").execute()
    print(f"Upserted {len(upserts)} rows into stocks.")

if __name__ == "__main__":
    main()
