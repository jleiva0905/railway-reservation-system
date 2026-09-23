<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"
    import="java.sql.*"
    import="com.cs336.pkg.ApplicationDB"%>

<%
    String userType =
        (String) session.getAttribute("userType");

    if (!"customer".equals(userType)) {
        response.sendRedirect(
            request.getContextPath() + "/login.jsp"
        );
        return;
    }

    String customerUsername =
        (String) session.getAttribute("username");

    String questionText =
        request.getParameter("questionText");

    String message = null;
    String errorMessage = null;

    ApplicationDB db = new ApplicationDB();
    Connection connection = null;

    PreparedStatement insertStatement = null;
    PreparedStatement questionStatement = null;

    ResultSet questionResult = null;

    try {
        connection = db.getConnection();

        /*
         * If the form was submitted, insert the new question.
         */
        if (questionText != null) {

            questionText = questionText.trim();

            if (questionText.isEmpty()) {

                errorMessage =
                    "Please enter a question before submitting.";

            } else {

                String insertQuery =
                    "INSERT INTO question " +
                    "(text, customer_username) " +
                    "VALUES (?, ?)";

                insertStatement =
                    connection.prepareStatement(insertQuery);

                insertStatement.setString(
                    1,
                    questionText
                );

                insertStatement.setString(
                    2,
                    customerUsername
                );

                int rowsInserted =
                    insertStatement.executeUpdate();

                if (rowsInserted > 0) {
                    message =
                        "Your question was submitted successfully.";
                } else {
                    errorMessage =
                        "Your question could not be submitted.";
                }
            }
        }

        /*
         * Load only the logged-in customer's questions.
         */
        String questionQuery =
            "SELECT " +
            "question_id, " +
            "text, " +
            "reply_text, " +
            "rep_ssn " +
            "FROM question " +
            "WHERE customer_username = ? " +
            "ORDER BY question_id DESC";

        questionStatement =
            connection.prepareStatement(questionQuery);

        questionStatement.setString(
            1,
            customerUsername
        );

        questionResult =
            questionStatement.executeQuery();

        boolean foundQuestion = false;
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Customer Questions</title>
</head>
<body>

    <h1>Ask a Question</h1>

    <%
        if (message != null) {
    %>

        <p style="color: green;">
            <%= message %>
        </p>

    <%
        }

        if (errorMessage != null) {
    %>

        <p style="color: red;">
            <%= errorMessage %>
        </p>

    <%
        }
    %>

    <form action="askQuestion.jsp" method="post">

        <label for="questionText">
            Enter your question:
        </label>

        <br><br>

        <textarea
            id="questionText"
            name="questionText"
            rows="5"
            cols="60"
            maxlength="2000"
            required></textarea>

        <br><br>

        <input
            type="submit"
            value="Submit Question">

    </form>

    <hr>

    <h2>My Questions</h2>

    <table border="1" cellpadding="8">
        <tr>
            <th>Question ID</th>
            <th>Question</th>
            <th>Status</th>
            <th>Representative Reply</th>
        </tr>

        <%
            while (questionResult.next()) {

                foundQuestion = true;

                String replyText =
                    questionResult.getString("reply_text");

                String representativeSsn =
                    questionResult.getString("rep_ssn");

                boolean answered =
                    replyText != null
                    && !replyText.trim().isEmpty();
        %>

        <tr>
            <td>
                <%= questionResult.getInt(
                    "question_id"
                ) %>
            </td>

            <td>
                <%= questionResult.getString(
                    "text"
                ) %>
            </td>

            <td>
                <%
                    if (answered) {
                %>

                    Answered

                <%
                    } else {
                %>

                    Pending

                <%
                    }
                %>
            </td>

            <td>
                <%
                    if (answered) {
                %>
                
                	<strong>Representative Reply:</strong>
                	
                	<br><br>
                	
                	<%= replyText %>
                	
                <%
                    } else {
                %>
                
                	No reply yet.
                <%
                    }
                %>
            </td>
        </tr>

        <%
            }
        %>

    </table>

    <%
        if (!foundQuestion) {
    %>

        <p>You have not submitted any questions yet.</p>

    <%
        }
    %>

    <br>

    <a href="<%= request.getContextPath() %>/customer/c_home.jsp">
        Back to customer home
    </a>

</body>
</html>

<%
    } catch (SQLException e) {

        e.printStackTrace();
%>

    <p style="color: red;">
        A database error occurred while processing your question.
    </p>

<%
    } finally {

        try {
            if (questionResult != null) {
                questionResult.close();
            }

            if (questionStatement != null) {
                questionStatement.close();
            }

            if (insertStatement != null) {
                insertStatement.close();
            }

            if (connection != null) {
                db.closeConnection(connection);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
%>