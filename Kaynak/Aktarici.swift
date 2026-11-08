import Foundation
import WebKit

/// Masaustundeki Python aktaricisinin iPhone karsiligi.
/// Sayfa gammafy://app adresinden yuklenir; /p istekleri telefonun kendi ag katmanindan (URLSession) Spotify'a gider.
/// Yonlendirmeden sonraki adres X-Son-Adres basligiyla sayfaya bildirilir (kisa linkler icin).
final class Aktarici: NSObject, WKURLSchemeHandler {
    private var durdurulan = Set<ObjectIdentifier>()
    private let oturum: URLSession = {
        let c = URLSessionConfiguration.default
        c.requestCachePolicy = .reloadIgnoringLocalCacheData
        c.urlCache = nil
        c.timeoutIntervalForRequest = 20
        c.timeoutIntervalForResource = 60
        return URLSession(configuration: c)
    }()
    private let webKlasoru: URL = Bundle.main.url(forResource: "web", withExtension: nil)
        ?? Bundle.main.bundleURL.appendingPathComponent("web")

    /// Yalnizca Spotify adresleri
    private static func izinli(_ u: URL?) -> Bool {
        guard let u = u, u.scheme == "https", let h = u.host?.lowercased() else { return false }
        return ["open.spotify.com", "spotify.link", "spotify.app.link", "link.tospotify.com"].contains(h)
            || h.hasSuffix(".scdn.co") || h.hasSuffix(".spotifycdn.com")
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        let gorev = urlSchemeTask
        guard let url = gorev.request.url else {
            gorev.didFailWithError(URLError(.badURL))
            return
        }
        if url.path == "/" || url.path == "/index.html" {
            if let v = try? Data(contentsOf: webKlasoru.appendingPathComponent("index.html")) {
                yanitla(gorev, 200, v, "text/html; charset=utf-8")
            } else {
                yanitla(gorev, 404)
            }
            return
        }
        guard url.path == "/p",
              let q = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
              let hedefMetin = q.first(where: { $0.name == "u" })?.value,
              let hedef = URL(string: hedefMetin), Aktarici.izinli(hedef) else {
            yanitla(gorev, 403, Data("Yalnizca Spotify adresleri".utf8))
            return
        }
        var istek = URLRequest(url: hedef)
        if let ua = q.first(where: { $0.name == "ua" })?.value, !ua.isEmpty {
            istek.setValue(ua, forHTTPHeaderField: "User-Agent")
        }
        istek.setValue("text/html,application/xhtml+xml,*/*;q=0.8", forHTTPHeaderField: "Accept")
        istek.setValue("tr-TR,tr;q=0.9,en;q=0.7", forHTTPHeaderField: "Accept-Language")
        let kimlik = ObjectIdentifier(gorev)
        oturum.dataTask(with: istek) { [weak self] veri, yanit, hata in
            DispatchQueue.main.async {
                guard let self = self, !self.durdurulan.contains(kimlik) else { return }
                guard let h = yanit as? HTTPURLResponse else {
                    self.yanitla(gorev, 502, Data((hata?.localizedDescription ?? "baglanti yok").utf8))
                    return
                }
                let son = h.url
                if !Aktarici.izinli(son) {
                    self.yanitla(gorev, 403)
                    return
                }
                self.yanitla(gorev, h.statusCode, veri ?? Data(),
                             h.value(forHTTPHeaderField: "Content-Type") ?? "text/html; charset=utf-8",
                             ["X-Son-Adres": son?.absoluteString ?? hedefMetin])
            }
        }.resume()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        durdurulan.insert(ObjectIdentifier(urlSchemeTask))
    }

    private func yanitla(_ gorev: WKURLSchemeTask, _ kod: Int, _ veri: Data = Data(),
                         _ tur: String = "text/plain; charset=utf-8", _ ek: [String: String] = [:]) {
        let kimlik = ObjectIdentifier(gorev)
        if durdurulan.contains(kimlik) { durdurulan.remove(kimlik); return }
        var basliklar = ek
        basliklar["Content-Type"] = tur
        basliklar["Content-Length"] = String(veri.count)
        basliklar["Cache-Control"] = "no-store"
        guard let url = gorev.request.url,
              let r = HTTPURLResponse(url: url, statusCode: kod, httpVersion: "HTTP/1.1", headerFields: basliklar) else { return }
        gorev.didReceive(r)
        if !veri.isEmpty { gorev.didReceive(veri) }
        gorev.didFinish()
    }
}
