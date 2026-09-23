<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"
    import="java.sql.*"
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
    String firstName = "";
    String lastName = "";
    String emailAddress = "";
    String username = "";

    String errorMessage = null;
    boolean registrationSuccessful = false;

    if ("POST".equalsIgnoreCase(request.getMethod())) {

        firstName =
            request.getParameter("firstName");

        lastName =
            request.getParameter("lastName");

        emailAddress =
            request.getParameter("emailAddress");

        username =
            request.getParameter("username");

        String password =
            request.getParameter("password");

        String confirmPassword =
            request.getParameter("confirmPassword");

        if (firstName != null) {
            firstName = firstName.trim();
        }

        if (lastName != null) {
            lastName = lastName.trim();
        }

        if (emailAddress != null) {
            emailAddress = emailAddress.trim();
        }

        if (username != null) {
            username = username.trim();
        }

        if (password != null) {
            password = password.trim();
        }

        if (confirmPassword != null) {
            confirmPassword =
                confirmPassword.trim();
        }

        if (firstName == null
                || firstName.isEmpty()
                || lastName == null
                || lastName.isEmpty()
                || emailAddress == null
                || emailAddress.isEmpty()
                || username == null
                || username.isEmpty()
                || password == null
                || password.isEmpty()
                || confirmPassword == null
                || confirmPassword.isEmpty()) {

            errorMessage =
                "All fields are required.";

        } else if (firstName.length() > 50) {

            errorMessage =
                "First name cannot exceed 50 characters.";

        } else if (lastName.length() > 50) {

            errorMessage =
                "Last name cannot exceed 50 characters.";

        } else if (emailAddress.length() > 100) {

            errorMessage =
                "Email address cannot exceed 100 characters.";

        } else if (username.length() > 50) {

            errorMessage =
                "Username cannot exceed 50 characters.";

        } else if (password.length() > 50) {

            errorMessage =
                "Password cannot exceed 50 characters.";

        } else if (!emailAddress.matches(
                "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+$")) {

            errorMessage =
                "Enter a valid email address.";

        } else if (!username.matches(
                "^[A-Za-z0-9._-]+$")) {

            errorMessage =
                "Username may contain only letters, numbers, periods, underscores, and hyphens.";

        } else if (password.length() < 6) {

            errorMessage =
                "Password must contain at least 6 characters.";

        } else if (!password.equals(confirmPassword)) {

            errorMessage =
                "The passwords do not match.";

        } else {

            ApplicationDB db =
                new ApplicationDB();

            Connection con = null;
            PreparedStatement checkUsername = null;
            PreparedStatement checkEmail = null;
            PreparedStatement insertCustomer = null;
            ResultSet usernameResult = null;
            ResultSet emailResult = null;

            try {
                con = db.getConnection();

                if (con == null) {
                    throw new SQLException(
                        "Could not connect to the database."
                    );
                }

                /*
                 * Username check is case-insensitive.
                 *
                 * Therefore, julio2005, JULIO2005, and
                 * Julio2005 are treated as the same username.
                 */
                String usernameCheckQuery =
                    "SELECT username " +
                    "FROM customer " +
                    "WHERE LOWER(username) = LOWER(?)";

                checkUsername =
                    con.prepareStatement(
                        usernameCheckQuery
                    );

                checkUsername.setString(
                    1,
                    username
                );

                usernameResult =
                    checkUsername.executeQuery();

                if (usernameResult.next()) {

                    errorMessage =
                        "That username is already taken.";

                } else {

                    /*
                     * Prevent two accounts from using the
                     * same email address.
                     */
                    String emailCheckQuery =
                        "SELECT email_address " +
                        "FROM customer " +
                        "WHERE LOWER(email_address) = LOWER(?)";

                    checkEmail =
                        con.prepareStatement(
                            emailCheckQuery
                        );

                    checkEmail.setString(
                        1,
                        emailAddress
                    );

                    emailResult =
                        checkEmail.executeQuery();

                    if (emailResult.next()) {

                        errorMessage =
                            "An account already exists with that email address.";

                    } else {

                        String insertQuery =
                            "INSERT INTO customer " +
                            "(username, first_name, last_name, " +
                            "email_address, password) " +
                            "VALUES (?, ?, ?, ?, ?)";

                        insertCustomer =
                            con.prepareStatement(
                                insertQuery
                            );

                        insertCustomer.setString(
                            1,
                            username
                        );

                        insertCustomer.setString(
                            2,
                            firstName
                        );

                        insertCustomer.setString(
                            3,
                            lastName
                        );

                        insertCustomer.setString(
                            4,
                            emailAddress
                        );

                        /*
                         * The password is stored exactly as entered.
                         * Your login query should use:
                         *
                         * BINARY password = ?
                         *
                         * so the password remains case-sensitive.
                         */
                        insertCustomer.setString(
                            5,
                            password
                        );

                        int rowsInserted =
                            insertCustomer.executeUpdate();

                        if (rowsInserted == 1) {
                            registrationSuccessful = true;
                        } else {
                            errorMessage =
                                "The account could not be created.";
                        }
                    }
                }

            } catch (SQLException e) {
                e.printStackTrace();

                errorMessage =
                    "Database error: "
                    + e.getMessage();

            } finally {
                try {
                    if (usernameResult != null) {
                        usernameResult.close();
                    }

                    if (emailResult != null) {
                        emailResult.close();
                    }

                    if (checkUsername != null) {
                        checkUsername.close();
                    }

                    if (checkEmail != null) {
                        checkEmail.close();
                    }

                    if (insertCustomer != null) {
                        insertCustomer.close();
                    }

                    if (con != null) {
                        db.closeConnection(con);
                    }

                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
        }
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">

    <title>Create Customer Account</title>

    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f4f4f4;
            margin: 0;
            padding: 30px;
        }

        .register-container {
            width: 440px;
            margin: 30px auto;
            padding: 28px;
            background-color: white;
            border: 1px solid #cccccc;
            border-radius: 6px;
        }

        h1 {
            text-align: center;
            margin-top: 0;
        }

        .description {
            text-align: center;
            color: #555555;
            margin-bottom: 25px;
        }

        .form-group {
            margin-bottom: 16px;
        }

        label {
            display: block;
            margin-bottom: 6px;
            font-weight: bold;
        }

        input[type="text"],
        input[type="email"],
        input[type="password"] {
            box-sizing: border-box;
            width: 100%;
            padding: 9px;
            border: 1px solid #999999;
            border-radius: 3px;
        }

        input[type="submit"] {
            width: 100%;
            padding: 11px;
            margin-top: 8px;
            border: none;
            border-radius: 3px;
            background-color: #333333;
            color: white;
            font-size: 16px;
            cursor: pointer;
        }

        input[type="submit"]:hover {
            background-color: #555555;
        }

        .error {
            padding: 10px;
            margin-bottom: 18px;
            border: 1px solid #cc0000;
            background-color: #ffecec;
            color: #990000;
        }

        .success {
            padding: 15px;
            border: 1px solid #188038;
            background-color: #e6f4ea;
            color: #116329;
            text-align: center;
        }

        .login-link {
            margin-top: 20px;
            text-align: center;
        }
    </style>
</head>

<body>

    <div class="register-container">

        <h1>Create an Account</h1>

        <p class="description">
            Register as a customer to search for trains
            and make reservations.
        </p>

        <%
            if (registrationSuccessful) {
        %>

            <div class="success">
                <strong>Account created successfully.</strong>

                <p>
                    You can now sign in using your username
                    and password.
                </p>

                <a href="<%= request.getContextPath() %>/login.jsp">
                    Continue to Login
                </a>
            </div>

        <%
            } else {
        %>

            <%
                if (errorMessage != null) {
            %>

                <div class="error">
                    <%= escapeHtml(errorMessage) %>
                </div>

            <%
                }
            %>

            <form
                method="post"
                action="<%= request.getContextPath() %>/register.jsp">

                <div class="form-group">
                    <label for="firstName">
                        First Name
                    </label>

                    <input
                        type="text"
                        id="firstName"
                        name="firstName"
                        maxlength="50"
                        value="<%= escapeHtml(firstName) %>"
                        required>
                </div>

                <div class="form-group">
                    <label for="lastName">
                        Last Name
                    </label>

                    <input
                        type="text"
                        id="lastName"
                        name="lastName"
                        maxlength="50"
                        value="<%= escapeHtml(lastName) %>"
                        required>
                </div>

                <div class="form-group">
                    <label for="emailAddress">
                        Email Address
                    </label>

                    <input
                        type="email"
                        id="emailAddress"
                        name="emailAddress"
                        maxlength="100"
                        value="<%= escapeHtml(emailAddress) %>"
                        required>
                </div>

                <div class="form-group">
                    <label for="username">
                        Username
                    </label>

                    <input
                        type="text"
                        id="username"
                        name="username"
                        maxlength="50"
                        value="<%= escapeHtml(username) %>"
                        required>
                </div>

                <div class="form-group">
                    <label for="password">
                        Password
                    </label>

                    <input
                        type="password"
                        id="password"
                        name="password"
                        maxlength="50"
                        required>
                </div>

                <div class="form-group">
                    <label for="confirmPassword">
                        Confirm Password
                    </label>

                    <input
                        type="password"
                        id="confirmPassword"
                        name="confirmPassword"
                        maxlength="50"
                        required>
                </div>

                <input
                    type="submit"
                    value="Create Account">

            </form>

            <div class="login-link">
                Already have an account?

                <a href="<%= request.getContextPath() %>/login.jsp">
                    Sign In
                </a>
            </div>

        <%
            }
        %>

    </div>

</body>
</html>