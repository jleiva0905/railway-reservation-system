<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"
    import="java.sql.*"
    import="java.util.*"
    import="java.text.*"
    import="com.cs336.pkg.ApplicationDB"%>

<%
    String userType =
        (String) session.getAttribute("userType");

    String employeeRole =
        (String) session.getAttribute("employeeRole");

    /*
     * Only managers may access this page.
     */
    if (!"employee".equals(userType)
            || !"manager".equals(employeeRole)) {

        response.sendRedirect(
            request.getContextPath() + "/login.jsp"
        );

        return;
    }

    String errorMessage = null;

    /*
     * Each map stores one month's sales information.
     */
    ArrayList<HashMap<String, String>> monthlySales =
        new ArrayList<HashMap<String, String>>();

    ApplicationDB db =
        new ApplicationDB();

    Connection connection = null;

    PreparedStatement salesStatement = null;

    ResultSet salesResult = null;

    try {

        connection =
            db.getConnection();

        if (connection == null) {

            throw new SQLException(
                "Could not connect to the database."
            );
        }

        /*
         * Group all reservations by the year and month
         * in which the reservation was made.
         */
        String salesQuery =
            "SELECT " +
            "YEAR(date_made) AS sales_year, " +
            "MONTH(date_made) AS sales_month, " +
            "COUNT(*) AS reservation_count, " +
            "SUM(total_fare) AS total_revenue " +
            "FROM reservation " +
            "GROUP BY " +
            "YEAR(date_made), " +
            "MONTH(date_made) " +
            "ORDER BY " +
            "YEAR(date_made) DESC, " +
            "MONTH(date_made) DESC";

        salesStatement =
            connection.prepareStatement(
                salesQuery
            );

        salesResult =
            salesStatement.executeQuery();

        while (salesResult.next()) {

            HashMap<String, String> salesRow =
                new HashMap<String, String>();

            salesRow.put(
                "year",
                String.valueOf(
                    salesResult.getInt(
                        "sales_year"
                    )
                )
            );

            salesRow.put(
                "month",
                String.valueOf(
                    salesResult.getInt(
                        "sales_month"
                    )
                )
            );

            salesRow.put(
                "reservationCount",
                String.valueOf(
                    salesResult.getInt(
                        "reservation_count"
                    )
                )
            );

            salesRow.put(
                "totalRevenue",
                salesResult.getBigDecimal(
                    "total_revenue"
                ).toPlainString()
            );

            monthlySales.add(
                salesRow
            );
        }

    } catch (SQLException e) {

        e.printStackTrace();

        errorMessage =
            "Database error: "
            + e.getMessage();

    } finally {

        try {

            if (salesResult != null) {
                salesResult.close();
            }

            if (salesStatement != null) {
                salesStatement.close();
            }

            if (connection != null) {
                db.closeConnection(connection);
            }

        } catch (SQLException e) {

            e.printStackTrace();
        }
    }

    /*
     * Used to display month names such as
     * July instead of month number 7.
     */
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

    DecimalFormat moneyFormat =
        new DecimalFormat("#,##0.00");

    double allTimeRevenue = 0.0;

    int allTimeReservationCount = 0;

    for (HashMap<String, String> salesRow
            : monthlySales) {

        allTimeRevenue +=
            Double.parseDouble(
                salesRow.get("totalRevenue")
            );

        allTimeReservationCount +=
            Integer.parseInt(
                salesRow.get("reservationCount")
            );
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">

    <title>
        Monthly Sales Report
    </title>
</head>

<body>

    <h1>
        Monthly Sales Report
    </h1>

    <p>
        This report shows the total reservation revenue
        generated during each month.
    </p>

    <%
        if (errorMessage != null) {
    %>

        <p style="color: red;">
            <%= errorMessage %>
        </p>

    <%
        } else if (monthlySales.isEmpty()) {
    %>

        <p>
            No reservation sales are currently available.
        </p>

    <%
        } else {
    %>

        <table border="1" cellpadding="8">
            <tr>
                <th>Month</th>
                <th>Year</th>
                <th>Number of Reservations</th>
                <th>Total Revenue</th>
            </tr>

            <%
                for (HashMap<String, String> salesRow
                        : monthlySales) {

                    int monthNumber =
                        Integer.parseInt(
                            salesRow.get("month")
                        );

                    String monthName =
                        monthNames[monthNumber];

                    String year =
                        salesRow.get("year");

                    String reservationCount =
                        salesRow.get(
                            "reservationCount"
                        );

                    double totalRevenue =
                        Double.parseDouble(
                            salesRow.get(
                                "totalRevenue"
                            )
                        );
            %>

                <tr>
                    <td>
                        <%= monthName %>
                    </td>

                    <td>
                        <%= year %>
                    </td>

                    <td>
                        <%= reservationCount %>
                    </td>

                    <td>
                        $<%= moneyFormat.format(
                            totalRevenue
                        ) %>
                    </td>
                </tr>

            <%
                }
            %>

            <tr>
                <td colspan="2">
                    <strong>
                        All-Time Total
                    </strong>
                </td>

                <td>
                    <strong>
                        <%= allTimeReservationCount %>
                    </strong>
                </td>

                <td>
                    <strong>
                        $<%= moneyFormat.format(
                            allTimeRevenue
                        ) %>
                    </strong>
                </td>
            </tr>
        </table>

    <%
        }
    %>

    <br>

    <a href="<%= request.getContextPath() %>/manager/m_home.jsp">
        Back to manager home
    </a>

</body>
</html>