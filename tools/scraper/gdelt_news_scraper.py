import os, json, requests
from datetime import datetime, timezone

SUPABASE_URL = os.environ["SUPABASE_URL"].rstrip("/")
SUPABASE_SERVICE_ROLE_KEY = os.environ["SUPABASE_SERVICE_ROLE_KEY"]

# Tune these queries as you like
QUERIES = [
  "Malawi Stock Exchange",
  "MSE Malawi",
  "Malawi business",
]

def fetch_gdelt(query: str):
  params = {
    "query": query,
    "mode": "ArtList",
    "format": "json",
    "maxrecords": 50,
    "sort": "datedesc",
  }
  r = requests.get("https://api.gdeltproject.org/api/v2/doc/doc", params=params, timeout=30)
  r.raise_for_status()
  return r.json()

def upsert_news(rows):
  if not rows:
    print("No rows to upsert.")
    return

  endpoint = f"{SUPABASE_URL}/rest/v1/news?on_conflict=source_url"
  headers = {
    "apikey": SUPABASE_SERVICE_ROLE_KEY,
    "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "resolution=merge-duplicates,return=minimal",
  }
  resp = requests.post(endpoint, headers=headers, data=json.dumps(rows), timeout=30)
  print("Supabase news upsert status:", resp.status_code)
  if resp.status_code >= 400:
    raise RuntimeError(resp.text)

def main():
  now = datetime.now(timezone.utc).isoformat()

  out = []
  for q in QUERIES:
    data = fetch_gdelt(q)
    arts = data.get("articles", [])
    print(f"GDELT query '{q}' returned {len(arts)} articles")
    for a in arts:
      title = (a.get("title") or "").strip()
      url = (a.get("url") or "").strip()
      if not title or not url:
        continue

      # GDELT has "seendate" like "20250615120000"
      seendate = (a.get("seendate") or "").strip()
      published_at = now
      if len(seendate) == 14 and seendate.isdigit():
        published_at = f"{seendate[0:4]}-{seendate[4:6]}-{seendate[6:8]}T{seendate[8:10]}:{seendate[10:12]}:{seendate[12:14]}Z"

      out.append({
        "title": title,
        "excerpt": (a.get("sourceCountry") or "Business News"),
        "category": "Business",
        "published_at": published_at,
        "source_url": url,
        "image_url": None,
      })

  # De-dupe by URL
  seen = set()
  deduped = []
  for r in out:
    if r["source_url"] in seen:
      continue
    seen.add(r["source_url"])
    deduped.append(r)

  upsert_news(deduped)
  print("Upserted (deduped) news:", len(deduped))

if __name__ == "__main__":
  main()
