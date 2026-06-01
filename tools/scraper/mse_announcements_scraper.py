import os
import re
import json
import datetime as dt
import requests
from bs4 import BeautifulSoup

ANN_URL = "https://mse.co.mw/announcements/market"

SUPABASE_URL = os.environ["SUPABASE_URL"].rstrip("/")
SUPABASE_SERVICE_ROLE_KEY = os.environ["SUPABASE_SERVICE_ROLE_KEY"]

def _clean(s):
    return re.sub(r"\s+", " ", (s or "").strip())

def _parse_date(text):
    t = _clean(text)
    if not t:
        return None
    # Try a few common patterns (site may change)
    for fmt in ("%d %b %Y", "%d %B %Y", "%Y-%m-%d"):
        try:
            d = dt.datetime.strptime(t, fmt)
            return d.replace(tzinfo=dt.timezone.utc).isoformat().replace("+00:00", "Z")
        except ValueError:
            pass
    return None

def fetch():
    headers = {"User-Agent": "MSEMarketConnectBot/1.0 (contact: support@premiumrays.mw)"}
    r = requests.get(ANN_URL, headers=headers, timeout=30)
    r.raise_for_status()
    return r.text

def parse(html):
    soup = BeautifulSoup(html, "lxml")

    # Collect links that look like announcement items.
    # If the site structure changes, we’ll refine this selector.
    links = soup.select("a[href]")
    items = []
    for a in links:
        href = a.get("href", "")
        title = _clean(a.get_text(" ", strip=True))
        if not title or len(title) < 8:
            continue
        # Heuristic: keep announcement-ish URLs and avoid menus
        if "announcements" not in href:
            continue

        if href.startswith("/"):
            href = "https://mse.co.mw" + href

        items.append((title, href))

    # De-dup by URL
    seen = set()
    uniq = []
    for title, href in items:
        if href in seen:
            continue
        seen.add(href)
        uniq.append((title, href))

    rows = []
    now = dt.datetime.utcnow().replace(tzinfo=dt.timezone.utc).isoformat().replace("+00:00", "Z")
    for title, href in uniq[:60]:
        rows.append({
            "title": title,
            "excerpt": title,          # lightweight: use title as excerpt; can improve later
            "category": "MSE Announcements",
            "published_at": now,       # if the list has dates we can parse them later
            "source_url": href,
            "image_url": None,
        })
    return rows

def upsert(rows):
    if not rows:
        print("No news rows parsed.")
        return

    endpoint = f"{SUPABASE_URL}/rest/v1/news?on_conflict=source_url"
    headers = {
        "apikey": SUPABASE_SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates,return=minimal",
    }
    r = requests.post(endpoint, headers=headers, data=json.dumps(rows), timeout=30)
    if r.status_code >= 400:
        raise RuntimeError(f"Supabase upsert failed: {r.status_code} {r.text}")
    print(f"Upserted {len(rows)} news rows.")

def main():
    html = fetch()
    rows = parse(html)
    print(f"Parsed {len(rows)} news rows.")
    upsert(rows)

if __name__ == "__main__":
    main()
