# v25.1.1-prod

Исправляющий релиз перед первым реальным VDS-тестом.

Главные исправления: корректный `FRONT_END_DOMAIN`, безопасный `TRUST_PROXY=1`, безопасное поведение с дефолтным PostgreSQL password, полноценный healthcheck и фактический импорт PostgreSQL dump при restore.

Статические проверки пройдены. Реальный VDS runtime deployment ещё обязателен.

