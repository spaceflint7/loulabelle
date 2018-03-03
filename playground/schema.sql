SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";
CREATE DATABASE IF NOT EXISTS `loulabelle_playground` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE `loulabelle_playground`;

CREATE TABLE `loulabelle_files` (
  `folder_name` varchar(99) NOT NULL,
  `file_name` varchar(99) NOT NULL,
  `source_text` varchar(20000) NOT NULL,
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `loulabelle_folders` (
  `folder_name` varchar(99) NOT NULL,
  `password` varchar(255) NOT NULL,
  `public` tinyint(1) NOT NULL DEFAULT '0',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

ALTER TABLE `loulabelle_files`
  ADD PRIMARY KEY (`folder_name`,`file_name`) USING BTREE;

ALTER TABLE `loulabelle_folders`
  ADD PRIMARY KEY (`folder_name`) USING BTREE,
  ADD KEY `system` (`public`);

ALTER TABLE `loulabelle_files`
  ADD CONSTRAINT `loulabelle_files_ibfk_1` FOREIGN KEY (`folder_name`) REFERENCES `loulabelle_folders` (`folder_name`);
