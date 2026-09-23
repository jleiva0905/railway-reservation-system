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

    String message =
        request.getParameter("message");

    ApplicationDB db =
        new ApplicationDB();

    Connection connection = null;
    PreparedStatement statement = null;
    ResultSet result = null;

    try {
        connection =
            db.getConnection();

        String scheduleQuery =
            "SELECT " +
            "ts.schedule_id, " +
            "ts.departure_datetime, " +
            "ts.arrival_datetime, " +
            "ts.line_name, " +
            "ts.train_id, " +

            "origin_station.name AS origin_name, " +
            "destination_station.name AS destination_name " +

            "FROM trainschedule ts " +

            "JOIN schedule_station_stops origin_stop " +
            "ON ts.schedule_id = origin_stop.schedule_id " +
            "AND origin_stop.stop_number = (" +
                "SELECT MIN(first_stop.stop_number) " +
                "FROM schedule_station_stops first_stop " +
                "WHERE first_stop.schedule_id = ts.schedule_id" +
            ") " +

            "JOIN station origin_station " +
            "ON origin_stop.station_id = " +
            "origin_station.station_id " +

            "JOIN schedule_station_stops destination_stop " +
            "ON ts.schedule_id = destination_stop.schedule_id " +
            "AND destination_stop.stop_number = (" +
                "SELECT MAX(last_stop.stop_number) " +
                "FROM schedule_station_stops last_stop " +
                "WHERE last_stop.schedule_id = ts.schedule_id" +
            ") " +

            "JOIN station destination_station " +
            "ON destination_stop.station_id = " +
            "destination_station.station_id " +

            "ORDER BY ts.departure_datetime";

        statement =
            connection.prepareStatement(
                scheduleQuery
            );

        result =
            statement.executeQuery();
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Manage Train Schedules</title>
</head>

<body>

    <h1>Manage Train Schedules</h1>

    <p>
        Edit or delete existing train schedule information.
    </p>

    <%
        if ("updated".equals(message)) {
    %>

        <p style="color: green;">
            The train schedule was updated successfully.
        </p>

    <%
        } else if ("deleted".equals(message)) {
    %>

        <p style="color: green;">
            The train schedule was deleted successfully.
        </p>

    <%
        } else if ("deleteError".equals(message)) {
    %>

        <p style="color: red;">
            The train schedule could not be deleted.
        </p>

    <%
        }
    %>

    <table border="1" cellpadding="8">

        <tr>
            <th>Schedule ID</th>
            <th>Train</th>
            <th>Transit Line</th>
            <th>Origin</th>
            <th>Destination</th>
            <th>Departure</th>
            <th>Arrival</th>
            <th>Edit</th>
            <th>Delete</th>
        </tr>

        <%
            boolean foundSchedule = false;

            while (result.next()) {

                foundSchedule = true;

                int scheduleId =
                    result.getInt(
                        "schedule_id"
                    );
        %>

        <tr>
            <td>
                <%= scheduleId %>
            </td>

            <td>
                <%= result.getString(
                    "train_id"
                ) %>
            </td>

            <td>
                <%= result.getString(
                    "line_name"
                ) %>
            </td>

            <td>
                <%= result.getString(
                    "origin_name"
                ) %>
            </td>

            <td>
                <%= result.getString(
                    "destination_name"
                ) %>
            </td>

            <td>
                <%= result.getTimestamp(
                    "departure_datetime"
                ) %>
            </td>

            <td>
                <%= result.getTimestamp(
                    "arrival_datetime"
                ) %>
            </td>

            <td>
                <a href="editSchedule.jsp?scheduleId=<%= scheduleId %>">
                    Edit
                </a>
            </td>

            <td>
                <a href="deleteSchedule.jsp?scheduleId=<%= scheduleId %>">
                    Delete / Manage Stops
                </a>
            </td>
        </tr>

        <%
            }

            if (!foundSchedule) {
        %>

        <tr>
            <td colspan="9">
                No train schedules were found.
            </td>
        </tr>

        <%
            }
        %>

    </table>

    <br>

    <a href="<%= request.getContextPath() %>/representative/r_home.jsp">
        Back to representative home
    </a>

</body>
</html>

<%
    } catch (SQLException e) {

        e.printStackTrace();
%>

    <p style="color: red;">
        A database error occurred while loading train schedules.
    </p>

    <a href="<%= request.getContextPath() %>/representative/r_home.jsp">
        Back to representative home
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
                db.closeConnection(connection);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
%>