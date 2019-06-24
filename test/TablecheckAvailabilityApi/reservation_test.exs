defmodule TablecheckAvailabilityApi.ReservationTest do
  alias TablecheckAvailabilityApi.Reservation
  use ExUnit.Case

  # not sure if these should be broken into seperate tests or not, because its a simple component I figured it makes sense to group them
  test "reservation day bounds valid data" do
    assert Reservation.verify_reservation_day_bounds(
             ~N[2019-06-23 11:00:00.000],
             ~N[2019-06-23 12:00:00.000]
           )

    # reservation length allows up to 24 hours minus 1 minute
    assert Reservation.verify_reservation_day_bounds(
             ~N[2019-06-23 00:00:00.000],
             ~N[2019-06-23 23:59:00.000]
           )

    assert Reservation.verify_reservation_day_bounds(
             ~N[2019-06-23 23:00:00.000],
             ~N[2019-06-24 00:00:00.000]
           )
  end

  test "reservation day bounds invalid data" do
    # shouldnt allow a day difference if the time is not exactly 00:00:00
    assert !Reservation.verify_reservation_day_bounds(
             ~N[2019-06-23 23:00:00.000],
             ~N[2019-06-24 00:01:00.000]
           )

    # shouldnt allow longer than 1 day
    assert !Reservation.verify_reservation_day_bounds(
             ~N[2019-06-23 23:00:00.000],
             ~N[2019-06-25 00:00:00.000]
           )

    assert_raise FunctionClauseError, fn ->
      # dont allow 0 length
      Reservation.verify_reservation_day_bounds(
        ~N[2019-06-23 23:00:00.000],
        ~N[2019-06-23 23:00:00.000]
      )
    end

    assert_raise FunctionClauseError, fn ->
      # dont allow end date smaller than start date
      Reservation.verify_reservation_day_bounds(
        ~N[2019-06-23 23:30:00.000],
        ~N[2019-06-23 23:00:00.000]
      )
    end
  end
end
