<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>

<%
    String userType =
        (String) session.getAttribute("userType");

    if (!"customer".equals(userType)) {
        response.sendRedirect(
            request.getContextPath() + "/login.jsp"
        );
        return;
    }

    String firstName =
        (String) session.getAttribute("firstName");

    String lastName =
        (String) session.getAttribute("lastName");

    String username =
        (String) session.getAttribute("username");
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Customer Home</title>
</head>
<body>

    <h1>Railway Reservation System</h1>

    <h2>Customer Home</h2>

    <p>
        Welcome,
        <%= firstName %> <%= lastName %>.
    </p>

    <p>
        Logged in as: <%= username %>
    </p>

    <h3>Customer Options</h3>

    <ul>
        <li>
            <a href="<%= request.getContextPath() %>/customer/search.jsp">
                Search train schedules
            </a>
        </li>

        <li>
            <a href="<%= request.getContextPath() %>/customer/viewReservations.jsp">
                View and manage reservations
            </a>
        </li>

        <li>
            <a href="<%= request.getContextPath() %>/customer/askQuestion.jsp">
                Ask a question
            </a>
        </li>

        <li>
            <a href="<%= request.getContextPath() %>/logout.jsp">
                Log out
            </a>
        </li>
    </ul>

</body>
</html>