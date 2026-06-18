# Headscale on Coolify via Cloudflared Tunnel

Setup ini cocok untuk:

- Headscale jalan di `Coolify`
- Domain publik control plane di `hs.domainsaya.com`
- Publikasi HTTPS lewat `Cloudflared Tunnel`

## 1. Ubah config headscale

Edit [config.yaml](C:/Users/pande/Downloads/headscale/config.yaml) dan ganti nilai ini:

```yaml
server_url: https://hs.domainsaya.com
```

`dns.base_domain` jangan sama dengan `server_url`. Contoh aman:

```yaml
dns:
  magic_dns: true
  base_domain: ts.domainsaya.com
```

Kalau Anda tidak butuh MagicDNS, bisa matikan:

```yaml
dns:
  magic_dns: false
```

## 2. Import ke Coolify

Deploy sebagai `Docker Compose` menggunakan [docker-compose.yaml](C:/Users/pande/Downloads/headscale/docker-compose.yaml).

Compose ini hanya menjalankan `headscale`.

Port yang dibuka:

- `127.0.0.1:18080:8080`

Artinya:

- `headscale` listen normal di port container `8080`
- host server membuka port lokal `18080`
- port itu tidak terekspos publik karena hanya bind ke `127.0.0.1`
- `cloudflared` yang berjalan sebagai resource terpisah bisa diarahkan ke `http://localhost:18080`

## 3. Buat Cloudflare Tunnel

Di Cloudflare Zero Trust, buat public hostname:

- Hostname: `hs.domainsaya.com`
- Service type: `HTTP`
- Service URL: `http://localhost:18080`

Karena `cloudflared` berjalan terpisah dari `headscale`, ia diarahkan ke host port lokal ini.

## 4. Catatan penting Cloudflare

- Compose ini tidak mengekspos `50443` dan `9090`, dan hanya membuka `18080` pada `127.0.0.1`.
- `Headscale` butuh endpoint HTTPS stabil; `Cloudflared Tunnel` cocok untuk ini.
- MagicDNS domain sebaiknya berbeda dari subdomain control plane.
- DERP bawaan di config ini memakai DERP publik Tailscale, jadi Anda tidak perlu publish UDP tambahan untuk server Headscale.

## 5. Verifikasi setelah deploy

Pastikan endpoint ini merespons lewat tunnel:

```txt
https://hs.domainsaya.com/health
```

Lalu buat user dan preauth key dari container:

```bash
headscale users create default
headscale preauthkeys create --user default --reusable --expiration 24h
```

## 6. Join client Tailscale

Contoh join dari node Linux:

```bash
tailscale up \
  --login-server https://hs.domainsaya.com \
  --auth-key tskey-xxxxxxxx
```

## 7. Rekomendasi akhir

Untuk domain yang Anda sebutkan, konfigurasi yang paling tepat:

- `server_url`: `https://hs.domainsaya.com`
- `dns.base_domain`: `ts.domainsaya.com`

Jangan gunakan `hs.domainsaya.com` untuk keduanya sekaligus.
