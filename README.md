<div align="center">
  <br>
  <img src="assets/bastion.png" width="620" alt="Bastion">

  <h2>bastion</h2>
  <p><i>hardened linux vps security & optimization suite</i></p>
  
  <p>
    <code>root</code> · <code>bbr</code> · <code>fail2ban</code> · <code>ufw</code> · <code>ed25519</code>
  </p>

  <p>
    <a href="#-русский">русский</a> · <a href="#-english">english</a>
  </p>

  <p>
    <img src="https://img.shields.io/badge/os-ubuntu_%7C_debian-000000?style=flat-square&logo=linux&logoColor=white" alt="OS">
    <img src="https://img.shields.io/badge/author-laguser-000000?style=flat-square&logo=github&logoColor=white" alt="Author">
    <img src="https://img.shields.io/badge/tcp-google_bbr-000000?style=flat-square" alt="TCP">
    <img src="https://img.shields.io/badge/license-mit-000000?style=flat-square" alt="License">
  </p>
  <br>
</div>

---

### ⚡ Быстрый старт / Quick Start

Выполните одну команду от имени `root`:

```bash
bash <(curl -sSL https://raw.githubusercontent.com/laguser/bastion/main/setup.sh)
```

---

# 🇷🇺 Русский

## ◈ О проекте

**Bastion** — инструмент от **laguser** для превращения свежего Linux VPS (Ubuntu / Debian) в защищённый и производительный сервер за 60 секунд. 
Полностью автономен, не зависит от сторонних облачных API, исключает любые риски удалённых инъекций и обеспечивает нулевой риск локаута.

* Работает под `root` с поддержкой как SSH-ключей, так и паролей.
* Чистый интерфейс с выбором дефолтных значений по нажатию `[Enter]`.
* Независимый сетевой разгон (BBR) и глубокое ячеечное ядровое экранирование.

---

## ◈ Режимы работы

| Режим | Описание |
| :--- | :--- |
| **`[1] Automatic (Recommended)`** | Моментальное развёртывание эталонного production-профиля безопасности без облачных зависимостей. |
| **`[2] Interactive Wizard`** | Пошаговый интерактивный мастер: добавление SSH-ключей, отключение паролей, кастомные порты, swap и лимиты. |

---

## ◈ Безопасность

* **Строгая криптография OpenSSH**: Приоритетный drop-in (`00-bastion.conf`), современные алгоритмы обмена ключами (`curve25519-sha256`, `diffie-hellman-group16-sha512`), шифры (`chacha20-poly1305`, `aes256-gcm`) и MAC (`hmac-sha2-512-etm`). Отключение X11 и TCP forwarding по умолчанию.
* **Управление аутентификацией**: Интерактивное добавление открытых ключей SSH (`authorized_keys`) и возможность полного отключения входа по паролю (`PasswordAuthentication no`, `PermitRootLogin prohibit-password`).
* **Защита от Lockout**: Проверка синтаксиса `sshd -t` с авто-откатом при ошибках, валидация привязки портов (`ss -tlnH`), аварийный порт 22 с rate-limit и гарантированное сокет-детектирование (`systemctl is-enabled ssh.socket`).
* **Fail2Ban (systemd-native)**: Чтение журнала systemd напрямую через `python3-systemd`, авто-вайтлист IP администратора (`ignoreip`), одновременная защита активного и аварийного портов.
* **UFW Firewall & Multi-Protocol Auto-Detect**: Автоматическое определение активных TCP и UDP сервисов (WireGuard, OpenVPN, Mail, Docker) с сохранением доступа и бэкапом правил в `/var/backups/bastion/`.
* **Защита `/dev/shm`**: Монтирование с флагами `noexec,nosuid,nodev` против исполнения вредоносных скриптов из общей памяти.
* **Ядро (DoS Shield)**: Криптографические `tcp_syncookies`, RFC 1337 (TIME-WAIT assasination fix), строгая фильтрация обратного пути (`rp_filter`), запрет ICMP redirects и спуфинга.
* **Безопасность IPv6**: Полная блокировка Router Advertisements (`accept_ra = 0`) и перенаправлений.
* **Автообновления**: Службы `unattended-upgrades` с преднастроенным файлом `50unattended-upgrades` ( security-репозитории, автоочистка неиспользуемых ядер и зависимостей).
* **Аварийный откат**: Автоматический бэкап `sshd_config`, `fstab`, `system.conf` и `ufw` в `/var/backups/bastion/`.

---

## ◈ Оптимизация

* **Google BBR**: Независимый модуль `98-bbr.conf` с очередями `fq` — максимальная пропускная способность и минимальный пинг даже при частичных ограничениях контейнеров.
* **Буферы TCP**: Расширение окон сокетов до 16 МБ для высокоскоростных гигабитных каналов.
* **Лимиты файлов**: Поднятие системного ограничения `nofile` до 65 535.
* **Swap & Filesystem Check**: Интеллектуальное выделение Swap с проверкой свободного места на диске, флагом `nofail` в `/etc/fstab` и приоритетом RAM (`swappiness = 10`).

---

# 🇬🇧 English

## ◈ Overview

**Bastion** is an autonomous security hardening and performance tuning tool engineered by **laguser** for modern Linux VPS (Ubuntu & Debian).
Completely offline-capable with zero cloud API dependencies, zero injection attack surface, and rock-solid lockout prevention.

* Designed for `root` administration with SSH key & password flexibility.
* Clean visual UI with intelligent Enter-defaults.
* Independent Google BBR network acceleration and kernel-level defense.

---

## ◈ Modes

| Mode | Description |
| :--- | :--- |
| **`[1] Automatic (Recommended)`** | Instant deployment of hardened production defaults with zero manual prompts. |
| **`[2] Interactive Wizard`** | Guided step-by-step setup: paste SSH keys, toggle password auth, tune ports, swap, and fail2ban. |

---

## ◈ Author

Engineered with 🤍 by **laguser** — [github.com/laguser](https://github.com/laguser)  
Project Repository: [github.com/laguser/bastion](https://github.com/laguser/bastion)
