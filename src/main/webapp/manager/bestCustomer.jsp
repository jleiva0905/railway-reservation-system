<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"
    import="java.sql.*"
    import="java.text.DecimalFormat"
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

    String errorMessage = null;

    String customerUsername = null;
    String customerName = null;
    String emailAddress = null;

    int reservationCount = 0;

    BigDecimal totalRevenue =
        BigDecimal.ZERO;

    boolean customerFound = false;

    ApplicationDB db =
        new ApplicationDB();

    Connection con = null;

    PreparedStatement statement = null;
    ResultSet result = null;

    try {
        con = db.getConnection();

        if (con == null) {
            throw new SQLException(
                "Could not connect to the database."
            );
        }

        String query =
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
            "JOIN reservation r " +
                "ON c.username = r.customer_username " +
            "GROUP BY " +
                "c.username, " +
                "c.first_name, " +
                "c.last_name, " +
                "c.email_address " +
            "ORDER BY total_revenue DESC, " +
                "reservation_count DESC, " +
                "c.username ASC " +
            "LIMIT 1";

        statement =
            con.prepareStatement(query);

        result =
            statement.executeQuery();

        if (result.next()) {
            customerFound = true;

            customerUsername =
                result.getString("username");

            customerName =
                result.getString("first_name")
                + " "
                + result.getString("last_name");

            emailAddress =
                result.getString("email_address");

            reservationCount =
                result.getInt("reservation_count");

            totalRevenue =
                result.getBigDecimal("total_revenue");

            if (totalRevenue == null) {
                totalRevenue = BigDecimal.ZERO;
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

    DecimalFormat moneyFormat =
        new DecimalFormat("#,##0.00");
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">

    <title>Best Customer</title>

    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 30px;
        }

        .customer-card {
            border: 1px solid #999;
            padding: 20px;
            width: 450px;
            margin-top: 20px;
        }

        .customer-card h2 {
            margin-top: 0;
        }

        .customer-card p {
            margin: 10px 0;
        }

        .revenue {
            font-size: 22px;
            font-weight: bold;
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

    <h1>Best Customer</h1>

    <p>
        Customer who generated the greatest total revenue.
    </p>

    <%
        if (errorMessage != null) {
    %>

        <p class="error">
            <%= escapeHtml(errorMessage) %>
        </p>

    <%
        } else if (!customerFound) {
    %>

        <p>
            No customers with reservations were found.
        </p>

    <%
        } else {
    %>

        <div class="customer-card">

            <h2>
                <%= escapeHtml(customerName) %>
            </h2>

            <p>
                <strong>Username:</strong>
                <%= escapeHtml(customerUsername) %>
            </p>

            <p>
                <strong>Email:</strong>
                <%= escapeHtml(emailAddress) %>
            </p>

            <p>
                <strong>Number of Reservations:</strong>
                <%= reservationCount %>
            </p>

            <p class="revenue">
                Total Revenue:
                $<%= moneyFormat.format(totalRevenue) %>
            </p>

        </div>

    <%
        }
    %>

    <a
        class="back-link"
        href="<%= request.getContextPath() %>/manager/m_home.jsp">

        Back to Manager Home
    </a>

</body>
</html>