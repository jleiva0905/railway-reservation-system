<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"
    import="java.sql.*"
    import="com.cs336.pkg.ApplicationDB"%>

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

    ApplicationDB db =
        new ApplicationDB();

    Connection connection = null;

    PreparedStatement representativeStatement =
        null;

    ResultSet representativeResult =
        null;

    String errorMessage = null;

    String successMessage =
        request.getParameter("message");

    try {

        connection =
            db.getConnection();

        if (connection == null) {

            throw new SQLException(
                "Could not connect to the database."
            );
        }

        String representativeQuery =
            "SELECT " +
            "ssn, " +
            "first_name, " +
            "last_name, " +
            "username " +

            "FROM employee " +

            "WHERE employee_role = ? " +

            "ORDER BY last_name, first_name";

        representativeStatement =
            connection.prepareStatement(
                representativeQuery
            );

        representativeStatement.setString(
            1,
            "representative"
        );

        representativeResult =
            representativeStatement.executeQuery();

    } catch (SQLException e) {

        e.printStackTrace();

        errorMessage =
            "A database error occurred while loading "
            + "customer representatives.";
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">

    <title>
        Manage Customer Representatives
    </title>
</head>

<body>

    <h1>
        Manage Customer Representatives
    </h1>

    <%
        if ("added".equals(successMessage)) {
    %>

        <p style="color: green;">
            The customer representative was added successfully.
        </p>

    <%
        } else if ("updated".equals(successMessage)) {
    %>

        <p style="color: green;">
            The customer representative was updated successfully.
        </p>

    <%
        } else if ("deleted".equals(successMessage)) {
    %>

        <p style="color: green;">
            The customer representative was deleted successfully.
        </p>

    <%
        } else if ("cannotDelete".equals(successMessage)) {
    %>

        <p style="color: red;">
            The customer representative could not be deleted
            because they are referenced by existing data.
        </p>

    <%
        }
    %>

    <%
        if (errorMessage != null) {
    %>

        <p style="color: red;">
            <%= errorMessage %>
        </p>

    <%
        } else {
    %>

        <p>
            <a href="<%= request.getContextPath() %>/manager/addRepresentative.jsp">
                Add New Customer Representative
            </a>
        </p>

        <table border="1" cellpadding="8">

            <tr>
                <th>SSN</th>
                <th>First Name</th>
                <th>Last Name</th>
                <th>Username</th>
                <th>Actions</th>
            </tr>

            <%
                boolean foundRepresentative =
                    false;

                while (representativeResult.next()) {

                    foundRepresentative =
                        true;

                    String ssn =
                        representativeResult.getString(
                            "ssn"
                        );

                    String firstName =
                        representativeResult.getString(
                            "first_name"
                        );

                    String lastName =
                        representativeResult.getString(
                            "last_name"
                        );

                    String username =
                        representativeResult.getString(
                            "username"
                        );
            %>

            <tr>

                <td>
                    <%= ssn %>
                </td>

                <td>
                    <%= firstName %>
                </td>

                <td>
                    <%= lastName %>
                </td>

                <td>
                    <%= username %>
                </td>

                <td>

                    <a href="<%= request.getContextPath() %>/manager/editRepresentative.jsp?ssn=<%= java.net.URLEncoder.encode(ssn, "UTF-8") %>">
                        Edit
                    </a>

                    &nbsp;|&nbsp;

                    <a
                        href="<%= request.getContextPath() %>/manager/deleteRepresentative.jsp?ssn=<%= java.net.URLEncoder.encode(ssn, "UTF-8") %>"
                        onclick="return confirm('Are you sure you want to delete this customer representative?');">

                        Delete
                    </a>

                </td>

            </tr>

            <%
                }

                if (!foundRepresentative) {
            %>

            <tr>
                <td colspan="5">
                    No customer representatives were found.
                </td>
            </tr>

            <%
                }
            %>

        </table>

    <%
        }
    %>

    <br>

    <a href="<%= request.getContextPath() %>/manager/m_home.jsp">
        Back to Manager Home
    </a>

</body>
</html>

<%
    try {

        if (representativeResult != null) {

            representativeResult.close();
        }

        if (representativeStatement != null) {

            representativeStatement.close();
        }

        if (connection != null) {

            db.closeConnection(
                connection
            );
        }

    } catch (SQLException e) {

        e.printStackTrace();
    }
%>