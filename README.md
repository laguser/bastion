<div align="center">
  <br>
  <img src="assets/bastion.png" width="620" alt="Bastion">

  <h2>bastion</h2>
  <p><i>intelligent server hardening & performance tuning</i></p>
  
  <p>
    <code>root</code> · <code>bbr</code> · <code>fail2ban</code> · <code>ufw</code> · <code>gemini-flash</code>
  </p>

  <p>
    <a href="#-русский">русский</a> · <a href="#-english">english</a>
  </p>

  <p>
    <img src="https://img.shields.io/badge/os-ubuntu_%7C_debian-000000?style=flat-square&logo=linux&logoColor=white" alt="OS">
    <img src="https://img.shields.io/badge/ai-gemini_flash-000000?style=flat-square&logo=google&logoColor=white" alt="AI">
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

**Bastion** — минималистичный инструмент для превращения свежего VPS в защищенный и оптимизированный сервер за 60 секунд.

* Работает напрямую из-под `root` (вход по паролю сохранён).
* Никакого визуального шума — чистый интерактивный интерфейс.
* Тюнинг ядра по стандартам безопасности и скорости.

---

## ◈ Режимы работы

| Режим | Описание |
| :--- | :--- |
| **`[1] Automatic`** | Моментальное применение оптимальных настроек без лишних вопросов. |
| **`[2] Manual`** | Пошаговый диалог. Достаточно нажимать `[Enter]` для выбора дефолтных значений. |
| **`[3] AI-Powered`** | Анализ через **Gemini Flash**. Нейросеть считывает CPU, RAM, диск и подбирает параметры. |

---

## ◈ Безопасность

* **OpenSSH**: Ограничение попыток входа (`MaxAuthTries 3`), тайм-аут ожидания 30с (`LoginGraceTime 30`), отключение X11.
* **Fail2Ban**: Автоматический бан IP-адресов при попытках подбора пароля по SSH.
* **UFW**: Закрыты все входящие порты, кроме SSH и опционально веб (80/443).
* **Защита `/dev/shm`**: Монтирование с флагами `noexec,nosuid,nodev` против исполнения скриптов из памяти.
* **Ядро (DoS Shield)**: Криптографические `tcp_syncookies`, защита от спуфинга (`rp_filter`), игнорирование ICMP Broadcast.
* **Права ядра**: Ограничение доступа к `dmesg` и адресам ядра (`kptr_restrict = 2`).
* **Автообновления**: Фоновая служба `unattended-upgrades` для своевременных патчей безопасности.

---

## ◈ Оптимизация

* **Google BBR**: Алгоритм контроля перегрузки TCP от Google — максимальная пропускная способность и низкий пинг.
* **Буферы TCP**: Расширение окон сокетов до 16 МБ для высокоскоростных каналов.
* **Лимиты файлов**: Поднятие системного ограничения `nofile` до 65 535 (никаких `Too many open files`).
* **Swap & Swappiness**: Автоматическое выделение Swap с правами `600` и `swappiness = 10` (приоритет оперативной памяти).

---

## ◈ Смена пароля

В конце любого из режимов скрипт предлагает задать новый пароль для `root`.

---

# 🇬🇧 English

## ◈ Overview

**Bastion** is a minimalist automation suite that hardens and tunes a fresh Linux VPS in under a minute.

* Root-focused workflow (preserves password authentication).
* Minimalist terminal interface with smart Enter-defaults.
* Kernel-level hardening & network congestion tuning.

---

## ◈ Modes

| Mode | Description |
| :--- | :--- |
| **`[1] Automatic`** | Instant hardening using battle-tested defaults. |
| **`[2] Manual`** | Interactive wizard. Press `[Enter]` to accept recommended values. |
| **`[3] AI-Powered`** | Tailored calibration via **Google Gemini Flash** based on server specs. |

---

## ◈ Hardening Features

* **SSH**: MaxAuthTries 3, LoginGraceTime 30s, keepalive watchdog.
* **Fail2Ban**: Dynamic jail banning brute-force attempts on the SSH port.
* **Firewall (UFW)**: Default-deny incoming policy with isolated whitelist rules.
* **Protected `/dev/shm`**: Mounted with `noexec,nosuid,nodev` to neutralize RAM payload execution.
* **Kernel DoS Shield**: TCP SYN cookies, reverse path filtering, and restricted `dmesg` access.
* **Unattended Upgrades**: Automated upstream security patches without disruption.

---

## ◈ Performance Tuning

* **Google BBR**: Next-generation TCP flow control yielding reduced bufferbloat and latency.
* **Extended TCP Windows**: Up to 16MB read/write socket buffers.
* **Resource Limits**: System-wide file descriptor ceiling raised to 65,535.
* **Virtual Memory**: Optimized swap allocation with `vm.swappiness = 10`.

---

<br>
<div align="center">
  <p>Made with 🤍 by <a href="https://github.com/laguser">laguser</a></p>
  <sub><i>less is more</i></sub>
</div>
