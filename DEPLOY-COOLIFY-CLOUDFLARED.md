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

Port yang perlu dipakai:

- `8080` untuk Headscale control plane
- `9090` hanya jika ingin metrics
- `50443` hanya jika memang perlu gRPC remote CLI

Untuk deployment publik minimal, cukup route trafik publik ke `8080`.

## 3. Buat Cloudflare Tunnel

Di sisi `cloudflared`, buat public hostname:

- Hostname: `hs.domainsaya.com`
- Service type: `HTTP`
- Service URL: `http://headscale:8080` jika `cloudflared` satu network/container dengan service `headscale`

Jika `cloudflared` tidak satu docker network dengan Headscale, arahkan ke host internal yang bisa dijangkau dari container `cloudflared`, misalnya:

```txt
http://<ip-atau-host-internal>:8080
```

## 4. Catatan penting Cloudflare

- Jangan expose `50443` ke internet kecuali Anda memang butuh dan tahu alurnya.
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
