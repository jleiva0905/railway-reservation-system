<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"
    import="java.sql.*"
    import="java.util.*"
    import="java.text.*"
    import="java.math.BigDecimal"
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
    String userType = (String) session.getAttribute("userType");
    String employeeRole = (String) session.getAttribute("employeeRole");

    if (!"employee".equals(userType)
            || !"manager".equals(employeeRole)) {
        response.sendRedirect(
            request.getContextPath() + "/login.jsp"
        );
        return;
    }

    String reportType = request.getParameter("reportType");

    if (!"customer".equals(reportType)) {
        reportType = "line";
    }

    String selectedLine = request.getParameter("lineName");
    String customerSearch = request.getParameter("customerSearch");

    if (selectedLine != null) {
        selectedLine = selectedLine.trim();
    }

    if (customerSearch != null) {
        customerSearch = customerSearch.trim();
    }

    boolean searchSubmitted =
        request.getParameter("search") != null;

    String errorMessage = null;

    ArrayList<String> transitLines =
        new ArrayList<String>();

    ArrayList<HashMap<String, String>> reservationRows =
        new ArrayList<HashMap<String, String>>();

    ApplicationDB db = new ApplicationDB();
    Connection con = null;

    PreparedStatement lineStatement = null;
    PreparedStatement reportStatement = null;

    ResultSet lineResult = null;
    ResultSet reportResult = null;

    try {
        con = db.getConnection();

        if (con == null) {
            throw new SQLException(
                "Could not connect to the database."
            );
        }

        String lineQuery =
            "SELECT line_name " +
            "FROM transitline " +
            "ORDER BY line_name";

        lineStatement = con.prepareStatement(lineQuery);
        lineResult = lineStatement.executeQuery();

        while (lineResult.next()) {
            transitLines.add(
                lineResult.getString("line_name")
            );
        }

        if (searchSubmitted) {
            if ("line".equals(reportType)) {
                if (selectedLine == null
                        || selectedLine.isEmpty()) {
                    errorMessage =
                        "Please select a transit line.";
                } else {
                    String reportQuery =
                        "SELECT " +
                            "r.reservation_number, " +
                            "r.customer_username, " +
                            "c.first_name, " +
                            "c.last_name, " +
                            "ts.line_name, " +
                            "departure_station.name " +
                                "AS departure_station_name, " +
                            "arrival_station.name " +
                                "AS arrival_station_name, " +
                            "ts.departure_datetime, " +
                            "ts.arrival_datetime, " +
                            "r.date_made, " +
                            "r.trip_type, " +
                            "r.total_fare " +
                        "FROM reservation r " +
                        "JOIN customer c " +
                            "ON r.customer_username = c.username " +
                        "JOIN trainschedule ts " +
                            "ON r.schedule_id = ts.schedule_id " +
                        "JOIN station departure_station " +
                            "ON r.departure_station_id = " +
                                "departure_station.station_id " +
                        "JOIN station arrival_station " +
                            "ON r.arrival_station_id = " +
                                "arrival_station.station_id " +
                        "WHERE ts.line_name = ? " +
                        "ORDER BY ts.departure_datetime, " +
                            "r.reservation_number";

                    reportStatement =
                        con.prepareStatement(reportQuery);

                    reportStatement.setString(
                        1,
                        selectedLine
                    );
                }
            } else {
                if (customerSearch == null
                        || customerSearch.isEmpty()) {
                    errorMessage =
                        "Please enter a customer search.";
                } else {
                    String reportQuery =
                        "SELECT " +
                            "r.reservation_number, " +
                            "r.customer_username, " +
                            "c.first_name, " +
                            "c.last_name, " +
                            "ts.line_name, " +
                            "departure_station.name " +
                                "AS departure_station_name, " +
                            "arrival_station.name " +
                                "AS arrival_station_name, " +
                            "ts.departure_datetime, " +
                            "ts.arrival_datetime, " +
                            "r.date_made, " +
                            "r.trip_type, " +
                            "r.total_fare " +
                        "FROM reservation r " +
                        "JOIN customer c " +
                            "ON r.customer_username = c.username " +
                        "JOIN trainschedule ts " +
                            "ON r.schedule_id = ts.schedule_id " +
                        "JOIN station departure_station " +
                            "ON r.departure_station_id = " +
                                "departure_station.station_id " +
                        "JOIN station arrival_station " +
                            "ON r.arrival_station_id = " +
                                "arrival_station.station_id " +
                        "WHERE c.username LIKE ? " +
                            "OR c.first_name LIKE ? " +
                            "OR c.last_name LIKE ? " +
                            "OR CONCAT(c.first_name, ' ', " +
                                "c.last_name) LIKE ? " +
                            "OR c.email_address LIKE ? " +
                        "ORDER BY c.last_name, c.first_name, " +
                            "ts.departure_datetime, " +
                            "r.reservation_number";

                    reportStatement =
                        con.prepareStatement(reportQuery);

                    String searchPattern =
                        "%" + customerSearch + "%";

                    reportStatement.setString(
                        1,
                        searchPattern
                    );

                    reportStatement.setString(
                        2,
                        searchPattern
                    );

                    reportStatement.setString(
                        3,
                        searchPattern
                    );

                    reportStatement.setString(
                        4,
                        searchPattern
                    );

                    reportStatement.setString(
                        5,
                        searchPattern
                    );
                }
            }

            if (errorMessage == null
                    && reportStatement != null) {
                reportResult =
                    reportStatement.executeQuery();

                SimpleDateFormat dateTimeFormat =
                    new SimpleDateFormat(
                        "MM/dd/yyyy hh:mm a"
                    );

                while (reportResult.next()) {
                    HashMap<String, String> row =
                        new HashMap<String, String>();

                    row.put(
                        "reservationNumber",
                        String.valueOf(
                            reportResult.getInt(
                                "reservation_number"
                            )
                        )
                    );

                    row.put(
                        "customerUsername",
                        reportResult.getString(
                            "customer_username"
                        )
                    );

                    row.put(
                        "customerName",
                        reportResult.getString(
                            "first_name"
                        )
                        + " "
                        + reportResult.getString(
                            "last_name"
                        )
                    );

                    row.put(
                        "lineName",
                        reportResult.getString(
                            "line_name"
                        )
                    );

                    row.put(
                        "departureStation",
                        reportResult.getString(
                            "departure_station_name"
                        )
                    );

                    row.put(
                        "arrivalStation",
                        reportResult.getString(
                            "arrival_station_name"
                        )
                    );

                    Timestamp departure =
                        reportResult.getTimestamp(
                            "departure_datetime"
                        );

                    Timestamp arrival =
                        reportResult.getTimestamp(
                            "arrival_datetime"
                        );

                    Timestamp dateMade =
                        reportResult.getTimestamp(
                            "date_made"
                        );

                    row.put(
                        "departureDatetime",
                        departure == null
                            ? ""
                            : dateTimeFormat.format(
                                departure
                            )
                    );

                    row.put(
                        "arrivalDatetime",
                        arrival == null
                            ? ""
                            : dateTimeFormat.format(
                                arrival
                            )
                    );

                    row.put(
                        "dateMade",
                        dateMade == null
                            ? ""
                            : dateTimeFormat.format(
                                dateMade
                            )
                    );

                    row.put(
                        "tripType",
                        reportResult.getString(
                            "trip_type"
                        )
                    );

                    BigDecimal totalFare =
                        reportResult.getBigDecimal(
                            "total_fare"
                        );

                    row.put(
                        "totalFare",
                        totalFare == null
                            ? "0.00"
                            : totalFare.toPlainString()
                    );

                    reservationRows.add(row);
                }
            }
        }

    } catch (SQLException e) {
        e.printStackTrace();

        errorMessage =
            "Database error: " + e.getMessage();

    } finally {
        try {
            if (reportResult != null) {
                reportResult.close();
            }

            if (lineResult != null) {
                lineResult.close();
            }

            if (reportStatement != null) {
                reportStatement.close();
            }

            if (lineStatement != null) {
                lineStatement.close();
            }

            if (con != null) {
                db.closeConnection(con);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    DecimalFormat moneyFormat =
        new DecimalFormat("#,##0.00");
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">

    <title>Reservation Report</title>

    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 30px;
        }

        .report-form {
            border: 1px solid #999;
            padding: 20px;
            width: 540px;
            margin-bottom: 25px;
        }

        .report-type,
        .selection-section {
            margin-bottom: 20px;
        }

        .report-type label {
            margin-right: 20px;
        }

        select,
        input[type="text"] {
            width: 300px;
            padding: 7px;
            box-sizing: border-box;
        }

        input[type="submit"] {
            padding: 8px 15px;
            cursor: pointer;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 15px;
        }

        th,
        td {
            border: 1px solid #777;
            padding: 8px;
            text-align: left;
        }

        th {
            background-color: #eeeeee;
        }

        .error {
            color: red;
            font-weight: bold;
        }

        .summary {
            font-weight: bold;
        }

        .help-text {
            color: #555;
            font-size: 13px;
            margin-top: 6px;
        }

        .back-link {
            display: inline-block;
            margin-top: 25px;
        }
    </style>

    <script>
        function updateReportSelection() {
            var lineSelected =
                document.getElementById(
                    "reportTypeLine"
                ).checked;

            var lineSection =
                document.getElementById(
                    "lineSelection"
                );

            var customerSection =
                document.getElementById(
                    "customerSelection"
                );

            var lineInput =
                document.getElementById(
                    "lineName"
                );

            var customerInput =
                document.getElementById(
                    "customerSearch"
                );

            if (lineSelected) {
                lineSection.style.display = "block";
                customerSection.style.display = "none";

                lineInput.required = true;
                customerInput.required = false;
            } else {
                lineSection.style.display = "none";
                customerSection.style.display = "block";

                lineInput.required = false;
                customerInput.required = true;
            }
        }

        window.onload = updateReportSelection;
    </script>
</head>

<body>

    <h1>Reservation Report</h1>

    <p>
        View reservations by transit line or search
        for reservations made by a customer.
    </p>

    <form
        class="report-form"
        method="get"
        action="<%= request.getContextPath() %>/manager/reservationReport.jsp">

        <div class="report-type">
            <strong>Report Type:</strong>

            <br><br>

            <label>
                <input
                    type="radio"
                    id="reportTypeLine"
                    name="reportType"
                    value="line"
                    onchange="updateReportSelection()"
                    <%= "line".equals(reportType)
                        ? "checked"
                        : "" %>>

                By Transit Line
            </label>

            <label>
                <input
                    type="radio"
                    id="reportTypeCustomer"
                    name="reportType"
                    value="customer"
                    onchange="updateReportSelection()"
                    <%= "customer".equals(reportType)
                        ? "checked"
                        : "" %>>

                By Customer
            </label>
        </div>

        <div
            id="lineSelection"
            class="selection-section">

            <label for="lineName">
                <strong>Transit Line:</strong>
            </label>

            <br><br>

            <select
                id="lineName"
                name="lineName">

                <option value="">
                    -- Select a transit line --
                </option>

                <%
                    for (String lineName : transitLines) {
                %>

                    <option
                        value="<%= escapeHtml(lineName) %>"
                        <%= lineName.equals(selectedLine)
                            ? "selected"
                            : "" %>>

                        <%= escapeHtml(lineName) %>
                    </option>

                <%
                    }
                %>
            </select>
        </div>

        <div
            id="customerSelection"
            class="selection-section">

            <label for="customerSearch">
                <strong>Customer Search:</strong>
            </label>

            <br><br>

            <input
                type="text"
                id="customerSearch"
                name="customerSearch"
                value="<%= escapeHtml(customerSearch) %>"
                placeholder="Username, name, or email">

            <div class="help-text">
                You may enter a full or partial username,
                first name, last name, full name, or email.
            </div>
        </div>

        <input
            type="hidden"
            name="search"
            value="true">

        <input
            type="submit"
            value="View Reservations">
    </form>

    <%
        if (errorMessage != null) {
    %>

        <p class="error">
            <%= escapeHtml(errorMessage) %>
        </p>

    <%
        } else if (searchSubmitted) {
    %>

        <%
            if ("line".equals(reportType)) {
        %>

            <h2>
                Reservations for Transit Line:
                <%= escapeHtml(selectedLine) %>
            </h2>

        <%
            } else {
        %>

            <h2>
                Customer Search Results:
                <%= escapeHtml(customerSearch) %>
            </h2>

        <%
            }
        %>

        <%
            if (reservationRows.isEmpty()) {
        %>

            <p>
                No matching reservations were found.
            </p>

        <%
            } else {
        %>

            <p class="summary">
                Number of reservations:
                <%= reservationRows.size() %>
            </p>

            <table>
                <tr>
                    <th>Reservation Number</th>

                    <%
                        if ("line".equals(reportType)) {
                    %>

                        <th>Customer</th>
                        <th>Username</th>

                    <%
                        } else {
                    %>

                        <th>Customer</th>
                        <th>Username</th>
                        <th>Transit Line</th>

                    <%
                        }
                    %>

                    <th>Departure Station</th>
                    <th>Arrival Station</th>
                    <th>Departure Date and Time</th>
                    <th>Arrival Date and Time</th>
                    <th>Reservation Date</th>
                    <th>Trip Type</th>
                    <th>Total Fare</th>
                </tr>

                <%
                    for (
                        HashMap<String, String> row
                            : reservationRows
                    ) {
                %>

                    <tr>
                        <td>
                            <%= escapeHtml(
                                row.get(
                                    "reservationNumber"
                                )
                            ) %>
                        </td>

                        <td>
                            <%= escapeHtml(
                                row.get(
                                    "customerName"
                                )
                            ) %>
                        </td>

                        <td>
                            <%= escapeHtml(
                                row.get(
                                    "customerUsername"
                                )
                            ) %>
                        </td>

                        <%
                            if ("customer".equals(
                                    reportType
                                )) {
                        %>

                            <td>
                                <%= escapeHtml(
                                    row.get(
                                        "lineName"
                                    )
                                ) %>
                            </td>

                        <%
                            }
                        %>

                        <td>
                            <%= escapeHtml(
                                row.get(
                                    "departureStation"
                                )
                            ) %>
                        </td>

                        <td>
                            <%= escapeHtml(
                                row.get(
                                    "arrivalStation"
                                )
                            ) %>
                        </td>

                        <td>
                            <%= escapeHtml(
                                row.get(
                                    "departureDatetime"
                                )
                            ) %>
                        </td>

                        <td>
                            <%= escapeHtml(
                                row.get(
                                    "arrivalDatetime"
                                )
                            ) %>
                        </td>

                        <td>
                            <%= escapeHtml(
                                row.get(
                                    "dateMade"
                                )
                            ) %>
                        </td>

                        <td>
                            <%= escapeHtml(
                                row.get(
                                    "tripType"
                                )
                            ) %>
                        </td>

                        <td>
                            $<%= moneyFormat.format(
                                Double.parseDouble(
                                    row.get(
                                        "totalFare"
                                    )
                                )
                            ) %>
                        </td>
                    </tr>

                <%
                    }
                %>
            </table>

        <%
            }
        }
    %>

    <a
        class="back-link"
        href="<%= request.getContextPath() %>/manager/m_home.jsp">

        Back to Manager Home
    </a>

</body>
</html>