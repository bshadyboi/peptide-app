import Foundation
import SwiftData

/// Phase 1 preview / offline fixture data. Production uses live Supabase sync (Phase 2+).
enum SampleDataLoader {
    static let bpc157Slug = "bpc-157"

    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Peptide>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }
        insertSeedData(context: context)
    }

    static func insertSeedData(context: ModelContext) {
        let vendors = makeVendors(context: context)
        let peptides = makePeptides(context: context)
        makePrices(vendors: vendors, peptides: peptides, context: context)
        try? context.save()
    }

    // MARK: - Vendors

    private static func makeVendors(context: ModelContext) -> [UUID: Vendor] {
        let entries: [(UUID, String, String?, String?, String?)] = [
            (UUID(uuidString: "e4000001-0000-4000-8000-000000000001")!, "Peptide Sciences", "https://www.peptidesciences.com", "USA", "COA on most products"),
            (UUID(uuidString: "e4000001-0000-4000-8000-000000000002")!, "Core Peptides", "https://corepeptides.com", "USA", nil),
            (UUID(uuidString: "e4000001-0000-4000-8000-000000000003")!, "Paradigm Peptides", "https://paradigmpeptides.com", "USA", "Frequent sales"),
            (UUID(uuidString: "e4000001-0000-4000-8000-000000000004")!, "Swiss Chems", "https://swisschems.is", "USA", nil)
        ]

        var map: [UUID: Vendor] = [:]
        for (id, name, url, shipsFrom, notes) in entries {
            let vendor = Vendor(id: id, name: name, url: url, shipsFrom: shipsFrom, notes: notes)
            context.insert(vendor)
            map[id] = vendor
        }
        return map
    }

    // MARK: - Peptides + Doses

    private static func makePeptides(context: ModelContext) -> [UUID: Peptide] {
        var map: [UUID: Peptide] = [:]

        func addPeptide(
            id: String,
            name: String,
            slug: String,
            category: PeptideCategory,
            aliases: [String] = [],
            description: String? = nil,
            doses: [(doseId: String, mg: Decimal, label: String?)]
        ) {
            let peptide = Peptide(
                id: UUID(uuidString: id)!,
                name: name,
                slug: slug,
                category: category,
                aliases: aliases,
                description: description
            )
            context.insert(peptide)
            map[peptide.id] = peptide

            for dose in doses {
                let doseModel = Dose(
                    id: UUID(uuidString: dose.doseId)!,
                    mg: dose.mg,
                    label: dose.label,
                    peptide: peptide
                )
                context.insert(doseModel)
                peptide.doses.append(doseModel)
            }
        }

        addPeptide(
            id: "a1000001-0000-4000-8000-000000000001",
            name: "BPC-157",
            slug: "bpc-157",
            category: .single,
            aliases: ["Body Protective Compound"],
            description: "Pentadecapeptide studied for tissue repair and gut health.",
            doses: [
                ("d3000001-0000-4000-8000-000000000001", 5, nil),
                ("d3000001-0000-4000-8000-000000000002", 10, nil)
            ]
        )

        addPeptide(
            id: "a1000001-0000-4000-8000-000000000002",
            name: "TB-500",
            slug: "tb-500",
            category: .single,
            aliases: ["Thymosin Beta-4"],
            description: "Synthetic fragment of thymosin beta-4.",
            doses: [
                ("d3000001-0000-4000-8000-000000000003", 5, nil),
                ("d3000001-0000-4000-8000-000000000004", 10, "Kit")
            ]
        )

        addPeptide(
            id: "a1000001-0000-4000-8000-000000000003",
            name: "Ipamorelin",
            slug: "ipamorelin",
            category: .single,
            doses: [
                ("d3000001-0000-4000-8000-000000000005", 5, nil),
                ("d3000001-0000-4000-8000-000000000006", 10, nil)
            ]
        )

        addPeptide(
            id: "a1000001-0000-4000-8000-000000000004",
            name: "Tesamorelin",
            slug: "tesamorelin",
            category: .single,
            aliases: ["Egrifta"],
            description: "GHRH analog peptide.",
            doses: [
                ("d3000001-0000-4000-8000-000000000007", 2, nil),
                ("d3000001-0000-4000-8000-000000000008", 5, nil)
            ]
        )

        addPeptide(
            id: "a1000001-0000-4000-8000-000000000005",
            name: "CJC-1295 / Ipamorelin Blend",
            slug: "cjc-ipa-blend",
            category: .blend,
            aliases: ["GH Stack"],
            description: "Blend of CJC-1295 (no DAC) and Ipamorelin.",
            doses: [
                ("d3000001-0000-4000-8000-000000000009", 4, "2mg/2mg vial"),
                ("d3000001-0000-4000-8000-000000000010", 10, "5mg/5mg vial")
            ]
        )

        return map
    }

    // MARK: - Prices

    private static func makePrices(
        vendors: [UUID: Vendor],
        peptides: [UUID: Peptide],
        context: ModelContext
    ) {
        let bpc = peptides[UUID(uuidString: "a1000001-0000-4000-8000-000000000001")!]!
        let tb = peptides[UUID(uuidString: "a1000001-0000-4000-8000-000000000002")!]!
        let ipa = peptides[UUID(uuidString: "a1000001-0000-4000-8000-000000000003")!]!
        let tesa = peptides[UUID(uuidString: "a1000001-0000-4000-8000-000000000004")!]!
        let blend = peptides[UUID(uuidString: "a1000001-0000-4000-8000-000000000005")!]!

        func dose(_ peptide: Peptide, index: Int) -> Dose {
            peptide.doses.sorted { $0.mg < $1.mg }[index]
        }

        func v(_ key: String) -> Vendor {
            vendors[UUID(uuidString: key)!]!
        }

        func insertPrice(
            id: String,
            dose: Dose,
            vendor: Vendor,
            price: Decimal,
            salePrice: Decimal? = nil,
            inStock: Bool = true,
            discountCode: String? = nil,
            coaAvailable: Bool = false
        ) {
            let row = Price(
                id: UUID(uuidString: id)!,
                price: price,
                salePrice: salePrice,
                inStock: inStock,
                discountCode: discountCode,
                coaAvailable: coaAvailable,
                source: .manual,
                dose: dose,
                vendor: vendor
            )
            context.insert(row)
            dose.prices.append(row)
        }

        // BPC-157 5mg
        insertPrice(id: "c5000001-0000-4000-8000-000000000001", dose: dose(bpc, index: 0), vendor: v("e4000001-0000-4000-8000-000000000001"), price: 59.50, discountCode: "RESEARCH10", coaAvailable: true)
        insertPrice(id: "c5000001-0000-4000-8000-000000000002", dose: dose(bpc, index: 0), vendor: v("e4000001-0000-4000-8000-000000000002"), price: 45.00, salePrice: 38.25, discountCode: "CORE15")
        insertPrice(id: "c5000001-0000-4000-8000-000000000003", dose: dose(bpc, index: 0), vendor: v("e4000001-0000-4000-8000-000000000003"), price: 52.00, coaAvailable: true)
        insertPrice(id: "c5000001-0000-4000-8000-000000000004", dose: dose(bpc, index: 0), vendor: v("e4000001-0000-4000-8000-000000000004"), price: 49.99, inStock: false, discountCode: "SWISS5")

        // BPC-157 10mg
        insertPrice(id: "c5000001-0000-4000-8000-000000000005", dose: dose(bpc, index: 1), vendor: v("e4000001-0000-4000-8000-000000000001"), price: 99.00, salePrice: 89.10, discountCode: "RESEARCH10", coaAvailable: true)
        insertPrice(id: "c5000001-0000-4000-8000-000000000006", dose: dose(bpc, index: 1), vendor: v("e4000001-0000-4000-8000-000000000002"), price: 79.00)
        insertPrice(id: "c5000001-0000-4000-8000-000000000007", dose: dose(bpc, index: 1), vendor: v("e4000001-0000-4000-8000-000000000003"), price: 85.00, discountCode: "PARA20", coaAvailable: true)

        // TB-500 5mg
        insertPrice(id: "c5000001-0000-4000-8000-000000000008", dose: dose(tb, index: 0), vendor: v("e4000001-0000-4000-8000-000000000001"), price: 55.00, coaAvailable: true)
        insertPrice(id: "c5000001-0000-4000-8000-000000000009", dose: dose(tb, index: 0), vendor: v("e4000001-0000-4000-8000-000000000002"), price: 42.00, discountCode: "CORE15")
        insertPrice(id: "c5000001-0000-4000-8000-000000000010", dose: dose(tb, index: 0), vendor: v("e4000001-0000-4000-8000-000000000004"), price: 48.00, salePrice: 40.80, inStock: false)

        // Ipamorelin 5mg
        insertPrice(id: "c5000001-0000-4000-8000-000000000011", dose: dose(ipa, index: 0), vendor: v("e4000001-0000-4000-8000-000000000001"), price: 38.00, discountCode: "RESEARCH10", coaAvailable: true)
        insertPrice(id: "c5000001-0000-4000-8000-000000000012", dose: dose(ipa, index: 0), vendor: v("e4000001-0000-4000-8000-000000000003"), price: 35.00, salePrice: 29.75, discountCode: "PARA20", coaAvailable: true)
        insertPrice(id: "c5000001-0000-4000-8000-000000000013", dose: dose(ipa, index: 0), vendor: v("e4000001-0000-4000-8000-000000000004"), price: 32.00)

        // Tesamorelin 2mg
        insertPrice(id: "c5000001-0000-4000-8000-000000000014", dose: dose(tesa, index: 0), vendor: v("e4000001-0000-4000-8000-000000000001"), price: 75.00, coaAvailable: true)
        insertPrice(id: "c5000001-0000-4000-8000-000000000015", dose: dose(tesa, index: 0), vendor: v("e4000001-0000-4000-8000-000000000002"), price: 68.00, salePrice: 61.20, discountCode: "CORE15")

        // Blend 4mg
        insertPrice(id: "c5000001-0000-4000-8000-000000000016", dose: dose(blend, index: 0), vendor: v("e4000001-0000-4000-8000-000000000001"), price: 52.00, discountCode: "RESEARCH10", coaAvailable: true)
        insertPrice(id: "c5000001-0000-4000-8000-000000000017", dose: dose(blend, index: 0), vendor: v("e4000001-0000-4000-8000-000000000003"), price: 44.00, salePrice: 39.60, discountCode: "PARA20", coaAvailable: true)
        insertPrice(id: "c5000001-0000-4000-8000-000000000018", dose: dose(blend, index: 0), vendor: v("e4000001-0000-4000-8000-000000000004"), price: 46.00, inStock: false, discountCode: "SWISS5")
    }
}
