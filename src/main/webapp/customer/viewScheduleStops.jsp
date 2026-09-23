<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"
    import="java.sql.*"
    import="java.util.*"
    import="java.text.*"
    import="com.cs336.pkg.ApplicationDB"%>

<%!
    public String escapeHtml(String value) {
        if (value == null) {
            return "";
        }

        return value
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")
            .replace("'", "&#39;");
    }
%>

<%
    String userType =
        (String) session.getAttribute("userType");

    if (!"customer".equals(userType)) {
        response.sendRedirect(
            request.getContextPath() + "/login.jsp"
        );

        return;
    }

    String scheduleIdParameter =
        request.getParameter("scheduleId");

    String origin =
        request.getParameter("origin");

    String destination =
        request.getParameter("destination");

    String travelDate =
        request.getParameter("travelDate");

    String sortBy =
        request.getParameter("sortBy");

    if (origin == null) {
        origin = "";
    }

    if (destination == null) {
        destination = "";
    }

    if (travelDate == null) {
        travelDate = "";
    }

    if (sortBy == null || sortBy.trim().isEmpty()) {
        sortBy = "departure_asc";
    }

    String errorMessage = null;

    String lineName = "";
    String trainId = "";
    String scheduleDeparture = "";
    String scheduleArrival = "";

    ArrayList<HashMap<String, String>> stops =
        new ArrayList<HashMap<String, String>>();

    ApplicationDB db =
        new ApplicationDB();

    Connection con = null;

    PreparedStatement scheduleStatement = null;
    PreparedStatement stopStatement = null;

    ResultSet scheduleResult = null;
    ResultSet stopResult = null;

    try {
        int scheduleId = 0;

        if (scheduleIdParameter == null
                || scheduleIdParameter.trim().isEmpty()) {

            errorMessage =
                "No schedule was selected.";

        } else {
            try {
                scheduleId =
                    Integer.parseInt(
                        scheduleIdParameter.trim()
                    );

            } catch (NumberFormatException e) {
                errorMessage =
                    "Invalid schedule information.";
            }
        }

        if (errorMessage == null) {
            con = db.getConnection();

            if (con == null) {
                throw new SQLException(
                    "Could not connect to the database."
                );
            }

            String scheduleQuery =
                "SELECT " +
                    "schedule_id, " +
                    "train_id, " +
                    "line_name, " +
                    "departure_datetime, " +
                    "arrival_datetime " +
                "FROM trainschedule " +
                "WHERE schedule_id = ?";

            scheduleStatement =
                con.prepareStatement(scheduleQuery);

            scheduleStatement.setInt(
                1,
                scheduleId
            );

            scheduleResult =
                scheduleStatement.executeQuery();

            SimpleDateFormat dateTimeFormat =
                new SimpleDateFormat(
                    "MMM d, yyyy h:mm a"
                );

            if (scheduleResult.next()) {
                lineName =
                    scheduleResult.getString(
                        "line_name"
                    );

                trainId =
                    String.valueOf(
                        scheduleResult.getInt(
                            "train_id"
                        )
                    );

                Timestamp departureTimestamp =
                    scheduleResult.getTimestamp(
                        "departure_datetime"
                    );

                Timestamp arrivalTimestamp =
                    scheduleResult.getTimestamp(
                        "arrival_datetime"
                    );

                scheduleDeparture =
                    departureTimestamp == null
                        ? ""
                        : dateTimeFormat.format(
                            departureTimestamp
                        );

                scheduleArrival =
                    arrivalTimestamp == null
                        ? ""
                        : dateTimeFormat.format(
                            arrivalTimestamp
                        );

            } else {
                errorMessage =
                    "The selected schedule does not exist.";
            }

            if (errorMessage == null) {

                String stopQuery =
                    "SELECT " +
                        "sss.stop_number, " +
                        "sss.station_id, " +
                        "s.name, " +
                        "s.city, " +
                        "s.state, " +
                        "sss.arrival_datetime, " +
                        "sss.departure_datetime " +

                    "FROM schedule_station_stops sss " +

                    "JOIN station s " +
                        "ON sss.station_id = s.station_id " +

                    "WHERE sss.schedule_id = ? " +

                    "ORDER BY sss.stop_number";

                stopStatement =
                    con.prepareStatement(stopQuery);

                stopStatement.setInt(
                    1,
                    scheduleId
                );

                stopResult =
                    stopStatement.executeQuery();

                while (stopResult.next()) {
                    HashMap<String, String> stop =
                        new HashMap<String, String>();

                    stop.put(
                        "stopNumber",
                        String.valueOf(
                            stopResult.getInt(
                                "stop_number"
                            )
                        )
                    );

                    stop.put(
                        "stationId",
                        String.valueOf(
                            stopResult.getInt(
                                "station_id"
                            )
                        )
                    );

                    stop.put(
                        "stationName",
                        stopResult.getString("name")
                    );

                    stop.put(
                        "city",
                        stopResult.getString("city")
                    );

                    stop.put(
                        "state",
                        stopResult.getString("state")
                    );

                    Timestamp arrivalTimestamp =
                        stopResult.getTimestamp(
                            "arrival_datetime"
                        );

                    Timestamp departureTimestamp =
                        stopResult.getTimestamp(
                            "departure_datetime"
                        );

                    stop.put(
                        "arrivalDateTime",
                        arrivalTimestamp == null
                            ? "Origin"
                            : dateTimeFormat.format(
                                arrivalTimestamp
                            )
                    );

                    stop.put(
                        "departureDateTime",
                        departureTimestamp == null
                            ? "Final destination"
                            : dateTimeFormat.format(
                                departureTimestamp
                            )
                    );

                    stops.add(stop);
                }
            }
        }

    } catch (SQLException e) {
        e.printStackTrace();

        errorMessage =
            "A database error occurred: "
            + e.getMessage();

    } finally {
        try {
            if (stopResult != null) {
                stopResult.close();
            }

            if (stopStatement != null) {
                stopStatement.close();
            }

            if (scheduleResult != null) {
                scheduleResult.close();
            }

            if (scheduleStatement != null) {
                scheduleStatement.close();
            }

            if (con != null) {
                db.closeConnection(con);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">

    <title>Schedule Stops</title>

    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 30px;
            background-color: #f5f5f5;
        }

        .page-container {
            max-width: 950px;
            margin: 0 auto;
            padding: 28px;
            background-color: white;
            border: 1px solid #cccccc;
            border-radius: 6px;
        }

        h1 {
            margin-top: 0;
        }

        .schedule-details {
            padding: 15px;
            margin-bottom: 20px;
            border: 1px solid #cccccc;
            background-color: #f1f1f1;
        }

        .schedule-details p {
            margin: 7px 0;
        }

        .error {
            padding: 12px;
            margin-bottom: 18px;
            border: 1px solid #cc0000;
            background-color: #ffecec;
            color: #990000;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 15px;
        }

        th,
        td {
            padding: 9px;
            border: 1px solid #999999;
            text-align: left;
        }

        th {
            background-color: #eeeeee;
        }

        .selected-origin {
            background-color: #e8f4ff;
        }

        .selected-destination {
            background-color: #e9f7e9;
        }

        .back-link {
            display: inline-block;
            margin-top: 24px;
        }
    </style>
</head>

<body>

<div class="page-container">

    <h1>All Schedule Stops</h1>

    <%
        if (errorMessage != null) {
    %>

        <div class="error">
            <%= escapeHtml(errorMessage) %>
        </div>

    <%
        } else {
    %>

        <div class="schedule-details">
            <p>
                <strong>Transit line:</strong>
                <%= escapeHtml(lineName) %>
            </p>

            <p>
                <strong>Train:</strong>
                <%= escapeHtml(trainId) %>
            </p>

            <p>
                <strong>Full schedule departure:</strong>
                <%= escapeHtml(scheduleDeparture) %>
            </p>

            <p>
                <strong>Full schedule arrival:</strong>
                <%= escapeHtml(scheduleArrival) %>
            </p>
        </div>

        <%
            if (stops.isEmpty()) {
        %>

            <p>
                No stops were found for this schedule.
            </p>

        <%
            } else {
        %>

            <table>
                <thead>
                    <tr>
                        <th>Stop #</th>
                        <th>Station</th>
                        <th>City</th>
                        <th>State</th>
                        <th>Arrival</th>
                        <th>Departure</th>
                    </tr>
                </thead>

                <tbody>

                <%
                    for (
                        HashMap<String, String> stop
                            : stops
                    ) {

                        String rowClass = "";

                        if (stop.get("stationId")
                                .equals(origin)) {

                            rowClass =
                                "selected-origin";

                        } else if (
                            stop.get("stationId")
                                .equals(destination)
                        ) {

                            rowClass =
                                "selected-destination";
                        }
                %>

                    <tr class="<%= rowClass %>">
                        <td>
                            <%= escapeHtml(
                                stop.get("stopNumber")
                            ) %>
                        </td>

                        <td>
                            <%= escapeHtml(
                                stop.get("stationName")
                            ) %>

                            <%
                                if (stop.get("stationId")
                                        .equals(origin)) {
                            %>

                                <strong>
                                    (Your origin)
                                </strong>

                            <%
                                } else if (
                                    stop.get("stationId")
                                        .equals(destination)
                                ) {
                            %>

                                <strong>
                                    (Your destination)
                                </strong>

                            <%
                                }
                            %>
                        </td>

                        <td>
                            <%= escapeHtml(
                                stop.get("city")
                            ) %>
                        </td>

                        <td>
                            <%= escapeHtml(
                                stop.get("state")
                            ) %>
                        </td>

                        <td>
                            <%= escapeHtml(
                                stop.get(
                                    "arrivalDateTime"
                                )
                            ) %>
                        </td>

                        <td>
                            <%= escapeHtml(
                                stop.get(
                                    "departureDateTime"
                                )
                            ) %>
                        </td>
                    </tr>

                <%
                    }
                %>

                </tbody>
            </table>

        <%
            }
        }
    %>

    <a
        class="back-link"
        href="<%= request.getContextPath() %>/customer/search.jsp?origin=<%= escapeHtml(origin) %>&destination=<%= escapeHtml(destination) %>&travelDate=<%= escapeHtml(travelDate) %>&sortBy=<%= escapeHtml(sortBy) %>&search=true">

        Back to Search Results
    </a>

</div>

</body>
</html>