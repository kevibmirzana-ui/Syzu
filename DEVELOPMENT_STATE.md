# DEVELOPMENT_STATE - Syzu (Syzu Demo 0.3)

Versi build diatur di version.env (APP_NAME, APP_ID, VERSION_NAME, VERSION_CODE, APK_NAME). Ganti angkanya di file itu untuk versi berikutnya, workflow tidak perlu diubah lagi (sesudah workflow v0.2 dipasang). APP_ID berbeda = terpasang berdampingan dengan versi lama.

Engine: Godot 4.3 (GDScript), GL Compatibility. Build APK: GitHub Actions (.github/workflows/build-apk.yml, sudah jalan).

## File
- project.godot, main.tscn, icon.svg, export_presets.cfg (tidak berubah)
- main.gd: input, level demo, spawn musuh dan checkpoint
- player.gd: movement + combat + parry + slam + HP
- enemy.gd: fighter, shooter, boss (mini-boss), dummy (latihan)
- projectile.gd, fx.gd: peluru musuh (bisa dipantulkan parry) dan efek cincin
- touch_controls.gd: tombol sentuh + HUD

## Milestone
- [x] M1 Foundation, M2 Movement (DITES di HP, lancar)
- [x] M3 Combat (ditulis, BELUM diuji): attack 4 hit + finisher (2x damage, stun 0,5 detik), tombol UP + ATK = tebasan ke atas, dash attack (ATK saat dash), parry + perfect parry (+10/+20 Energy), counter (ATK setelah parry), ground slam (ATK saat jatuh cepat, atau tahan v + ATK di udara), air finisher membanting musuh + shockwave
- [x] M4 Enemy (ditulis, BELUM diuji): fighter, shooter (peluru bisa di-parry/dipantulkan), mini-boss 3 pola, dummy latihan
- [x] M5 Demo level (ditulis, BELUM diuji): 9 musuh, 2 checkpoint, mini-boss di ujung, tulisan DEMO COMPLETE
- [ ] M6 Tes performa + perbaikan bug dari daftar tester

## Keputusan desain
- Energy: maks 100, dash 15, double jump 12, regen 20/5 detik, parry +10, perfect +20 (usulan, belum final)
- Slam: ATK saat kecepatan jatuh > 450, atau tahan tombol v di udara
- Musuh tidak bertabrakan dengan pemain (dash menembus musuh)
- Mini-boss: stun hanya dari finisher/parry, dengan resist
- Belum ada: Mana, 5 elemen, ultimate, Monster Index, pixel art final (di luar demo)

## Bug / catatan
- Belum ada. Kumpulkan dari tes lalu kirim sekaligus.

## Ikon
- icon.png (ikon proyek), icon_192.png (launcher), icon_fg_432.png + icon_bg_432.png (adaptive icon Android 8+), dibuat dari gambar rubah bertopeng buatan pengguna
- Dipasang lewat export_presets (dibuat ulang oleh workflow tiap build): launcher_icons/main_192x192, adaptive_foreground_432x432, adaptive_background_432x432

## Visual (Demo 0.2)
- Pixel art dibuat lewat kode (tools/gen_art.py di sisi Claude): rubah bertopeng 48x40, monster serigala terinfeksi 48x36 (fighter, shooter, boss), ubin batu, latar parallax (bulan merah, struktur lab, kanopi sakura), pohon sakura, lampu, ikon tombol.
- Semua file gambar berawalan art_ di root repo. Sprite sheet: baris = animasi, kolom = frame.
- Kontrol: joystick kiri (kiri/kanan/atas/bawah) + tombol ikon kanan (ATK, JUMP, DASH, RUN, PARRY) + tombol pause.
- Penghitung gem = placeholder (+1 per musuh, +10 boss).
- Catatan: animasi masih sederhana (kerangka dari kode), bukan gambar tangan; bisa diganti sprite sheet buatan sendiri dengan layout baris/kolom yang sama.

## Demo 0.3 (belum dites)
- Varian infeksi: fighter = ringan (1 kotak penanda), heavy = berat (2 kotak; lambat, HP 130, pukulan 28, bulky), extreme = ekstrem (3 kotak; cepat, HP 90, ada serangan lompat, tubuh paling aneh: kristal besar, mata ekstra, lengan panjang).
- Mana (maks 100, regen 20 per 7,5 detik) + bar hijau-tosca di HUD.
- Elemen Air (tombol tetesan air, keyboard O): Attack 2 jarum air x3 (10 Mana); Tide Slash = tombol skill setelah serangan, gelombang menembus (20); Rain Needles = skill di udara, jarum jatuh menyebar (20); Geyser = tahan bawah di tanah + skill, semburan melempar musuh ke atas (25); Mirror Tide = skill setelah parry berhasil, ledakan air + memantulkan peluru (20).
- Ultimate Air "Abyss: Heavenfall" (tombol bintang, keyboard P): 67 Mana + 33 Energy; geyser mengangkat musuh sekitar, Syzu naik lalu menukik, ledakan air 55 damage radius 330. Versi sederhana, BELUM ada sinematik.
- Downward dash sekarang menyerang (kena musuh di bawah).
- Level: 2 heavy/extreme baru di area 2 dan arena bos.
- Belum: 3 combo rahasia Air, kunci progres (10 kill / 50 kill; sekarang semua terbuka), 4 elemen lain, sinematik ultimate, nama unik + Monster Index, mini-boss antropomorfik, serangan 6 arah penuh, kumis 3 garis.
- Versi diatur di version.env (APP_ID com.syzu.demo03 -> terpasang berdampingan dengan 0.2).
