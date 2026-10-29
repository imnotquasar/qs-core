CREATE TABLE IF NOT EXISTS `players` (
    `citizenid`     VARCHAR(50)  NOT NULL,
    `license`       VARCHAR(60)  NOT NULL,
    `name`          VARCHAR(100) DEFAULT NULL,
    `charinfo`      LONGTEXT     DEFAULT NULL,
    `money`         LONGTEXT     DEFAULT NULL, 
    `job`           LONGTEXT     DEFAULT NULL,
    `inventory`     LONGTEXT     DEFAULT NULL,
    `metadata`      LONGTEXT     DEFAULT NULL,
    `position`      LONGTEXT     DEFAULT NULL,
    `skin`          LONGTEXT     DEFAULT NULL,
    `is_dead`       TINYINT(1)   NOT NULL DEFAULT 0,
    `cid`           INT          DEFAULT NULL,
    `last_updated`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`citizenid`),
    KEY `idx_players_license` (`license`),
    KEY `idx_players_license_cid` (`license`, `cid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `bans` (
    `id`         INT          NOT NULL AUTO_INCREMENT,
    `license`    VARCHAR(60)  NOT NULL,
    `name`       VARCHAR(100) DEFAULT NULL,
    `reason`     TEXT         DEFAULT NULL,
    `banned_by`  VARCHAR(100) DEFAULT NULL,
    `expires`    TIMESTAMP    NULL DEFAULT NULL,
    `created`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_bans_license` (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `player_colors` (
    `license`  VARCHAR(60) NOT NULL,
    `palette`  LONGTEXT    NOT NULL,
    PRIMARY KEY (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `player_groups` (
    `license`  VARCHAR(60) NOT NULL,
    `group`    VARCHAR(50) NOT NULL DEFAULT 'user',
    PRIMARY KEY (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `trunk_inventories` (
    `plate`  VARCHAR(12) NOT NULL,
    `items`  LONGTEXT,
    PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `glovebox_inventories` (
    `plate`  VARCHAR(12) NOT NULL,
    `items`  LONGTEXT,
    PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `stash_inventories` (
    `stash`  VARCHAR(64) NOT NULL,
    `items`  LONGTEXT,
    PRIMARY KEY (`stash`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `vehicles` (
    `id`         INT NOT NULL AUTO_INCREMENT,
    `citizenid`  VARCHAR(50) NOT NULL,
    `license`    VARCHAR(60) DEFAULT NULL,
    `plate`      VARCHAR(12) NOT NULL,
    `model`      VARCHAR(60) NOT NULL,
    `garage`     VARCHAR(60) NOT NULL DEFAULT 'legion',
    `state`      TINYINT(1)  NOT NULL DEFAULT 1,
    `fuel`       INT         NOT NULL DEFAULT 100,
    `engine`     FLOAT       NOT NULL DEFAULT 1000.0,
    `body`       FLOAT       NOT NULL DEFAULT 1000.0,
    `props`      LONGTEXT    DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_vehicles_plate` (`plate`),
    KEY `idx_vehicles_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `bank_accounts` (
    `citizenid`      VARCHAR(50) NOT NULL,
    `account_number` VARCHAR(20) NOT NULL, 
    PRIMARY KEY (`citizenid`),
    UNIQUE KEY `uniq_account_number` (`account_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `bank_transactions` (
    `id`        INT NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `type`      VARCHAR(20) NOT NULL,
    `amount`    INT NOT NULL,
    `balance`   INT NOT NULL,
    `label`     VARCHAR(120) DEFAULT NULL,
    `created`   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_bank_tx_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
