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

    PreparedStatement insertStatement = null;
    PreparedStatement checkSsnStatement = null;
    PreparedStatement checkUsernameStatement = null;

    ResultSet checkSsnResult = null;
    ResultSet checkUsernameResult = null;

    String errorMessage = null;

    String submittedSsn = "";
    String submittedFirstName = "";
    String submittedLastName = "";
    String submittedUsername = "";

    try {

        connection =
            db.getConnection();

        if (connection == null) {

            throw new SQLException(
                "Could not connect to the database."
            );
        }

        if ("POST".equalsIgnoreCase(
                request.getMethod())) {

            String ssn =
                request.getParameter("ssn");

            String firstName =
                request.getParameter("firstName");

            String lastName =
                request.getParameter("lastName");

            String username =
                request.getParameter("username");

            String password =
                request.getParameter("password");

            String confirmPassword =
                request.getParameter(
                    "confirmPassword"
                );

            submittedSsn =
                ssn == null
                ? ""
                : ssn.trim();

            submittedFirstName =
                firstName == null
                ? ""
                : firstName.trim();

            submittedLastName =
                lastName == null
                ? ""
                : lastName.trim();

            submittedUsername =
                username == null
                ? ""
                : username.trim();

            if (submittedSsn.isEmpty()
                    || submittedFirstName.isEmpty()
                    || submittedLastName.isEmpty()
                    || submittedUsername.isEmpty()
                    || password == null
                    || password.isEmpty()
                    || confirmPassword == null
                    || confirmPassword.isEmpty()) {

                errorMessage =
                    "All fields are required.";

            } else if (!password.equals(
                    confirmPassword)) {

                errorMessage =
                    "The passwords do not match.";

            } else {

                String checkSsnQuery =
                    "SELECT COUNT(*) AS ssn_count " +
                    "FROM employee " +
                    "WHERE ssn = ?";

                checkSsnStatement =
                    connection.prepareStatement(
                        checkSsnQuery
                    );

                checkSsnStatement.setString(
                    1,
                    submittedSsn
                );

                checkSsnResult =
                    checkSsnStatement.executeQuery();

                checkSsnResult.next();

                int ssnCount =
                    checkSsnResult.getInt(
                        "ssn_count"
                    );

                if (ssnCount > 0) {

                    errorMessage =
                        "An employee with that SSN "
                        + "already exists.";
                }
            }

            if (errorMessage == null) {

                String checkUsernameQuery =
                    "SELECT COUNT(*) AS username_count " +
                    "FROM employee " +
                    "WHERE username = ?";

                checkUsernameStatement =
                    connection.prepareStatement(
                        checkUsernameQuery
                    );

                checkUsernameStatement.setString(
                    1,
                    submittedUsername
                );

                checkUsernameResult =
                    checkUsernameStatement
                        .executeQuery();

                checkUsernameResult.next();

                int usernameCount =
                    checkUsernameResult.getInt(
                        "username_count"
                    );

                if (usernameCount > 0) {

                    errorMessage =
                        "That employee username is "
                        + "already being used.";
                }
            }

            if (errorMessage == null) {

                String insertQuery =
                    "INSERT INTO employee " +
                    "(" +
                        "ssn, " +
                        "first_name, " +
                        "last_name, " +
                        "username, " +
                        "password, " +
                        "employee_role" +
                    ") " +
                    "VALUES (?, ?, ?, ?, ?, ?)";

                insertStatement =
                    connection.prepareStatement(
                        insertQuery
                    );

                insertStatement.setString(
                    1,
                    submittedSsn
                );

                insertStatement.setString(
                    2,
                    submittedFirstName
                );

                insertStatement.setString(
                    3,
                    submittedLastName
                );

                insertStatement.setString(
                    4,
                    submittedUsername
                );

                insertStatement.setString(
                    5,
                    password
                );

                insertStatement.setString(
                    6,
                    "representative"
                );

                int insertedRows =
                    insertStatement.executeUpdate();

                if (insertedRows != 1) {

                    throw new SQLException(
                        "The customer representative "
                        + "could not be added."
                    );
                }

                response.sendRedirect(
                    request.getContextPath()
                    + "/manager/"
                    + "manageRepresentatives.jsp"
                    + "?message=added"
                );

                return;
            }
        }

    } catch (SQLException e) {

        e.printStackTrace();

        errorMessage =
            "Database error: "
            + e.getMessage();
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">

    <title>
        Add Customer Representative
    </title>
</head>

<body>

    <h1>
        Add Customer Representative
    </h1>

    <%
        if (errorMessage != null) {
    %>

        <p style="color: red;">
            <%= errorMessage %>
        </p>

    <%
        }
    %>

    <form
        action="addRepresentative.jsp"
        method="post">

        <label for="ssn">
            SSN:
        </label>

        <input
            type="text"
            id="ssn"
            name="ssn"
            maxlength="11"
            value="<%= submittedSsn %>"
            required>

        <br><br>

        <label for="firstName">
            First Name:
        </label>

        <input
            type="text"
            id="firstName"
            name="firstName"
            maxlength="50"
            value="<%= submittedFirstName %>"
            required>

        <br><br>

        <label for="lastName">
            Last Name:
        </label>

        <input
            type="text"
            id="lastName"
            name="lastName"
            maxlength="50"
            value="<%= submittedLastName %>"
            required>

        <br><br>

        <label for="username">
            Username:
        </label>

        <input
            type="text"
            id="username"
            name="username"
            maxlength="50"
            value="<%= submittedUsername %>"
            required>

        <br><br>

        <label for="password">
            Password:
        </label>

        <input
            type="password"
            id="password"
            name="password"
            maxlength="50"
            required>

        <br><br>

        <label for="confirmPassword">
            Confirm Password:
        </label>

        <input
            type="password"
            id="confirmPassword"
            name="confirmPassword"
            maxlength="50"
            required>

        <br><br>

        <input
            type="submit"
            value="Add Representative">

        &nbsp;

        <a href="<%= request.getContextPath() %>/manager/manageRepresentatives.jsp">
            Cancel
        </a>

    </form>

</body>
</html>

<%
    try {

        if (checkUsernameResult != null) {
            checkUsernameResult.close();
        }

        if (checkSsnResult != null) {
            checkSsnResult.close();
        }

        if (insertStatement != null) {
            insertStatement.close();
        }

        if (checkUsernameStatement != null) {
            checkUsernameStatement.close();
        }

        if (checkSsnStatement != null) {
            checkSsnStatement.close();
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