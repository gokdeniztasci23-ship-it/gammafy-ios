import AVFoundation
import UIKit

/// GammaFY iPhone: tek ekranli uygulama; arayuz WKWebView icinde, Spotify istekleri Aktarici uzerinden.
@main
final class Uygulama: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // acilis sesi calan muzigi durdurmaz ve sessiz dugmesine uyar
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        let w = UIWindow(frame: UIScreen.main.bounds)
        w.backgroundColor = Yardimci.zemin
        w.rootViewController = AnaEkran()
        w.makeKeyAndVisible()
        window = w
        return true
    }
}
