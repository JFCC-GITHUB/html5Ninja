# 忍者手裏劍 (Ninja Shuriken / Shuriken Hero) 🇹🇼

以 **Godot 4** 製作並匯出為 HTML5 (WebAssembly) 的 2D 像素風忍者防守遊戲，支援中文 / English 切換。

## 🎮 遊戲特色

- **兩種模式**：經典防守（Classic）、箭塔防禦（Tower Defense，需守護箭塔）。
- **六種難度**：上帝、極簡、簡單、普通、困難、噩夢。
- **五種敵人**：普通、疾風（FAST）、重裝（TANK）、暗影（SHADOW）、首領（BOSS）；依等級逐步出現。
- **攻擊方式**：手裏劍自動連射、近身斬擊；升級後箭塔會自動射擊。
- **最高分記錄**：存於 Godot `user://highscore.save`（網頁版即瀏覽器 IndexedDB）。

## 🕹️ 操作

- **電腦**：`A` / `D` 或 ⬅️ / ➡️ 移動，`J` / `Z` 斬擊，`P` / `Esc` 暫停。
- **手機 / 平板**：使用畫面下方「左移 & 射擊」「右移 & 射擊」「斬擊」按鈕。

## 🚀 執行

- **線上版**：<https://jfcc-github.github.io/html5Ninja/>
- **桌面版**：到 [Releases](../../releases) 下載 `ShurikenHero-windows.zip`（Windows）或 `ShurikenHero-linux.zip`（Linux），解壓後直接執行。
- **本機網頁版**：Godot 匯出的 WebAssembly 無法用 `file://` 開啟，請用靜態伺服器：

```bash
python3 -m http.server 8000
# 瀏覽 http://localhost:8000
```

## 🛠️ 建置

需安裝 Godot 4.7（含 export templates），專案位於 `godot_project/`：

```bash
./build.sh   # 網頁版：匯出到根目錄的 index.* 並為 index.pck 加上內容雜湊以避免快取

# 桌面版（輸出到 dist/，不進 git）
mkdir -p dist/linux dist/windows
godot --headless --path godot_project --export-release "Linux" ../dist/linux/ShurikenHero.x86_64
godot --headless --path godot_project --export-release "Windows Desktop" ../dist/windows/ShurikenHero.exe
```

推送到 `main` 時 CI 會匯出三個平台；推送 `v*` 標籤時會另外建立 GitHub Release 並附上三個 zip。

## 🔤 字型

`godot_project/fonts/NotoSansTC-Regular.ttf` 是只含實際用到字元的子集（約 230KB，原檔 12MB）。新增或修改介面文字後，請重新產生：

```bash
cd godot_project/fonts
python3 - <<'PY'
import glob
t="".join(open(f,encoding='utf8').read() for f in glob.glob('../scripts/*.gd')+glob.glob('../scenes/*.tscn'))
open('subset-chars.txt','w',encoding='utf8').write("".join(sorted({c for c in t if ord(c)>0x7f}))+"\n")
PY
# 需先取得完整版 NotoSansTC-Regular.ttf（Google Fonts）
uvx --from fonttools --with brotli pyftsubset NotoSansTC-Regular.ttf --text-file=subset-chars.txt \
  --unicodes="U+0020-007E,U+3000-303F,U+FF00-FFEF,U+2010-206F" --layout-features='*' --output-file=sub.ttf
mv sub.ttf NotoSansTC-Regular.ttf
```

## 📜 授權

本專案採用 [PolyForm Noncommercial License 1.0.0](LICENSE)：**僅限非商業用途**。個人學習、研究與非營利使用可自由取得、修改與散布（散布時須附上授權與版權聲明）。商業用途請先聯絡作者取得授權。

第三方素材：

- `godot_project/fonts/NotoSansTC-Regular.ttf`（Noto Sans TC 子集）依 [SIL Open Font License 1.1](https://openfontlicense.org/) 授權，原始字型版權歸其作者所有。

---

Made in Taiwan 🇹🇼
