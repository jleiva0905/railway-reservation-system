-- Railway Reservation & Reporting System
-- MySQL 8.0.16+ is required for enforced CHECK constraints.
-- This creates a separate demo database and leaves the original course database untouched.
-- Import once into a new database; no original account or reservation data is included.
CREATE DATABASE `railway_portfolio_demo`
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE `railway_portfolio_demo`;

CREATE TABLE `customer` (
  `username` varchar(50) NOT NULL,
  `first_name` varchar(50) NOT NULL,
  `last_name` varchar(50) NOT NULL,
  `email_address` varchar(100) NOT NULL,
  `password` varchar(50) NOT NULL,
  PRIMARY KEY (`username`),
  UNIQUE KEY `unique_customer_email` (`email_address`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `employee` (
  `ssn` varchar(11) NOT NULL,
  `first_name` varchar(50) NOT NULL,
  `last_name` varchar(50) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(50) NOT NULL,
  `employee_role` varchar(50) NOT NULL,
  PRIMARY KEY (`ssn`),
  UNIQUE KEY `unique_employee_username` (`username`),
  CONSTRAINT `check_employee_role` CHECK ((`employee_role` in (_utf8mb4'manager',_utf8mb4'representative')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `train` (
  `train_id` char(4) NOT NULL,
  PRIMARY KEY (`train_id`),
  CONSTRAINT `check_train_id` CHECK (regexp_like(`train_id`,_utf8mb4'^[0-9]{4}$'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `station` (
  `station_id` int NOT NULL,
  `name` varchar(100) NOT NULL,
  `city` varchar(50) NOT NULL,
  `state` varchar(50) NOT NULL,
  PRIMARY KEY (`station_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `transitline` (
  `line_name` varchar(100) NOT NULL,
  `base_fare` decimal(10,2) NOT NULL,
  `starts_station_id` int NOT NULL,
  `ends_station_id` int NOT NULL,
  PRIMARY KEY (`line_name`),
  KEY `starts_station_id` (`starts_station_id`),
  KEY `ends_station_id` (`ends_station_id`),
  CONSTRAINT `fk_transitline_end_station` FOREIGN KEY (`ends_station_id`) REFERENCES `station` (`station_id`),
  CONSTRAINT `fk_transitline_start_station` FOREIGN KEY (`starts_station_id`) REFERENCES `station` (`station_id`),
  CONSTRAINT `check_different_endpoints` CHECK ((`starts_station_id` <> `ends_station_id`)),
  CONSTRAINT `check_transitline_fare` CHECK ((`base_fare` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `trainschedule` (
  `schedule_id` int NOT NULL,
  `departure_datetime` datetime NOT NULL,
  `arrival_datetime` datetime NOT NULL,
  `line_name` varchar(100) NOT NULL,
  `train_id` char(4) NOT NULL,
  PRIMARY KEY (`schedule_id`),
  KEY `line_name` (`line_name`),
  KEY `train_id` (`train_id`),
  CONSTRAINT `fk_schedule_train` FOREIGN KEY (`train_id`) REFERENCES `train` (`train_id`),
  CONSTRAINT `trainschedule_ibfk_1` FOREIGN KEY (`line_name`) REFERENCES `transitline` (`line_name`),
  CONSTRAINT `check_schedule_times` CHECK ((`arrival_datetime` > `departure_datetime`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `schedule_station_stops` (
  `schedule_id` int NOT NULL,
  `station_id` int NOT NULL,
  `stop_number` int NOT NULL,
  `arrival_datetime` datetime DEFAULT NULL,
  `departure_datetime` datetime DEFAULT NULL,
  PRIMARY KEY (`schedule_id`,`station_id`),
  UNIQUE KEY `unique_schedule_stop_number` (`schedule_id`,`stop_number`),
  KEY `station_id` (`station_id`),
  CONSTRAINT `schedule_station_stops_ibfk_1` FOREIGN KEY (`schedule_id`) REFERENCES `trainschedule` (`schedule_id`),
  CONSTRAINT `schedule_station_stops_ibfk_2` FOREIGN KEY (`station_id`) REFERENCES `station` (`station_id`),
  CONSTRAINT `chk_stop_number_nonnegative` CHECK ((`stop_number` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `reservation` (
  `reservation_number` int NOT NULL AUTO_INCREMENT,
  `date_made` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `total_fare` decimal(10,2) NOT NULL,
  `trip_type` varchar(50) NOT NULL,
  `customer_username` varchar(50) NOT NULL,
  `schedule_id` int NOT NULL,
  `departure_station_id` int NOT NULL,
  `arrival_station_id` int NOT NULL,
  PRIMARY KEY (`reservation_number`),
  KEY `fk_reservation_customer` (`customer_username`),
  KEY `fk_reservation_departure_stop` (`schedule_id`,`departure_station_id`),
  KEY `fk_reservation_arrival_stop` (`schedule_id`,`arrival_station_id`),
  CONSTRAINT `fk_reservation_arrival_stop` FOREIGN KEY (`schedule_id`, `arrival_station_id`) REFERENCES `schedule_station_stops` (`schedule_id`, `station_id`),
  CONSTRAINT `fk_reservation_customer` FOREIGN KEY (`customer_username`) REFERENCES `customer` (`username`),
  CONSTRAINT `fk_reservation_departure_stop` FOREIGN KEY (`schedule_id`, `departure_station_id`) REFERENCES `schedule_station_stops` (`schedule_id`, `station_id`),
  CONSTRAINT `check_different_reservation_stations` CHECK ((`departure_station_id` <> `arrival_station_id`)),
  CONSTRAINT `check_reservation_fare` CHECK ((`total_fare` >= 0)),
  CONSTRAINT `check_trip_type` CHECK ((`trip_type` in (_utf8mb4'one-way',_utf8mb4'round-trip')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `question` (
  `question_id` int NOT NULL AUTO_INCREMENT,
  `text` text NOT NULL,
  `reply_text` text,
  `customer_username` varchar(50) NOT NULL,
  `rep_ssn` varchar(11) DEFAULT NULL,
  PRIMARY KEY (`question_id`),
  KEY `customer_username` (`customer_username`),
  KEY `rep_ssn` (`rep_ssn`),
  CONSTRAINT `question_ibfk_1` FOREIGN KEY (`customer_username`) REFERENCES `customer` (`username`),
  CONSTRAINT `question_ibfk_2` FOREIGN KEY (`rep_ssn`) REFERENCES `employee` (`ssn`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
