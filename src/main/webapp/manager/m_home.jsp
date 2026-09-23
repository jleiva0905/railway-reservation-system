<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>

<%
    String userType =
        (String) session.getAttribute(
            "userType"
        );

    String employeeRole =
        (String) session.getAttribute(
            "employeeRole"
        );

    if (!"employee".equals(userType)
            || !"manager".equals(employeeRole)) {

        response.sendRedirect(
            request.getContextPath()
            + "/login.jsp"
        );

        return;
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">

    <title>
        Manager Home
    </title>
</head>

<body>

    <h1>
        Railway Manager Dashboard
    </h1>

    <h2>
        Customer Representative Management
    </h2>

    <p>
        <a href="<%= request.getContextPath() %>/manager/manageRepresentatives.jsp">
            Add, Edit, or Delete Customer Representatives
        </a>
    </p>

    <h2>
        Sales and Reservation Reports
    </h2>

    <p>
        <a href="<%= request.getContextPath() %>/manager/salesReport.jsp">
            Monthly Sales Report
        </a>
    </p>

    <p>
        <a href="<%= request.getContextPath() %>/manager/reservationReport.jsp">
            Reservations by Transit Line or Customer
        </a>
    </p>

    <p>
        <a href="<%= request.getContextPath() %>/manager/revenueReport.jsp">
            Revenue by Transit Line or Customer
        </a>
    </p>

    <p>
        <a href="<%= request.getContextPath() %>/manager/bestCustomer.jsp">
            Customer Who Generated the Most Revenue
        </a>
    </p>

    <p>
        <a href="<%= request.getContextPath() %>/manager/activeTransitLines.jsp">
            Five Most Active Transit Lines
        </a>
    </p>

    <br>

    <a href="<%= request.getContextPath() %>/logout.jsp">
        Log Out
    </a>

</body>
</html>