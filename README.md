# TickerNormalizer

A tiny, dependency-free Swift utility that canonicalizes crypto-exchange ticker symbols, so the
same asset coming from different exchanges — in wildly different formats — deduplicates cleanly.

Eleven exchanges express *"Bitcoin perpetual"* eleven different ways. `TickerNormalizer.sanitize`
maps all of them to one symbol:

| Exchange | Raw symbol | → |
|---|---|---|
| Binance / Bybit / Bitget | `BTCUSDT` | `BTC` |
| OKX | `BTC-USDT-SWAP` | `BTC` |
| MEXC / Gate.io | `BTC_USDT` | `BTC` |
| Coinbase | `BTC-PERP-INTX` | `BTC` |
| KuCoin | `XBTUSDTM` | `BTC` |
| BingX | `BTC-USDT` | `BTC` |
| Kraken | `PF_XBTUSD` | `BTC` |
| Bitfinex | `tBTCF0:USTF0` | `BTC` |

```swift
import TickerNormalizer

TickerNormalizer.sanitize("BTCUSDT")        // "BTC"
TickerNormalizer.sanitize("BTC/USDT")       // "BTC"
TickerNormalizer.sanitize("tBTCF0:USTF0")   // "BTC"  (Bitfinex)
TickerNormalizer.sanitize("PF_XBTUSD")      // "BTC"  (Kraken, XBT→BTC alias)
TickerNormalizer.sanitize("ETH-USDC-SWAP")  // "ETH"  (OKX)
TickerNormalizer.sanitize("USDT")           // "USDT" (a bare suffix is not collapsed to empty)
```

## How it works

1. Strip a leading Bitfinex `t` — but only when an uppercase symbol follows, so `test` stays `TEST`.
2. Remove separators `/ - _ :`, then uppercase.
3. Strip a leading Kraken futures prefix **with its underscore** (`PF_` `PI_` `FI_` `FF_`),
   before the separators are removed. The underscore is the only thing that tells a venue
   prefix apart from the first two letters of a coin's name — without it `FIL` normalizes to
   `L` and `PIXELUSDT` to `XEL`.
4. Strip a trailing quote/contract suffix — **longest-first**, so `BTCUSDT` → `BTC`, never `BTCUS`.
5. Remap legacy base-currency aliases (`XBT` → `BTC`).

The subtle bits — suffix ordering, the `count > suffix.count` guard that stops a bare `USDT`
from collapsing to an empty string, and the case-aware Bitfinex prefix rule — are the parts that
break in naive implementations. They're all covered by tests.

## Install (Swift Package Manager)

```swift
.package(url: "https://github.com/OleksandrUskov/swift-ticker-normalizer.git", from: "1.0.0")
```

## Test

```bash
swift test
```

22 tests (Swift Testing), including a cross-exchange consistency check that every BTC-perp format
normalizes to `BTC`.

## Background

Extracted from **Cursaris**, a multi-exchange crypto-futures terminal — where deduplicating
positions imported from 11 exchanges depends entirely on getting this normalization right.

## License

MIT
