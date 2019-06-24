defmodule TablecheckAvailabilityApi.Restaurant do
  alias TablecheckAvailabilityApi.Restaurant
  alias TablecheckAvailabilityApi.Reservation

  @moduledoc """
  This module contains the struct for a restaurant, as well as the business logic for identifying free tables at a given time span.
  """
  @enforce_keys [:id]
  defstruct [
    :id,
    :reservation_length_in_minutes,
    :reservations_pivot_time,
    restaurant_tables: %{}
  ]

  @doc """
  Given a Restaurant and reservation start and end times returns the list of table ids that do not have a reservation colliding with it.
  Because the result is a list that potentially includes all of the tables, the complexity of this method is O(n) where n is the number of tables.

  Assumptions:
  *  All existing reservations have the same duration, with timeslots compatible to the pivot time defined in the restaurant.
     whereby timeslots refers to the fact that reservations always fall into the same times every day.
     for example given a start time of 08:00, and a duration of 60 minutes, the slots will be 08:00->09:00,09:00->10:00, etc.
  *  All existing reservations' timestamps are in the UTC timezone. it is generally a reasonable assumption for a production system as well.
     Though the user's timezone should be kept, having the underlying data in UTC keeps things simple.
  *  All existing reservations should have a valid start and end time.
  ## Examples

    iex> restaurant = %Restaurant{
    ...>      id: 1,
    ...>      reservation_length_in_minutes: 60,
    ...>      reservations_pivot_time: ~T[12:00:00],
    ...>      restaurant_tables: %{
    ...>        1 => %RestaurantTable{
    ...>      id: 1,
    ...>      reservations: %{
    ...>        ~N[2019-06-23 11:00:00.000] => %Reservation{
    ...>          start_ts: ~N[2019-06-23 11:00:00.000],
    ...>          end_ts: ~N[2019-06-23 12:00:00.000]
    ...>         },}
    ...>      }
    ...>      }
    ...>}
    ...> Restaurant.find_free_restaurant_tables(restaurant,~N[2019-06-23 17:00:00.000],~N[2019-06-23 18:00:00.000])
    {:ok,[1]}

  """
  @spec find_free_restaurant_tables(Restaurant, NaiveDateTime, NaiveDateTime) ::
          {:error, String.t()} | {:ok, [integer]}
  def find_free_restaurant_tables(
        %Restaurant{} = restaurant,
        %NaiveDateTime{} = reservation_start_time,
        %NaiveDateTime{} = reservation_end_time
      ) do
    # we validate the data we have, and return error if invalid
    if !verify_reservation_length_and_timeslot(
         restaurant,
         reservation_start_time,
         reservation_end_time
       ) do
      {:error, "invalid data"}
    else
      {:ok,
       restaurant.restaurant_tables
       # Because of the assumption that all reservations are of uniform size, and in predetermined slots,
       # the only way a reservation will overlap with the requested time is if it has the exact same start and end time,
       # but because the reservation length are uniform there is no need to compare both start and end time, as equality of one guarantees equality of the other.
       |> Stream.filter(fn {_, restaurant_table} ->
         !Map.has_key?(restaurant_table.reservations, reservation_start_time)
       end)
       |> Enum.map(fn {id, _} -> id end)}
    end
  end

  #
  # We verify the length of the reservation, whether or not the start time matches our timeslots and if the reservation crosses the day bounds.
  #
  defp verify_reservation_length_and_timeslot(
         %Restaurant{} = restaurant,
         %NaiveDateTime{} = reservation_start_time,
         %NaiveDateTime{} = reservation_end_time
       ) do
    # end time must be bigger than start time
    reservation_end_time > reservation_start_time and
      verify_reservation_length(
        reservation_start_time,
        reservation_end_time,
        restaurant.reservation_length_in_minutes
      ) and
      Reservation.verify_reservation_day_bounds(reservation_start_time, reservation_end_time) and
      verify_reservation_timeslot(
        reservation_start_time,
        restaurant.reservation_length_in_minutes,
        restaurant.reservations_pivot_time
      )
  end

  #
  # We calculate the length of the reservation by diffing its end and start time, and compare it to the allowed duration in minutes multiplied by 60.
  # Assumptions:
  # *  The allowed reservation duration must not be negative, nor should it exceed 24 hours. The reason for not allowing reservations that last longer than 24 hours is that doing so will cause orders to cross day boundaries,
  #    which is incompatible with the current implementation.
  #
  defp verify_reservation_length(
         %NaiveDateTime{} = reservation_start_time,
         %NaiveDateTime{} = reservation_end_time,
         allowed_reservation_duration_in_minutes
       )
       when allowed_reservation_duration_in_minutes < 24 * 60 and
              allowed_reservation_duration_in_minutes > 0 do
    NaiveDateTime.diff(reservation_end_time, reservation_start_time) ==
      allowed_reservation_duration_in_minutes * 60
  end

  #
  # We verify if the start time supplied is a valid time slot by calculating its difference from the pivot, finding its absolute value and finding its reminder from the established reservation duration.
  # The reason for using absolute value is that the pivot is not the start time, it only defines the intersection point of the timeslots.
  #
  # Assumptions:
  # *  This method assumes any hour of the day is a valid potential reservation, meaning hours of operation are assumed to be 00:00:00 to 24:00:00.
  #    In a production system obviously every restaurant will have a specific time range during which reservations will be allowed.
  # *  This method assumes the timeslots do not cross day boundries, meaning every day's timeslots are identical.

  defp verify_reservation_timeslot(
         %NaiveDateTime{} = reservation_start_time,
         reservation_length_in_minutes,
         %Time{} = reservations_pivot_time
       ) do
    # computation broken into intermediaries to ease debugging
    # not sure if this has performance/memory implication in elixir and couldnt find answer to that online, so for now I am keeping it.
    timediff = Time.diff(NaiveDateTime.to_time(reservation_start_time), reservations_pivot_time)
    reminder = rem(abs(timediff), reservation_length_in_minutes * 60)
    reminder == 0
  end
end
