import os
from datetime import datetime, timezone
from supabase import create_client

def main():
    sb = create_client(os.environ["SUPABASE_URL"], os.environ["SUPABASE_SERVICE_ROLE_KEY"])
    now_iso = datetime.now(timezone.utc).isoformat()

    alerts = sb.table("price_alerts") \
        .select("id,user_id,stock_symbol,alert_type,condition,target_price") \
        .eq("is_active", True) \
        .execute().data or []

    if not alerts:
        print("No active alerts to evaluate.")
        return

    symbols = sorted({a["stock_symbol"] for a in alerts if a.get("stock_symbol")})
    stocks = sb.table("stocks") \
        .select("symbol,price") \
        .in_("symbol", symbols) \
        .execute().data or []

    price_by_symbol = {s["symbol"]: float(s["price"]) for s in stocks if s.get("symbol") and s.get("price") is not None}

    triggered_ids = []
    notifications = []

    for a in alerts:
        sym = a["stock_symbol"]
        current = price_by_symbol.get(sym)
        if current is None:
            continue

        target = float(a["target_price"])
        cond = a["condition"]  # gte | lte

        hit = (current >= target) if cond == "gte" else (current <= target)
        if not hit:
            continue

        triggered_ids.append(a["id"])
        side = (a["alert_type"] or "alert").upper()

        notifications.append({
            "user_id": a["user_id"],
            "title": f"Price alert hit: {sym}",
            "body": f"{side} target MWK {target:.2f} reached. Current: MWK {current:.2f}",
            "data": {
                "alert_id": a["id"],
                "symbol": sym,
                "target": target,
                "current": current,
                "type": a["alert_type"],
                "condition": cond,
            },
            "created_at": now_iso,
        })

    if not triggered_ids:
        print(f"Evaluated {len(alerts)} alerts. None triggered.")
        return

    # Mark triggered (disable + timestamp)
    sb.table("price_alerts") \
        .update({"is_active": False, "triggered_at": now_iso}) \
        .in_("id", triggered_ids) \
        .execute()

    # Insert notifications
    sb.table("notifications").insert(notifications).execute()

    print(f"Triggered {len(triggered_ids)} alerts and inserted {len(notifications)} notifications.")

if __name__ == "__main__":
    main()
