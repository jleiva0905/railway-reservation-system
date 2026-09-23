<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"
    import="java.sql.*"
    import="java.util.*"
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

    String selectedLine =
        request.getParameter("lineName");

    String selectedDate =
        request.getParameter("travelDate");

    String searchParameter =
        request.getParameter("search");

    boolean searchSubmitted =
        searchParameter != null;

    if (selectedLine == null) {
        selectedLine = "";
    }

    if (selectedDate == null) {
        selectedDate = "";
    }

    selectedLine =
        selectedLine.trim();

    selectedDate =
        selectedDate.trim();

    ApplicationDB db =
        new ApplicationDB();

    Connection connection = null;

    PreparedStatement lineStatement = null;
    PreparedStatement customerStatement = null;

    ResultSet lineResult = null;
    ResultSet customerResult = null;

    try {

        connection =
            db.getConnection();

        if (connection == null) {

            throw new SQLException(
                "Could not connect to the database."
            );
        }

        /*
         * Load all transit lines for the dropdown.
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
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">

    <title>
        Search Customers with Reservations
    </title>
</head>

<body>

    <h1>
        Search Customers with Reservations
    </h1>

    <p>
        Search by transit line, travel date, both,
        or leave both fields empty to view all reservations.
    </p>

    <form
        action="viewCustomersByLineDate.jsp"
        method="get">

        <input
            type="hidden"
            name="search"
            value="true">

        <label for="lineName">
            Transit line:
        </label>

        <select
            id="lineName"
            name="lineName">

            <option value="">
                All transit lines
            </option>

            <%
                while (lineResult.next()) {

                    String lineName =
                        lineResult.getString(
                            "line_name"
                        );

                    boolean selected =
                        lineName.equals(
                            selectedLine
                        );
            %>

                <option
                    value="<%= lineName %>"
                    <%= selected
                        ? "selected"
                        : "" %>>

                    <%= lineName %>

                </option>

            <%
                }
            %>

        </select>

        <br><br>

        <label for="travelDate">
            Travel date:
        </label>

        <input
            type="date"
            id="travelDate"
            name="travelDate"
            value="<%= selectedDate %>">

        <br><br>

        <input
            type="submit"
            value="Search">

        <a href="viewCustomersByLineDate.jsp">
            Clear Search
        </a>

    </form>

    <hr>

<%
        if (searchSubmitted) {

            /*
             * departure_stop represents the station
             * from which the customer is departing.
             *
             * arrival_stop represents the station
             * at which the customer is arriving.
             */
            StringBuilder customerQuery =
                new StringBuilder();

            customerQuery.append(
                "SELECT " +

                "r.reservation_number, " +
                "c.username, " +
                "c.first_name, " +
                "c.last_name, " +

                "r.trip_type, " +
                "r.total_fare, " +

                "ts.schedule_id, " +
                "ts.train_id, " +
                "ts.line_name, " +

                "departure_station.name " +
                "AS departure_station_name, " +

                "arrival_station.name " +
                "AS arrival_station_name, " +

                "departure_stop.departure_datetime " +
                "AS customer_departure_datetime, " +

                "arrival_stop.arrival_datetime " +
                "AS customer_arrival_datetime " +

                "FROM reservation r " +

                "JOIN customer c " +
                "ON r.customer_username = c.username " +

                "JOIN trainschedule ts " +
                "ON r.schedule_id = ts.schedule_id " +

                /*
                 * Match the reservation's departure
                 * station to its stop in the schedule.
                 */
                "JOIN schedule_station_stops " +
                "departure_stop " +
                "ON r.schedule_id = " +
                "departure_stop.schedule_id " +
                "AND r.departure_station_id = " +
                "departure_stop.station_id " +

                /*
                 * Match the reservation's arrival
                 * station to its stop in the schedule.
                 */
                "JOIN schedule_station_stops " +
                "arrival_stop " +
                "ON r.schedule_id = " +
                "arrival_stop.schedule_id " +
                "AND r.arrival_station_id = " +
                "arrival_stop.station_id " +

                "JOIN station departure_station " +
                "ON r.departure_station_id = " +
                "departure_station.station_id " +

                "JOIN station arrival_station " +
                "ON r.arrival_station_id = " +
                "arrival_station.station_id " +

                "WHERE 1 = 1 "
            );

            /*
             * Store the search values in the same order
             * that the placeholders are added.
             */
            ArrayList<Object> searchValues =
                new ArrayList<Object>();

            if (!selectedLine.isEmpty()) {

                customerQuery.append(
                    "AND ts.line_name = ? "
                );

                searchValues.add(
                    selectedLine
                );
            }

            if (!selectedDate.isEmpty()) {

                /*
                 * Search using the customer's actual
                 * departure date at the selected station.
                 */
                customerQuery.append(
                    "AND DATE(" +
                    "departure_stop.departure_datetime" +
                    ") = ? "
                );

                searchValues.add(
                    java.sql.Date.valueOf(
                        selectedDate
                    )
                );
            }

            customerQuery.append(
                "ORDER BY " +
                "departure_stop.departure_datetime, " +
                "c.last_name, " +
                "c.first_name"
            );

            customerStatement =
                connection.prepareStatement(
                    customerQuery.toString()
                );

            for (int i = 0;
                    i < searchValues.size();
                    i++) {

                Object value =
                    searchValues.get(i);

                if (value instanceof String) {

                    customerStatement.setString(
                        i + 1,
                        (String) value
                    );

                } else if (
                    value instanceof java.sql.Date
                ) {

                    customerStatement.setDate(
                        i + 1,
                        (java.sql.Date) value
                    );
                }
            }

            customerResult =
                customerStatement.executeQuery();

            boolean foundCustomer = false;
%>

    <h2>
        Search Results
    </h2>

    <p>
        <strong>Transit line:</strong>

        <%= selectedLine.isEmpty()
            ? "All transit lines"
            : selectedLine %>

        <br>

        <strong>Travel date:</strong>

        <%= selectedDate.isEmpty()
            ? "All dates"
            : selectedDate %>
    </p>

    <table
        border="1"
        cellpadding="8">

        <tr>
            <th>Reservation Number</th>
            <th>Customer Username</th>
            <th>Customer Name</th>
            <th>Schedule ID</th>
            <th>Train</th>
            <th>Transit Line</th>
            <th>Departure Station</th>
            <th>Arrival Station</th>
            <th>Departure Time</th>
            <th>Arrival Time</th>
            <th>Trip Type</th>
            <th>Total Fare</th>
        </tr>

        <%
            while (customerResult.next()) {

                foundCustomer = true;
        %>

        <tr>

            <td>
                <%= customerResult.getInt(
                    "reservation_number"
                ) %>
            </td>

            <td>
                <%= customerResult.getString(
                    "username"
                ) %>
            </td>

            <td>
                <%= customerResult.getString(
                    "first_name"
                ) %>

                <%= customerResult.getString(
                    "last_name"
                ) %>
            </td>

            <td>
                <%= customerResult.getInt(
                    "schedule_id"
                ) %>
            </td>

            <td>
                <%= customerResult.getString(
                    "train_id"
                ) %>
            </td>

            <td>
                <%= customerResult.getString(
                    "line_name"
                ) %>
            </td>

            <td>
                <%= customerResult.getString(
                    "departure_station_name"
                ) %>
            </td>

            <td>
                <%= customerResult.getString(
                    "arrival_station_name"
                ) %>
            </td>

            <td>
                <%= customerResult.getTimestamp(
                    "customer_departure_datetime"
                ) %>
            </td>

            <td>
                <%= customerResult.getTimestamp(
                    "customer_arrival_datetime"
                ) %>
            </td>

            <td>
                <%= customerResult.getString(
                    "trip_type"
                ) %>
            </td>

            <td>
                $<%= String.format(
                    "%.2f",
                    customerResult.getDouble(
                        "total_fare"
                    )
                ) %>
            </td>

        </tr>

        <%
            }
        %>

    </table>

    <%
        if (!foundCustomer) {
    %>

        <p>
            No reservations matched the selected
            search criteria.
        </p>

    <%
        }
    %>

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
    } catch (IllegalArgumentException e) {

        e.printStackTrace();
%>

    <p style="color: red;">
        The selected date is invalid.
    </p>

    <a href="<%= request.getContextPath() %>/representative/viewCustomersByLineDate.jsp">
        Return to customer search
    </a>

<%
    } catch (SQLException e) {

        e.printStackTrace();
%>

    <p style="color: red;">
        A database error occurred while loading customers.
    </p>

    <a href="<%= request.getContextPath() %>/representative/r_home.jsp">
        Back to representative home
    </a>

<%
    } finally {

        try {

            if (customerResult != null) {
                customerResult.close();
            }

            if (customerStatement != null) {
                customerStatement.close();
            }

            if (lineResult != null) {
                lineResult.close();
            }

            if (lineStatement != null) {
                lineStatement.close();
            }

            if (connection != null) {
                db.closeConnection(
                    connection
                );
            }

        } catch (SQLException e) {

            e.printStackTrace();
        }
    }
%>