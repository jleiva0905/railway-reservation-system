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

    String cancelReservationNumber =
        request.getParameter("cancelReservationNumber");

    String message = null;
    String errorMessage = null;

    ApplicationDB db =
        new ApplicationDB();

    Connection connection = null;

    PreparedStatement cancelStatement = null;
    PreparedStatement reservationStatement = null;

    ResultSet reservationResult = null;

    try {
        connection =
            db.getConnection();

        /*
         * Cancel a reservation when the customer
         * presses the Cancel button.
         */
        if (cancelReservationNumber != null
                && !cancelReservationNumber.isEmpty()) {

            String cancelQuery =
                "DELETE FROM reservation " +
                "WHERE reservation_number = ? " +
                "AND customer_username = ?";

            cancelStatement =
                connection.prepareStatement(
                    cancelQuery
                );

            cancelStatement.setInt(
                1,
                Integer.parseInt(
                    cancelReservationNumber
                )
            );

            cancelStatement.setString(
                2,
                customerUsername
            );

            int rowsDeleted =
                cancelStatement.executeUpdate();

            if (rowsDeleted > 0) {

                message =
                    "The reservation was cancelled "
                    + "successfully.";

            } else {

                errorMessage =
                    "The reservation could not be "
                    + "cancelled.";
            }
        }

        /*
         * Get every reservation belonging to the
         * logged-in customer.
         *
         * departure_stop gives the departure datetime
         * at the customer's selected departure station.
         *
         * arrival_stop gives the arrival datetime at
         * the customer's selected arrival station.
         */
        String reservationQuery =
            "SELECT " +

            "r.reservation_number, " +
            "r.date_made, " +
            "r.total_fare, " +
            "r.trip_type, " +
            "r.schedule_id, " +

            "ts.train_id, " +
            "ts.line_name, " +

            "departure_stop.departure_datetime " +
            "AS customer_departure_datetime, " +

            "arrival_stop.arrival_datetime " +
            "AS customer_arrival_datetime, " +

            "departure_station.name " +
            "AS departure_station_name, " +

            "arrival_station.name " +
            "AS arrival_station_name " +

            "FROM reservation r " +

            "JOIN trainschedule ts " +
            "ON r.schedule_id = ts.schedule_id " +

            "JOIN schedule_station_stops " +
            "departure_stop " +
            "ON r.schedule_id = " +
            "departure_stop.schedule_id " +
            "AND r.departure_station_id = " +
            "departure_stop.station_id " +

            "JOIN schedule_station_stops " +
            "arrival_stop " +
            "ON r.schedule_id = " +
            "arrival_stop.schedule_id " +
            "AND r.arrival_station_id = " +
            "arrival_stop.station_id " +

            "JOIN station departure_station " +
            "ON r.departure_station_id = " +
            "departure_station.station_id " +

            "JOIN station arrival_station " +
            "ON r.arrival_station_id = " +
            "arrival_station.station_id " +

            "WHERE r.customer_username = ? " +

            "ORDER BY " +
            "departure_stop.departure_datetime";

        reservationStatement =
            connection.prepareStatement(
                reservationQuery
            );

        reservationStatement.setString(
            1,
            customerUsername
        );

        reservationResult =
            reservationStatement.executeQuery();

        boolean foundReservation = false;
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">

    <title>
        My Reservations
    </title>
</head>

<body>

    <h1>
        My Reservations
    </h1>

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

    <table border="1">

        <tr>
            <th>Reservation Number</th>
            <th>Date Made</th>
            <th>Schedule</th>
            <th>Train</th>
            <th>Transit Line</th>
            <th>Departure Station</th>
            <th>Arrival Station</th>
            <th>Departure Time</th>
            <th>Arrival Time</th>
            <th>Trip Type</th>
            <th>Total Fare</th>
            <th>Cancel</th>
        </tr>

        <%
            while (reservationResult.next()) {

                foundReservation = true;
        %>

        <tr>

            <td>
                <%= reservationResult.getInt(
                    "reservation_number"
                ) %>
            </td>

            <td>
                <%= reservationResult.getTimestamp(
                    "date_made"
                ) %>
            </td>

            <td>
                <%= reservationResult.getInt(
                    "schedule_id"
                ) %>
            </td>

            <td>
                <%= reservationResult.getString(
                    "train_id"
                ) %>
            </td>

            <td>
                <%= reservationResult.getString(
                    "line_name"
                ) %>
            </td>

            <td>
                <%= reservationResult.getString(
                    "departure_station_name"
                ) %>
            </td>

            <td>
                <%= reservationResult.getString(
                    "arrival_station_name"
                ) %>
            </td>

            <td>
                <%= reservationResult.getTimestamp(
                    "customer_departure_datetime"
                ) %>
            </td>

            <td>
                <%= reservationResult.getTimestamp(
                    "customer_arrival_datetime"
                ) %>
            </td>

            <td>
                <%= reservationResult.getString(
                    "trip_type"
                ) %>
            </td>

            <td>
                $<%= String.format(
                    "%.2f",
                    reservationResult.getDouble(
                        "total_fare"
                    )
                ) %>
            </td>

            <td>
                <form
                    action="viewReservations.jsp"
                    method="post">

                    <input
                        type="hidden"
                        name="cancelReservationNumber"
                        value="<%= reservationResult.getInt(
                            "reservation_number"
                        ) %>">

                    <input
                        type="submit"
                        value="Cancel"
                        onclick="return confirm(
                            'Are you sure you want to cancel this reservation?'
                        );">

                </form>
            </td>

        </tr>

        <%
            }
        %>

    </table>

    <%
        if (!foundReservation) {
    %>

        <p>
            You do not currently have any reservations.
        </p>

    <%
        }
    %>

    <br>

    <a href="<%= request.getContextPath() %>/customer/search.jsp">
        Search train schedules
    </a>

    <br><br>

    <a href="<%= request.getContextPath() %>/customer/c_home.jsp">
        Back to customer home
    </a>

</body>
</html>

<%
    } catch (NumberFormatException e) {

        e.printStackTrace();
%>

    <p style="color: red;">
        Invalid reservation number.
    </p>

<%
    } catch (SQLException e) {

        e.printStackTrace();
%>

    <p style="color: red;">
        A database error occurred while loading reservations.
    </p>

<%
    } finally {

        try {

            if (reservationResult != null) {
                reservationResult.close();
            }

            if (reservationStatement != null) {
                reservationStatement.close();
            }

            if (cancelStatement != null) {
                cancelStatement.close();
            }

            if (connection != null) {
                db.closeConnection(connection);
            }

        } catch (SQLException e) {

            e.printStackTrace();
        }
    }
%>