<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"
    import="java.sql.*"
    import="java.util.*"
    import="com.cs336.pkg.ApplicationDB"%>

<%!
    /*
     * Prevent text from being interpreted as HTML when
     * displaying database values inside the page.
     */
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

    /*
     * Only logged-in customer representatives may
     * access this page.
     */
    if (!"employee".equals(userType)
            || !"representative".equals(employeeRole)) {

        response.sendRedirect(
            request.getContextPath() + "/login.jsp"
        );

        return;
    }

    /*
     * The representative SSN is used internally as the
     * foreign key, but it is never displayed on the page.
     */
    String representativeSsn =
        (String) session.getAttribute("employeeSsn");

    if (representativeSsn == null
            || representativeSsn.trim().isEmpty()) {

        response.sendRedirect(
            request.getContextPath() + "/login.jsp"
        );

        return;
    }

    String message = null;
    String errorMessage = null;

    /*
     * Each map in this list stores one question.
     * This allows the database resources to be closed
     * before the single HTML document is displayed.
     */
    ArrayList<HashMap<String, String>> questions =
        new ArrayList<HashMap<String, String>>();

    ApplicationDB db =
        new ApplicationDB();

    Connection connection = null;

    PreparedStatement updateStatement = null;
    PreparedStatement questionStatement = null;

    ResultSet questionResult = null;

    try {

        connection =
            db.getConnection();

        if (connection == null) {

            throw new SQLException(
                "Could not connect to the database."
            );
        }

        /*
         * Process a submitted reply.
         */
        if ("POST".equalsIgnoreCase(
                request.getMethod())) {

            String questionIdParameter =
                request.getParameter("questionId");

            String replyText =
                request.getParameter("replyText");

            if (questionIdParameter == null
                    || questionIdParameter.trim().isEmpty()) {

                errorMessage =
                    "Invalid question number.";

            } else if (replyText == null
                    || replyText.trim().isEmpty()) {

                errorMessage =
                    "Please enter a reply before submitting.";

            } else {

                try {

                    int questionId =
                        Integer.parseInt(
                            questionIdParameter.trim()
                        );

                    replyText =
                        replyText.trim();

                    String updateQuery =
                        "UPDATE question " +
                        "SET reply_text = ?, " +
                        "rep_ssn = ? " +
                        "WHERE question_id = ?";

                    updateStatement =
                        connection.prepareStatement(
                            updateQuery
                        );

                    updateStatement.setString(
                        1,
                        replyText
                    );

                    updateStatement.setString(
                        2,
                        representativeSsn
                    );

                    updateStatement.setInt(
                        3,
                        questionId
                    );

                    int rowsUpdated =
                        updateStatement.executeUpdate();

                    if (rowsUpdated == 1) {

                        message =
                            "The reply was saved successfully.";

                    } else {

                        errorMessage =
                            "The question could not be found.";
                    }

                } catch (NumberFormatException e) {

                    errorMessage =
                        "Invalid question number.";
                }
            }
        }

        /*
         * Load all questions.
         *
         * The LEFT JOIN retrieves the representative's
         * first and last name instead of displaying SSNs.
         */
        String questionQuery =
            "SELECT " +
            "q.question_id, " +
            "q.text, " +
            "q.reply_text, " +
            "q.customer_username, " +
            "q.rep_ssn, " +
            "e.first_name AS rep_first_name, " +
            "e.last_name AS rep_last_name " +
            "FROM question q " +
            "LEFT JOIN employee e " +
            "ON q.rep_ssn = e.ssn " +
            "ORDER BY q.question_id DESC";

        questionStatement =
            connection.prepareStatement(
                questionQuery
            );

        questionResult =
            questionStatement.executeQuery();

        while (questionResult.next()) {

            HashMap<String, String> question =
                new HashMap<String, String>();

            question.put(
                "questionId",
                String.valueOf(
                    questionResult.getInt(
                        "question_id"
                    )
                )
            );

            question.put(
                "customerUsername",
                questionResult.getString(
                    "customer_username"
                )
            );

            question.put(
                "questionText",
                questionResult.getString(
                    "text"
                )
            );

            question.put(
                "replyText",
                questionResult.getString(
                    "reply_text"
                )
            );

            question.put(
                "representativeSsn",
                questionResult.getString(
                    "rep_ssn"
                )
            );

            question.put(
                "representativeFirstName",
                questionResult.getString(
                    "rep_first_name"
                )
            );

            question.put(
                "representativeLastName",
                questionResult.getString(
                    "rep_last_name"
                )
            );

            questions.add(question);
        }

    } catch (SQLException e) {

        e.printStackTrace();

        errorMessage =
            "Database error: "
            + e.getMessage();

    } finally {

        try {

            if (questionResult != null) {
                questionResult.close();
            }

            if (questionStatement != null) {
                questionStatement.close();
            }

            if (updateStatement != null) {
                updateStatement.close();
            }

            if (connection != null) {
                db.closeConnection(connection);
            }

        } catch (SQLException e) {

            e.printStackTrace();
        }
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">

    <title>
        Manage Customer Questions
    </title>
</head>

<body>

    <h1>
        Manage Customer Questions
    </h1>

    <%
        if (message != null) {
    %>

        <p style="color: green;">
            <%= escapeHtml(message) %>
        </p>

    <%
        }

        if (errorMessage != null) {
    %>

        <p style="color: red;">
            <%= escapeHtml(errorMessage) %>
        </p>

    <%
        }

        if (!questions.isEmpty()) {
    %>

        <table border="1" cellpadding="8">
            <tr>
                <th>Question ID</th>
                <th>Customer</th>
                <th>Question</th>
                <th>Status</th>
                <th>Current Reply</th>
                <th>Reply or Update</th>
            </tr>

            <%
                for (HashMap<String, String> question
                        : questions) {

                    String questionId =
                        question.get("questionId");

                    String customerUsername =
                        question.get(
                            "customerUsername"
                        );

                    String questionText =
                        question.get("questionText");

                    String existingReply =
                        question.get("replyText");

                    String answeringRepresentativeSsn =
                        question.get(
                            "representativeSsn"
                        );

                    String representativeFirstName =
                        question.get(
                            "representativeFirstName"
                        );

                    String representativeLastName =
                        question.get(
                            "representativeLastName"
                        );

                    boolean answered =
                        existingReply != null
                        && !existingReply.trim().isEmpty();

                    String answeringRepresentativeName =
                        null;

                    if (representativeFirstName != null
                            && !representativeFirstName
                                .trim().isEmpty()) {

                        answeringRepresentativeName =
                            representativeFirstName.trim();
                    }

                    if (representativeLastName != null
                            && !representativeLastName
                                .trim().isEmpty()) {

                        if (answeringRepresentativeName
                                == null) {

                            answeringRepresentativeName =
                                representativeLastName.trim();

                        } else {

                            answeringRepresentativeName =
                                answeringRepresentativeName
                                + " "
                                + representativeLastName.trim();
                        }
                    }
            %>

                <tr>
                    <td>
                        <%= escapeHtml(questionId) %>
                    </td>

                    <td>
                        <%= escapeHtml(
                            customerUsername
                        ) %>
                    </td>

                    <td>
                        <%= escapeHtml(
                            questionText
                        ) %>
                    </td>

                    <td>
                        <%= answered
                            ? "Answered"
                            : "Pending" %>
                    </td>

                    <td>
                        <%
                            if (answered) {
                        %>

                            <%= escapeHtml(
                                existingReply
                            ) %>

                            <br><br>

                            <strong>
                                Answered by representative:
                            </strong>

                            <%
                                if (answeringRepresentativeName
                                        != null) {
                            %>

                                <%= escapeHtml(
                                    answeringRepresentativeName
                                ) %>

                            <%
                                } else if (
                                    answeringRepresentativeSsn
                                        != null
                                ) {
                            %>

                                Former representative

                            <%
                                } else {
                            %>

                                Representative unavailable

                            <%
                                }
                            %>

                        <%
                            } else {
                        %>

                            No reply yet.

                        <%
                            }
                        %>
                    </td>

                    <td>
                        <form
                            action="<%= request.getContextPath() %>/representative/manageQuestions.jsp"
                            method="post">

                            <input
                                type="hidden"
                                name="questionId"
                                value="<%= escapeHtml(
                                    questionId
                                ) %>">

                            <textarea
                                name="replyText"
                                rows="4"
                                cols="35"
                                maxlength="4000"
                                required><%= answered
                                    ? escapeHtml(existingReply)
                                    : "" %></textarea>

                            <br><br>

                            <input
                                type="submit"
                                value="<%= answered
                                    ? "Update Reply"
                                    : "Submit Reply" %>">

                        </form>
                    </td>
                </tr>

            <%
                }
            %>

        </table>

    <%
        } else if (errorMessage == null) {
    %>

        <p>
            There are currently no customer questions.
        </p>

    <%
        }
    %>

    <br>

    <a href="<%= request.getContextPath() %>/representative/r_home.jsp">
        Back to representative home
    </a>

</body>
</html>