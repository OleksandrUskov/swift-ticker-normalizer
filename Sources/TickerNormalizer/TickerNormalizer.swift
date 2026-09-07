import Foundation

/// Canonicalizes exchange ticker symbols to a single comparable form, so the same
/// asset arriving from different exchanges (in wildly different formats) deduplicates cleanly.
///
/// The problem: eleven exchanges express "Bitcoin perpetual" eleven different ways —
/// `BTCUSDT` (Binance), `BTC-USDT-SWAP` (OKX), `XBTUSDTM` (KuCoin), `PF_XBTUSD` (Kraken),
/// `tBTCF0:USTF0` (Bitfinex), `BTC-PERP-INTX` (Coinbase)… `sanitize` maps all of them to `BTC`.
///
/// Pipeline:
/// 1. strip a leading Bitfinex `t` (only when an uppercase symbol follows, so `test` stays `TEST`)
/// 2. uppercase
/// 3. strip a leading Kraken futures prefix **with its underscore** (`PF_` `PI_` `FI_` `FF_`)
/// 4. remove separators `/ - _ :`
/// 5. strip a trailing quote/contract suffix (longest-first, so `BTCUSDT` → `BTC`, never `BTCUS`)
/// 6. remap legacy base-currency aliases (`XBT` → `BTC`)
public enum TickerNormalizer {

    /// Trailing suffixes to strip, ordered **longest-first**.
    ///
    /// Order matters: `USDT` must come before `USD` so `BTCUSDT` → `BTC` (not `BTCUS`);
    /// `USDTSWAP`/`USDTM` come before `USDT` for OKX/KuCoin; `F0USTF0`/`F0BTCF0` cover Bitfinex
    /// perpetuals (`tBTCF0:USTF0` → … → `BTCF0USTF0` → `BTC`).
    private static let suffixes = [
        "F0USTF0", "F0BTCF0", "PERPINTX", "USDTSWAP", "USDCSWAP",
        "USDTM", "USDCM", "USDT", "USDC", "BUSD", "USD", "PERP",
    ]

    /// Base-currency aliases applied **after** suffix stripping.
    /// KuCoin/Kraken use the legacy `XBT` for Bitcoin.
    private static let aliases: [String: String] = [
        "XBT": "BTC",
    ]

    /// Returns the canonical symbol for any exchange ticker or user input.
    ///
    /// A guard (`count > suffix.count`) keeps a string that *is* a suffix from collapsing to
    /// empty — `sanitize("USDT") == "USDT"`, not `""`.
    ///
    /// - Parameter raw: ticker from an exchange API, a CSV, or user input — any format.
    /// - Returns: the normalized symbol, e.g. `"BTC"`.
    public static func sanitize(_ raw: String) -> String {
        // Step 1 — strip a leading Bitfinex "t" (lowercase t before an uppercase symbol).
        // Done before uppercasing so the case boundary is still visible.
        var cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("t"), cleaned.count > 1 {
            let secondIndex = cleaned.index(after: cleaned.startIndex)
            if cleaned[secondIndex].isUppercase {
                cleaned.removeFirst()
            }
        }

        // Step 2 — uppercase.
        var result = cleaned.uppercased()

        // Step 3 — strip a Kraken futures prefix WITH ITS UNDERSCORE, and BEFORE the separators go.
        //
        // The underscore is the only thing that tells a venue prefix apart from the first two
        // letters of a coin's own name. This loop used to run AFTER separator removal, so by the
        // time it saw the string the `_` was already gone and the match had degraded to a bare
        // two-letter prefix. Measured on the released package:
        //
        //   FIL → L · PIXELUSDT → XEL · FIDAUSDT → DA · PIVXUSDT → VX · FISUSDT → S · FITFIUSDT → TFI
        //
        // Those are all real assets. Wherever this normalizer's output is used as a price-lookup or
        // dedup key, a Filecoin position ends up filed under `L` and priced through `LUSDT`, which
        // no venue serves — so it renders with no price at all.
        //
        // Order matters twice over: this must run AFTER the lowercase-`t` strip, which needs the
        // original case to spot the Bitfinex boundary, and BEFORE separator removal, which is what
        // destroys the disambiguator. It also stays ahead of suffix removal, so
        // `PF_XBTUSD` → `XBTUSD` → `XBT` → `BTC`.
        for prefix in ["PF_", "PI_", "FI_", "FF_"] {
            if result.hasPrefix(prefix), result.count > prefix.count {
                result = String(result.dropFirst(prefix.count))
                break
            }
        }

        // Step 4 — remove separators.
        result = result
            .replacingOccurrences(of: "/", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: ":", with: "")

        // Step 5 — strip a trailing quote/contract suffix (longest-first).
        for suffix in suffixes {
            if result.hasSuffix(suffix), result.count > suffix.count {
                result = String(result.dropLast(suffix.count))
                break
            }
        }

        // Step 6 — remap legacy aliases.
        if let alias = aliases[result] {
            result = alias
        }

        return result
    }
}
