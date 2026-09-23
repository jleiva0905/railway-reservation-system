<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"
    import="java.sql.*"
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

    String action =
        request.getParameter("action");

    String message =
        request.getParameter("message");

    if (scheduleIdParameter == null
            || scheduleIdParameter.isEmpty()) {

        response.sendRedirect(
            "manageSchedules.jsp?message=deleteError"
        );

        return;
    }

    int scheduleId;

    try {

        scheduleId =
            Integer.parseInt(
                scheduleIdParameter
            );

    } catch (NumberFormatException e) {

        response.sendRedirect(
            "manageSchedules.jsp?message=deleteError"
        );

        return;
    }

    ApplicationDB db =
        new ApplicationDB();

    Connection connection = null;

    PreparedStatement statement = null;
    ResultSet result = null;

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
         * DELETE AN INTERMEDIATE STOP
         * =====================================================
         */
        if ("deleteStop".equals(action)
                && "POST".equalsIgnoreCase(
                    request.getMethod()
                )) {

            String stopNumberParameter =
                request.getParameter(
                    "stopNumber"
                );

            String stationIdParameter =
                request.getParameter(
                    "stationId"
                );

            if (stopNumberParameter == null
                    || stationIdParameter == null) {

                response.sendRedirect(
                    "deleteSchedule.jsp"
                    + "?scheduleId="
                    + scheduleId
                    + "&message=stopDeleteError"
                );

                return;
            }

            int stopNumber;
            int stationId;

            try {

                stopNumber =
                    Integer.parseInt(
                        stopNumberParameter
                    );

                stationId =
                    Integer.parseInt(
                        stationIdParameter
                    );

            } catch (NumberFormatException e) {

                response.sendRedirect(
                    "deleteSchedule.jsp"
                    + "?scheduleId="
                    + scheduleId
                    + "&message=stopDeleteError"
                );

                return;
            }

            connection.setAutoCommit(false);

            /*
             * Lock and retrieve the stop being deleted.
             */
            String selectedStopQuery =
                "SELECT " +
                "station_id, " +
                "stop_number, " +
                "arrival_datetime, " +
                "departure_datetime " +

                "FROM schedule_station_stops " +

                "WHERE schedule_id = ? " +
                "AND stop_number = ? " +
                "AND station_id = ? " +

                "FOR UPDATE";

            statement =
                connection.prepareStatement(
                    selectedStopQuery
                );

            statement.setInt(
                1,
                scheduleId
            );

            statement.setInt(
                2,
                stopNumber
            );

            statement.setInt(
                3,
                stationId
            );

            result =
                statement.executeQuery();

            if (!result.next()) {

                connection.rollback();

                response.sendRedirect(
                    "deleteSchedule.jsp"
                    + "?scheduleId="
                    + scheduleId
                    + "&message=stopNotFound"
                );

                return;
            }

            Timestamp stopArrival =
                result.getTimestamp(
                    "arrival_datetime"
                );

            Timestamp stopDeparture =
                result.getTimestamp(
                    "departure_datetime"
                );

            result.close();
            result = null;

            statement.close();
            statement = null;

            /*
             * Find the first and last stop numbers.
             *
             * The origin and destination cannot be deleted.
             */
            String boundaryQuery =
                "SELECT " +
                    "MIN(stop_number) AS first_stop_number, " +
                    "MAX(stop_number) AS last_stop_number " +

                "FROM schedule_station_stops " +

                "WHERE schedule_id = ?";

            statement =
                connection.prepareStatement(
                    boundaryQuery
                );

            statement.setInt(
                1,
                scheduleId
            );

            result =
                statement.executeQuery();

            int firstStopNumber = -1;
            int lastStopNumber = -1;

            if (result.next()) {

                firstStopNumber =
                    result.getInt(
                        "first_stop_number"
                    );

                lastStopNumber =
                    result.getInt(
                        "last_stop_number"
                    );
            }

            result.close();
            result = null;

            statement.close();
            statement = null;

            if (stopNumber == firstStopNumber) {

                connection.rollback();

                response.sendRedirect(
                    "deleteSchedule.jsp"
                    + "?scheduleId="
                    + scheduleId
                    + "&message=cannotDeleteOrigin"
                );

                return;
            }

            if (stopNumber == lastStopNumber) {

                connection.rollback();

                response.sendRedirect(
                    "deleteSchedule.jsp"
                    + "?scheduleId="
                    + scheduleId
                    + "&message=cannotDeleteDestination"
                );

                return;
            }

            /*
             * A stop cannot be deleted when a customer has
             * selected it as either their departure station
             * or arrival station on this schedule.
             */
            String stopReservationQuery =
                "SELECT COUNT(*) AS reservation_count " +

                "FROM reservation " +

                "WHERE schedule_id = ? " +

                "AND (" +
                    "departure_station_id = ? " +
                    "OR arrival_station_id = ?" +
                ")";

            statement =
                connection.prepareStatement(
                    stopReservationQuery
                );

            statement.setInt(
                1,
                scheduleId
            );

            statement.setInt(
                2,
                stationId
            );

            statement.setInt(
                3,
                stationId
            );

            result =
                statement.executeQuery();

            int reservationCount = 0;

            if (result.next()) {

                reservationCount =
                    result.getInt(
                        "reservation_count"
                    );
            }

            result.close();
            result = null;

            statement.close();
            statement = null;

            if (reservationCount > 0) {

                connection.rollback();

                response.sendRedirect(
                    "deleteSchedule.jsp"
                    + "?scheduleId="
                    + scheduleId
                    + "&message=stopHasReservations"
                );

                return;
            }

            /*
             * An intermediate stop should have both an arrival
             * datetime and a departure datetime.
             */
            if (stopArrival == null
                    || stopDeparture == null) {

                connection.rollback();

                response.sendRedirect(
                    "deleteSchedule.jsp"
                    + "?scheduleId="
                    + scheduleId
                    + "&message=invalidStopTimes"
                );

                return;
            }

            long removedDurationMilliseconds =
                stopDeparture.getTime()
                - stopArrival.getTime();

            if (removedDurationMilliseconds < 0) {

                connection.rollback();

                response.sendRedirect(
                    "deleteSchedule.jsp"
                    + "?scheduleId="
                    + scheduleId
                    + "&message=invalidStopTimes"
                );

                return;
            }

            long removedDurationSeconds =
                removedDurationMilliseconds
                / 1000;

            /*
             * Delete only the stop from this particular
             * schedule.
             *
             * Nothing is removed from the station table.
             */
            String deleteStopQuery =
                "DELETE FROM schedule_station_stops " +

                "WHERE schedule_id = ? " +
                "AND stop_number = ? " +
                "AND station_id = ?";

            statement =
                connection.prepareStatement(
                    deleteStopQuery
                );

            statement.setInt(
                1,
                scheduleId
            );

            statement.setInt(
                2,
                stopNumber
            );

            statement.setInt(
                3,
                stationId
            );

            int deletedStops =
                statement.executeUpdate();

            statement.close();
            statement = null;

            if (deletedStops != 1) {

                connection.rollback();

                response.sendRedirect(
                    "deleteSchedule.jsp"
                    + "?scheduleId="
                    + scheduleId
                    + "&message=stopDeleteError"
                );

                return;
            }

            /*
             * Move every later stop earlier by the dwell time
             * of the deleted stop.
             *
             * TIMESTAMPADD preserves NULL values:
             * TIMESTAMPADD(..., NULL) returns NULL.
             */
            String shiftLaterStopsQuery =
                "UPDATE schedule_station_stops " +

                "SET " +

                "arrival_datetime = " +
                    "CASE " +
                        "WHEN arrival_datetime IS NULL " +
                            "THEN NULL " +
                        "ELSE TIMESTAMPADD(" +
                            "SECOND, ?, arrival_datetime" +
                        ") " +
                    "END, " +

                "departure_datetime = " +
                    "CASE " +
                        "WHEN departure_datetime IS NULL " +
                            "THEN NULL " +
                        "ELSE TIMESTAMPADD(" +
                            "SECOND, ?, departure_datetime" +
                        ") " +
                    "END " +

                "WHERE schedule_id = ? " +
                "AND stop_number > ?";

            statement =
                connection.prepareStatement(
                    shiftLaterStopsQuery
                );

            /*
             * The value must be negative because the later
             * stops are moving earlier.
             */
            statement.setLong(
                1,
                -removedDurationSeconds
            );

            statement.setLong(
                2,
                -removedDurationSeconds
            );

            statement.setInt(
                3,
                scheduleId
            );

            statement.setInt(
                4,
                stopNumber
            );

            statement.executeUpdate();

            statement.close();
            statement = null;

            /*
             * Retrieve the remaining stops in their existing
             * order so they can be renumbered.
             */
            String remainingStopsQuery =
                "SELECT station_id, stop_number " +

                "FROM schedule_station_stops " +

                "WHERE schedule_id = ? " +

                "ORDER BY stop_number";

            statement =
                connection.prepareStatement(
                    remainingStopsQuery
                );

            statement.setInt(
                1,
                scheduleId
            );

            result =
                statement.executeQuery();

            ArrayList<Integer> remainingStationIds =
                new ArrayList<Integer>();

            ArrayList<Integer> oldStopNumbers =
                new ArrayList<Integer>();

            while (result.next()) {

                remainingStationIds.add(
                    result.getInt(
                        "station_id"
                    )
                );

                oldStopNumbers.add(
                    result.getInt(
                        "stop_number"
                    )
                );
            }

            result.close();
            result = null;

            statement.close();
            statement = null;

            /*
             * Renumber the stops as 0, 1, 2, 3, ...
             */
            String renumberQuery =
                "UPDATE schedule_station_stops " +

                "SET stop_number = ? " +

                "WHERE schedule_id = ? " +
                "AND station_id = ? " +
                "AND stop_number = ?";

            statement =
                connection.prepareStatement(
                    renumberQuery
                );

            for (int index = 0;
                    index < remainingStationIds.size();
                    index++) {

                int oldStopNumber =
                    oldStopNumbers.get(index);

                int newStopNumber =
                    index;

                if (oldStopNumber != newStopNumber) {

                    statement.setInt(
                        1,
                        newStopNumber
                    );

                    statement.setInt(
                        2,
                        scheduleId
                    );

                    statement.setInt(
                        3,
                        remainingStationIds.get(index)
                    );

                    statement.setInt(
                        4,
                        oldStopNumber
                    );

                    statement.executeUpdate();
                }
            }

            statement.close();
            statement = null;

            /*
             * Recalculate the overall schedule datetimes.
             *
             * Departure comes from the newly numbered origin.
             * Arrival comes from the newly numbered destination.
             */
            String updateScheduleTimesQuery =
                "UPDATE trainschedule ts " +

                "SET " +

                "ts.departure_datetime = (" +

                    "SELECT first_stop.departure_datetime " +

                    "FROM schedule_station_stops first_stop " +

                    "WHERE first_stop.schedule_id = " +
                        "ts.schedule_id " +

                    "ORDER BY first_stop.stop_number " +

                    "LIMIT 1" +

                "), " +

                "ts.arrival_datetime = (" +

                    "SELECT last_stop.arrival_datetime " +

                    "FROM schedule_station_stops last_stop " +

                    "WHERE last_stop.schedule_id = " +
                        "ts.schedule_id " +

                    "ORDER BY last_stop.stop_number DESC " +

                    "LIMIT 1" +

                ") " +

                "WHERE ts.schedule_id = ?";

            statement =
                connection.prepareStatement(
                    updateScheduleTimesQuery
                );

            statement.setInt(
                1,
                scheduleId
            );

            int schedulesUpdated =
                statement.executeUpdate();

            statement.close();
            statement = null;

            if (schedulesUpdated != 1) {

                connection.rollback();

                response.sendRedirect(
                    "deleteSchedule.jsp"
                    + "?scheduleId="
                    + scheduleId
                    + "&message=stopDeleteError"
                );

                return;
            }

            connection.commit();

            response.sendRedirect(
                "deleteSchedule.jsp"
                + "?scheduleId="
                + scheduleId
                + "&message=stopDeleted"
            );

            return;
        }

        /*
         * =====================================================
         * DELETE THE ENTIRE SCHEDULE
         * =====================================================
         */
        if ("deleteSchedule".equals(action)
                && "POST".equalsIgnoreCase(
                    request.getMethod()
                )) {

            connection.setAutoCommit(false);

            String reservationCheckQuery =
                "SELECT COUNT(*) AS reservation_count " +

                "FROM reservation " +

                "WHERE schedule_id = ?";

            statement =
                connection.prepareStatement(
                    reservationCheckQuery
                );

            statement.setInt(
                1,
                scheduleId
            );

            result =
                statement.executeQuery();

            int reservationCount = 0;

            if (result.next()) {

                reservationCount =
                    result.getInt(
                        "reservation_count"
                    );
            }

            result.close();
            result = null;

            statement.close();
            statement = null;

            if (reservationCount > 0) {

                connection.rollback();

                response.sendRedirect(
                    "deleteSchedule.jsp"
                    + "?scheduleId="
                    + scheduleId
                    + "&message=scheduleHasReservations"
                );

                return;
            }

            /*
             * Delete all stop rows belonging to the schedule.
             *
             * This does not delete stations from the
             * station table.
             */
            String deleteScheduleStopsQuery =
                "DELETE FROM schedule_station_stops " +
                "WHERE schedule_id = ?";

            statement =
                connection.prepareStatement(
                    deleteScheduleStopsQuery
                );

            statement.setInt(
                1,
                scheduleId
            );

            statement.executeUpdate();

            statement.close();
            statement = null;

            String deleteScheduleQuery =
                "DELETE FROM trainschedule " +
                "WHERE schedule_id = ?";

            statement =
                connection.prepareStatement(
                    deleteScheduleQuery
                );

            statement.setInt(
                1,
                scheduleId
            );

            int deletedSchedules =
                statement.executeUpdate();

            statement.close();
            statement = null;

            if (deletedSchedules != 1) {

                connection.rollback();

                response.sendRedirect(
                    "deleteSchedule.jsp"
                    + "?scheduleId="
                    + scheduleId
                    + "&message=scheduleDeleteError"
                );

                return;
            }

            connection.commit();

            response.sendRedirect(
                "manageSchedules.jsp?message=deleted"
            );

            return;
        }

        /*
         * =====================================================
         * LOAD THE SCHEDULE INFORMATION
         * =====================================================
         */
        String scheduleQuery =
            "SELECT " +
                "ts.schedule_id, " +
                "ts.train_id, " +
                "ts.line_name, " +
                "ts.departure_datetime, " +
                "ts.arrival_datetime, " +

                "origin_station.name AS origin_name, " +
                "destination_station.name AS destination_name " +

            "FROM trainschedule ts " +

            "JOIN schedule_station_stops origin_stop " +
                "ON ts.schedule_id = origin_stop.schedule_id " +

                "AND origin_stop.stop_number = (" +

                    "SELECT MIN(first_stop.stop_number) " +

                    "FROM schedule_station_stops first_stop " +

                    "WHERE first_stop.schedule_id = " +
                        "ts.schedule_id" +

                ") " +

            "JOIN station origin_station " +
                "ON origin_stop.station_id = " +
                    "origin_station.station_id " +

            "JOIN schedule_station_stops destination_stop " +
                "ON ts.schedule_id = destination_stop.schedule_id " +

                "AND destination_stop.stop_number = (" +

                    "SELECT MAX(last_stop.stop_number) " +

                    "FROM schedule_station_stops last_stop " +

                    "WHERE last_stop.schedule_id = " +
                        "ts.schedule_id" +

                ") " +

            "JOIN station destination_station " +
                "ON destination_stop.station_id = " +
                    "destination_station.station_id " +

            "WHERE ts.schedule_id = ?";

        statement =
            connection.prepareStatement(
                scheduleQuery
            );

        statement.setInt(
            1,
            scheduleId
        );

        result =
            statement.executeQuery();

        if (!result.next()) {

            result.close();
            result = null;

            statement.close();
            statement = null;

            response.sendRedirect(
                "manageSchedules.jsp?message=deleteError"
            );

            return;
        }

        String trainId =
            result.getString(
                "train_id"
            );

        String lineName =
            result.getString(
                "line_name"
            );

        String originName =
            result.getString(
                "origin_name"
            );

        String destinationName =
            result.getString(
                "destination_name"
            );

        Timestamp scheduleDeparture =
            result.getTimestamp(
                "departure_datetime"
            );

        Timestamp scheduleArrival =
            result.getTimestamp(
                "arrival_datetime"
            );

        result.close();
        result = null;

        statement.close();
        statement = null;
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">

    <title>
        Delete Schedule or Stops
    </title>
</head>

<body>

    <h1>
        Delete Schedule or Stops
    </h1>

    <p>
        You may delete an intermediate stop or delete
        the entire train schedule.
    </p>

    <%
        if ("stopDeleted".equals(message)) {
    %>

        <p style="color: green;">
            The stop was deleted successfully. All later
            stops were moved earlier by the deleted stop's
            waiting time, and the remaining stops were
            renumbered.
        </p>

    <%
        } else if ("cannotDeleteOrigin".equals(message)) {
    %>

        <p style="color: red;">
            The origin station cannot be deleted.
        </p>

    <%
        } else if ("cannotDeleteDestination".equals(message)) {
    %>

        <p style="color: red;">
            The destination station cannot be deleted.
        </p>

    <%
        } else if ("stopHasReservations".equals(message)) {
    %>

        <p style="color: red;">
            This stop cannot be deleted because at least one
            customer has a reservation that begins or ends
            at this stop.
        </p>

    <%
        } else if ("scheduleHasReservations".equals(message)) {
    %>

        <p style="color: red;">
            This schedule cannot be deleted because customer
            reservations currently use it.
        </p>

    <%
        } else if ("invalidStopTimes".equals(message)) {
    %>

        <p style="color: red;">
            This stop could not be deleted because its arrival
            and departure datetimes are invalid.
        </p>

    <%
        } else if ("stopNotFound".equals(message)) {
    %>

        <p style="color: red;">
            The selected stop was not found.
        </p>

    <%
        } else if ("stopDeleteError".equals(message)) {
    %>

        <p style="color: red;">
            The stop could not be deleted.
        </p>

    <%
        } else if ("scheduleDeleteError".equals(message)) {
    %>

        <p style="color: red;">
            The schedule could not be deleted.
        </p>

    <%
        }
    %>

    <h2>
        Schedule Information
    </h2>

    <table border="1" cellpadding="8">

        <tr>
            <th>Schedule ID</th>
            <td><%= scheduleId %></td>
        </tr>

        <tr>
            <th>Train</th>
            <td><%= trainId %></td>
        </tr>

        <tr>
            <th>Transit Line</th>
            <td><%= lineName %></td>
        </tr>

        <tr>
            <th>Origin</th>
            <td><%= originName %></td>
        </tr>

        <tr>
            <th>Destination</th>
            <td><%= destinationName %></td>
        </tr>

        <tr>
            <th>Overall Departure</th>
            <td><%= scheduleDeparture %></td>
        </tr>

        <tr>
            <th>Overall Arrival</th>
            <td><%= scheduleArrival %></td>
        </tr>

    </table>

    <h2>
        Schedule Stops
    </h2>

    <%
        String stopsQuery =
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

        statement =
            connection.prepareStatement(
                stopsQuery
            );

        statement.setInt(
            1,
            scheduleId
        );

        result =
            statement.executeQuery();
    %>

    <table border="1" cellpadding="8">

        <tr>
            <th>Stop Number</th>
            <th>Station</th>
            <th>Arrival</th>
            <th>Departure</th>
            <th>Delete</th>
        </tr>

        <%
            while (result.next()) {

                int stationId =
                    result.getInt(
                        "station_id"
                    );

                int stopNumber =
                    result.getInt(
                        "stop_number"
                    );

                int firstStopNumber =
                    result.getInt(
                        "first_stop_number"
                    );

                int lastStopNumber =
                    result.getInt(
                        "last_stop_number"
                    );

                boolean isOrigin =
                    stopNumber == firstStopNumber;

                boolean isDestination =
                    stopNumber == lastStopNumber;
        %>

        <tr>

            <td>
                <%= stopNumber %>
            </td>

            <td>
                <%= result.getString(
                    "station_name"
                ) %>

                -

                <%= result.getString(
                    "city"
                ) %>,

                <%= result.getString(
                    "state"
                ) %>
            </td>

            <td>
                <%= result.getTimestamp(
                    "arrival_datetime"
                ) %>
            </td>

            <td>
                <%= result.getTimestamp(
                    "departure_datetime"
                ) %>
            </td>

            <td>

                <%
                    if (isOrigin) {
                %>

                    Origin — cannot delete

                <%
                    } else if (isDestination) {
                %>

                    Destination — cannot delete

                <%
                    } else {
                %>

                    <form
                        action="deleteSchedule.jsp"
                        method="post"
                        style="display: inline;">

                        <input
                            type="hidden"
                            name="action"
                            value="deleteStop">

                        <input
                            type="hidden"
                            name="scheduleId"
                            value="<%= scheduleId %>">

                        <input
                            type="hidden"
                            name="stationId"
                            value="<%= stationId %>">

                        <input
                            type="hidden"
                            name="stopNumber"
                            value="<%= stopNumber %>">

                        <input
                            type="submit"
                            value="Delete Stop"
                            onclick="return confirm(
                                'Are you sure you want to delete this stop? '
                                + 'All later stops will be moved earlier '
                                + 'by this stop\\'s waiting time.'
                            );">

                    </form>

                <%
                    }
                %>

            </td>

        </tr>

        <%
            }
        %>

    </table>

    <br>

    <h2>
        Delete Entire Schedule
    </h2>

    <p>
        The entire schedule can only be deleted when it
        has no customer reservations.
    </p>

    <form
        action="deleteSchedule.jsp"
        method="post">

        <input
            type="hidden"
            name="action"
            value="deleteSchedule">

        <input
            type="hidden"
            name="scheduleId"
            value="<%= scheduleId %>">

        <input
            type="submit"
            value="Delete Entire Schedule"
            onclick="return confirm(
                'Are you sure you want to permanently delete '
                + 'this entire train schedule and all of its '
                + 'schedule-stop records?'
            );">

    </form>

    <br>

    <a href="manageSchedules.jsp">
        Back to Manage Train Schedules
    </a>

    <br><br>

    <a href="<%= request.getContextPath() %>/representative/r_home.jsp">
        Back to Representative Home
    </a>

</body>
</html>

<%
    } catch (SQLException e) {

        e.printStackTrace();

        try {

            if (connection != null
                    && !connection.getAutoCommit()) {

                connection.rollback();
            }

        } catch (SQLException rollbackError) {

            rollbackError.printStackTrace();
        }
%>

    <p style="color: red;">
        A database error occurred.
    </p>

    <a href="manageSchedules.jsp">
        Back to Manage Train Schedules
    </a>

<%
    } finally {

        try {

            if (result != null) {
                result.close();
            }

            if (statement != null) {
                statement.close();
            }

            if (connection != null) {

                try {

                    if (!connection.getAutoCommit()) {
                        connection.setAutoCommit(true);
                    }

                } catch (SQLException e) {

                    e.printStackTrace();
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