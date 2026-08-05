// deno-lint-ignore-file no-explicit-any
import "https://deno.land/x/dotenv@v3.2.2/load.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { DOMParser } from "https://deno.land/x/deno_dom@v0.1.45/deno-dom-wasm.ts";

const PROJECT_URL = Deno.env.get("PROJECT_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SERVICE_ROLE_KEY")!;
const sb = createClient(PROJECT_URL, SERVICE_ROLE_KEY, { auth: { persistSession: false } });

function num(s: string): number {
  const m = s.replaceAll(",", "").match(/-?\d+(\.\d+)?/);
  return m ? parseFloat(m[0]) : 0;
}

async function fetchViaProxy(url: string): Promise<string> {
  const proxies = [
    // ScrapingBee-style public proxies
    `https://api.allorigins.win/raw?url=${encodeURIComponent(url)}`,
    `https://corsproxy.io/?${encodeURIComponent(url)}`,
    `https://api.codetabs.com/v1/proxy?quest=${encodeURIComponent(url)}`,
    // Cloudflare worker proxy (no SSL validation)
    `https://workers.cloudflare.com/cf.json?url=${encodeURIComponent(url)}`,
  ];

  for (const proxy of proxies) {
    try {
      console.log(`Trying proxy: ${proxy}`);
      const res = await fetch(proxy, {
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        },
        signal: AbortSignal.timeout(10000),
      });

      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const text = await res.text();
      
      // Validate we got HTML
      if (!text.includes("<table") && !text.includes("mainboard")) {
        throw new Error("Invalid response (not HTML)");
      }
      
      console.log(`✓ Success via ${proxy.split("?")[0]}`);
      return text;
    } catch (err) {
      console.warn(`Proxy failed: ${err.message}`);
    }
  }

  throw new Error("All proxy attempts failed");
}

async function scrapeMainboard(): Promise<any[]> {
  const html = await fetchViaProxy("https://mse.co.mw/market/mainboard");
  
  const doc = new DOMParser().parseFromString(html, "text/html");
  if (!doc) throw new Error("Failed to parse HTML");

  const rows = doc.querySelectorAll("table tbody tr");
  if (rows.length === 0) {
    // Try alternative selectors
    const altRows = doc.querySelectorAll("table tr");
    if (altRows.length === 0) throw new Error("No table rows found");
  }

  const data = Array.from(rows.length > 0 ? rows : doc.querySelectorAll("table tr")).map((row) => {
    const cells = row.querySelectorAll("td");
    if (cells.length < 5) return null;
    
    return {
      symbol: cells[0]?.textContent.trim() || "",
      price: num(cells[1]?.textContent || "0"),
      change: num(cells[2]?.textContent || "0"),
      volume: num(cells[3]?.textContent || "0"),
      value: num(cells[4]?.textContent || "0"),
    };
  }).filter((r) => r && r.symbol);

  console.log(`✓ Scraped ${data.length} stocks`);
  return data;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: { "Access-Control-Allow-Origin": "*" } });
  }

  try {
    const stocks = await scrapeMainboard();

    if (stocks.length === 0) {
      throw new Error("No stocks scraped - check HTML structure");
    }

    for (const stock of stocks) {
      await sb.from("stocks").upsert({
        symbol: stock.symbol,
        price: stock.price,
        change: stock.change,
        volume: stock.volume,
        value: stock.value,
        updated_at: new Date().toISOString(),
      }, { onConflict: "symbol" });
    }

    return new Response(JSON.stringify({ 
      success: true, 
      count: stocks.length,
      stocks 
    }), {
      headers: { 
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
    });

  } catch (error) {
    console.error("Error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
    });
  }
});
