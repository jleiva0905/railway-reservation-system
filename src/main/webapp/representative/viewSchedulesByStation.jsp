<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"
    import="java.sql.*"
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

    String selectedStationId =
        request.getParameter("stationId");

    String searchParameter =
        request.getParameter("search");

    boolean searchSubmitted =
        searchParameter != null;

    if (selectedStationId == null) {
        selectedStationId = "";
    }

    selectedStationId =
        selectedStationId.trim();

    String errorMessage = null;

    ApplicationDB db =
        new ApplicationDB();

    Connection connection = null;

    PreparedStatement stationStatement = null;
    PreparedStatement scheduleStatement = null;

    ResultSet stationResult = null;
    ResultSet scheduleResult = null;

    try {
        connection =
            db.getConnection();

        if (connection == null) {
            throw new SQLException(
                "Could not connect to the database."
            );
        }

        /*
         * Load all stations for the dropdown menu.
         */
        String stationQuery =
            "SELECT station_id, name " +
            "FROM station " +
            "ORDER BY name";

        stationStatement =
            connection.prepareStatement(
                stationQuery
            );

        stationResult =
            stationStatement.executeQuery();
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>View Schedules by Station</title>
</head>

<body>

    <h1>View Train Schedules by Station</h1>

    <p>
        Select a station to view every train schedule
        that stops at that station.
    </p>

    <form
        action="viewSchedulesByStation.jsp"
        method="get">

        <input
            type="hidden"
            name="search"
            value="true">

        <label for="stationId">
            Station:
        </label>

        <select
            id="stationId"
            name="stationId"
            required>

            <option value="">
                Select a station
            </option>

            <%
                while (stationResult.next()) {

                    int stationId =
                        stationResult.getInt(
                            "station_id"
                        );

                    String stationName =
                        stationResult.getString(
                            "name"
                        );

                    boolean selected =
                        selectedStationId.equals(
                            String.valueOf(stationId)
                        );
            %>

                <option
                    value="<%= stationId %>"
                    <%= selected
                        ? "selected"
                        : "" %>>

                    <%= stationName %>

                </option>

            <%
                }
            %>

        </select>

        <br><br>

        <input
            type="submit"
            value="View Schedules">

        &nbsp;

        <a href="viewSchedulesByStation.jsp">
            Clear Search
        </a>

    </form>

    <hr>

<%
        if (searchSubmitted) {

            if (selectedStationId.isEmpty()) {

                errorMessage =
                    "Please select a station.";

            } else {

                int stationId =
                    Integer.parseInt(
                        selectedStationId
                    );

                /*
                 * Return every schedule containing the
                 * selected station.
                 *
                 * origin_stop finds the first stop.
                 * destination_stop finds the final stop.
                 * selected_stop contains the arrival and
                 * departure time at the selected station.
                 */
                String scheduleQuery =
                    "SELECT " +
                    "ts.schedule_id, " +
                    "ts.train_id, " +
                    "ts.line_name, " +

                    "origin_station.name " +
                    "AS origin_name, " +

                    "destination_station.name " +
                    "AS destination_name, " +

                    "selected_station.name " +
                    "AS selected_station_name, " +

                    "selected_stop.stop_number, " +

                    "ts.departure_datetime " +
                    "AS full_schedule_departure, " +

                    "selected_stop.arrival_datetime " +
                    "AS stop_arrival_datetime, " +

                    "selected_stop.departure_datetime " +
                    "AS stop_departure_datetime, " +

                    "ts.arrival_datetime " +
                    "AS full_schedule_arrival " +

                    "FROM trainschedule ts " +

                    /*
                     * Join the selected station stop.
                     */
                    "JOIN schedule_station_stops " +
                    "selected_stop " +
                    "ON ts.schedule_id = " +
                    "selected_stop.schedule_id " +

                    "JOIN station selected_station " +
                    "ON selected_stop.station_id = " +
                    "selected_station.station_id " +

                    /*
                     * Join the first stop of the schedule.
                     */
                    "JOIN schedule_station_stops " +
                    "origin_stop " +
                    "ON ts.schedule_id = " +
                    "origin_stop.schedule_id " +

                    "AND origin_stop.stop_number = (" +
                        "SELECT MIN(first_stop.stop_number) " +
                        "FROM schedule_station_stops " +
                        "first_stop " +
                        "WHERE first_stop.schedule_id = " +
                        "ts.schedule_id" +
                    ") " +

                    "JOIN station origin_station " +
                    "ON origin_stop.station_id = " +
                    "origin_station.station_id " +

                    /*
                     * Join the final stop of the schedule.
                     */
                    "JOIN schedule_station_stops " +
                    "destination_stop " +
                    "ON ts.schedule_id = " +
                    "destination_stop.schedule_id " +

                    "AND destination_stop.stop_number = (" +
                        "SELECT MAX(last_stop.stop_number) " +
                        "FROM schedule_station_stops " +
                        "last_stop " +
                        "WHERE last_stop.schedule_id = " +
                        "ts.schedule_id" +
                    ") " +

                    "JOIN station destination_station " +
                    "ON destination_stop.station_id = " +
                    "destination_station.station_id " +

                    /*
                     * Include every schedule that stops
                     * at the selected station.
                     */
                    "WHERE selected_stop.station_id = ? " +

                    "ORDER BY " +
                    "ts.departure_datetime, " +
                    "ts.line_name";

                scheduleStatement =
                    connection.prepareStatement(
                        scheduleQuery
                    );

                scheduleStatement.setInt(
                    1,
                    stationId
                );

                scheduleResult =
                    scheduleStatement.executeQuery();

                boolean foundSchedule = false;
%>

    <h2>Schedule Results</h2>

    <table border="1" cellpadding="8">

        <tr>
            <th>Schedule ID</th>
            <th>Train</th>
            <th>Transit Line</th>
            <th>Origin</th>
            <th>Destination</th>
            <th>Selected Station</th>
            <th>Stop Number</th>
            <th>Origin Departure</th>
            <th>Stop Arrival</th>
            <th>Stop Departure</th>
            <th>Destination Arrival</th>
        </tr>

        <%
            while (scheduleResult.next()) {

                foundSchedule = true;

                Timestamp stopArrival =
                    scheduleResult.getTimestamp(
                        "stop_arrival_datetime"
                    );

                Timestamp stopDeparture =
                    scheduleResult.getTimestamp(
                        "stop_departure_datetime"
                    );
        %>

        <tr>
            <td>
                <%= scheduleResult.getInt(
                    "schedule_id"
                ) %>
            </td>

            <td>
                <%= scheduleResult.getString(
                    "train_id"
                ) %>
            </td>

            <td>
                <%= scheduleResult.getString(
                    "line_name"
                ) %>
            </td>

            <td>
                <%= scheduleResult.getString(
                    "origin_name"
                ) %>
            </td>

            <td>
                <%= scheduleResult.getString(
                    "destination_name"
                ) %>
            </td>

            <td>
                <%= scheduleResult.getString(
                    "selected_station_name"
                ) %>
            </td>

            <td>
                <%= scheduleResult.getInt(
                    "stop_number"
                ) %>
            </td>

            <td>
                <%= scheduleResult.getTimestamp(
                    "full_schedule_departure"
                ) %>
            </td>

            <td>
                <%
                    if (stopArrival == null) {
                %>

                    Route origin

                <%
                    } else {
                %>

                    <%= stopArrival %>

                <%
                    }
                %>
            </td>

            <td>
                <%
                    if (stopDeparture == null) {
                %>

                    Route destination

                <%
                    } else {
                %>

                    <%= stopDeparture %>

                <%
                    }
                %>
            </td>

            <td>
                <%= scheduleResult.getTimestamp(
                    "full_schedule_arrival"
                ) %>
            </td>
        </tr>

        <%
            }
        %>

    </table>

    <%
        if (!foundSchedule) {
    %>

        <p>
            No train schedules stop at the selected station.
        </p>

    <%
        }
    %>

<%
            }
        }

        if (errorMessage != null) {
%>

    <p style="color: red;">
        <%= errorMessage %>
    </p>

<%
        }
%>

    <br>

    <a href="<%= request.getContextPath() %>/representative/r_home.jsp">
        Back to representative home
    </a>

</body>
</html>

<%
    } catch (NumberFormatException e) {

        e.printStackTrace();
%>

    <p style="color: red;">
        The selected station number is invalid.
    </p>

    <a href="<%= request.getContextPath() %>/representative/viewSchedulesByStation.jsp">
        Return to schedule search
    </a>

<%
    } catch (SQLException e) {

        e.printStackTrace();
%>

    <p style="color: red;">
        A database error occurred while loading schedules.
    </p>

    <a href="<%= request.getContextPath() %>/representative/r_home.jsp">
        Back to representative home
    </a>

<%
    } finally {

        try {
            if (scheduleResult != null) {
                scheduleResult.close();
            }

            if (scheduleStatement != null) {
                scheduleStatement.close();
            }

            if (stationResult != null) {
                stationResult.close();
            }

            if (stationStatement != null) {
                stationStatement.close();
            }

            if (connection != null) {
                db.closeConnection(connection);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
%>