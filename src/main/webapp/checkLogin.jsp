<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"
    import="java.sql.*"
    import="com.cs336.pkg.ApplicationDB"%>

<%
    String username = request.getParameter("username");
    String password = request.getParameter("password");

    if (username == null || password == null
            || username.trim().isEmpty()
            || password.isEmpty()) {

        response.sendRedirect("login.jsp?error=invalid");
        return;
    }

    /*
     * Remove any previous login before checking the new credentials.
     */
    session.invalidate();

    ApplicationDB db = new ApplicationDB();
    Connection connection = db.getConnection();

    if (connection == null) {
        response.sendRedirect("login.jsp?error=database");
        return;
    }

    PreparedStatement statement = null;
    ResultSet result = null;

    try {
        /*
         * First check whether the account is a customer.
         */
        String customerQuery =
            "SELECT username, first_name, last_name " +
            "FROM customer " +
            "WHERE LOWER(username) = LOWER(?) " +
            "AND BINARY password = ?";

        statement = connection.prepareStatement(customerQuery);
        statement.setString(1, username.trim());
        statement.setString(2, password);

        result = statement.executeQuery();

        if (result.next()) {
            request.getSession(true).setAttribute(
                "username",
                result.getString("username")
            );

            request.getSession().setAttribute(
                "firstName",
                result.getString("first_name")
            );

            request.getSession().setAttribute(
                "lastName",
                result.getString("last_name")
            );

            request.getSession().setAttribute(
                "userType",
                "customer"
            );

            response.sendRedirect("customer/c_home.jsp");
            return;
        }

        result.close();
        statement.close();

        /*
         * No customer matched, so check the employee table.
         */
        String employeeQuery =
            "SELECT ssn, username, first_name, last_name, employee_role " +
            "FROM employee " +
            "WHERE LOWER(username) = LOWER(?) " +
            "AND BINARY password = ?";

        statement = connection.prepareStatement(employeeQuery);
        statement.setString(1, username.trim());
        statement.setString(2, password);

        result = statement.executeQuery();

        if (result.next()) {
            String role = result.getString("employee_role");

            request.getSession(true).setAttribute(
                "username",
                result.getString("username")
            );

            request.getSession().setAttribute(
                "firstName",
                result.getString("first_name")
            );

            request.getSession().setAttribute(
                "lastName",
                result.getString("last_name")
            );

            request.getSession().setAttribute(
                "employeeSsn",
                result.getString("ssn")
            );

            request.getSession().setAttribute(
                "userType",
                "employee"
            );

            request.getSession().setAttribute(
                "employeeRole",
                role
            );

            if ("manager".equals(role)) {
                response.sendRedirect("manager/m_home.jsp");
                return;
            }

            if ("representative".equals(role)) {
                response.sendRedirect("representative/r_home.jsp");
                return;
            }
        }

        /*
         * No valid customer or employee was found.
         */
        response.sendRedirect("login.jsp?error=invalid");

    } catch (SQLException e) {
        e.printStackTrace();
        response.sendRedirect("login.jsp?error=database");

    } finally {
        try {
            if (result != null) {
                result.close();
            }

            if (statement != null) {
                statement.close();
            }

            if (connection != null) {
                db.closeConnection(connection);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
%>