import UIKit
import WebKit

/// Tek ekran: arayuz tum ekrani kaplar (centik ve ev cubugu paylarini sayfa kendisi birakir).
final class AnaEkran: UIViewController, WKScriptMessageHandlerWithReply, WKNavigationDelegate, WKUIDelegate {
    private var web: WKWebView!
    private let aktarici = Aktarici()
    private var sonDosya: URL?

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .allButUpsideDown }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Yardimci.zemin
        let ayar = WKWebViewConfiguration()
        ayar.setURLSchemeHandler(aktarici, forURLScheme: "gammafy")
        ayar.allowsInlineMediaPlayback = true
        ayar.mediaTypesRequiringUserActionForPlayback = []
        ayar.userContentController.addScriptMessageHandler(self, contentWorld: .page, name: "gamma")

        let w = WKWebView(frame: .zero, configuration: ayar)
        w.isOpaque = false
        w.backgroundColor = .clear
        w.scrollView.backgroundColor = .clear
        w.scrollView.contentInsetAdjustmentBehavior = .never
        w.scrollView.bounces = false
        w.scrollView.isScrollEnabled = false
        w.scrollView.minimumZoomScale = 1
        w.scrollView.maximumZoomScale = 1
        w.scrollView.bouncesZoom = false
        w.navigationDelegate = self
        w.uiDelegate = self
        if #available(iOS 16.4, *) { w.isInspectable = true }
        web = w
        w.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(w)
        NSLayoutConstraint.activate([
            w.topAnchor.constraint(equalTo: view.topAnchor),
            w.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            w.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            w.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        NotificationCenter.default.addObserver(self, selector: #selector(klavyeKapandi),
                                               name: UIResponder.keyboardDidHideNotification, object: nil)
        if let adres = URL(string: "gammafy://app/index.html") {
            w.load(URLRequest(url: adres))
        }
    }

    @objc private func klavyeKapandi() {
        web.scrollView.setContentOffset(.zero, animated: true)
    }

    // MARK: sayfadan gelen istekler (window.webkit.messageHandlers.gamma.postMessage)

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage,
                               replyHandler: @escaping (Any?, String?) -> Void) {
        guard let g = message.body as? [String: Any], let k = g["k"] as? String else {
            replyHandler(nil, "gecersiz istek")
            return
        }
        switch k {
        case "yukle":
            replyHandler(Yardimci.veriOku(), nil)
        case "kaydet":
            Yardimci.veriYaz(g["v"] as? String ?? "{}")
            replyHandler(true, nil)
        case "dosyaKaydet":
            guard let ad = g["ad"] as? String, let b64 = g["b64"] as? String, let veri = Data(base64Encoded: b64) else {
                replyHandler(["ok": false, "hata": "dosya okunamadı"], nil)
                return
            }
            do {
                let u = try Yardimci.dosyaYaz(ad, veri)
                sonDosya = u
                replyHandler(["ok": true, "yol": u.path, "konum": "Dosyalar › GammaFY", "eylem": "Paylaş"], nil)
            } catch {
                replyHandler(["ok": false, "hata": error.localizedDescription], nil)
            }
        case "dosyaEylem":
            let yol = (g["yol"] as? String).map { URL(fileURLWithPath: $0) } ?? sonDosya
            if let u = yol, FileManager.default.fileExists(atPath: u.path) { paylas(u) }
            replyHandler(true, nil)
        case "disariAc":
            if let s = g["u"] as? String, let u = URL(string: s), u.scheme == "https" { UIApplication.shared.open(u) }
            replyHandler(true, nil)
        case "pano":
            replyHandler(UIPasteboard.general.string ?? "", nil)
        default:
            replyHandler(nil, "bilinmeyen istek")
        }
    }

    /// Paylasim sayfasi: Dosyalar'a kaydet, AirDrop, Mesajlar, e-posta...
    private func paylas(_ u: URL) {
        let p = UIActivityViewController(activityItems: [u], applicationActivities: nil)
        if let pop = p.popoverPresentationController {          // iPad
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY - 80, width: 1, height: 1)
            pop.permittedArrowDirections = .down
        }
        present(p, animated: true)
    }

    // MARK: gezinme: uygulama sayfasi disindaki baglantilar Spotify'da / Safari'de acilir

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let u = navigationAction.request.url, u.scheme != "gammafy", u.scheme != "about",
           navigationAction.targetFrame?.isMainFrame ?? true {
            UIApplication.shared.open(u)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let u = navigationAction.request.url { UIApplication.shared.open(u) }
        return nil
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }
}
