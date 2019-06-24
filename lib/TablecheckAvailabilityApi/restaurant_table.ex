defmodule TablecheckAvailabilityApi.RestaurantTable do
  @moduledoc """
  This module holds the struct for a restaurant table.
  I decided to name this module and struct as "RestaurantTable" because a table is a fairly common term in CompSci,
  thus it could lead to unclarity regarding what it refers to.

  A unique, per restaurant,  ID is neeeded as it would be used for filtering the results.
  On a technical level storing all of a restaurant's reservations in a single data structure would have better performance if using variable length/time slots for reservations.
  But because I am handling a much more limited scenario there are no real performance advantages to combining the restaurant table reservation lists,
  thus the ergonomics of seperating them wins.

  Assumptions taken:
  *  Tables have unique IDs, This is a reasonable assumption for a production system as well.
  *  A restaurant table with no reservation should hold an empty map in the reservations field.
  *  There is no need to store a back-reference to the retaurant in this struct, as the relation will be maintained in the restairant struct.
     In a production system having back-references to identify bugs that attampt to associate an object to the wrong parent is useful, but because this scenario is fairly removed a real system having such fields is fairly useless.
  """
  @enforce_keys [:id]
  defstruct [:id, reservations: %{}]
end
