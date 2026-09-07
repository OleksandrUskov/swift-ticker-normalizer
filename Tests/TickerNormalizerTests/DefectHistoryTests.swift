import Testing
@testable import TickerNormalizer

/// Cases that reached production, kept apart from the suite above on purpose.
///
/// The suite above was written by the author of the code and has 22 green tests. Every one of the
/// six cases below failed while those 22 stayed green: the released package stripped a **bare**
/// two-letter venue prefix, so it ate the first two letters of any coin whose name happens to start
/// with `PF`, `PI`, `FI` or `FF`.
///
/// They are here as a set, and named for what they are, because that is the whole lesson: a test
/// set chosen by the author of an implementation agrees with it, and a set drawn from what actually
/// broke does not.
@Suite("Defect history — coins whose names start like a venue prefix")
struct DefectHistoryTests {

    @Test("FIL stays FIL and does not become L")
    func filecoin() { #expect(TickerNormalizer.sanitize("FIL") == "FIL") }

    @Test("PIXELUSDT → PIXEL, not XEL")
    func pixel() { #expect(TickerNormalizer.sanitize("PIXELUSDT") == "PIXEL") }

    @Test("FIDAUSDT → FIDA, not DA")
    func fida() { #expect(TickerNormalizer.sanitize("FIDAUSDT") == "FIDA") }

    @Test("PIVXUSDT → PIVX, not VX")
    func pivx() { #expect(TickerNormalizer.sanitize("PIVXUSDT") == "PIVX") }

    @Test("FISUSDT → FIS, not S")
    func fis() { #expect(TickerNormalizer.sanitize("FISUSDT") == "FIS") }

    @Test("FITFIUSDT → FITFI, not TFI")
    func fitfi() { #expect(TickerNormalizer.sanitize("FITFIUSDT") == "FITFI") }

    // The other direction, so the fix cannot be "stop stripping prefixes": the venue prefixes it
    // exists for must still be stripped, and they always arrive with the underscore.

    @Test("Kraken PF_XBTUSD still → BTC")
    func krakenPerp() { #expect(TickerNormalizer.sanitize("PF_XBTUSD") == "BTC") }

    @Test("Kraken FI_XBTUSD still → BTC")
    func krakenInverse() { #expect(TickerNormalizer.sanitize("FI_XBTUSD") == "BTC") }

    @Test("Kraken PI_ETHUSD still → ETH")
    func krakenPI() { #expect(TickerNormalizer.sanitize("PI_ETHUSD") == "ETH") }

    @Test("lowercase pf_xbtusd still → BTC")
    func krakenLowercase() { #expect(TickerNormalizer.sanitize("pf_xbtusd") == "BTC") }
}
