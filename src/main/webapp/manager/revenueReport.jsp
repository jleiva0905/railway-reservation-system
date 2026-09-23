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
    String userType =
        (String) session.getAttribute("userType");

    String employeeRole =
        (String) session.getAttribute("employeeRole");

    if (!"employee".equals(userType)
            || !"manager".equals(employeeRole)) {

        response.sendRedirect(
            request.getContextPath() + "/login.jsp"
        );

        return;
    }

    String reportType =
        request.getParameter("reportType");

    if (!"customer".equals(reportType)) {
        reportType = "line";
    }

    String selectedLine =
        request.getParameter("lineName");

    String customerSearch =
        request.getParameter("customerSearch");

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

    ArrayList<HashMap<String, String>> revenueRows =
        new ArrayList<HashMap<String, String>>();

    ApplicationDB db =
        new ApplicationDB();

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

        /*
         * Load transit lines for the dropdown.
         */
        String lineQuery =
            "SELECT line_name " +
            "FROM transitline " +
            "ORDER BY line_name";

        lineStatement =
            con.prepareStatement(lineQuery);

        lineResult =
            lineStatement.executeQuery();

        while (lineResult.next()) {
            transitLines.add(
                lineResult.getString("line_name")
            );
        }

        /*
         * Run the selected revenue report.
         */
        if (searchSubmitted) {

            if ("line".equals(reportType)) {

                if (selectedLine == null
                        || selectedLine.isEmpty()) {

                    errorMessage =
                        "Please select a transit line.";

                } else {

                    String reportQuery =
                        "SELECT " +
                            "ts.line_name, " +
                            "COUNT(r.reservation_number) " +
                                "AS reservation_count, " +
                            "COALESCE(SUM(r.total_fare), 0) " +
                                "AS total_revenue " +
                        "FROM trainschedule ts " +
                        "LEFT JOIN reservation r " +
                            "ON ts.schedule_id = r.schedule_id " +
                        "WHERE ts.line_name = ? " +
                        "GROUP BY ts.line_name";

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
                            "c.username, " +
                            "c.first_name, " +
                            "c.last_name, " +
                            "c.email_address, " +
                            "COUNT(r.reservation_number) " +
                                "AS reservation_count, " +
                            "COALESCE(SUM(r.total_fare), 0) " +
                                "AS total_revenue " +
                        "FROM customer c " +
                        "LEFT JOIN reservation r " +
                            "ON c.username = " +
                                "r.customer_username " +
                        "WHERE c.username LIKE ? " +
                            "OR c.first_name LIKE ? " +
                            "OR c.last_name LIKE ? " +
                            "OR CONCAT(c.first_name, ' ', " +
                                "c.last_name) LIKE ? " +
                            "OR c.email_address LIKE ? " +
                        "GROUP BY " +
                            "c.username, " +
                            "c.first_name, " +
                            "c.last_name, " +
                            "c.email_address " +
                        "ORDER BY " +
                            "c.last_name, " +
                            "c.first_name, " +
                            "c.username";

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

                while (reportResult.next()) {

                    HashMap<String, String> row =
                        new HashMap<String, String>();

                    if ("line".equals(reportType)) {

                        row.put(
                            "lineName",
                            reportResult.getString(
                                "line_name"
                            )
                        );

                    } else {

                        row.put(
                            "customerUsername",
                            reportResult.getString(
                                "username"
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
                            "emailAddress",
                            reportResult.getString(
                                "email_address"
                            )
                        );
                    }

                    row.put(
                        "reservationCount",
                        String.valueOf(
                            reportResult.getInt(
                                "reservation_count"
                            )
                        )
                    );

                    BigDecimal totalRevenue =
                        reportResult.getBigDecimal(
                            "total_revenue"
                        );

                    row.put(
                        "totalRevenue",
                        totalRevenue == null
                            ? "0.00"
                            : totalRevenue.toPlainString()
                    );

                    revenueRows.add(row);
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

    BigDecimal combinedRevenue =
        BigDecimal.ZERO;

    int combinedReservationCount = 0;

    for (HashMap<String, String> row : revenueRows) {

        combinedReservationCount +=
            Integer.parseInt(
                row.get("reservationCount")
            );

        combinedRevenue =
            combinedRevenue.add(
                new BigDecimal(
                    row.get("totalRevenue")
                )
            );
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">

    <title>Revenue Report</title>

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

        .summary-box {
            border: 1px solid #999;
            padding: 15px;
            width: 380px;
            margin-top: 20px;
        }

        .summary-box p {
            margin: 6px 0;
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

    <h1>Revenue Report</h1>

    <p>
        View total revenue generated by a transit line
        or by a customer.
    </p>

    <form
        class="report-form"
        method="get"
        action="<%= request.getContextPath() %>/manager/revenueReport.jsp">

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
                Enter a full or partial username, first name,
                last name, full name, or email.
            </div>
        </div>

        <input
            type="hidden"
            name="search"
            value="true">

        <input
            type="submit"
            value="View Revenue">

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
                Revenue for Transit Line:
                <%= escapeHtml(selectedLine) %>
            </h2>

        <%
            } else {
        %>

            <h2>
                Customer Revenue Search:
                <%= escapeHtml(customerSearch) %>
            </h2>

        <%
            }
        %>

        <%
            if (revenueRows.isEmpty()) {
        %>

            <p>No matching results were found.</p>

        <%
            } else if ("line".equals(reportType)) {

                HashMap<String, String> row =
                    revenueRows.get(0);
        %>

            <table>
                <tr>
                    <th>Transit Line</th>
                    <th>Number of Reservations</th>
                    <th>Total Revenue</th>
                </tr>

                <tr>
                    <td>
                        <%= escapeHtml(
                            row.get("lineName")
                        ) %>
                    </td>

                    <td>
                        <%= escapeHtml(
                            row.get("reservationCount")
                        ) %>
                    </td>

                    <td>
                        $<%= moneyFormat.format(
                            new BigDecimal(
                                row.get("totalRevenue")
                            )
                        ) %>
                    </td>
                </tr>
            </table>

        <%
            } else {
        %>

            <table>
                <tr>
                    <th>Customer</th>
                    <th>Username</th>
                    <th>Email</th>
                    <th>Number of Reservations</th>
                    <th>Total Revenue</th>
                </tr>

                <%
                    for (
                        HashMap<String, String> row
                            : revenueRows
                    ) {
                %>

                    <tr>
                        <td>
                            <%= escapeHtml(
                                row.get("customerName")
                            ) %>
                        </td>

                        <td>
                            <%= escapeHtml(
                                row.get(
                                    "customerUsername"
                                )
                            ) %>
                        </td>

                        <td>
                            <%= escapeHtml(
                                row.get("emailAddress")
                            ) %>
                        </td>

                        <td>
                            <%= escapeHtml(
                                row.get(
                                    "reservationCount"
                                )
                            ) %>
                        </td>

                        <td>
                            $<%= moneyFormat.format(
                                new BigDecimal(
                                    row.get(
                                        "totalRevenue"
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
                if (revenueRows.size() > 1) {
            %>

                <div class="summary-box">
                    <strong>
                        Combined Search Results
                    </strong>

                    <p>
                        Matching customers:
                        <%= revenueRows.size() %>
                    </p>

                    <p>
                        Total reservations:
                        <%= combinedReservationCount %>
                    </p>

                    <p>
                        Combined revenue:
                        $<%= moneyFormat.format(
                            combinedRevenue
                        ) %>
                    </p>
                </div>

            <%
                }
            %>

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