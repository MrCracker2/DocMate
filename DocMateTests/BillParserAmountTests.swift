//
//  BillParserAmountTests.swift
//  DocMateTests
//
//  Unit tests for `BillParser.extractAmount`.
//

import Testing
@testable import DocMate

@MainActor
struct BillParserAmountTests {

    // MARK: - Regression: plain (non-comma) numbers must not be truncated

    /// Reproduces the bug where the comma-grouped branch used `*` (zero-or-more
    /// comma groups) and greedily claimed only the first three digits of a plain
    /// number — e.g. `₹1500` was parsed as `150`.
    @Test func plainNumberIsNotTruncated() {
        #expect(BillParser.extractAmount(from: "Amount due ₹1500") == 1500)
    }

    @Test func plainNumberWithDecimals() {
        #expect(BillParser.extractAmount(from: "Pay ₹1234.56 now") == 1234.56)
    }

    @Test func largePlainNumber() {
        #expect(BillParser.extractAmount(from: "Outstanding ₹1234567") == 1234567)
    }

    // MARK: - Comma grouping (Western & Indian)

    @Test func westernGrouping() {
        #expect(BillParser.extractAmount(from: "Total of ₹1,234.56") == 1234.56)
    }

    @Test func indianGrouping() {
        #expect(BillParser.extractAmount(from: "Balance ₹12,34,567") == 1234567)
    }

    // MARK: - Tier 1: labelled totals

    @Test func labelledTotalAmountDue() {
        #expect(BillParser.extractAmount(from: "Total Amount Due: ₹2,499") == 2499)
    }

    @Test func totalWinsOverMinimumDue() {
        let text = "Total Amount Due ₹5,000\nMinimum Amount Due ₹250"
        #expect(BillParser.extractAmount(from: text) == 5000)
    }

    @Test func labelWithRupeeWord() {
        #expect(BillParser.extractAmount(from: "Bill Amount Rs. 899") == 899)
    }

    // MARK: - Tier 2: largest genuine currency value, promo lines excluded

    @Test func promoLineDoesNotOutbidRealTotal() {
        let text = """
        Win ₹1,00,000 in our lucky draw!
        Your payable balance is ₹750
        """
        #expect(BillParser.extractAmount(from: text) == 750)
    }

    /// Word-boundary regression: a line containing "office" (substring "off")
    /// must NOT be treated as a promo line and dropped.
    @Test func substringOfPromoWordIsNotExcluded() {
        let text = "Visit our office, kindly pay ₹750 before the cutoff."
        #expect(BillParser.extractAmount(from: text) == 750)
    }

    @Test func picksLargestCurrencyValue() {
        let text = "Item ₹120\nDelivery ₹40\nGrand sum ₹160"
        #expect(BillParser.extractAmount(from: text) == 160)
    }

    // MARK: - Tier 3: generic, no currency marker

    @Test func genericTotalWithoutCurrencySymbol() {
        #expect(BillParser.extractAmount(from: "Total: 399") == 399)
    }

    // MARK: - No amount present

    @Test func returnsNilWhenNoAmount() {
        #expect(BillParser.extractAmount(from: "Thank you for being a customer") == nil)
    }
}
