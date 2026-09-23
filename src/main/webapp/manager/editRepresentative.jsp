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

    String ssnParameter =
        request.getParameter("ssn");

    if (ssnParameter == null
            || ssnParameter.trim().isEmpty()) {

        response.sendRedirect(
            request.getContextPath()
            + "/manager/manageRepresentatives.jsp"
        );

        return;
    }

    String representativeSsn =
        ssnParameter.trim();

    ApplicationDB db =
        new ApplicationDB();

    Connection connection = null;

    PreparedStatement representativeStatement = null;
    PreparedStatement usernameStatement = null;
    PreparedStatement updateStatement = null;

    ResultSet representativeResult = null;
    ResultSet usernameResult = null;

    String errorMessage = null;

    String firstName = "";
    String lastName = "";
    String username = "";
    String currentPassword = "";

    try {

        connection =
            db.getConnection();

        if (connection == null) {

            throw new SQLException(
                "Could not connect to the database."
            );
        }

        /*
         * Load the representative.
         */
        String representativeQuery =
            "SELECT " +
            "first_name, " +
            "last_name, " +
            "username, " +
            "password " +
            "FROM employee " +
            "WHERE ssn = ? " +
            "AND employee_role = ?";

        representativeStatement =
            connection.prepareStatement(
                representativeQuery
            );

        representativeStatement.setString(
            1,
            representativeSsn
        );

        representativeStatement.setString(
            2,
            "representative"
        );

        representativeResult =
            representativeStatement.executeQuery();

        if (!representativeResult.next()) {

            response.sendRedirect(
                request.getContextPath()
                + "/manager/manageRepresentatives.jsp"
            );

            return;
        }

        firstName =
            representativeResult.getString(
                "first_name"
            );

        lastName =
            representativeResult.getString(
                "last_name"
            );

        username =
            representativeResult.getString(
                "username"
            );

        currentPassword =
            representativeResult.getString(
                "password"
            );

        /*
         * Process the edit form.
         */
        if ("POST".equalsIgnoreCase(
                request.getMethod())) {

            String submittedFirstName =
                request.getParameter(
                    "firstName"
                );

            String submittedLastName =
                request.getParameter(
                    "lastName"
                );

            String submittedUsername =
                request.getParameter(
                    "username"
                );

            String submittedPassword =
                request.getParameter(
                    "password"
                );

            String confirmPassword =
                request.getParameter(
                    "confirmPassword"
                );

            firstName =
                submittedFirstName == null
                ? ""
                : submittedFirstName.trim();

            lastName =
                submittedLastName == null
                ? ""
                : submittedLastName.trim();

            username =
                submittedUsername == null
                ? ""
                : submittedUsername.trim();

            if (firstName.isEmpty()
                    || lastName.isEmpty()
                    || username.isEmpty()) {

                errorMessage =
                    "First name, last name, and username "
                    + "are required.";

            } else if (submittedPassword != null
                    && !submittedPassword.isEmpty()
                    && !submittedPassword.equals(
                        confirmPassword
                    )) {

                errorMessage =
                    "The passwords do not match.";
            }

            /*
             * Check whether another employee already
             * uses the submitted username.
             */
            if (errorMessage == null) {

                String usernameQuery =
                    "SELECT COUNT(*) AS username_count " +
                    "FROM employee " +
                    "WHERE username = ? " +
                    "AND ssn <> ?";

                usernameStatement =
                    connection.prepareStatement(
                        usernameQuery
                    );

                usernameStatement.setString(
                    1,
                    username
                );

                usernameStatement.setString(
                    2,
                    representativeSsn
                );

                usernameResult =
                    usernameStatement.executeQuery();

                usernameResult.next();

                int usernameCount =
                    usernameResult.getInt(
                        "username_count"
                    );

                if (usernameCount > 0) {

                    errorMessage =
                        "That employee username is "
                        + "already being used.";
                }
            }

            if (errorMessage == null) {

                String passwordToSave =
                    currentPassword;

                if (submittedPassword != null
                        && !submittedPassword.isEmpty()) {

                    passwordToSave =
                        submittedPassword;
                }

                String updateQuery =
                    "UPDATE employee " +
                    "SET first_name = ?, " +
                    "last_name = ?, " +
                    "username = ?, " +
                    "password = ? " +
                    "WHERE ssn = ? " +
                    "AND employee_role = ?";

                updateStatement =
                    connection.prepareStatement(
                        updateQuery
                    );

                updateStatement.setString(
                    1,
                    firstName
                );

                updateStatement.setString(
                    2,
                    lastName
                );

                updateStatement.setString(
                    3,
                    username
                );

                updateStatement.setString(
                    4,
                    passwordToSave
                );

                updateStatement.setString(
                    5,
                    representativeSsn
                );

                updateStatement.setString(
                    6,
                    "representative"
                );

                int updatedRows =
                    updateStatement.executeUpdate();

                if (updatedRows != 1) {

                    throw new SQLException(
                        "The customer representative "
                        + "could not be updated."
                    );
                }

                response.sendRedirect(
                    request.getContextPath()
                    + "/manager/"
                    + "manageRepresentatives.jsp"
                    + "?message=updated"
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
        Edit Customer Representative
    </title>
</head>

<body>

    <h1>
        Edit Customer Representative
    </h1>

    <p>
        SSN:
        <strong><%= representativeSsn %></strong>
    </p>

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
        action="editRepresentative.jsp"
        method="post">

        <input
            type="hidden"
            name="ssn"
            value="<%= representativeSsn %>">

        <label for="firstName">
            First Name:
        </label>

        <input
            type="text"
            id="firstName"
            name="firstName"
            maxlength="50"
            value="<%= firstName %>"
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
            value="<%= lastName %>"
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
            value="<%= username %>"
            required>

        <br><br>

        <label for="password">
            New Password:
        </label>

        <input
            type="password"
            id="password"
            name="password"
            maxlength="50">

        <p>
            Leave the new password blank to keep the
            current password.
        </p>

        <label for="confirmPassword">
            Confirm New Password:
        </label>

        <input
            type="password"
            id="confirmPassword"
            name="confirmPassword"
            maxlength="50">

        <br><br>

        <input
            type="submit"
            value="Save Changes">

        &nbsp;

        <a href="<%= request.getContextPath() %>/manager/manageRepresentatives.jsp">
            Cancel
        </a>

    </form>

</body>
</html>

<%
    try {

        if (usernameResult != null) {
            usernameResult.close();
        }

        if (representativeResult != null) {
            representativeResult.close();
        }

        if (updateStatement != null) {
            updateStatement.close();
        }

        if (usernameStatement != null) {
            usernameStatement.close();
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