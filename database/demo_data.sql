-- Fictional data for a local portfolio demonstration only.
-- All account names, email addresses, employee IDs, and passwords below are invented.
-- Import after schema.sql. The publicly documented password is for demo accounts only.
USE `railway_portfolio_demo`;
START TRANSACTION;

INSERT INTO customer (username, first_name, last_name, email_address, password) VALUES
('demo_customer', 'Demo', 'Rider', 'demo.rider@example.com', 'DemoOnly123!'),
('demo_traveler', 'Sample', 'Traveler', 'sample.traveler@example.com', 'DemoOnly123!');

INSERT INTO employee (ssn, first_name, last_name, username, password, employee_role) VALUES
('000-00-0001', 'Demo', 'Manager', 'demo_manager', 'DemoOnly123!', 'manager'),
('000-00-0002', 'Demo', 'Representative', 'demo_rep', 'DemoOnly123!', 'representative');

INSERT INTO train (train_id) VALUES ('1001'), ('1002');
INSERT INTO station (station_id, name, city, state) VALUES
(100, 'Harbor Central', 'Harbor City', 'NJ'),
(200, 'Maple Crossing', 'Maple Borough', 'NJ'),
(300, 'University Park', 'Campus Town', 'NJ'),
(400, 'Lake Junction', 'Lake Town', 'NJ');

INSERT INTO transitline (line_name, base_fare, starts_station_id, ends_station_id) VALUES
('Harbor Local', 12.00, 100, 400),
('Campus Express', 10.00, 100, 300);

SET @demo_day = DATE_ADD(CURDATE(), INTERVAL 1 DAY);
SET @next_day = DATE_ADD(CURDATE(), INTERVAL 2 DAY);

INSERT INTO trainschedule (schedule_id, departure_datetime, arrival_datetime, line_name, train_id) VALUES
(101, TIMESTAMP(@demo_day, '08:00:00'), TIMESTAMP(@demo_day, '08:45:00'), 'Harbor Local', '1001'),
(102, TIMESTAMP(@demo_day, '09:00:00'), TIMESTAMP(@demo_day, '09:25:00'), 'Campus Express', '1002'),
(103, TIMESTAMP(@next_day, '17:00:00'), TIMESTAMP(@next_day, '17:45:00'), 'Harbor Local', '1001'),
(104, TIMESTAMP(@next_day, '18:00:00'), TIMESTAMP(@next_day, '18:25:00'), 'Campus Express', '1002');

INSERT INTO schedule_station_stops
(schedule_id, station_id, stop_number, arrival_datetime, departure_datetime) VALUES
(101, 100, 0, NULL, TIMESTAMP(@demo_day, '08:00:00')),
(101, 200, 1, TIMESTAMP(@demo_day, '08:13:00'), TIMESTAMP(@demo_day, '08:15:00')),
(101, 300, 2, TIMESTAMP(@demo_day, '08:28:00'), TIMESTAMP(@demo_day, '08:30:00')),
(101, 400, 3, TIMESTAMP(@demo_day, '08:45:00'), NULL),
(102, 100, 0, NULL, TIMESTAMP(@demo_day, '09:00:00')),
(102, 300, 1, TIMESTAMP(@demo_day, '09:25:00'), NULL),
(103, 100, 0, NULL, TIMESTAMP(@next_day, '17:00:00')),
(103, 200, 1, TIMESTAMP(@next_day, '17:13:00'), TIMESTAMP(@next_day, '17:15:00')),
(103, 300, 2, TIMESTAMP(@next_day, '17:28:00'), TIMESTAMP(@next_day, '17:30:00')),
(103, 400, 3, TIMESTAMP(@next_day, '17:45:00'), NULL),
(104, 100, 0, NULL, TIMESTAMP(@next_day, '18:00:00')),
(104, 300, 1, TIMESTAMP(@next_day, '18:25:00'), NULL);

INSERT INTO reservation
(date_made, total_fare, trip_type, customer_username, schedule_id, departure_station_id, arrival_station_id) VALUES
(NOW(), 8.00, 'one-way', 'demo_customer', 101, 100, 300),
(NOW(), 10.00, 'one-way', 'demo_customer', 102, 100, 300),
(NOW(), 24.00, 'round-trip', 'demo_traveler', 103, 100, 400),
(DATE_SUB(NOW(), INTERVAL 1 MONTH), 20.00, 'round-trip', 'demo_customer', 104, 100, 300),
(DATE_SUB(NOW(), INTERVAL 1 MONTH), 12.00, 'one-way', 'demo_traveler', 101, 100, 400);

INSERT INTO question (text, reply_text, customer_username, rep_ssn) VALUES
('Where can I view the stops for a schedule?', 'Open the schedule details from the search results.', 'demo_customer', '000-00-0002'),
('Can I cancel a reservation from my account?', NULL, 'demo_traveler', NULL);

COMMIT;
