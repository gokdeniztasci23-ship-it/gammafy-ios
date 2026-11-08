# GammaFY.py icindeki arayuzu iPhone uygulamasinin web/ klasorune donusturur ve kopruyu ekler.
# Kullanim: python3 araclar/hazirla.py ../GammaFY.py web
import importlib.util, os, sys
kaynak, hedef = sys.argv[1], sys.argv[2]
s = importlib.util.spec_from_file_location("gammafy", kaynak); m = importlib.util.module_from_spec(s); s.loader.exec_module(m)
sayfa = m.SAYFA
kopru = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "kopru_ios.js"), encoding="utf-8").read()
i = sayfa.index("<head>") + len("<head>")
sayfa = sayfa[:i] + "\n<script>" + kopru + "</script>" + sayfa[i:]
os.makedirs(hedef, exist_ok=True)
open(os.path.join(hedef, "index.html"), "w", encoding="utf-8").write(sayfa)
print("web:", sorted(os.listdir(hedef)))
