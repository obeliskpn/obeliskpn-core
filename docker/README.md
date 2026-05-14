# Obelisk PN — Docker Deployment

This directory contains a ready-to-use Docker environment for deploying the Obelisk PN core (Nginx Facade + Xray VLESS REALITY).

## 🚀 Quick Start

To deploy the node automatically, just run the initialization script. It will generate the cryptographic keys, create the configuration, and start the containers.

```bash
chmod +x init.sh
./init.sh
```

The script will output your connection parameters (UUID, Public Key, Short ID).

## 🏗️ Architecture

- **`nginx/`**: Contains the Nginx configuration. Nginx listens on ports 80 and 443. Port 80 serves a dummy HTML page. Port 443 routes traffic to Xray using the PROXY Protocol.
- **`xray/`**: The Xray configuration file is mapped here. 
- **`docker-compose.yml`**: Manages the lifecycle of both containers.

### Note on Kernel Optimization
If you are running this in production, make sure to apply BBR and TCP optimizations on your **host machine** kernel (see the main `setup.sh` in the repository root). Docker containers share the host's networking stack, so kernel optimizations must be applied at the host level.

---

<a name="русский"></a>
## Русский

Эта директория содержит готовое к использованию Docker-окружение для развертывания ядра Obelisk PN (Nginx Фасад + Xray VLESS REALITY).

### 🚀 Быстрый старт

Для автоматического развертывания узла просто запустите скрипт инициализации. Он сгенерирует криптографические ключи, создаст конфигурацию и запустит контейнеры.

```bash
chmod +x init.sh
./init.sh
```

Скрипт выведет ваши параметры подключения (UUID, Public Key, Short ID).

### 🏗️ Архитектура

- **`nginx/`**: Содержит конфигурацию Nginx. Nginx слушает порты 80 и 443. Порт 80 отдает заглушку HTML. Порт 443 направляет трафик в Xray с использованием PROXY Protocol.
- **`xray/`**: Сюда монтируется конфигурационный файл Xray.
- **`docker-compose.yml`**: Управляет жизненным циклом обоих контейнеров.

#### Заметка по оптимизации ядра
Если вы запускаете это в продакшене, обязательно примените оптимизации BBR и TCP на **хост-машине** (см. основной файл `setup.sh` в корне репозитория). Docker-контейнеры используют сетевой стек хоста, поэтому оптимизации ядра должны применяться на уровне самого сервера.
