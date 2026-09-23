<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>

<%
    String error = request.getParameter("error");
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Railway Login</title>
</head>
<body>

    <h1>Railway Reservation System</h1>
    <h2>Log In</h2>
    
    <%
        if ("invalid".equals(error)) {
    %>
        <p style="color: red;">
            Incorrect username or password. Please try again.
        </p>
    <%
        } else if ("database".equals(error)) {
    %>
        <p style="color: red;">
            Unable to connect to the database.
        </p>
    <%
        } else if ("logout".equals(error)) {
    %>
        <p style="color: green;">
            You have been logged out.
        </p>
    <%
        }
    %>

    <form action="checkLogin.jsp" method="post">

        <label for="username">Username:</label>

        <input
            type="text"
            id="username"
            name="username"
            required>

        <br><br>

        <label for="password">Password:</label>

        <input
            type="password"
            id="password"
            name="password"
            required>

        <br><br>

        <input type="submit" value="Log In">
        
        <p>
    Don't have a customer account?

    <a href="<%= request.getContextPath() %>/register.jsp">
        Create an Account
    </a>
</p>

    </form>

</body>
</html>