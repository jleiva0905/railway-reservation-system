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

    String employeeRole =
        (String) session.getAttribute("employeeRole");

    if (!"employee".equals(userType)
            || !"manager".equals(employeeRole)) {

        response.sendRedirect(
            request.getContextPath() + "/login.jsp"
        );

        return;
    }

    String monthParameter =
        request.getParameter("month");

    String yearParameter =
        request.getParameter("year");

    boolean reportSubmitted =
        request.getParameter("generate") != null;

    Calendar currentDate =
        Calendar.getInstance();

    int selectedMonth =
        currentDate.get(Calendar.MONTH) + 1;

    int selectedYear =
        currentDate.get(Calendar.YEAR);

    String errorMessage = null;

    if (monthParameter != null
            && !monthParameter.trim().isEmpty()) {

        try {
            selectedMonth =
                Integer.parseInt(
                    monthParameter.trim()
                );

        } catch (NumberFormatException e) {
            errorMessage =
                "Invalid month selection.";
        }
    }

    if (yearParameter != null
            && !yearParameter.trim().isEmpty()) {

        try {
            selectedYear =
                Integer.parseInt(
                    yearParameter.trim()
                );

        } catch (NumberFormatException e) {
            errorMessage =
                "Invalid year selection.";
        }
    }

    if (selectedMonth < 1
            || selectedMonth > 12) {

        errorMessage =
            "Invalid month selection.";
    }

    if (selectedYear < 1900
            || selectedYear > 9999) {

        errorMessage =
            "Invalid year selection.";
    }

    ArrayList<HashMap<String, String>> lineRows =
        new ArrayList<HashMap<String, String>>();

    ApplicationDB db =
        new ApplicationDB();

    Connection con = null;
    PreparedStatement statement = null;
    ResultSet result = null;

    try {
        if (reportSubmitted
                && errorMessage == null) {

            con = db.getConnection();

            if (con == null) {
                throw new SQLException(
                    "Could not connect to the database."
                );
            }

            String query =
                "SELECT " +
                    "ts.line_name, " +
                    "COUNT(r.reservation_number) " +
                        "AS reservation_count " +
                "FROM reservation r " +
                "JOIN trainschedule ts " +
                    "ON r.schedule_id = " +
                        "ts.schedule_id " +
                "WHERE MONTH(r.date_made) = ? " +
                    "AND YEAR(r.date_made) = ? " +
                "GROUP BY ts.line_name " +
                "ORDER BY " +
                    "reservation_count DESC, " +
                    "ts.line_name ASC " +
                "LIMIT 5";

            statement =
                con.prepareStatement(query);

            statement.setInt(
                1,
                selectedMonth
            );

            statement.setInt(
                2,
                selectedYear
            );

            result =
                statement.executeQuery();

            int rank = 1;

            while (result.next()) {

                HashMap<String, String> row =
                    new HashMap<String, String>();

                row.put(
                    "rank",
                    String.valueOf(rank)
                );

                row.put(
                    "lineName",
                    result.getString(
                        "line_name"
                    )
                );

                row.put(
                    "reservationCount",
                    String.valueOf(
                        result.getInt(
                            "reservation_count"
                        )
                    )
                );

                lineRows.add(row);

                rank++;
            }
        }

    } catch (SQLException e) {
        e.printStackTrace();

        errorMessage =
            "Database error: "
            + e.getMessage();

    } finally {
        try {
            if (result != null) {
                result.close();
            }

            if (statement != null) {
                statement.close();
            }

            if (con != null) {
                db.closeConnection(con);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    String[] monthNames = {
        "",
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December"
    };

    int earliestYear =
        currentDate.get(Calendar.YEAR) - 10;

    int latestYear =
        currentDate.get(Calendar.YEAR) + 5;
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">

    <title>
        Most Active Transit Lines
    </title>

    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 30px;
        }

        .report-form {
            border: 1px solid #999;
            padding: 20px;
            width: 430px;
            margin-bottom: 25px;
        }

        .form-row {
            margin-bottom: 18px;
        }

        select {
            width: 220px;
            padding: 7px;
        }

        input[type="submit"] {
            padding: 8px 15px;
            cursor: pointer;
        }

        table {
            border-collapse: collapse;
            width: 650px;
            margin-top: 15px;
        }

        th,
        td {
            border: 1px solid #777;
            padding: 9px;
            text-align: left;
        }

        th {
            background-color: #eeeeee;
        }

        .number-column {
            text-align: right;
        }

        .error {
            color: red;
            font-weight: bold;
        }

        .back-link {
            display: inline-block;
            margin-top: 25px;
        }
    </style>
</head>

<body>

    <h1>
        Most Active Transit Lines
    </h1>

    <p>
        View the five transit lines with the most
        reservations for a selected month.
    </p>

    <form
        class="report-form"
        method="get"
        action="<%= request.getContextPath() %>/manager/activeTransitLines.jsp">

        <div class="form-row">

            <label for="month">
                <strong>Month:</strong>
            </label>

            <br><br>

            <select
                id="month"
                name="month"
                required>

                <%
                    for (
                        int monthNumber = 1;
                        monthNumber <= 12;
                        monthNumber++
                    ) {
                %>

                    <option
                        value="<%= monthNumber %>"
                        <%= monthNumber == selectedMonth
                            ? "selected"
                            : "" %>>

                        <%= monthNames[monthNumber] %>
                    </option>

                <%
                    }
                %>

            </select>
        </div>

        <div class="form-row">

            <label for="year">
                <strong>Year:</strong>
            </label>

            <br><br>

            <select
                id="year"
                name="year"
                required>

                <%
                    for (
                        int year = latestYear;
                        year >= earliestYear;
                        year--
                    ) {
                %>

                    <option
                        value="<%= year %>"
                        <%= year == selectedYear
                            ? "selected"
                            : "" %>>

                        <%= year %>
                    </option>

                <%
                    }
                %>

            </select>
        </div>

        <input
            type="hidden"
            name="generate"
            value="true">

        <input
            type="submit"
            value="Generate Report">

    </form>

    <%
        if (errorMessage != null) {
    %>

        <p class="error">
            <%= escapeHtml(errorMessage) %>
        </p>

    <%
        } else if (reportSubmitted) {
    %>

        <h2>
            Top Transit Lines for
            <%= monthNames[selectedMonth] %>
            <%= selectedYear %>
        </h2>

        <%
            if (lineRows.isEmpty()) {
        %>

            <p>
                No reservations were found for this month.
            </p>

        <%
            } else {
        %>

            <table>
                <tr>
                    <th>Rank</th>
                    <th>Transit Line</th>
                    <th>Number of Reservations</th>
                </tr>

                <%
                    for (
                        HashMap<String, String> row
                            : lineRows
                    ) {
                %>

                    <tr>
                        <td class="number-column">
                            <%= escapeHtml(
                                row.get("rank")
                            ) %>
                        </td>

                        <td>
                            <%= escapeHtml(
                                row.get("lineName")
                            ) %>
                        </td>

                        <td class="number-column">
                            <%= escapeHtml(
                                row.get(
                                    "reservationCount"
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