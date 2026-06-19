//
//  BillParser.swift
//  DocMate
//
//  Created by Shashwat kumar on 27/04/26.
//

import Foundation

/// Heuristic parser that turns a raw Gmail bill/invoice email into an `Infetch`.
///
/// Design follows the CRED-style "trust the biller, not the text" principle:
/// the **sender domain** is the primary signal for *who* a bill is from, because
/// a marketing line inside a Netflix email that merely mentions "HDFC" or "Paytm"
/// must never relabel the bill. Only when the domain is unknown do we fall back to
/// word-boundary keyword matching, and finally to a name derived from the domain.
///
/// It stays rule-based (no network / ML): amount uses a tiered, promo-aware
/// strategy (labelled total → largest *plausible* currency value → generic), and a
/// due date is pulled from common phrasings with a sanity window. Amounts handle
/// both Western (`1,234,567`) and Indian (`12,34,567`) digit grouping.
struct BillParser {

    /// Builds an importable bill, or returns `nil` when the email should be skipped.
    ///
    /// The app's purpose is "don't miss a payment", so we import **every unpaid
    /// bill** — overdue, due today, or due in the future. The only emails dropped
    /// are ones that are already settled (receipts, "payment received"
    /// confirmations like a paid Zepto / Zomato order).
    static func makeBill(from email: GmailEmail, userId: UUID) -> Infetch? {

        let haystack = email.subject + "\n" + email.body

        // Skip anything that's already been paid — receipts / confirmations.
        guard !isAlreadyPaid(text: haystack) else { return nil }

        let match = detect(subject: email.subject, body: email.body, sender: email.from)

        // Skip subscription services (OTT / music / cloud) — the user doesn't
        // want recurring entertainment subscriptions tracked as bills.
        guard !match.isSubscription else { return nil }

        let amount = extractAmount(from: haystack)
        let dueDate = resolvedDueDate(from: haystack, billDate: email.receivedAt)

        return Infetch(
            name: match.vendor,
            dueDate: dueDate,
            billDate: email.receivedAt,
            SubjectName: match.vendor,
            amount: amount,
            customerName: "",
            phoneNumber: nil,
            billNumber: email.id,
            isPaid: false,
            gmailMessageId: email.id,
            paidAt: nil,
            inFetchCategory: match.category,
            userId: userId
        )
    }

    // MARK: - Already-Paid Detection

    /// Returns `true` when the email is a payment confirmation / receipt rather
    /// than an outstanding bill. Only strong, unambiguous "settled" phrases are
    /// used so genuine "payment is due" reminders are never dropped by mistake.
    static func isAlreadyPaid(text: String) -> Bool {

        let t = text.lowercased()

        // Guard: a reminder like "your payment is due" must NOT count as paid,
        // even though it contains the word "payment".
        let dueSignals = ["is due", "due on", "due date", "pay by", "payment due",
                          "amount due", "outstanding", "please pay", "to avoid",
                          "before due"]
        if dueSignals.contains(where: { t.contains($0) }) { return false }

        let paidSignals = [
            "payment received", "payment successful", "successful payment",
            "payment was successful", "successfully paid", "paid successfully",
            "thank you for your payment", "thanks for your payment",
            "thank you for paying", "payment confirmation", "payment confirmed",
            "we have received your payment", "received your payment",
            "debited successfully", "successfully debited", "auto-debited",
            "autopay successful", "transaction successful", "payment receipt",
            "has been paid", "bill paid", "recharge successful", "order delivered"
        ]
        return paidSignals.contains { t.contains($0) }
    }

    // MARK: - Vendor / Category Detection

    struct Detection {
        let vendor: String
        let category: InfetchCategory
        /// `true` when the bill came from a recognised biller domain (high
        /// confidence). Heuristic / domain-derived guesses are `false`.
        let verified: Bool
        /// `true` for entertainment / cloud subscriptions the user wants ignored.
        var isSubscription: Bool = false
    }

    /// A known biller. The sender `domains` are the authoritative signal; the
    /// `keywords` are only a fallback when the domain doesn't match a biller.
    private struct Biller {
        let name: String
        let category: InfetchCategory
        let domains: [String]
        let keywords: [String]
        /// Streaming / music / cloud subscriptions — detected so they can be
        /// skipped rather than imported as bills.
        var isSubscription: Bool = false
    }

    /// Registry of recognised billers. Domains are matched as host suffixes so
    /// `email.airtel.in` and `airtel.in` both resolve to Airtel.
    private static let billers: [Biller] = [
        // Telecom
        .init(name: "Airtel", category: .bill, domains: ["airtel.in", "airtel.com"], keywords: ["airtel"]),
        .init(name: "Jio", category: .bill, domains: ["jio.com", "jio.in", "ril.com"], keywords: ["jio"]),
        .init(name: "Vi", category: .bill, domains: ["vodafoneidea.com", "myvi.in", "vodafone.in"], keywords: ["vodafone", "vodafone idea"]),
        .init(name: "BSNL", category: .bill, domains: ["bsnl.co.in", "bsnl.in"], keywords: ["bsnl"]),

        // OTT & Subscriptions — flagged so they are skipped, not imported.
        .init(name: "Netflix", category: .bill, domains: ["netflix.com"], keywords: ["netflix"], isSubscription: true),
        .init(name: "Disney+ Hotstar", category: .bill, domains: ["hotstar.com", "disneyplus.com"], keywords: ["hotstar", "disney+"], isSubscription: true),
        .init(name: "Spotify", category: .bill, domains: ["spotify.com"], keywords: ["spotify"], isSubscription: true),
        .init(name: "YouTube Premium", category: .bill, domains: ["youtube.com"], keywords: ["youtube premium"], isSubscription: true),
        .init(name: "Amazon Prime", category: .bill, domains: ["primevideo.com"], keywords: ["prime video", "amazon prime"], isSubscription: true),

        // E-Commerce
        .init(name: "Amazon", category: .bill, domains: ["amazon.in", "amazon.com"], keywords: ["amazon"]),
        .init(name: "Flipkart", category: .bill, domains: ["flipkart.com"], keywords: ["flipkart"]),
        .init(name: "Myntra", category: .bill, domains: ["myntra.com"], keywords: ["myntra"]),
        .init(name: "Meesho", category: .bill, domains: ["meesho.com"], keywords: ["meesho"]),
        .init(name: "Nykaa", category: .bill, domains: ["nykaa.com"], keywords: ["nykaa"]),
        .init(name: "AJIO", category: .bill, domains: ["ajio.com"], keywords: ["ajio"]),

        // Food / Quick-commerce
        .init(name: "Swiggy", category: .bill, domains: ["swiggy.in", "swiggy.com"], keywords: ["swiggy"]),
        .init(name: "Zomato", category: .bill, domains: ["zomato.com"], keywords: ["zomato"]),
        .init(name: "Blinkit", category: .bill, domains: ["blinkit.com", "grofers.com"], keywords: ["blinkit"]),
        .init(name: "Zepto", category: .bill, domains: ["zepto.co.in", "zeptonow.com"], keywords: ["zepto"]),

        // Electricity
        .init(name: "Adani Electricity", category: .bill, domains: ["adani.com"], keywords: ["adani electricity"]),
        .init(name: "Torrent Power", category: .bill, domains: ["torrentpower.com"], keywords: ["torrent power"]),
        .init(name: "BESCOM", category: .bill, domains: ["bescom.org", "bescom.co.in"], keywords: ["bescom"]),
        .init(name: "MSEDCL", category: .bill, domains: ["mahadiscom.in"], keywords: ["msedcl", "mahadiscom"]),
        .init(name: "BSES", category: .bill, domains: ["bsesdelhi.com", "bses.co.in"], keywords: ["bses"]),
        .init(name: "Tata Power", category: .bill, domains: ["tatapower.com"], keywords: ["tata power"]),

        // Banking / Finance
        .init(name: "ICICI Bank", category: .finance, domains: ["icicibank.com", "icici.com"], keywords: ["icici"]),
        .init(name: "HDFC Bank", category: .finance, domains: ["hdfcbank.com", "hdfcbank.net"], keywords: ["hdfc bank"]),
        .init(name: "SBI", category: .finance, domains: ["sbi.co.in", "onlinesbi.com", "sbicard.com"], keywords: ["state bank of india"]),
        .init(name: "Axis Bank", category: .finance, domains: ["axisbank.com"], keywords: ["axis bank"]),
        .init(name: "Kotak Bank", category: .finance, domains: ["kotak.com"], keywords: ["kotak"]),
        .init(name: "Paytm", category: .finance, domains: ["paytm.com", "paytmbank.com"], keywords: ["paytm"]),
        .init(name: "PhonePe", category: .finance, domains: ["phonepe.com"], keywords: ["phonepe"]),
        .init(name: "Razorpay", category: .finance, domains: ["razorpay.com"], keywords: ["razorpay"]),
        .init(name: "Bajaj Finance", category: .finance, domains: ["bajajfinserv.in", "bajajfinance.in"], keywords: ["bajaj finserv", "bajaj finance"]),

        // Insurance
        .init(name: "LIC", category: .insurance, domains: ["licindia.in", "licindia.com"], keywords: ["life insurance corporation"]),
        .init(name: "HDFC Life", category: .insurance, domains: ["hdfclife.com"], keywords: ["hdfc life"]),
        .init(name: "Star Health", category: .insurance, domains: ["starhealth.in"], keywords: ["star health"]),
        .init(name: "PolicyBazaar", category: .insurance, domains: ["policybazaar.com"], keywords: ["policybazaar"]),

        // Travel
        .init(name: "IRCTC", category: .bill, domains: ["irctc.co.in", "irctc.com"], keywords: ["irctc"]),
        .init(name: "MakeMyTrip", category: .bill, domains: ["makemytrip.com"], keywords: ["makemytrip"]),
        .init(name: "Goibibo", category: .bill, domains: ["goibibo.com"], keywords: ["goibibo"]),
        .init(name: "Cleartrip", category: .bill, domains: ["cleartrip.com"], keywords: ["cleartrip"]),

        // LPG cylinder
        .init(name: "LPG Gas", category: .bill, domains: ["indane.co.in", "ebharatgas.com", "hindustanpetroleum.com"], keywords: ["indane", "hp gas", "bharat gas"]),

        // Broadband / Wi-Fi
        .init(name: "JioFiber", category: .bill, domains: ["jiofiber.com"], keywords: ["jiofiber", "jio fiber"]),
        .init(name: "Airtel Xstream", category: .bill, domains: ["airtelxstream.in"], keywords: ["airtel xstream", "xstream fiber"]),
        .init(name: "ACT Fibernet", category: .bill, domains: ["actcorp.in", "acttv.in"], keywords: ["act fibernet", "act broadband"]),
        .init(name: "Hathway", category: .bill, domains: ["hathway.com", "hathway.net"], keywords: ["hathway"]),
        .init(name: "Excitel", category: .bill, domains: ["excitel.com"], keywords: ["excitel"]),
        .init(name: "Tikona", category: .bill, domains: ["tikona.in"], keywords: ["tikona"]),

        // DTH / Cable TV
        .init(name: "Tata Play", category: .bill, domains: ["tataplay.com", "tatasky.com"], keywords: ["tata play", "tatasky", "tata sky"]),
        .init(name: "Dish TV", category: .bill, domains: ["dishtv.in"], keywords: ["dish tv"]),
        .init(name: "d2h", category: .bill, domains: ["d2h.com", "videocond2h.com"], keywords: ["d2h"]),
        .init(name: "Sun Direct", category: .bill, domains: ["sundirect.in"], keywords: ["sun direct"]),

        // Piped gas (PNG)
        .init(name: "IGL", category: .bill, domains: ["iglonline.net"], keywords: ["indraprastha gas"]),
        .init(name: "Mahanagar Gas", category: .bill, domains: ["mahanagargas.com"], keywords: ["mahanagar gas"]),
        .init(name: "Adani Gas", category: .bill, domains: ["adanigas.com", "adani.com"], keywords: ["adani gas", "adani total gas"]),
        .init(name: "Gujarat Gas", category: .bill, domains: ["gujaratgas.com"], keywords: ["gujarat gas"]),

        // Water (municipal boards)
        .init(name: "BWSSB Water", category: .bill, domains: ["bwssb.gov.in", "bwssb.karnataka.gov.in"], keywords: ["bwssb"]),
        .init(name: "Delhi Jal Board", category: .bill, domains: ["djb.gov.in", "delhijalboard.nic.in"], keywords: ["delhi jal board"]),

        // FASTag / Toll
        .init(name: "Paytm FASTag", category: .finance, domains: ["paytm.com", "paytmbank.com"], keywords: ["fastag"]),
        .init(name: "NHAI FASTag", category: .bill, domains: ["ihmcl.com", "nhai.gov.in"], keywords: ["nhai fastag"]),

        // Credit cards / card issuers
        .init(name: "SBI Card", category: .finance, domains: ["sbicard.com"], keywords: ["sbi card"]),
        .init(name: "American Express", category: .finance, domains: ["americanexpress.com", "aexp.com"], keywords: ["american express", "amex"]),
        .init(name: "AU Bank", category: .finance, domains: ["aubank.in"], keywords: ["au small finance", "au bank"]),
        .init(name: "IDFC FIRST Bank", category: .finance, domains: ["idfcfirstbank.com"], keywords: ["idfc first"]),
        .init(name: "Yes Bank", category: .finance, domains: ["yesbank.in"], keywords: ["yes bank"]),
        .init(name: "IndusInd Bank", category: .finance, domains: ["indusind.com"], keywords: ["indusind"]),

        // BNPL / Pay-later
        .init(name: "Simpl", category: .finance, domains: ["getsimpl.com"], keywords: ["simpl"]),
        .init(name: "LazyPay", category: .finance, domains: ["lazypay.in"], keywords: ["lazypay"]),
        .init(name: "Amazon Pay Later", category: .finance, domains: ["amazon.in"], keywords: ["amazon pay later"]),
        .init(name: "Slice", category: .finance, domains: ["sliceit.com"], keywords: ["slice"]),

        // Rent / Housing / Society
        .init(name: "NoBroker", category: .bill, domains: ["nobroker.in"], keywords: ["nobroker"]),
        .init(name: "MyGate", category: .bill, domains: ["mygate.com"], keywords: ["mygate"]),
        .init(name: "NestAway", category: .bill, domains: ["nestaway.com"], keywords: ["nestaway"]),
        .init(name: "Urban Company", category: .bill, domains: ["urbancompany.com", "urbanclap.com"], keywords: ["urban company", "urbanclap"]),

        // OTT / Cloud / Software (subscriptions) — flagged so they are skipped.
        .init(name: "SonyLIV", category: .bill, domains: ["sonyliv.com"], keywords: ["sonyliv", "sony liv"], isSubscription: true),
        .init(name: "ZEE5", category: .bill, domains: ["zee5.com"], keywords: ["zee5"], isSubscription: true),
        .init(name: "JioCinema", category: .bill, domains: ["jiocinema.com"], keywords: ["jiocinema"], isSubscription: true),
        .init(name: "Google One", category: .bill, domains: ["google.com"], keywords: ["google one"], isSubscription: true),
        .init(name: "iCloud+", category: .bill, domains: ["apple.com"], keywords: ["icloud+", "icloud storage", "apple one"], isSubscription: true),
        .init(name: "Microsoft 365", category: .bill, domains: ["microsoft.com"], keywords: ["microsoft 365", "office 365"], isSubscription: true),
        .init(name: "Adobe", category: .bill, domains: ["adobe.com"], keywords: ["adobe", "creative cloud"], isSubscription: true),

        // Health / general insurance
        .init(name: "Niva Bupa", category: .insurance, domains: ["nivabupa.com", "maxbupa.com"], keywords: ["niva bupa", "max bupa"]),
        .init(name: "HDFC Ergo", category: .insurance, domains: ["hdfcergo.com"], keywords: ["hdfc ergo"]),
        .init(name: "ICICI Lombard", category: .insurance, domains: ["icicilombard.com"], keywords: ["icici lombard"]),
        .init(name: "Bajaj Allianz", category: .insurance, domains: ["bajajallianz.com"], keywords: ["bajaj allianz"]),
        .init(name: "Max Life", category: .insurance, domains: ["maxlifeinsurance.com"], keywords: ["max life"]),
        .init(name: "SBI Life", category: .insurance, domains: ["sbilife.co.in"], keywords: ["sbi life"]),
        .init(name: "Acko", category: .insurance, domains: ["acko.com"], keywords: ["acko"]),

        // Groceries
        .init(name: "BigBasket", category: .bill, domains: ["bigbasket.com"], keywords: ["bigbasket"]),
    ]

    /// Resolves the vendor + category for an email, preferring the authoritative
    /// sender domain and only then falling back to keyword / domain heuristics.
    static func detect(subject: String, body: String, sender: String) -> Detection {

        // ── 1. Authoritative: match the sender's host against a known biller ──
        if let host = senderHost(from: sender) {
            if let biller = billers.first(where: { b in
                b.domains.contains { host == $0 || host.hasSuffix("." + $0) }
            }) {
                return Detection(vendor: biller.name, category: biller.category,
                                 verified: true, isSubscription: biller.isSubscription)
            }
        }

        // ── 2. Fallback: word-boundary keyword match in subject + body ────────
        // Word boundaries stop "sbi"/"jio"/"vi" from matching inside other words.
        let text = (subject + " " + body).lowercased()
        if let biller = billers.first(where: { b in
            b.keywords.contains { containsWord($0, in: text) }
        }) {
            return Detection(vendor: biller.name, category: biller.category,
                             verified: false, isSubscription: biller.isSubscription)
        }

        // ── 3. Last resort: derive a readable name from the domain ────────────
        let vendor = (senderHost(from: sender).flatMap(brandName(fromHost:)))
            ?? extractSenderDomain(from: text)
            ?? "Bill"
        return Detection(vendor: vendor, category: detectCategory(text: text), verified: false)
    }

    /// Category when no known biller matched — keyed off the most specific terms.
    private static func detectCategory(text: String) -> InfetchCategory {
        if containsWord("insurance", in: text) || containsWord("policy", in: text) { return .insurance }
        if containsWord("loan", in: text) || containsWord("emi", in: text)
            || containsWord("credit card", in: text) || containsWord("bank", in: text) { return .finance }
        return .bill
    }

    // MARK: - Sender / Domain Helpers

    /// Extracts the lowercased host from a `From` header, e.g.
    /// `"Airtel" <noreply@email.airtel.in>` → `email.airtel.in`.
    private static func senderHost(from sender: String) -> String? {
        guard let domain = firstMatch(pattern: #"@([\w.-]+\.\w{2,})"#,
                                      in: sender.lowercased()) else { return nil }
        return domain
    }

    /// Turns a host into a readable brand, stripping mail/TLD sub-labels:
    /// `email.hdfcbank.com` → `Hdfcbank`. Returns `nil` for generic providers.
    nonisolated private static func brandName(fromHost host: String) -> String? {
        return cleanedBrand(fromDomain: host)
    }

    /// Derives a human-readable brand name from an email address found in free
    /// text, e.g. `billing@amazon.in` → `Amazon`. Used only as a deep fallback.
    private static func extractSenderDomain(from text: String) -> String? {
        guard let domain = firstMatch(pattern: #"[\w.+-]+@([\w.-]+\.\w{2,})"#,
                                      in: text.lowercased())?.lowercased() else { return nil }
        return cleanedBrand(fromDomain: domain)
    }

    /// Shared domain → brand cleanup used by both fallbacks.
    nonisolated private static func cleanedBrand(fromDomain domain: String) -> String? {
        var labels = domain.split(separator: ".").map(String.init)

        // Strip trailing TLDs / country codes: amazon.co.in → amazon
        let tlds: Set<String> = ["com", "in", "co", "net", "org", "io", "biz", "info", "gov", "edu"]
        while let last = labels.last, tlds.contains(last), labels.count > 1 {
            labels.removeLast()
        }

        // Strip leading mail-server / department sub-labels: email.amazon → amazon
        let fluff: Set<String> = [
            "email", "mail", "mailer", "e", "mkt", "marketing", "noreply", "no-reply",
            "info", "support", "update", "updates", "news", "newsletter", "notification",
            "notifications", "alerts", "alert", "billing", "account", "accounts", "smtp",
            "send", "sender", "txn", "transaction"
        ]
        let pick = labels.reversed().first(where: { !fluff.contains($0) }) ?? labels.last
        guard let name = pick, name.count > 1 else { return nil }

        // Generic consumer mail providers carry no vendor signal.
        let generic: Set<String> = [
            "gmail", "yahoo", "outlook", "hotmail", "icloud", "proton", "protonmail",
            "ymail", "live", "msn", "rediffmail", "rediff", "zoho"
        ]
        if generic.contains(name) { return nil }

        return name.prefix(1).uppercased() + name.dropFirst()
    }

    // MARK: - Amount Detection

    /// A number that accepts Western (`1,234,567`) and Indian (`12,34,567`) grouping,
    /// or a plain run of digits, with an optional 1–2 digit decimal part.
    ///
    /// The comma-grouped alternative requires **at least one** comma group (`+`),
    /// so it only claims numbers that are actually grouped. Without this, a plain
    /// number like `1500` would match the first alternative as just its leading
    /// `\d{1,3}` (→ `150`) and never fall through to the plain-digits branch.
    private static let numberPattern =
        #"(\d{1,3}(?:,\d{2,3})+(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)"#

    /// Lines containing these are promotional noise — "win ₹50,000", "flat 60% off",
    /// "₹500 cashback". Amounts on such lines must never be taken as the payable.
    private static let promoWords = [
        "cashback", "reward", "rewards", "off", "discount", "save", "savings",
        "win", "won", "coupon", "voucher", "offer", "upto", "up to", "flat",
        "% off", "scratch", "lucky", "bonus", "earn", "prize", "loan upto",
        "credit limit", "pre-approved", "pre approved", "eligible for"
    ]

    static func extractAmount(from text: String) -> Double? {

        let lowered = text.lowercased()

        // ── Tier 1: amounts explicitly labelled as the payable total ──────────
        // Most specific labels first so "total amount due" wins over "amount due".
        let totalLabels = [
            "total amount due", "grand total", "amount payable", "total payable",
            "net payable", "total amount", "amount due", "total due", "bill amount",
            "net amount", "amount to be paid", "order total", "minimum amount due",
            "min amount due"
        ]
        for label in totalLabels {
            // <label> … [₹|Rs|INR]? <number>   (a few separator chars allowed between)
            let pattern = label + #"[^\d₹]{0,15}(?:₹|rs\.?|inr)?\s?"# + numberPattern
            if let v = firstMatch(pattern: pattern, in: lowered), let amt = parseAmount(v) {
                return amt
            }
        }

        // ── Tier 2: every currency-tagged amount on a non-promo line ──────────
        // For bills the payable figure is almost always the biggest *genuine*
        // value (totals dwarf line items), but promo lines ("win ₹1,00,000") are
        // excluded so a teaser can't outbid the real total.
        let currencyPatterns = [
            #"₹\s?"# + numberPattern,
            #"inr\s?"# + numberPattern,
            #"rs\.?\s?"# + numberPattern,
        ]
        var candidates: [Double] = []
        for line in lowered.split(whereSeparator: \.isNewline) {
            let lineStr = String(line)
            // Word-boundary match (not substring) so promo terms like "off"/"win"/
            // "save"/"earn" don't drop legitimate lines via *office*, *window*,
            // *saved*, *earnings*, etc. — mirrors the vendor keyword matching.
            if promoWords.contains(where: { containsWord($0, in: lineStr) }) { continue }
            for pattern in currencyPatterns {
                candidates.append(contentsOf: allMatches(pattern: pattern, in: lineStr).compactMap(parseAmount))
            }
        }
        if let best = candidates.max() { return best }

        // ── Tier 3: generic "total: 399" style with no currency marker ────────
        let generic = #"(?:total|amount|pay|payment)[:\s]+"# + numberPattern
        if let v = firstMatch(pattern: generic, in: lowered), let amt = parseAmount(v) {
            return amt
        }

        return nil
    }

    nonisolated private static func parseAmount(_ raw: String) -> Double? {
        let cleaned = raw.replacingOccurrences(of: ",", with: "")
        guard let amount = Double(cleaned), amount > 0 else { return nil }
        return amount
    }

    // MARK: - Due Date Detection

    /// Parses a due date and validates it falls in a believable window around the
    /// bill date; otherwise falls back to `billDate + 7 days`. This prevents a
    /// stray date elsewhere in the email from becoming a nonsensical due date.
    static func resolvedDueDate(from text: String, billDate: Date) -> Date {
        if let parsed = extractDueDate(from: text), isPlausibleDueDate(parsed, billDate: billDate) {
            return parsed
        }
        return Calendar.current.date(byAdding: .day, value: 7, to: billDate) ?? billDate
    }

    /// A due date should sit roughly between two months before the bill arrived
    /// (overdue reminders) and a year after (annual subscriptions / insurance).
    private static func isPlausibleDueDate(_ date: Date, billDate: Date) -> Bool {
        let cal = Calendar.current
        guard let lower = cal.date(byAdding: .day, value: -60, to: billDate),
              let upper = cal.date(byAdding: .day, value: 365, to: billDate) else { return true }
        return date >= lower && date <= upper
    }

    static func extractDueDate(from text: String) -> Date? {

        let lower = text.lowercased()

        // A date token: numeric (12/03/2026, 12-03-26) or month-name
        // (12 mar 2026, 12th march 2026, mar 12, 2026).
        let dateToken =
            #"(\d{1,2}[-/.]\d{1,2}[-/.]\d{2,4}"# +
            #"|\d{1,2}(?:st|nd|rd|th)?\s+[a-z]{3,9}\.?\s+\d{2,4}"# +
            #"|[a-z]{3,9}\.?\s+\d{1,2},?\s+\d{2,4})"#

        // Most specific phrasings first; bare "due" last to avoid false hits.
        let keywords = [
            "due on", "due date", "due by", "pay by", "payment due",
            "last date of payment", "last date", "payable by", "due"
        ]
        for kw in keywords {
            let pattern = kw + #"[:\s]+"# + dateToken
            if let match = firstMatch(pattern: pattern, in: lower), let date = parseDate(match) {
                return date
            }
        }

        return nil
    }

    // MARK: - Regex Helpers

    /// Whole-word containment that tolerates brand punctuation (e.g. `disney+`).
    static func containsWord(_ word: String, in text: String) -> Bool {
        let escaped = NSRegularExpression.escapedPattern(for: word)
        // (?<![a-z0-9]) / (?![a-z0-9]) act as alphanumeric-aware boundaries so
        // "vi" won't match inside "video" but "vi." or "vi " will.
        let pattern = "(?<![a-z0-9])" + escaped + "(?![a-z0-9])"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return text.contains(word)
        }
        let nsrange = NSRange(text.startIndex..., in: text)
        return regex.firstMatch(in: text, options: [], range: nsrange) != nil
    }

    /// Returns capture group 1 of the first match, or `nil`.
    static func firstMatch(pattern: String, in text: String) -> String? {

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }

        let nsrange = NSRange(text.startIndex..., in: text)

        guard let match = regex.firstMatch(in: text, options: [], range: nsrange),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text) else { return nil }

        return String(text[range])
    }

    /// Returns capture group 1 of every match.
    static func allMatches(pattern: String, in text: String) -> [String] {

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }

        let nsrange = NSRange(text.startIndex..., in: text)

        return regex.matches(in: text, options: [], range: nsrange).compactMap { match in
            guard match.numberOfRanges > 1,
                  let range = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[range])
        }
    }

    // MARK: - Date Parsing

    static func parseDate(_ value: String) -> Date? {

        // Drop ordinal suffixes: "12th" → "12"
        let normalized = value
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: #"(\d)(st|nd|rd|th)"#, with: "$1",
                                  options: [.regularExpression, .caseInsensitive])

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        // dd/MM first — Indian bills are day-first. (Genuinely ambiguous dates like
        // 03/04/2026 are read as 3 April, the regional convention here.)
        let formats = [
            "dd/MM/yyyy", "dd-MM-yyyy", "dd.MM.yyyy", "dd/MM/yy", "dd-MM-yy", "dd.MM.yy",
            "MM/dd/yyyy", "MM-dd-yyyy", "yyyy-MM-dd",
            "dd MMM yyyy", "dd MMMM yyyy", "dd MMM yy",
            "MMM dd yyyy", "MMMM dd yyyy", "MMM dd, yyyy", "MMMM dd, yyyy"
        ]

        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: normalized) { return date }
        }

        return nil
    }
}
