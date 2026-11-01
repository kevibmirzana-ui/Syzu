# DEVELOPMENT_STATE - Syzu

Engine: Godot 4.3 (GDScript), renderer GL Compatibility (ringan untuk HP)
Target: APK Android (landscape), build lewat GitHub Actions (.github/workflows/build-apk.yml)

## File
- project.godot, main.tscn, icon.svg, export_presets.cfg
- main.gd: input keyboard (tes PC) + level dibuat lewat kode
- player.gd: movement Syzu (placeholder visual kotak)
- touch_controls.gd: tombol sentuh multi-touch + bar Energy
- .github/workflows/build-apk.yml: build APK otomatis

## Milestone
- [x] M1 Foundation (ditulis, BELUM diuji di Godot)
- [x] M2 Movement: walk, run, jump, double jump, dash (i-frame sebagian), air dash 1x, wall slide, wall jump, ledge grab, downward dash (hancurkan platform rapuh) (ditulis, BELUM diuji)
- [ ] M3 Combat (attack 6 arah, combo, finisher, dash attack, parry, counter, ground slam)
- [ ] M4 Enemy
- [ ] M5 Demo level
- [ ] M6 APK final + tes performa

## Keputusan desain (jangan diubah tanpa persetujuan)
- Run aktif lewat tombol RUN saat berjalan, berhenti kalau diam
- Air dash 1x, tidak reset oleh wall jump; dash setelah wall jump boleh
- Wall slide: tidak bisa serang, boleh dash. Ledge grab: tidak bisa serang
- Energy maks 100, dash 15, double jump 12, regen 20/5 detik (USULAN, belum final)
- Wall jump tidak mereset double jump (asumsi, bisa diubah)

## Error / catatan
- Belum ada build pertama. Kalau build GitHub gagal, kirim log error ke Claude.

## Langkah berikutnya
1. Build APK pertama, tes feel gerakan di HP, tune angka di player.gd
2. Lanjut M3 Combat
