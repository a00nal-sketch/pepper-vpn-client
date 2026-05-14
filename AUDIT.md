# АУДИТ pepper-vpn-client

## Обзор проекта
Проект pepper-vpn-client (форк Outline) представляет собой кроссплатформенный VPN-клиент с поддержкой протокола VLESS (с REALITY, XTLS-Vision, uTLS). Проект использует Xray-core в качестве основного движка и имеет реализации для различных платформ, включая iOS, Android, Windows, macOS и Linux.

## 1. Файлы, связанные с парсингом конфигурации VLESS

### Найденные файлы:
1. `src/tun2socks/outline/xray_mobile/xray.go` - Основной файл для работы с Xray, включая конфигурацию
2. `src/tun2socks/outline/xray_mobile/tunnel.go` - Туннель для мобильных платформ с поддержкой Xray
3. `src/tun2socks/outline/xray_mobile/tunnel_android.go` - Специфичная реализация для Android
4. `src/tun2socks/outline/xray_mobile/tunnel_darwin.go` - Специфичная реализация для Darwin/macOS
5. `src/www/app/outline_server_repository/access_key_serialization.ts` - Сериализация ключей доступа, вероятно включает VLESS
6. `src/www/app/outline_server_repository/server.ts` - Работа с серверами, включая конфигурацию

### Краткие описания:
- `xray.go` - Инициализация и настройка Xray-ядра, включая обработку конфигурации
- `tunnel.go` - Общая реализация туннеля для мобильных платформ с поддержкой Xray
- `tunnel_android.go` - Реализация туннеля для Android
- `tunnel_darwin.go` - Реализация туннеля для Darwin/macOS
- `access_key_serialization.ts` - Сериализация/десериализация ключей доступа, включая VLESS
- `server.ts` - Представление сервера и работа с его конфигурацией

## 2. Файлы, связанные с VPN-туннелем (NetworkExtension / PacketTunnelProvider)

### Найденные файлы:
1. `src/cordova/plugin/apple/src/OutlinePlugin.swift` - Основной плагин для Apple платформ
2. `src/cordova/plugin/apple/src/macos/Outline-Bridging-Header.h` - Заголовочный файл для Swift/Objective-C
3. `src/electron/go_vpn_tunnel.ts` - VPN-туннель для Electron/Go
4. `src/electron/vpn_tunnel.ts` - Базовый интерфейс VPN-туннеля
5. `src/tun2socks/tunnel/tunnel.go` - Основной туннель
6. `src/tun2socks/tunnel/tun_android.go` - Реализация TUN для Android
7. `src/tun2socks/tunnel_darwin/tunwriter.go` - Запись в TUN для Darwin
8. `src/tun2socks/outline/tun2socks/tunnel.go` - Туннель tun2socks
9. `src/tun2socks/outline/tun2socks/tunnel_android.go` - Реализация tun2socks для Android
10. `src/tun2socks/outline/tun2socks/tunnel_darwin.go` - Реализация tun2socks для Darwin

### Краткие описания:
- `OutlinePlugin.swift` - Основной плагин для интеграции с Apple NetworkExtension
- `Outline-Bridging-Header.h` - Заголовочный файл для обеспечения совместимости Swift/Objective-C
- `go_vpn_tunnel.ts` - Интеграция Go VPN-туннеля с Electron
- `vpn_tunnel.ts` - Базовый интерфейс для VPN-туннелей
- `tunnel.go` - Основная реализация туннеля
- `tun_android.go` - Реализация TUN для Android
- `tunwriter.go` - Запись в TUN для Darwin/macOS
- `tun2socks/tunnel.go` - Туннель tun2socks для преобразования трафика
- `tun2socks/tunnel_android.go` - Реализация tun2socks для Android
- `tun2socks/tunnel_darwin.go` - Реализация tun2socks для Darwin/macOS

## 3. Файлы UI-слоя (Swift/TypeScript UI)

### Найденные файлы:
1. `src/cordova/plugin/apple/src/OutlinePlugin.swift` - Swift-код для Apple платформ
2. `src/www/app/app.ts` - Основное приложение
3. `src/www/app/main.ts` - Точка входа в приложение
4. `src/www/ui_components/*.js` - Компоненты пользовательского интерфейса
5. `src/www/views/**/*.ts` - Представления приложения
6. `src/www/app/cordova_main.ts` - Точка входа для Cordova
7. `src/www/app/electron_main.ts` - Точка входа для Electron

### Краткие описания:
- `OutlinePlugin.swift` - Swift-код для интеграции с Apple платформами
- `app.ts` - Основная логика приложения
- `main.ts` - Точка входа в веб-приложение
- `ui_components/*.js` - Компоненты пользовательского интерфейса (JavaScript)
- `views/**/*.ts` - Представления приложения (TypeScript)
- `cordova_main.ts` - Точка входа для мобильных платформ через Cordova
- `electron_main.ts` - Точка входа для десктоп-платформ через Electron

## 4. Файлы, связанные с логикой импорта подписки

### Найденные файлы:
1. `src/www/app/outline_server_repository/index.ts` - Репозиторий серверов Outline
2. `src/www/app/outline_server_repository/server.ts` - Представление сервера
3. `src/www/app/outline_server_repository/access_key_serialization.ts` - Сериализация ключей доступа
4. `src/www/app/app.ts` - Основное приложение, включая логику добавления серверов

### Краткие описания:
- `index.ts` - Основной репозиторий для работы с серверами Outline
- `server.ts` - Представление и управление сервером
- `access_key_serialization.ts` - Сериализация/десериализация ключей доступа (включая VLESS)
- `app.ts` - Основная логика приложения, включая добавление серверов через ссылки

## 5. Что нужно удалить (брендинг Pepper/Outline)

### Найденные файлы с брендингом:
1. `src/www/assets/brand-logo.png` - Логотип бренда
2. `src/www/assets/jigsaw-logo.png` - Логотип Jigsaw
3. `src/www/assets/jigsaw-logo.svg` - Логотип Jigsaw (SVG)
4. `src/www/assets/outline-client-logo.png` - Логотип клиента Outline
5. `src/www/assets/outline-client-logo.svg` - Логотип клиента Outline (SVG)
6. `src/www/ui_components/outline-icons.js` - Иконки Outline
7. `src/www/app/outline_server_repository/` - Репозиторий серверов Outline
8. Все упоминания "Outline" в коде
9. Все упоминания "Jigsaw" в коде

## 6. Что можно повторно использовать

### Компоненты, которые можно повторно использовать:
1. Вся логика работы с Xray-core - полностью переиспользуема
2. Туннельные реализации для различных платформ - можно переиспользовать с изменениями под VLESS
3. Архитектура приложения - хорошо структурирована и может быть переиспользована
4. Компоненты UI - могут быть переиспользованы с изменением визуального оформления
5. Система сборки и развертывания - может быть переиспользована
6. Локализация - может быть частично переиспользована
7. Логика работы с серверами и ключами доступа - может быть адаптирована под VLESS

## Заключение

Проект pepper-vpn-client представляет собой хорошо структурированное приложение с четким разделением компонентов для различных платформ. Основная логика работы с VPN и Xray-core может быть полностью переиспользована. Основные изменения потребуются в UI-слое для удаления брендинга Outline/Jigsaw и адаптации под новый бренд. Также потребуется адаптация логики работы с конфигурацией под протокол VLESS.