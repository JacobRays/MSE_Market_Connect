import os, re, argparse
from datetime import datetime, timezone

# Force IPv4 on some GitHub runners (avoids "network is unreachable" from IPv6 routing)
import socket
try:
    import urllib3.util.connection as urllib3_cn
    urllib3_cn.allowed_gai_family = lambda: socket.AF_INET
except Exception:
    pass

import requests
from bs4 import BeautifulSoup
from supabase import create_client

URLS = [
    "https://www.mse.co.mw/market/mainboard",
    "https://mse.co.mw/market/mainboard",
]

KNOWN_NAMES = {
    "AIRTEL": "Airtel Malawi Plc",
    "BHL": "Blantyre Hotels Plc",
    "FDHB": "FDH Bank Plc",
    "FMBCH": "FMBcapital Holdings Plc",
    "ICON": "ICON Properties Plc",
    "ILLOVO": "Illovo Sugar (Malawi) Plc",
    "MPICO": "Malawi Property Investment Company Plc",
    "NBM": "National Bank of Malawi Plc",
    "NBS": "NBS Bank Plc",
    "NICO": "NICO Holdings Plc",
    "NITL": "National Investment Trust Plc",
    "OMU": "Old Mutual Limited",
    "PCL": "Press Corporation Plc",
    "STANDARD": "Standard Bank Malawi Plc",
    "SUNBIRD": "Sunbird Tourism Plc",
    "TNM": "Telekom Networks Malawi Plc",
}

def norm(s: str) -> str:
    return re.sub(r"\s+", " ", (s or "").strip().lower())

def num(s: str):
    if s is None:
        return None
    s = re.sub(r"[^\d\.\-\+]", "", s.strip().replace(",", ""))
    if s in ("", "+", "-"):
        return None
    try:
        return float(s)
    except:
        return None

def find_col(headers, wanted):
    hn = [norm(h) for h in headers]
    for i, h in enumerate(hn):
        for w in wanted:
            if w in h:
                return i
    return None

def fetch_html():
    last = None
    for url in URLS:
        try:
            r = requests.get(url, timeout=60, headers={"User-Agent": "Mozilla/5.0"})
            r.raise_for_status()
            return url, r.text
        except Exception as e:
            last = e
    raise SystemExit(f"Failed to fetch mainboard page. Last error: {last}")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    used_url, html = fetch_html()

    soup = BeautifulSoup(html, "html.parser")
    table = soup.find("table")
    if not table:
        raise SystemExit(f"No <table> found on the page: {used_url}")

    headers = [th.get_text(" ", strip=True) for th in table.find_all("th")]

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
        close_price = num(cols[close_i])
        if not symbol or close_price is None:
            continue

        open_price = num(cols[open_i]) if open_i is not None and open_i < len(cols) else None
        change_pct = num(cols[chg_i]) if chg_i is not None and chg_i < len(cols) else None
        volume     = num(cols[vol_i]) if vol_i is not None and vol_i < len(cols) else None
        turnover   = num(cols[turn_i]) if turn_i is not None and turn_i < len(cols) else None

        parsed.append({
            "symbol": symbol,
            "open_price": round(open_price, 2) if open_price is not None else None,
            "price": round(close_price, 2),
            "change_percent": round(change_pct, 2) if change_pct is not None else 0.0,
            "volume": int(volume) if volume is not None else 0,
            "turnover_mwk": round(turnover, 2) if turnover is not None else None,
        })

    if args.dry_run:
        print(f"Parsed rows: {len(parsed)} from {used_url}")
        for r in parsed:
            print(r)
        return

    sb = create_client(os.environ["SUPABASE_URL"], os.environ["SUPABASE_SERVICE_ROLE_KEY"])

    existing = sb.table("stocks").select("symbol,company_name").execute().data or []
    name_by_symbol = {r["symbol"]: (r.get("company_name") or "").strip() for r in existing if r.get("symbol")}
    print(f"Seeded symbols in DB: {len(name_by_symbol)}")

    now_iso = datetime.now(timezone.utc).isoformat()

    upserts = []
    for row in parsed:
        sym = row["symbol"]

        # MUST be non-null to satisfy NOT NULL, even during upsert.
        company_name = name_by_symbol.get(sym) or KNOWN_NAMES.get(sym) or sym

        upserts.append({
            "symbol": sym,
            "company_name": company_name,
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
