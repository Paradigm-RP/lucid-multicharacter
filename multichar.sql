CREATE TABLE IF NOT EXISTS `multichar_permissions` (
  `license` varchar(255) COLLATE utf8mb4_bin NOT NULL,
  `slot` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;


ALTER TABLE `players`
	ADD COLUMN `mugshot` VARCHAR(255) NULL DEFAULT 'https://i.imgur.com/HAF61R9.png'