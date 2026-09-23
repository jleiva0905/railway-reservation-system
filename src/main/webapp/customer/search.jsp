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

    origin = origin.trim();
    destination = destination.trim();
    travelDate = travelDate.trim();
    sortBy = sortBy.trim();

    boolean searchSubmitted =
        request.getParameter("search") != null;

    String errorMessage = null;

    ArrayList<HashMap<String, String>> stations =
        new ArrayList<HashMap<String, String>>();

    ArrayList<HashMap<String, String>> schedules =
        new ArrayList<HashMap<String, String>>();

    ApplicationDB db =
        new ApplicationDB();

    Connection con = null;

    PreparedStatement stationStatement = null;
    PreparedStatement scheduleStatement = null;

    ResultSet stationResult = null;
    ResultSet scheduleResult = null;

    try {
        con = db.getConnection();

        if (con == null) {
            throw new SQLException(
                "Could not connect to the database."
            );
        }

        /*
         * Load stations for the two dropdown menus.
         */
        String stationQuery =
            "SELECT " +
                "station_id, " +
                "name, " +
                "city, " +
                "state " +
            "FROM station " +
            "ORDER BY state, city, name";

        stationStatement =
            con.prepareStatement(stationQuery);

        stationResult =
            stationStatement.executeQuery();

        while (stationResult.next()) {
            HashMap<String, String> station =
                new HashMap<String, String>();

            station.put(
                "stationId",
                String.valueOf(
                    stationResult.getInt("station_id")
                )
            );

            station.put(
                "name",
                stationResult.getString("name")
            );

            station.put(
                "city",
                stationResult.getString("city")
            );

            station.put(
                "state",
                stationResult.getString("state")
            );

            stations.add(station);
        }

        /*
         * Process the schedule search.
         */
        if (searchSubmitted) {
            int originId = 0;
            int destinationId = 0;

            if (origin.isEmpty()
                    || destination.isEmpty()
                    || travelDate.isEmpty()) {

                errorMessage =
                    "Select an origin, destination, and travel date.";

            } else {
                try {
                    originId =
                        Integer.parseInt(origin);

                    destinationId =
                        Integer.parseInt(destination);

                } catch (NumberFormatException e) {
                    errorMessage =
                        "Invalid station selection.";
                }
            }

            if (errorMessage == null
                    && originId == destinationId) {

                errorMessage =
                    "Origin and destination must be different.";
            }

            /*
             * Choose the ORDER BY clause from an approved
             * set of choices.
             *
             * The request value is never inserted directly
             * into the SQL statement.
             */
            String orderByClause =
                "origin_stop.departure_datetime ASC";

            if ("arrival_asc".equals(sortBy)) {

                orderByClause =
                    "destination_stop.arrival_datetime ASC";

            } else if ("fare_asc".equals(sortBy)) {

                orderByClause =
                    "calculated_fare ASC";

            } else if ("fare_desc".equals(sortBy)) {

                orderByClause =
                    "calculated_fare DESC";

            } else {

                sortBy =
                    "departure_asc";
            }

            if (errorMessage == null) {

                /*
                 * Fare calculation:
                 *
                 * 1. Find the number of segments in the
                 *    schedule.
                 *
                 * 2. Divide the transit line's full base
                 *    fare by the number of segments.
                 *
                 * 3. Multiply by the number of segments
                 *    traveled by this customer.
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

                        "origin_stop.departure_datetime " +
                            "AS selected_departure_datetime, " +

                        "destination_stop.arrival_datetime " +
                            "AS selected_arrival_datetime, " +

                        "origin_stop.stop_number " +
                            "AS origin_stop_number, " +

                        "destination_stop.stop_number " +
                            "AS destination_stop_number, " +

                        "ROUND(" +
                            "(" +
                                "tl.base_fare / " +
                                "NULLIF(" +
                                    "route_information.total_segments, " +
                                    "0" +
                                ")" +
                            ") * " +
                            "(" +
                                "destination_stop.stop_number - " +
                                "origin_stop.stop_number" +
                            "), " +
                            "2" +
                        ") AS calculated_fare " +

                    "FROM trainschedule ts " +

                    "JOIN transitline tl " +
                        "ON ts.line_name = tl.line_name " +

                    "JOIN schedule_station_stops origin_stop " +
                        "ON ts.schedule_id = " +
                            "origin_stop.schedule_id " +

                    "JOIN schedule_station_stops destination_stop " +
                        "ON ts.schedule_id = " +
                            "destination_stop.schedule_id " +

                    "JOIN station origin_station " +
                        "ON origin_stop.station_id = " +
                            "origin_station.station_id " +

                    "JOIN station destination_station " +
                        "ON destination_stop.station_id = " +
                            "destination_station.station_id " +

                    "JOIN (" +

                        "SELECT " +
                            "schedule_id, " +
                            "MAX(stop_number) - " +
                            "MIN(stop_number) " +
                                "AS total_segments " +

                        "FROM schedule_station_stops " +

                        "GROUP BY schedule_id" +

                    ") route_information " +

                        "ON ts.schedule_id = " +
                            "route_information.schedule_id " +

                    "WHERE origin_stop.station_id = ? " +

                    "AND destination_stop.station_id = ? " +

                    "AND origin_stop.stop_number " +
                        "< destination_stop.stop_number " +

                    "AND DATE(" +
                        "origin_stop.departure_datetime" +
                    ") = ? " +

                    "ORDER BY " +
                        orderByClause;

                scheduleStatement =
                    con.prepareStatement(scheduleQuery);

                scheduleStatement.setInt(
                    1,
                    originId
                );

                scheduleStatement.setInt(
                    2,
                    destinationId
                );

                scheduleStatement.setString(
                    3,
                    travelDate
                );

                scheduleResult =
                    scheduleStatement.executeQuery();

                SimpleDateFormat dateTimeFormat =
                    new SimpleDateFormat(
                        "MMM d, yyyy h:mm a"
                    );

                DecimalFormat fareFormat =
                    new DecimalFormat("0.00");

                while (scheduleResult.next()) {
                    HashMap<String, String> schedule =
                        new HashMap<String, String>();

                    schedule.put(
                        "scheduleId",
                        String.valueOf(
                            scheduleResult.getInt(
                                "schedule_id"
                            )
                        )
                    );

                    schedule.put(
                        "trainId",
                        String.valueOf(
                            scheduleResult.getInt(
                                "train_id"
                            )
                        )
                    );

                    schedule.put(
                        "lineName",
                        scheduleResult.getString(
                            "line_name"
                        )
                    );

                    schedule.put(
                        "originName",
                        scheduleResult.getString(
                            "origin_name"
                        )
                    );

                    schedule.put(
                        "destinationName",
                        scheduleResult.getString(
                            "destination_name"
                        )
                    );

                    Timestamp departureTimestamp =
                        scheduleResult.getTimestamp(
                            "selected_departure_datetime"
                        );

                    Timestamp arrivalTimestamp =
                        scheduleResult.getTimestamp(
                            "selected_arrival_datetime"
                        );

                    schedule.put(
                        "departureDateTime",
                        departureTimestamp == null
                            ? ""
                            : dateTimeFormat.format(
                                departureTimestamp
                            )
                    );

                    schedule.put(
                        "arrivalDateTime",
                        arrivalTimestamp == null
                            ? ""
                            : dateTimeFormat.format(
                                arrivalTimestamp
                            )
                    );

                    double fare =
                        scheduleResult.getDouble(
                            "calculated_fare"
                        );

                    schedule.put(
                        "fare",
                        fareFormat.format(fare)
                    );

                    schedules.add(schedule);
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

    <title>Search Train Schedules</title>

    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 30px;
            background-color: #f5f5f5;
        }

        .page-container {
            max-width: 1250px;
            margin: 0 auto;
            background-color: white;
            padding: 28px;
            border: 1px solid #cccccc;
            border-radius: 6px;
        }

        h1,
        h2 {
            margin-top: 0;
        }

        .search-form {
            padding: 20px;
            margin-bottom: 25px;
            background-color: #f1f1f1;
            border: 1px solid #cccccc;
        }

        .form-row {
            display: flex;
            flex-wrap: wrap;
            gap: 18px;
            margin-bottom: 18px;
        }

        .form-group {
            min-width: 210px;
            flex: 1;
        }

        label {
            display: block;
            margin-bottom: 6px;
            font-weight: bold;
        }

        select,
        input[type="date"] {
            box-sizing: border-box;
            width: 100%;
            padding: 8px;
        }

        input[type="submit"],
        .button-link {
            display: inline-block;
            padding: 8px 13px;
            border: none;
            border-radius: 3px;
            background-color: #333333;
            color: white;
            text-decoration: none;
            cursor: pointer;
        }

        input[type="submit"]:hover,
        .button-link:hover {
            background-color: #555555;
        }

        .secondary-button {
            background-color: #555555;
        }

        .error {
            padding: 12px;
            margin-bottom: 18px;
            border: 1px solid #cc0000;
            background-color: #ffecec;
            color: #990000;
        }

        .results-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 15px;
        }

        .results-table th,
        .results-table td {
            padding: 9px;
            border: 1px solid #999999;
            text-align: left;
            vertical-align: middle;
        }

        .results-table th {
            background-color: #eeeeee;
        }

        .money {
            text-align: right;
            white-space: nowrap;
        }

        .date-cell {
            white-space: nowrap;
        }

        .action-cell {
            text-align: center;
            white-space: nowrap;
        }

        .reserve-form {
            margin: 0;
        }

        .back-link {
            display: inline-block;
            margin-top: 25px;
        }

        .search-summary {
            margin-bottom: 15px;
            color: #444444;
        }
    </style>
</head>

<body>

<div class="page-container">

    <h1>Search Train Schedules</h1>

    <p>
        Search by origin, destination, and date.
        Results may be sorted by departure time,
        arrival time, or fare.
    </p>

    <form
        class="search-form"
        action="<%= request.getContextPath() %>/customer/search.jsp"
        method="get">

        <div class="form-row">

            <div class="form-group">
                <label for="origin">
                    Origin station
                </label>

                <select
                    id="origin"
                    name="origin"
                    required>

                    <option value="">
                        Select origin
                    </option>

                    <%
                        for (
                            HashMap<String, String> station
                                : stations
                        ) {

                            String stationId =
                                station.get("stationId");
                    %>

                        <option
                            value="<%= escapeHtml(stationId) %>"
                            <%= stationId.equals(origin)
                                ? "selected"
                                : "" %>>

                            <%= escapeHtml(
                                station.get("name")
                            ) %>
                            -
                            <%= escapeHtml(
                                station.get("city")
                            ) %>,
                            <%= escapeHtml(
                                station.get("state")
                            ) %>
                        </option>

                    <%
                        }
                    %>

                </select>
            </div>

            <div class="form-group">
                <label for="destination">
                    Destination station
                </label>

                <select
                    id="destination"
                    name="destination"
                    required>

                    <option value="">
                        Select destination
                    </option>

                    <%
                        for (
                            HashMap<String, String> station
                                : stations
                        ) {

                            String stationId =
                                station.get("stationId");
                    %>

                        <option
                            value="<%= escapeHtml(stationId) %>"
                            <%= stationId.equals(destination)
                                ? "selected"
                                : "" %>>

                            <%= escapeHtml(
                                station.get("name")
                            ) %>
                            -
                            <%= escapeHtml(
                                station.get("city")
                            ) %>,
                            <%= escapeHtml(
                                station.get("state")
                            ) %>
                        </option>

                    <%
                        }
                    %>

                </select>
            </div>

            <div class="form-group">
                <label for="travelDate">
                    Travel date
                </label>

                <input
                    type="date"
                    id="travelDate"
                    name="travelDate"
                    value="<%= escapeHtml(travelDate) %>"
                    required>
            </div>

            <div class="form-group">
                <label for="sortBy">
                    Sort results by
                </label>

                <select
                    id="sortBy"
                    name="sortBy">

                    <option
                        value="departure_asc"
                        <%= "departure_asc".equals(sortBy)
                            ? "selected"
                            : "" %>>

                        Departure Time
                    </option>

                    <option
                        value="arrival_asc"
                        <%= "arrival_asc".equals(sortBy)
                            ? "selected"
                            : "" %>>

                        Arrival Time
                    </option>

                    <option
                        value="fare_asc"
                        <%= "fare_asc".equals(sortBy)
                            ? "selected"
                            : "" %>>

                        Fare: Low to High
                    </option>

                    <option
                        value="fare_desc"
                        <%= "fare_desc".equals(sortBy)
                            ? "selected"
                            : "" %>>

                        Fare: High to Low
                    </option>

                </select>
            </div>

        </div>

        <input
            type="hidden"
            name="search"
            value="true">

        <input
            type="submit"
            value="Search Schedules">

    </form>

    <%
        if (errorMessage != null) {
    %>

        <div class="error">
            <%= escapeHtml(errorMessage) %>
        </div>

    <%
        }
    %>

    <%
        if (searchSubmitted
                && errorMessage == null) {
    %>

        <h2>Search Results</h2>

        <p class="search-summary">
            Found
            <strong><%= schedules.size() %></strong>
            matching schedule<%= schedules.size() == 1
                ? ""
                : "s" %>.
        </p>

        <%
            if (schedules.isEmpty()) {
        %>

            <p>
                No schedules were found for the selected
                route and travel date.
            </p>

        <%
            } else {
        %>

            <table class="results-table">

                <thead>
                    <tr>
                        <th>Transit Line</th>
                        <th>Train</th>
                        <th>Origin</th>
                        <th>Destination</th>
                        <th>Departure</th>
                        <th>Arrival</th>
                        <th>One-Way Fare</th>
                        <th>Stops</th>
                        <th>Reserve</th>
                    </tr>
                </thead>

                <tbody>

                <%
                    for (
                        HashMap<String, String> schedule
                            : schedules
                    ) {
                %>

                    <tr>
                        <td>
                            <%= escapeHtml(
                                schedule.get("lineName")
                            ) %>
                        </td>

                        <td>
                            <%= escapeHtml(
                                schedule.get("trainId")
                            ) %>
                        </td>

                        <td>
                            <%= escapeHtml(
                                schedule.get("originName")
                            ) %>
                        </td>

                        <td>
                            <%= escapeHtml(
                                schedule.get(
                                    "destinationName"
                                )
                            ) %>
                        </td>

                        <td class="date-cell">
                            <%= escapeHtml(
                                schedule.get(
                                    "departureDateTime"
                                )
                            ) %>
                        </td>

                        <td class="date-cell">
                            <%= escapeHtml(
                                schedule.get(
                                    "arrivalDateTime"
                                )
                            ) %>
                        </td>

                        <td class="money">
                            $<%= escapeHtml(
                                schedule.get("fare")
                            ) %>
                        </td>

                        <td class="action-cell">

                            <a
                                class="button-link secondary-button"
                                href="<%= request.getContextPath() %>/customer/viewScheduleStops.jsp?scheduleId=<%= escapeHtml(schedule.get("scheduleId")) %>&origin=<%= escapeHtml(origin) %>&destination=<%= escapeHtml(destination) %>&travelDate=<%= escapeHtml(travelDate) %>&sortBy=<%= escapeHtml(sortBy) %>">

                                View Stops
                            </a>

                        </td>

                        <td class="action-cell">

                            <form
                                class="reserve-form"
                                action="<%= request.getContextPath() %>/customer/reservation.jsp"
                                method="post">

                                <input
                                    type="hidden"
                                    name="scheduleId"
                                    value="<%= escapeHtml(
                                        schedule.get(
                                            "scheduleId"
                                        )
                                    ) %>">

                                <input
                                    type="hidden"
                                    name="departureStationId"
                                    value="<%= escapeHtml(origin) %>">

                                <input
                                    type="hidden"
                                    name="arrivalStationId"
                                    value="<%= escapeHtml(
                                        destination
                                    ) %>">

                                <input
                                    type="hidden"
                                    name="travelDate"
                                    value="<%= escapeHtml(
                                        travelDate
                                    ) %>">

                                <input
                                    type="submit"
                                    value="Reserve">

                            </form>

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
        href="<%= request.getContextPath() %>/customer/c_home.jsp">

        Back to Customer Home
    </a>

</div>

</body>
</html>