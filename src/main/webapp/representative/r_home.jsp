<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>

<%
    String employeeRole =
        (String) session.getAttribute("employeeRole");

    if (!"representative".equals(employeeRole)) {
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
    <title>Representative Home</title>
</head>
<body>

    <h1>Railway Reservation System</h1>

    <h2>Representative Home</h2>

    <p>
        Welcome,
        <%= firstName %> <%= lastName %>.
    </p>

    <p>
        Logged in as: <%= username %>
    </p>

    <h3>Representative Options</h3>

    <ul>
        <li>
            <a href="<%= request.getContextPath() %>/representative/manageSchedules.jsp">
                Edit or delete train schedules
            </a>
        </li>

        <li>
            <a href="<%= request.getContextPath() %>/representative/manageQuestions.jsp">
                Manage customer questions
            </a>
        </li>

        <li>
            <a href="<%= request.getContextPath() %>/representative/viewCustomersByLineDate.jsp">
                View customers by transit line and/or date
            </a>
        </li>

        <li>
            <a href="<%= request.getContextPath() %>/representative/viewSchedulesByStation.jsp">
                View schedules by station
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