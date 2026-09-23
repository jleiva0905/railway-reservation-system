<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"
    import="java.sql.*"
    import="com.cs336.pkg.ApplicationDB"%>

<%
    /*
     * Make sure only logged-in customers
     * can access this page.
     */
    String userType =
        (String) session.getAttribute("userType");

    if (!"customer".equals(userType)) {

        response.sendRedirect(
            request.getContextPath() + "/login.jsp"
        );

        return;
    }

    /*
     * Information stored during login.
     */
    String customerUsername =
        (String) session.getAttribute("username");

    /*
     * Values sent from search.jsp.
     */
    String scheduleId =
        request.getParameter("scheduleId");

    String departureStationId =
        request.getParameter("departureStationId");

    String arrivalStationId =
        request.getParameter("arrivalStationId");

    /*
     * Values sent when the customer
     * confirms the reservation.
     */
    String action =
        request.getParameter("action");

    String tripType =
        request.getParameter("tripType");

    String discountType =
        request.getParameter("discountType");

    String message = null;
    String errorMessage = null;

    /*
     * Database variables.
     */
    ApplicationDB db =
        new ApplicationDB();

    Connection connection = null;

    PreparedStatement tripStatement = null;
    PreparedStatement insertStatement = null;

    ResultSet tripResult = null;

    /*
     * Trip information.
     */
    String trainId = null;
    String lineName = null;

    String departureStationName = null;
    String arrivalStationName = null;

    Timestamp scheduleDeparture = null;
    Timestamp scheduleArrival = null;

    Timestamp departureStopDatetime = null;
    Timestamp arrivalStopDatetime = null;

    int departureStopNumber = 0;
    int arrivalStopNumber = 0;
    int finalStopNumber = 0;

    int totalSegments = 0;
    int segmentsTraveled = 0;

    double baseFare = 0.0;
    double farePerSegment = 0.0;
    double oneWayFare = 0.0;
    double discountRate = 0.0;
    double totalFare = 0.0;

    boolean validTrip = false;
    boolean reservationCreated = false;

    try {

        connection =
            db.getConnection();

        /*
         * Check that the required trip
         * information was received.
         */
        if (scheduleId == null
                || departureStationId == null
                || arrivalStationId == null
                || scheduleId.isEmpty()
                || departureStationId.isEmpty()
                || arrivalStationId.isEmpty()) {

            errorMessage =
                "No trip was selected. Please return "
                + "to the schedule search.";

        } else {

            /*
             * Get the selected schedule, stations,
             * stop numbers, stop datetimes and full
             * transit-line fare.
             *
             * final_stop_number is the highest stop
             * number in the schedule. Since stop
             * numbering starts at 0, this is also the
             * total number of segments in the full line.
             */
            String tripQuery =
                "SELECT " +

                "ts.train_id, " +
                "ts.line_name, " +
                "ts.departure_datetime, " +
                "ts.arrival_datetime, " +

                "tl.base_fare, " +

                "departure_station.name " +
                "AS departure_station_name, " +

                "arrival_station.name " +
                "AS arrival_station_name, " +

                "departure_stop.departure_datetime " +
                "AS departure_stop_datetime, " +

                "arrival_stop.arrival_datetime " +
                "AS arrival_stop_datetime, " +

                "departure_stop.stop_number " +
                "AS departure_stop_number, " +

                "arrival_stop.stop_number " +
                "AS arrival_stop_number, " +

                "(SELECT MAX(all_stops.stop_number) " +
                " FROM schedule_station_stops all_stops " +
                " WHERE all_stops.schedule_id = " +
                "ts.schedule_id) " +
                "AS final_stop_number " +

                "FROM trainschedule ts " +

                "JOIN transitline tl " +
                "ON ts.line_name = tl.line_name " +

                "JOIN schedule_station_stops " +
                "departure_stop " +
                "ON ts.schedule_id = " +
                "departure_stop.schedule_id " +

                "JOIN schedule_station_stops " +
                "arrival_stop " +
                "ON ts.schedule_id = " +
                "arrival_stop.schedule_id " +

                "JOIN station departure_station " +
                "ON departure_stop.station_id = " +
                "departure_station.station_id " +

                "JOIN station arrival_station " +
                "ON arrival_stop.station_id = " +
                "arrival_station.station_id " +

                "WHERE ts.schedule_id = ? " +
                "AND departure_stop.station_id = ? " +
                "AND arrival_stop.station_id = ? " +
                "AND departure_stop.stop_number " +
                "< arrival_stop.stop_number";

            tripStatement =
                connection.prepareStatement(
                    tripQuery
                );

            tripStatement.setInt(
                1,
                Integer.parseInt(scheduleId)
            );

            tripStatement.setInt(
                2,
                Integer.parseInt(departureStationId)
            );

            tripStatement.setInt(
                3,
                Integer.parseInt(arrivalStationId)
            );

            tripResult =
                tripStatement.executeQuery();

            if (tripResult.next()) {

                trainId =
                    tripResult.getString(
                        "train_id"
                    );

                lineName =
                    tripResult.getString(
                        "line_name"
                    );

                departureStationName =
                    tripResult.getString(
                        "departure_station_name"
                    );

                arrivalStationName =
                    tripResult.getString(
                        "arrival_station_name"
                    );

                scheduleDeparture =
                    tripResult.getTimestamp(
                        "departure_datetime"
                    );

                scheduleArrival =
                    tripResult.getTimestamp(
                        "arrival_datetime"
                    );

                departureStopDatetime =
                    tripResult.getTimestamp(
                        "departure_stop_datetime"
                    );

                arrivalStopDatetime =
                    tripResult.getTimestamp(
                        "arrival_stop_datetime"
                    );

                departureStopNumber =
                    tripResult.getInt(
                        "departure_stop_number"
                    );

                arrivalStopNumber =
                    tripResult.getInt(
                        "arrival_stop_number"
                    );

                finalStopNumber =
                    tripResult.getInt(
                        "final_stop_number"
                    );

                baseFare =
                    tripResult.getDouble(
                        "base_fare"
                    );

                /*
                 * Because stop numbering begins at 0,
                 * finalStopNumber equals the total
                 * number of segments in the complete
                 * line.
                 */
                totalSegments =
                    finalStopNumber;

                segmentsTraveled =
                    arrivalStopNumber
                    - departureStopNumber;

                if (totalSegments <= 0) {

                    errorMessage =
                        "The schedule does not contain "
                        + "enough stops to calculate a fare.";

                } else if (segmentsTraveled <= 0) {

                    errorMessage =
                        "The selected stations are in "
                        + "an invalid order.";

                } else if (
                    departureStopDatetime == null
                ) {

                    errorMessage =
                        "The selected departure station "
                        + "does not have a departure "
                        + "datetime.";

                } else if (
                    arrivalStopDatetime == null
                ) {

                    errorMessage =
                        "The selected arrival station "
                        + "does not have an arrival "
                        + "datetime.";

                } else {

                    farePerSegment =
                        baseFare / totalSegments;

                    oneWayFare =
                        farePerSegment
                        * segmentsTraveled;

                    validTrip = true;
                }

            } else {

                errorMessage =
                    "The selected trip is not valid.";
            }
        }

        /*
         * Process the Confirm Reservation form.
         */
        if (validTrip
                && "confirm".equals(action)) {

            /*
             * Validate the trip type.
             */
            if (!"one-way".equals(tripType)
                    && !"round-trip".equals(
                        tripType
                    )) {

                errorMessage =
                    "Please select a valid trip type.";
            }

            /*
             * Validate the passenger type and
             * determine the applicable discount.
             */
            if (errorMessage == null) {

                if ("adult".equals(discountType)) {

                    discountRate = 0.00;

                } else if (
                    "child".equals(discountType)
                ) {

                    discountRate = 0.25;

                } else if (
                    "senior".equals(discountType)
                ) {

                    discountRate = 0.35;

                } else if (
                    "disabled".equals(discountType)
                ) {

                    discountRate = 0.50;

                } else {

                    errorMessage =
                        "Please select a valid "
                        + "passenger type.";
                }
            }

            /*
             * Calculate the total fare.
             */
            if (errorMessage == null) {

                totalFare =
                    oneWayFare
                    * (1.0 - discountRate);

                if ("round-trip".equals(tripType)) {

                    totalFare =
                        totalFare * 2;
                }

                /*
                 * Round the fare to two decimal places.
                 */
                totalFare =
                    Math.round(
                        totalFare * 100.0
                    ) / 100.0;

                /*
                 * Insert the reservation.
                 *
                 * reservation_number is AUTO_INCREMENT.
                 * date_made uses CURRENT_TIMESTAMP.
                 */
                String insertQuery =
                    "INSERT INTO reservation " +

                    "(total_fare, trip_type, " +
                    "customer_username, schedule_id, " +
                    "departure_station_id, " +
                    "arrival_station_id) " +

                    "VALUES (?, ?, ?, ?, ?, ?)";

                insertStatement =
                    connection.prepareStatement(
                        insertQuery
                    );

                insertStatement.setDouble(
                    1,
                    totalFare
                );

                insertStatement.setString(
                    2,
                    tripType
                );

                insertStatement.setString(
                    3,
                    customerUsername
                );

                insertStatement.setInt(
                    4,
                    Integer.parseInt(scheduleId)
                );

                insertStatement.setInt(
                    5,
                    Integer.parseInt(
                        departureStationId
                    )
                );

                insertStatement.setInt(
                    6,
                    Integer.parseInt(
                        arrivalStationId
                    )
                );

                int rowsInserted =
                    insertStatement.executeUpdate();

                if (rowsInserted > 0) {

                    reservationCreated = true;

                    message =
                        "Your reservation was created "
                        + "successfully.";

                } else {

                    errorMessage =
                        "The reservation could not "
                        + "be created.";
                }
            }
        }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">

    <title>
        Make Reservation
    </title>
</head>

<body>

    <h1>
        Make a Reservation
    </h1>

    <%
        if (errorMessage != null) {
    %>

        <p style="color: red;">
            <%= errorMessage %>
        </p>

    <%
        }

        if (reservationCreated) {
    %>

        <p style="color: green;">
            <%= message %>
        </p>

        <h2>
            Reservation Confirmation
        </h2>

        <p>
            <strong>Customer:</strong>
            <%= customerUsername %>
        </p>

        <p>
            <strong>Schedule ID:</strong>
            <%= scheduleId %>
        </p>

        <p>
            <strong>Transit line:</strong>
            <%= lineName %>
        </p>

        <p>
            <strong>Train:</strong>
            <%= trainId %>
        </p>

        <p>
            <strong>Departure station:</strong>
            <%= departureStationName %>
        </p>

        <p>
            <strong>Departure datetime:</strong>
            <%= departureStopDatetime %>
        </p>

        <p>
            <strong>Arrival station:</strong>
            <%= arrivalStationName %>
        </p>

        <p>
            <strong>Arrival datetime:</strong>
            <%= arrivalStopDatetime %>
        </p>

        <p>
            <strong>Trip type:</strong>
            <%= tripType %>
        </p>

        <p>
            <strong>Passenger type:</strong>
            <%= discountType %>
        </p>

        <p>
            <strong>Total fare:</strong>

            $<%= String.format(
                "%.2f",
                totalFare
            ) %>
        </p>

        <p>
            <a href="<%= request.getContextPath() %>/customer/search.jsp">
                Search for another trip
            </a>
        </p>

        <p>
            <a href="<%= request.getContextPath() %>/customer/c_home.jsp">
                Return to customer home
            </a>
        </p>

    <%
        } else if (validTrip) {
    %>

        <h2>
            Selected Trip
        </h2>

        <p>
            <strong>Schedule ID:</strong>
            <%= scheduleId %>
        </p>

        <p>
            <strong>Transit line:</strong>
            <%= lineName %>
        </p>

        <p>
            <strong>Train:</strong>
            <%= trainId %>
        </p>

        <p>
            <strong>Departure station:</strong>
            <%= departureStationName %>
        </p>

        <p>
            <strong>Departure stop datetime:</strong>
            <%= departureStopDatetime %>
        </p>

        <p>
            <strong>Arrival station:</strong>
            <%= arrivalStationName %>
        </p>

        <p>
            <strong>Arrival stop datetime:</strong>
            <%= arrivalStopDatetime %>
        </p>

        <p>
            <strong>Full schedule departure:</strong>
            <%= scheduleDeparture %>
        </p>

        <p>
            <strong>Full schedule final arrival:</strong>
            <%= scheduleArrival %>
        </p>

        <h3>
            Fare Information
        </h3>

        <p>
            <strong>Full-line fare:</strong>

            $<%= String.format(
                "%.2f",
                baseFare
            ) %>
        </p>

        <p>
            <strong>Total line segments:</strong>
            <%= totalSegments %>
        </p>

        <p>
            <strong>Segments traveled:</strong>
            <%= segmentsTraveled %>
        </p>

        <p>
            <strong>Fare per segment:</strong>

            $<%= String.format(
                "%.2f",
                farePerSegment
            ) %>
        </p>

        <p>
            <strong>
                Selected one-way fare before discounts:
            </strong>

            $<%= String.format(
                "%.2f",
                oneWayFare
            ) %>
        </p>

        <form
            action="reservation.jsp"
            method="post">

            <input
                type="hidden"
                name="action"
                value="confirm">

            <input
                type="hidden"
                name="scheduleId"
                value="<%= scheduleId %>">

            <input
                type="hidden"
                name="departureStationId"
                value="<%= departureStationId %>">

            <input
                type="hidden"
                name="arrivalStationId"
                value="<%= arrivalStationId %>">

            <label for="tripType">
                Trip type:
            </label>

            <select
                id="tripType"
                name="tripType"
                required>

                <option value="">
                    Select trip type
                </option>

                <option value="one-way">
                    One-way
                </option>

                <option value="round-trip">
                    Round-trip
                </option>

            </select>

            <br><br>

            <label for="discountType">
                Passenger type:
            </label>

            <select
                id="discountType"
                name="discountType"
                required>

                <option value="">
                    Select passenger type
                </option>

                <option value="adult">
                    Adult — no discount
                </option>

                <option value="child">
                    Child — 25% discount
                </option>

                <option value="senior">
                    Senior — 35% discount
                </option>

                <option value="disabled">
                    Disabled — 50% discount
                </option>

            </select>

            <br><br>

            <input
                type="submit"
                value="Confirm Reservation">

        </form>

        <br>

        <a href="<%= request.getContextPath() %>/customer/search.jsp">
            Back to schedule search
        </a>

    <%
        } else {
    %>

        <p>
            <a href="<%= request.getContextPath() %>/customer/search.jsp">
                Return to schedule search
            </a>
        </p>

    <%
        }
    %>

</body>
</html>

<%
    } catch (NumberFormatException e) {

        e.printStackTrace();
%>

    <p style="color: red;">
        Invalid schedule or station information.
    </p>

    <p>
        <a href="<%= request.getContextPath() %>/customer/search.jsp">
            Return to schedule search
        </a>
    </p>

<%
    } catch (SQLException e) {

        e.printStackTrace();
%>

    <p style="color: red;">
        Database error:
        <%= e.getMessage() %>
    </p>

<%
    } finally {

        try {

            if (tripResult != null) {
                tripResult.close();
            }

            if (tripStatement != null) {
                tripStatement.close();
            }

            if (insertStatement != null) {
                insertStatement.close();
            }

            if (connection != null) {
                db.closeConnection(connection);
            }

        } catch (SQLException e) {

            e.printStackTrace();
        }
    }
%>