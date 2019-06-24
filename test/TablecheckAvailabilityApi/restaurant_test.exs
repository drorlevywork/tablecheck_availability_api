defmodule TablecheckAvailabilityApi.RestaurantTest do
  alias TablecheckAvailabilityApi.Restaurant
  alias TablecheckAvailabilityApi.RestaurantTable
  alias TablecheckAvailabilityApi.Reservation
  use ExUnit.Case
  doctest TablecheckAvailabilityApi.Restaurant

  test "reservation timeslot valid data" do
    restaurant = %Restaurant{
      id: 1,
      reservation_length_in_minutes: 60,
      reservations_pivot_time: ~T[12:00:00]
    }

    # allow reservation before time pivot
    assert {:ok, _} =
             Restaurant.find_free_restaurant_tables(
               restaurant,
               ~N[2019-06-23 11:00:00.000],
               ~N[2019-06-23 12:00:00.000]
             )

    # allow resevation at pivot
    assert {:ok, _} =
             Restaurant.find_free_restaurant_tables(
               restaurant,
               ~N[2019-06-23 12:00:00.000],
               ~N[2019-06-23 13:00:00.000]
             )

    # allow resevation after pivot
    assert {:ok, _} =
             Restaurant.find_free_restaurant_tables(
               restaurant,
               ~N[2019-06-23 13:00:00.000],
               ~N[2019-06-23 14:00:00.000]
             )
  end

  test "reservation timeslot invalid data" do
    # more assertions could be imagined, such as using reservation lengths which are not dividers of 60, but the current implementation does not depend on that,
    # and no know edgecases currently exist for such a case, so I would not add a unit test for it, until an actual bug turned out, after which the condtion
    # that caused the bug should be added as a unit test
    restaurant = %Restaurant{
      id: 1,
      reservation_length_in_minutes: 60,
      reservations_pivot_time: ~T[12:00:00]
    }

    # allow reservation before time pivot
    assert {:error, _} =
             Restaurant.find_free_restaurant_tables(
               restaurant,
               ~N[2019-06-23 11:00:01.000],
               ~N[2019-06-23 12:00:01.000]
             )
  end

  test "reservation length valid data" do
    restaurant = %Restaurant{
      id: 1,
      reservation_length_in_minutes: 60,
      reservations_pivot_time: ~T[12:00:00]
    }

    assert {:ok, _} =
             Restaurant.find_free_restaurant_tables(
               restaurant,
               ~N[2019-06-23 11:00:00.000],
               ~N[2019-06-23 12:00:00.000]
             )
  end

  test "reservation length invalid data" do
    restaurant = %Restaurant{
      id: 1,
      reservation_length_in_minutes: 60,
      reservations_pivot_time: ~T[12:00:00]
    }

    assert {:error, _} =
             Restaurant.find_free_restaurant_tables(
               restaurant,
               ~N[2019-06-23 11:00:00.000],
               ~N[2019-06-23 12:00:01.000]
             )
  end

  test "find free restaurant tables" do
    restaurant_table1 = %RestaurantTable{
      id: 1,
      reservations: %{
        ~N[2019-06-23 11:00:00.000] => %Reservation{
          start_ts: ~N[2019-06-23 11:00:00.000],
          end_ts: ~N[2019-06-23 12:00:00.000]
        },
        ~N[2019-06-23 13:00:00.000] => %Reservation{
          start_ts: ~N[2019-06-23 13:00:00.000],
          end_ts: ~N[2019-06-23 14:00:00.000]
        }
      }
    }

    restaurant_table2 = %RestaurantTable{
      id: 2,
      reservations: %{
        ~N[2019-06-23 13:00:00.000] => %Reservation{
          start_ts: ~N[2019-06-23 13:00:00.000],
          end_ts: ~N[2019-06-23 14:00:00.000]
        },
        ~N[2019-06-23 14:00:00.000] => %Reservation{
          start_ts: ~N[2019-06-23 14:00:00.000],
          end_ts: ~N[2019-06-23 15:00:00.000]
        }
      }
    }

    restaurant = %Restaurant{
      id: 1,
      reservation_length_in_minutes: 60,
      reservations_pivot_time: ~T[12:00:00],
      restaurant_tables: %{
        restaurant_table1.id => restaurant_table1,
        restaurant_table2.id => restaurant_table2
      }
    }

    assert {:ok, [2]} =
             Restaurant.find_free_restaurant_tables(
               restaurant,
               ~N[2019-06-23 11:00:00.000],
               ~N[2019-06-23 12:00:00.000]
             )

    assert {:ok, []} =
             Restaurant.find_free_restaurant_tables(
               restaurant,
               ~N[2019-06-23 13:00:00.000],
               ~N[2019-06-23 14:00:00.000]
             )

    assert {:ok, [1]} =
             Restaurant.find_free_restaurant_tables(
               restaurant,
               ~N[2019-06-23 14:00:00.000],
               ~N[2019-06-23 15:00:00.000]
             )

    # I'm comparing to a [1,2], might need to add Enum.sort/2 over the result
    assert {:ok, [1, 2]} =
             Restaurant.find_free_restaurant_tables(
               restaurant,
               ~N[2019-06-23 17:00:00.000],
               ~N[2019-06-23 18:00:00.000]
             )
  end
end
