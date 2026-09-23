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
    PreparedStatement referenceStatement = null;
    PreparedStatement deleteStatement = null;

    ResultSet representativeResult = null;
    ResultSet referenceResult = null;

    try {

        connection =
            db.getConnection();

        if (connection == null) {

            throw new SQLException(
                "Could not connect to the database."
            );
        }

        connection.setAutoCommit(
            false
        );

        /*
         * Confirm that the employee exists and is
         * actually a customer representative.
         */
        String representativeQuery =
            "SELECT ssn " +
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

            connection.rollback();

            response.sendRedirect(
                request.getContextPath()
                + "/manager/manageRepresentatives.jsp"
            );

            return;
        }

        /*
         * Check whether any customer question references
         * this representative.
         */
        String referenceQuery =
            "SELECT COUNT(*) AS reference_count " +
            "FROM question " +
            "WHERE rep_ssn = ?";

        referenceStatement =
            connection.prepareStatement(
                referenceQuery
            );

        referenceStatement.setString(
            1,
            representativeSsn
        );

        referenceResult =
            referenceStatement.executeQuery();

        referenceResult.next();

        int referenceCount =
            referenceResult.getInt(
                "reference_count"
            );

        if (referenceCount > 0) {

            connection.rollback();

            response.sendRedirect(
                request.getContextPath()
                + "/manager/"
                + "manageRepresentatives.jsp"
                + "?message=cannotDelete"
            );

            return;
        }

        /*
         * Delete the representative.
         */
        String deleteQuery =
            "DELETE FROM employee " +
            "WHERE ssn = ? " +
            "AND employee_role = ?";

        deleteStatement =
            connection.prepareStatement(
                deleteQuery
            );

        deleteStatement.setString(
            1,
            representativeSsn
        );

        deleteStatement.setString(
            2,
            "representative"
        );

        int deletedRows =
            deleteStatement.executeUpdate();

        if (deletedRows != 1) {

            throw new SQLException(
                "The customer representative "
                + "could not be deleted."
            );
        }

        connection.commit();

        response.sendRedirect(
            request.getContextPath()
            + "/manager/"
            + "manageRepresentatives.jsp"
            + "?message=deleted"
        );

        return;

    } catch (SQLException e) {

        e.printStackTrace();

        try {

            if (connection != null
                    && !connection.getAutoCommit()) {

                connection.rollback();
            }

        } catch (SQLException rollbackException) {

            rollbackException.printStackTrace();
        }

        response.sendRedirect(
            request.getContextPath()
            + "/manager/"
            + "manageRepresentatives.jsp"
            + "?message=cannotDelete"
        );

        return;

    } finally {

        try {

            if (referenceResult != null) {
                referenceResult.close();
            }

            if (representativeResult != null) {
                representativeResult.close();
            }

            if (deleteStatement != null) {
                deleteStatement.close();
            }

            if (referenceStatement != null) {
                referenceStatement.close();
            }

            if (representativeStatement != null) {
                representativeStatement.close();
            }

            if (connection != null) {

                try {

                    if (!connection.getAutoCommit()) {
                        connection.setAutoCommit(
                            true
                        );
                    }

                } catch (SQLException autoCommitException) {

                    autoCommitException.printStackTrace();
                }

                db.closeConnection(
                    connection
                );
            }

        } catch (SQLException e) {

            e.printStackTrace();
        }
    }
%>