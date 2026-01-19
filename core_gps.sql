CREATE TABLE IF NOT EXISTS `core_gps` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) NOT NULL,
    `label` varchar(100) NOT NULL,
    `coords` longtext NOT NULL,
    `street` varchar(255) DEFAULT NULL,
    `timestamp` bigint(20) DEFAULT NULL,
    `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
    PRIMARY KEY (`id`),
    KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
