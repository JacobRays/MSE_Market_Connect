import os
from datetime import datetime, timezone
from supabase import create_client

def main():
    sb = create_client(os.environ["SUPABASE_URL"], os.environ["SUPABASE_SERVICE_ROLE_KEY"])

    alerts = (
        sb.table("price_alerts")
        .select("id,user_id,stock_symbol,alert_type,condition,target_price")
        .eq("is_active", True)
        .execute()
        .data
        or []
    )

    if not alerts:
        print("No active alerts.")
        return

    symbols = sorted({a["stock_symbol"] for a in alerts if a.get("stock_symbol")})
    prices = (
        sb.table("stocks")
        .select("symbol,price")
        .in_("symbol", symbols)
        .execute()
        .data
        or []
    )
    price_by_symbol = {p["symbol"]: float(p["price"]) for p in prices if p.get("symbol") and p.get("price") is not None}

    now_iso = datetime.now(timezone.utc).isoformat()

    triggered_ids = []
    notifications = []

    for a in alerts:
        sym = a["stock_symbol"]
        current = price_by_symbol.get(sym)
        if current is None:
            continue

        target = float(a["target_price"])
        cond = a["condition"]  # gte | lte

        ok = (current >= target) if cond == "gte" else (current <= target)
        if not ok:
            continue

        triggered_ids.append(a["id"])

        alert_type = a["alert_type"]  # buy | sell
        title = f"Price alert triggered: {sym}"
        body = (
            f"{sym} is now MWK {current:.2f}. "
            f"Your {alert_type.upper()} target was MWK {target:.2f}."
        )

        notifications.append({
            "user_id": a["user_id"],
            "title": title,
            "body": body,
            "data": {
                "symbol": sym,
                "current_price": current,
                "target_price": target,
                "alert_type": alert_type,
                "condition": cond,
            },
            "created_at": now_iso,
        })

    if not triggered_ids:
        print("No alerts triggered.")
        return

    # auto-disable triggered alerts
    sb.table("price_alerts").update({
        "is_active": False,
        "triggered_at": now_iso,
    }).in_("id", triggered_ids).execute()

    sb.table("notifications").insert(notifications).execute()

    print(f"Triggered {len(triggered_ids)} alerts and created {len(notifications)} notifications.")

if __name__ == "__main__":
    main()
