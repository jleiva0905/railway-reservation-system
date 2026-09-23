<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"
    import="java.sql.*"
    import="java.text.SimpleDateFormat"
    import="java.util.ArrayList"
    import="com.cs336.pkg.ApplicationDB"%>

<%
    String userType =
        (String) session.getAttribute("userType");

    String employeeRole =
        (String) session.getAttribute("employeeRole");

    if (!"employee".equals(userType)
            || !"representative".equals(employeeRole)) {

        response.sendRedirect(
            request.getContextPath() + "/login.jsp"
        );

        return;
    }

    String scheduleIdParameter =
        request.getParameter("scheduleId");

    if (scheduleIdParameter == null
            || scheduleIdParameter.trim().isEmpty()) {

        response.sendRedirect(
            request.getContextPath()
            + "/representative/manageSchedules.jsp"
        );

        return;
    }

    int scheduleId;

    try {

        scheduleId =
            Integer.parseInt(
                scheduleIdParameter.trim()
            );

    } catch (NumberFormatException e) {

        response.sendRedirect(
            request.getContextPath()
            + "/representative/manageSchedules.jsp"
        );

        return;
    }

    String errorMessage = null;

    ApplicationDB db =
        new ApplicationDB();

    Connection connection = null;

    PreparedStatement scheduleStatement = null;
    PreparedStatement trainStatement = null;
    PreparedStatement lineStatement = null;
    PreparedStatement stopStatement = null;

    PreparedStatement updateScheduleStatement = null;
    PreparedStatement updateStopStatement = null;

    ResultSet scheduleResult = null;
    ResultSet trainResult = null;
    ResultSet lineResult = null;
    ResultSet stopResult = null;

    try {

        connection =
            db.getConnection();

        if (connection == null) {

            throw new SQLException(
                "Could not connect to the database."
            );
        }

        /*
         * =====================================================
         * PROCESS THE UPDATE
         * =====================================================
         */
        if ("POST".equalsIgnoreCase(
                request.getMethod())) {

            String trainId =
                request.getParameter("trainId");

            String lineName =
                request.getParameter("lineName");

            String[] stationIds =
                request.getParameterValues(
                    "stationId"
                );

            String[] stopNumbers =
                request.getParameterValues(
                    "stopNumber"
                );

            if (trainId == null
                    || trainId.trim().isEmpty()
                    || lineName == null
                    || lineName.trim().isEmpty()) {

                errorMessage =
                    "The train and transit line are required.";

            } else if (stationIds == null
                    || stopNumbers == null
                    || stationIds.length == 0
                    || stationIds.length
                        != stopNumbers.length) {

                errorMessage =
                    "The station-stop information is invalid.";

            } else {

                ArrayList<Integer> submittedStationIds =
                    new ArrayList<Integer>();

                ArrayList<Integer> submittedStopNumbers =
                    new ArrayList<Integer>();

                ArrayList<Timestamp> submittedArrivals =
                    new ArrayList<Timestamp>();

                ArrayList<Timestamp> submittedDepartures =
                    new ArrayList<Timestamp>();

                /*
                 * Parse all submitted station-stop datetimes.
                 */
                for (int index = 0;
                        index < stationIds.length;
                        index++) {

                    int stationId =
                        Integer.parseInt(
                            stationIds[index]
                        );

                    int stopNumber =
                        Integer.parseInt(
                            stopNumbers[index]
                        );

                    String arrivalDatetimeText =
                        request.getParameter(
                            "arrivalDatetime_"
                            + stationId
                        );

                    String departureDatetimeText =
                        request.getParameter(
                            "departureDatetime_"
                            + stationId
                        );

                    Timestamp arrivalTimestamp = null;
                    Timestamp departureTimestamp = null;

                    if (arrivalDatetimeText != null
                            && !arrivalDatetimeText
                                .trim()
                                .isEmpty()) {

                        String arrivalValue =
                            arrivalDatetimeText
                                .trim()
                                .replace(
                                    "T",
                                    " "
                                );

                        if (arrivalValue.length() == 16) {
                            arrivalValue += ":00";
                        }

                        arrivalTimestamp =
                            Timestamp.valueOf(
                                arrivalValue
                            );
                    }

                    if (departureDatetimeText != null
                            && !departureDatetimeText
                                .trim()
                                .isEmpty()) {

                        String departureValue =
                            departureDatetimeText
                                .trim()
                                .replace(
                                    "T",
                                    " "
                                );

                        if (departureValue.length() == 16) {
                            departureValue += ":00";
                        }

                        departureTimestamp =
                            Timestamp.valueOf(
                                departureValue
                            );
                    }

                    submittedStationIds.add(
                        stationId
                    );

                    submittedStopNumbers.add(
                        stopNumber
                    );

                    submittedArrivals.add(
                        arrivalTimestamp
                    );

                    submittedDepartures.add(
                        departureTimestamp
                    );
                }

                int lastIndex =
                    submittedStationIds.size() - 1;

                Timestamp originArrival =
                    submittedArrivals.get(0);

                Timestamp originDeparture =
                    submittedDepartures.get(0);

                Timestamp destinationArrival =
                    submittedArrivals.get(lastIndex);

                Timestamp destinationDeparture =
                    submittedDepartures.get(lastIndex);

                /*
                 * =================================================
                 * VALIDATE ORIGIN
                 * =================================================
                 */
                if (originArrival != null) {

                    errorMessage =
                        "The route origin cannot have an "
                        + "arrival datetime.";
                }

                if (errorMessage == null
                        && originDeparture == null) {

                    errorMessage =
                        "The route origin must have a "
                        + "departure datetime.";
                }

                /*
                 * =================================================
                 * VALIDATE DESTINATION
                 * =================================================
                 */
                if (errorMessage == null
                        && destinationArrival == null) {

                    errorMessage =
                        "The route destination must have an "
                        + "arrival datetime.";
                }

                if (errorMessage == null
                        && destinationDeparture != null) {

                    errorMessage =
                        "The route destination cannot have a "
                        + "departure datetime.";
                }

                /*
                 * =================================================
                 * VALIDATE INTERMEDIATE STOPS
                 * =================================================
                 */
                if (errorMessage == null) {

                    for (int index = 1;
                            index < lastIndex;
                            index++) {

                        Timestamp arrival =
                            submittedArrivals.get(
                                index
                            );

                        Timestamp departure =
                            submittedDepartures.get(
                                index
                            );

                        int stopNumber =
                            submittedStopNumbers.get(
                                index
                            );

                        if (arrival == null
                                || departure == null) {

                            errorMessage =
                                "Intermediate stop "
                                + stopNumber
                                + " must have both an arrival "
                                + "datetime and a departure "
                                + "datetime.";

                            break;
                        }

                        if (departure.before(arrival)) {

                            errorMessage =
                                "Stop "
                                + stopNumber
                                + " has a departure datetime "
                                + "before its arrival datetime.";

                            break;
                        }
                    }
                }

                /*
                 * =================================================
                 * VALIDATE CONSECUTIVE STOP CHRONOLOGY
                 * =================================================
                 */
                if (errorMessage == null) {

                    for (int index = 0;
                            index < lastIndex;
                            index++) {

                        Timestamp currentDeparture =
                            submittedDepartures.get(
                                index
                            );

                        Timestamp nextArrival =
                            submittedArrivals.get(
                                index + 1
                            );

                        int currentStopNumber =
                            submittedStopNumbers.get(
                                index
                            );

                        int nextStopNumber =
                            submittedStopNumbers.get(
                                index + 1
                            );

                        if (currentDeparture == null) {

                            errorMessage =
                                "Stop "
                                + currentStopNumber
                                + " must have a departure "
                                + "datetime because another "
                                + "stop follows it.";

                            break;
                        }

                        if (nextArrival == null) {

                            errorMessage =
                                "Stop "
                                + nextStopNumber
                                + " must have an arrival "
                                + "datetime.";

                            break;
                        }

                        if (nextArrival.before(
                                currentDeparture)) {

                            errorMessage =
                                "The arrival datetime at stop "
                                + nextStopNumber
                                + " cannot be earlier than the "
                                + "departure datetime from stop "
                                + currentStopNumber
                                + ".";

                            break;
                        }
                    }
                }

                /*
                 * The overall schedule runs from the origin
                 * departure to the destination arrival.
                 */
                if (errorMessage == null
                        && !destinationArrival.after(
                            originDeparture
                        )) {

                    errorMessage =
                        "The destination arrival must be after "
                        + "the origin departure.";
                }

                /*
                 * =================================================
                 * UPDATE AFTER ALL VALIDATION PASSES
                 * =================================================
                 */
                if (errorMessage == null) {

                    try {

                        connection.setAutoCommit(
                            false
                        );

                        String updateStopQuery =
                            "UPDATE schedule_station_stops " +

                            "SET arrival_datetime = ?, " +
                            "departure_datetime = ? " +

                            "WHERE schedule_id = ? " +
                            "AND station_id = ? " +
                            "AND stop_number = ?";

                        updateStopStatement =
                            connection.prepareStatement(
                                updateStopQuery
                            );

                        for (int index = 0;
                                index
                                    < submittedStationIds.size();
                                index++) {

                            Timestamp arrival =
                                submittedArrivals.get(
                                    index
                                );

                            Timestamp departure =
                                submittedDepartures.get(
                                    index
                                );

                            if (arrival == null) {

                                updateStopStatement.setNull(
                                    1,
                                    Types.TIMESTAMP
                                );

                            } else {

                                updateStopStatement
                                    .setTimestamp(
                                        1,
                                        arrival
                                    );
                            }

                            if (departure == null) {

                                updateStopStatement.setNull(
                                    2,
                                    Types.TIMESTAMP
                                );

                            } else {

                                updateStopStatement
                                    .setTimestamp(
                                        2,
                                        departure
                                    );
                            }

                            updateStopStatement.setInt(
                                3,
                                scheduleId
                            );

                            updateStopStatement.setInt(
                                4,
                                submittedStationIds.get(
                                    index
                                )
                            );

                            updateStopStatement.setInt(
                                5,
                                submittedStopNumbers.get(
                                    index
                                )
                            );

                            int updatedStops =
                                updateStopStatement
                                    .executeUpdate();

                            if (updatedStops != 1) {

                                throw new SQLException(
                                    "A station stop could not "
                                    + "be updated."
                                );
                            }
                        }

                        String updateScheduleQuery =
                            "UPDATE trainschedule " +

                            "SET train_id = ?, " +
                            "line_name = ?, " +
                            "departure_datetime = ?, " +
                            "arrival_datetime = ? " +

                            "WHERE schedule_id = ?";

                        updateScheduleStatement =
                            connection.prepareStatement(
                                updateScheduleQuery
                            );

                        updateScheduleStatement.setString(
                            1,
                            trainId.trim()
                        );

                        updateScheduleStatement.setString(
                            2,
                            lineName.trim()
                        );

                        updateScheduleStatement.setTimestamp(
                            3,
                            originDeparture
                        );

                        updateScheduleStatement.setTimestamp(
                            4,
                            destinationArrival
                        );

                        updateScheduleStatement.setInt(
                            5,
                            scheduleId
                        );

                        int updatedSchedules =
                            updateScheduleStatement
                                .executeUpdate();

                        if (updatedSchedules != 1) {

                            throw new SQLException(
                                "The train schedule could not "
                                + "be updated."
                            );
                        }

                        connection.commit();

                        response.sendRedirect(
                            request.getContextPath()
                            + "/representative/"
                            + "manageSchedules.jsp"
                            + "?message=updated"
                        );

                        return;

                    } catch (Exception updateException) {

                        try {

                            connection.rollback();

                        } catch (SQLException rollbackException) {

                            rollbackException.printStackTrace();
                        }

                        throw updateException;

                    } finally {

                        try {

                            connection.setAutoCommit(
                                true
                            );

                        } catch (SQLException autoCommitException) {

                            autoCommitException.printStackTrace();
                        }
                    }
                }
            }
        }

        /*
         * =====================================================
         * LOAD CURRENT SCHEDULE
         * =====================================================
         */
        String scheduleQuery =
            "SELECT " +
            "schedule_id, " +
            "train_id, " +
            "line_name " +

            "FROM trainschedule " +

            "WHERE schedule_id = ?";

        scheduleStatement =
            connection.prepareStatement(
                scheduleQuery
            );

        scheduleStatement.setInt(
            1,
            scheduleId
        );

        scheduleResult =
            scheduleStatement.executeQuery();

        if (!scheduleResult.next()) {

            response.sendRedirect(
                request.getContextPath()
                + "/representative/"
                + "manageSchedules.jsp"
            );

            return;
        }

        String currentTrainId =
            scheduleResult.getString(
                "train_id"
            );

        String currentLineName =
            scheduleResult.getString(
                "line_name"
            );

        /*
         * Load trains.
         */
        String trainQuery =
            "SELECT train_id " +
            "FROM train " +
            "ORDER BY train_id";

        trainStatement =
            connection.prepareStatement(
                trainQuery
            );

        trainResult =
            trainStatement.executeQuery();

        /*
         * Load transit lines.
         */
        String lineQuery =
            "SELECT line_name " +
            "FROM transitline " +
            "ORDER BY line_name";

        lineStatement =
            connection.prepareStatement(
                lineQuery
            );

        lineResult =
            lineStatement.executeQuery();

        /*
         * Load all stops, including the first and last
         * stop numbers for identifying the origin and
         * destination.
         */
        String stopQuery =
            "SELECT " +

            "sss.station_id, " +
            "sss.stop_number, " +
            "sss.arrival_datetime, " +
            "sss.departure_datetime, " +

            "s.name AS station_name, " +
            "s.city, " +
            "s.state, " +

            "(SELECT MIN(first_stop.stop_number) " +
                "FROM schedule_station_stops first_stop " +
                "WHERE first_stop.schedule_id = " +
                    "sss.schedule_id" +
            ") AS first_stop_number, " +

            "(SELECT MAX(last_stop.stop_number) " +
                "FROM schedule_station_stops last_stop " +
                "WHERE last_stop.schedule_id = " +
                    "sss.schedule_id" +
            ") AS last_stop_number " +

            "FROM schedule_station_stops sss " +

            "JOIN station s " +
            "ON sss.station_id = s.station_id " +

            "WHERE sss.schedule_id = ? " +

            "ORDER BY sss.stop_number";

        stopStatement =
            connection.prepareStatement(
                stopQuery
            );

        stopStatement.setInt(
            1,
            scheduleId
        );

        stopResult =
            stopStatement.executeQuery();

        SimpleDateFormat datetimeFormat =
            new SimpleDateFormat(
                "yyyy-MM-dd'T'HH:mm"
            );
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">

    <title>
        Edit Train Schedule
    </title>
</head>

<body>

    <h1>
        Edit Train Schedule
    </h1>

    <p>
        Schedule ID:
        <strong><%= scheduleId %></strong>
    </p>

    <%
        if (errorMessage != null) {
    %>

        <p style="color: red;">
            <%= errorMessage %>
        </p>

    <%
        }
    %>

    <form
        action="editSchedule.jsp"
        method="post">

        <input
            type="hidden"
            name="scheduleId"
            value="<%= scheduleId %>">

        <h2>
            Main Schedule Information
        </h2>

        <label for="trainId">
            Train:
        </label>

        <select
            id="trainId"
            name="trainId"
            required>

            <%
                while (trainResult.next()) {

                    String trainId =
                        trainResult.getString(
                            "train_id"
                        );
            %>

                <option
                    value="<%= trainId %>"
                    <%= trainId.equals(
                            currentTrainId
                        )
                        ? "selected"
                        : "" %>>

                    <%= trainId %>

                </option>

            <%
                }
            %>

        </select>

        <br><br>

        <label for="lineName">
            Transit Line:
        </label>

        <select
            id="lineName"
            name="lineName"
            required>

            <%
                while (lineResult.next()) {

                    String lineName =
                        lineResult.getString(
                            "line_name"
                        );
            %>

                <option
                    value="<%= lineName %>"
                    <%= lineName.equals(
                            currentLineName
                        )
                        ? "selected"
                        : "" %>>

                    <%= lineName %>

                </option>

            <%
                }
            %>

        </select>

        <br><br>

        <p>
            The full-schedule departure and arrival
            are calculated automatically from the origin
            departure and destination arrival.
        </p>

        <h2>
            Station Stop Datetimes
        </h2>

        <table border="1" cellpadding="8">

            <tr>
                <th>Stop Number</th>
                <th>Station</th>
                <th>Arrival Datetime</th>
                <th>Departure Datetime</th>
            </tr>

            <%
                boolean foundStop = false;

                while (stopResult.next()) {

                    foundStop = true;

                    int stationId =
                        stopResult.getInt(
                            "station_id"
                        );

                    int stopNumber =
                        stopResult.getInt(
                            "stop_number"
                        );

                    int firstStopNumber =
                        stopResult.getInt(
                            "first_stop_number"
                        );

                    int lastStopNumber =
                        stopResult.getInt(
                            "last_stop_number"
                        );

                    boolean isOrigin =
                        stopNumber == firstStopNumber;

                    boolean isDestination =
                        stopNumber == lastStopNumber;

                    String stationName =
                        stopResult.getString(
                            "station_name"
                        );

                    String city =
                        stopResult.getString(
                            "city"
                        );

                    String state =
                        stopResult.getString(
                            "state"
                        );

                    Timestamp stopArrival =
                        stopResult.getTimestamp(
                            "arrival_datetime"
                        );

                    Timestamp stopDeparture =
                        stopResult.getTimestamp(
                            "departure_datetime"
                        );

                    String arrivalInputValue = "";

                    if (stopArrival != null) {

                        arrivalInputValue =
                            datetimeFormat.format(
                                stopArrival
                            );
                    }

                    String departureInputValue = "";

                    if (stopDeparture != null) {

                        departureInputValue =
                            datetimeFormat.format(
                                stopDeparture
                            );
                    }
            %>

            <tr>

                <td>
                    <%= stopNumber %>

                    <input
                        type="hidden"
                        name="stopNumber"
                        value="<%= stopNumber %>">
                </td>

                <td>
                    <%= stationName %>
                    -
                    <%= city %>,
                    <%= state %>

                    <input
                        type="hidden"
                        name="stationId"
                        value="<%= stationId %>">
                </td>

                <td>
                    <%
                        if (isOrigin) {
                    %>

                        Route origin — no arrival

                        <input
                            type="hidden"
                            name="arrivalDatetime_<%= stationId %>"
                            value="">

                    <%
                        } else {
                    %>

                        <input
                            type="datetime-local"
                            name="arrivalDatetime_<%= stationId %>"
                            value="<%= arrivalInputValue %>"
                            required>

                    <%
                        }
                    %>
                </td>

                <td>
                    <%
                        if (isDestination) {
                    %>

                        Route destination — no departure

                        <input
                            type="hidden"
                            name="departureDatetime_<%= stationId %>"
                            value="">

                    <%
                        } else {
                    %>

                        <input
                            type="datetime-local"
                            name="departureDatetime_<%= stationId %>"
                            value="<%= departureInputValue %>"
                            required>

                    <%
                        }
                    %>
                </td>

            </tr>

            <%
                }

                if (!foundStop) {
            %>

            <tr>
                <td colspan="4">
                    No stops were found for this schedule.
                </td>
            </tr>

            <%
                }
            %>

        </table>

        <br>

        <input
            type="submit"
            value="Save Schedule Changes">

        &nbsp;

        <a href="<%= request.getContextPath() %>/representative/manageSchedules.jsp">
            Cancel
        </a>

    </form>

</body>
</html>

<%
    } catch (IllegalArgumentException e) {

        e.printStackTrace();
%>

    <p style="color: red;">
        One of the entered datetime values is invalid.
    </p>

    <a href="<%= request.getContextPath() %>/representative/manageSchedules.jsp">
        Back to train schedules
    </a>

<%
    } catch (SQLException e) {

        e.printStackTrace();

        try {

            if (connection != null
                    && !connection.getAutoCommit()) {

                connection.rollback();
            }

        } catch (SQLException rollbackException) {

            rollbackException.printStackTrace();
        }
%>

    <p style="color: red;">
        A database error occurred while editing the
        train schedule.
    </p>

    <a href="<%= request.getContextPath() %>/representative/manageSchedules.jsp">
        Back to train schedules
    </a>

<%
    } catch (Exception e) {

        e.printStackTrace();

        try {

            if (connection != null
                    && !connection.getAutoCommit()) {

                connection.rollback();
            }

        } catch (SQLException rollbackException) {

            rollbackException.printStackTrace();
        }
%>

    <p style="color: red;">
        The train schedule could not be updated.
    </p>

    <a href="<%= request.getContextPath() %>/representative/manageSchedules.jsp">
        Back to train schedules
    </a>

<%
    } finally {

        try {

            if (stopResult != null) {
                stopResult.close();
            }

            if (lineResult != null) {
                lineResult.close();
            }

            if (trainResult != null) {
                trainResult.close();
            }

            if (scheduleResult != null) {
                scheduleResult.close();
            }

            if (updateStopStatement != null) {
                updateStopStatement.close();
            }

            if (updateScheduleStatement != null) {
                updateScheduleStatement.close();
            }

            if (stopStatement != null) {
                stopStatement.close();
            }

            if (lineStatement != null) {
                lineStatement.close();
            }

            if (trainStatement != null) {
                trainStatement.close();
            }

            if (scheduleStatement != null) {
                scheduleStatement.close();
            }

            if (connection != null) {

                try {

                    if (!connection.getAutoCommit()) {
                        connection.setAutoCommit(true);
                    }

                } catch (SQLException autoCommitException) {

                    autoCommitException.printStackTrace();
                }

                db.closeConnection(
                    connection
                );
            }

        } catch (SQLException e) {

            e.printStackTrace();
        }
    }
%>