import UIKit

/// Kayit (veri.json) ve dosya yardimcilari
enum Yardimci {
    static let zemin = UIColor(red: 0x12 / 255.0, green: 0x12 / 255.0, blue: 0x12 / 255.0, alpha: 1)

    static let klasor: URL = {
        let u = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("GammaFY", isDirectory: true)
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }()

    /// Belgeler klasoru: Dosyalar uygulamasinda "iPhone'umda > GammaFY" olarak gorunur
    static let belgeler: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

    static func veriOku() -> String {
        (try? String(contentsOf: klasor.appendingPathComponent("veri.json"), encoding: .utf8)) ?? "{}"
    }

    static func veriYaz(_ s: String) {
        try? s.write(to: klasor.appendingPathComponent("veri.json"), atomically: true, encoding: .utf8)
    }

    /// Dosya adindaki yasak karakterleri temizler
    static func guvenliAd(_ ad: String) -> String {
        let yasak = CharacterSet(charactersIn: "/\\:?*\"<>|").union(.controlCharacters)
        var s = ad.components(separatedBy: yasak).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        while s.hasPrefix(".") { s.removeFirst() }
        if s.isEmpty { s = "GammaFY.txt" }
        return String(s.prefix(120))
    }

    /// Belgeler klasorune yazar; ayni ad varsa " (2)" eklenir
    static func dosyaYaz(_ ad: String, _ veri: Data) throws -> URL {
        let temiz = guvenliAd(ad)
        let kok = (temiz as NSString).deletingPathExtension, uzanti = (temiz as NSString).pathExtension
        var hedef = belgeler.appendingPathComponent(temiz), n = 2
        while FileManager.default.fileExists(atPath: hedef.path) {
            hedef = belgeler.appendingPathComponent(uzanti.isEmpty ? "\(kok) (\(n))" : "\(kok) (\(n)).\(uzanti)")
            n += 1
        }
        try veri.write(to: hedef, options: .atomic)
        return hedef
    }
}
