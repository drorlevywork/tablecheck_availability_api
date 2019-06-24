defmodule TablecheckAvailabilityApi.Reservation do
  @moduledoc """
  This module contains the struct for a single reservation.
  The task specifically mentioned that this type is required.
  In a real application such a structure would include many other fields such as identity, state[active,cancelled,pending], number of guests, etc.
  But for the scope of the application as defined in the task I went with a relatively minimal set of fields.

  Thus a couple of assumption have been taken about a reservation:
  *  Reservation's are uniform, meaning all reservations have the exact same duration.
     In the real world reservation's may vary whether by having different reservation lengths in different periods of the day,
     or by having a restuarant make a custom(extra long or short) reservation manually.
  *  All of the reservations are active, and relevant. This assumption basically means this module will not need to filter for active reservations,
     meaning the assumption is that any reservation passed into this library is relevant for availability
  *  Reservations have no issue being back-to-back, in reality a restaurant will want to enforce a buffer between reservations,
     thus either the buffer will be incorporated in the stored reservation, but will require an extra field to specify, or the rules for the availability search should take it into account.
  """
  @enforce_keys [:start_ts, :end_ts]
  defstruct [:start_ts, :end_ts]

  @doc """
  We verify that the order does not go beyond the bounds of the day.

  Assumptions:
  *  We assume that reservations can not cross day doundries, meaning an order cannot start in one date and end on another,
     with the exception of allowing reservations that end exactly on 24:00:00/00:00:00 of the next day.
     This is done because otherwise the calculation of the valid timeslots might vary between days, so instead of a pivot time we will need a pivot daytime.
     once such a need arises this "timeslot" system is already out of its scope, thus it is not handled.
  """
  def verify_reservation_day_bounds(
        %NaiveDateTime{} = reservation_start_time,
        %NaiveDateTime{} = reservation_end_time
      )
      when reservation_end_time > reservation_start_time do
    dates_diff =
      Date.diff(
        NaiveDateTime.to_date(reservation_end_time),
        NaiveDateTime.to_date(reservation_start_time)
      )

    # using diff as otherwise ~T[00:00:00]!=~T[00:00:00.0]
    dates_diff == 0 or
      (dates_diff == 1 &&
         Time.diff(NaiveDateTime.to_time(reservation_end_time), ~T[00:00:00]) == 0)
  end
end
