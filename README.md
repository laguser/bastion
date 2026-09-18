<div align="center">
  <img src="assets/banner.png" width="740" alt="Bastion — Intelligent Server Hardening">

  <h1>🛡️ Bastion</h1>
  <p><strong>Интеллектуальный комплекс автоматической защиты и глубокой оптимизации Linux VPS.</strong></p>
  <p><em>Intelligent Linux VPS hardening, TCP/BBR acceleration & AI-driven tuning suite.</em></p>

  <p>
    <a href="#-русский">🇷🇺 Русский</a> • <a href="#-english">🇬🇧 English</a>
  </p>

  <p>
    <img src="https://img.shields.io/badge/OS-Ubuntu_%7C_Debian-E95420?style=for-the-badge&logo=ubuntu&logoColor=white" alt="OS">
    <img src="https://img.shields.io/badge/AI-Gemini_Flash-4285F4?style=for-the-badge&logo=google&logoColor=white" alt="AI Engine">
    <img src="https://img.shields.io/badge/TCP-Google_BBR-00C7B7?style=for-the-badge&logo=fastapi&logoColor=white" alt="Network">
    <img src="https://img.shields.io/badge/License-MIT-8A2BE2?style=for-the-badge" alt="License">
  </p>
</div>

---

### ⚡ Instant Launch / Быстрый запуск

Запустите одну команду на чистом сервере (от имени `root`):

```bash
bash <(curl -sSL https://raw.githubusercontent.com/laguser/bastion/main/setup.sh)
```

---

# 🇷🇺 Русский

## ✨ О проекте

**Bastion** превращает свежеустановленный сервер в защищенную и разогнанную крепость за 60 секунд. Скрипт сочетает строгие стандарты безопасности Linux (CIS benchmark practices) с тюнингом ядра для максимальной пропускной способности сети.

Поддерживает работу с учетной записью `root`, не ломая вход по паролю, защищает от брутфорса и подбирает идеальные параметры ядра.

---

## 🎯 3 режима работы

<table>
  <tr>
    <td width="33%" align="center">
      <h3>🚀 Automatic</h3>
      <p>Мгновенная настройка в 1 клик. Применяет идеальные стандарты безопасности и оптимизации без лишних вопросов.</p>
    </td>
    <td width="33%" align="center">
      <h3>🛠️ Manual Wizard</h3>
      <p>Пошаговый интерактивный диалог. Каждый параметр имеет подсказку — достаточно нажимать <code>[Enter]</code> для выбора оптимума.</p>
    </td>
    <td width="33%" align="center">
      <h3>🧠 AI-Powered</h3>
      <p>Анализ через <b>Google Gemini Flash</b>. Нейросеть считывает CPU, RAM, диск и профиль нагрузки сервера и рассчитывает параметры персонально.</p>
    </td>
  </tr>
</table>

---

## 🛡️ Безопасность (Hardening)

* 🔒 **OpenSSH Armor**: Защита от зависших сессий (`ClientAliveInterval`), лимит 3 попыток авторизации (`MaxAuthTries 3`), тайм-аут ввода пароля 30с (`LoginGraceTime 30`).
* 🚫 **Fail2Ban Shield**: Автоматический бан IP-адресов ботов и сканеров при попытках подбора пароля по SSH (настраиваемое время блокировки).
* 🧱 **UFW Firewall**: Политика «запрещено всё, что не разрешено». Открыт только нужный SSH-порт и веб (80/443 по желанию).
* 🛡️ **Защита памяти `/dev/shm`**: Монтирование с флагами `noexec,nosuid,nodev` — блокирует запуск вредоносных бинарников и скриптов из временной памяти.
* 🧬 **Защита ядра от DoS**: Включение криптографических кук `tcp_syncookies`, ограничение SYN-ACK ретраев, защита от Smurf-атак (`icmp_echo_ignore_broadcasts`).
* 🕵️ **Анти-спуфинг IP**: Проверка обратного пути пакетов (`rp_filter = 1`) и отключение ICMP-редиректов.
* 🔒 **Ограничение прав на ядро**: `kptr_restrict = 2`, `dmesg_restrict = 1` (скрытие адресов ядра и логов от непривилегированных процессов).
* 🔄 **Автообновления безопасности**: Фоновая служба `unattended-upgrades` автоматически патчит уязвимости ОС без перезагрузок.

---

## ⚡ Оптимизация производительности

* 🌐 **Google BBR**: Активация современного алгоритма контроля перегрузки TCP от Google. Обеспечивает максимальную скорость передачи и минимальный пинг на загруженных каналах.
* 🚀 **Тюнинг буферов TCP**: Увеличение сетевых окон чтения/записи до 16 МБ (`tcp_rmem`, `tcp_wmem`) для работы на 1–10 Гбит/с каналах.
* 📂 **Лимит файлов 65535**: Снятие стандартного ограничения Linux в 1024 дескриптора на уровне ядра и `systemd` (забудьте про ошибку `Too many open files`).
* 💾 **Swap & Swappiness**: Автоматическое создание файла подкачки с правами `600` и параметром `swappiness = 10` (сервер использует быстрый RAM, обращаясь к диску только в крайнем случае).
* ⚙️ **Очереди сокетов**: Увеличение `somaxconn` до 65 535 и `netdev_max_backlog` до 10 000 для стабильной обработки наплыва клиентов.

---

## 🔑 Смена пароля в 1 клик

В финале любого режима скрипт интерактивно предложит установить новый надёжный пароль для суперпользователя `root`, полностью завершая цикл первоначальной настройки.

---

# 🇬🇧 English

## ✨ Overview

**Bastion** turns a fresh Linux VPS into an impenetrable and fully optimized fortress in under 60 seconds. It pairs battle-tested Linux security standards with kernel-level performance tuning.

Designed specifically for root environments with password authentication, brute-force mitigation, and AI-assisted hardware calibration.

---

## 🎯 3 Operational Modes

* **`[1] Automatic`** — Zero-friction instant deployment with proven, secure defaults.
* **`[2] Manual Wizard`** — Step-by-step interactive CLI questionnaire. Press `[Enter]` to accept optimal suggestions.
* **`[3] AI-Powered (Gemini Flash)`** — Deep telemetry scan (CPU, RAM, disk, OS) sent to Google's fastest Gemini Flash model to calculate tailored buffer sizes, swap allocations, and jail rules.

---

## 🛡️ Security Features

* 🔐 **SSH Hardening**: MaxAuthTries 3, LoginGraceTime 30s, session keepalive checks, and port randomization support.
* 🛑 **Fail2Ban Defense**: Intelligent brute-force isolation with customizable jail durations.
* 🧱 **Strict UFW Rules**: Default-deny incoming policy; whitelisted SSH and optional HTTP/HTTPS traffic.
* 🚫 **Hardened `/dev/shm`**: Mounted with `noexec,nosuid,nodev` to prevent in-memory script execution.
* 🛡️ **DoS & SYN Mitigation**: TCP SYN cookies enabled, SYN-ACK retries pruned, ICMP broadcasts ignored.
* 🕵️ **Anti-Spoofing & Privacy**: Reverse path filtering enabled, kernel log inspection restricted (`dmesg_restrict`).
* 🔄 **Unattended Upgrades**: Automated background security patches straight from upstream repositories.

---

## 🚀 Performance Optimizations

* ⚡ **Google BBR**: Next-gen congestion control algorithm yielding significantly higher throughput and reduced jitter.
* 🏎️ **Dynamic TCP Buffers**: Expanded network window sizes (up to 16MB) for modern multi-gigabit connections.
* 📂 **65,535 File Descriptors**: System-wide limits lifted for high-concurrency daemons (Docker, Nginx, databases).
* 💾 **Smart Swappiness**: Configured to `vm.swappiness = 10` to keep application memory resident in RAM.

---

## 📋 Compatibility

* **Ubuntu**: 20.04 LTS, 22.04 LTS, 24.04 LTS
* **Debian**: 11 (Bullseye), 12 (Bookworm)

---

<div align="center">
  <p>Made with 💜 by <a href="https://github.com/laguser">laguser</a></p>
  <sub><i>craft, don't clutter</i></sub>
</div>
