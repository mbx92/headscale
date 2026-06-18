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

Config dibundel ke image saat build melalui [Dockerfile](C:/Users/pande/Downloads/headscale/Dockerfile:1), jadi `Coolify` tidak perlu bind-mount `config.yaml` dan `acl.json` dari repo saat runtime.

Compose ini hanya menjalankan `headscale`.

Port yang dibuka:

- `10.100.10.6:18080:8080`

Artinya:

- `headscale` listen normal di port container `8080`
- host `Coolify` membuka `10.100.10.6:18080`
- port ini hanya bisa diakses lewat IP internal server `Coolify`
- reverse proxy terpisah di `10.100.10.10` dapat diarahkan ke `http://10.100.10.6:18080`
- perubahan `config.yaml` atau `acl.json` memerlukan rebuild/redeploy aplikasi

## 3. Buat Cloudflare Tunnel

Jika memakai reverse proxy terpisah seperti `Nginx Proxy Manager`, arahkan upstream ke:

```txt
http://10.100.10.6:18080
```

## 4. Catatan penting Cloudflare

- Compose ini tidak mengekspos `50443` dan `9090`, dan hanya membuka `18080` pada IP internal `10.100.10.6`.
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
