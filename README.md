# TablecheckAvailabilityApi

This project is based on a task given by tablecheck.

## Task interpretation
The task needed interpretation as it is described in a vague way.  
Following an email conversation with Jay, I was instructed to interpret the vagueness myself, and simply document any such aspects and assumptions that were taken about things which were not described

### Task Requirements
The task specifies that the context for the development is a need to show clients a restaurant's availability during the day.  
It states that to do so an API is to be developed.

- Design API that describe the available tables given a restaurant and a range of time

- Design the API in one of the following languages: Ruby, Elixir, Python, Go, or Scala

- The Restaurant,Table,Reservation **Objects** must be designed and exist internally in the application

- The returned result of the API should be the **list of non reserved tables** for the given period of time

- The developed class/module should be an **isolated** component

- It should be possible to use the module with **multiple storage backends**


### Interpreted Task
My interpretation of the task requires that the user of the API will supply a restaurant identifier, as well as a reservation start and end time.  
The API will return a list of tables that are free for the entire duration, from the start until the end time.  
Because the component needs to be isolated, the delivered module should simply be a library, as opposed to an api server.


#### Assumptions and justifications
The above interpretations incorporate a lot of assumptions about the objectives of this task.
Below I will try to document as many of them as I can.

##### The API should accept a reservation start and end dates
The document states that the result should be a "list of non-reserved tables in a period of time", this could either be interpreted in the way I did, or alternatively it could be interpreted as a list of time=>[table].  

This second interpretation is more fitting with the context, however that interpretation would require a lot more assumptions about how reservations work, which are not documented.
Further, a list of tables makes little sense when the data is supposed to represent the possible times for a reservation.    
In such a scenario simply returning the list of times should be sufficient in many scenarios.

##### The component should perform the lookup in memory
In a real system I would not usually expect such an API to use in memory data structures, but because the requirement explicitly demand that all of the objects should exist in the API, while offloading this calculation would in practice leave at most an empty schema that defines structures in the project.  
This would break that instruction in spirit if not in letter.  

Further, the specification explicitly calls for supporting multiple back-ends without any specific limit.
Because of that, using any kind of query engine would not be portable, as at least to my knowledge there does not exist a query engine that could use postgreSQL, mongodb, redis in addition to arbitrary data storages. Because of these interpretations the only option left is to use in memory data structures and implement the lookup internally.

## Design
This module is expected to be used in the context of an API server.  
This server should have access to an arbitrary data storage, but the data storage should not in any reasonable capacity be used by this API directly, as it would incur the costs of re-indexing the data into multiple maps.  

Thus the only kind of API where this module will make sense in, is a server that can host a cache of all of the relevant data in pre-indexed state.  
This will be possible either in a singular API server that handles all incoming requests and shares events internally with the cache, or in a distributed api that uses some mechanism to get updates over relevant (any modifications of reservations, tables or restaurants) events.
Such a system could be done using an update channel such as a notification queue, but such considerations are outside the scope of this project.

Alternatively it could be accepted as a compromise that the data will have a lag, and utilize a simple time based cache for the full scope of the data.

### Limitations
This module has one major limitation in that it does not support having arbitrary reservation times,
this is a result from using a map, which does not support such complex lookups.
A possible improvement of this API would be to migrate it to use a BST instead of a map for reservations.
However from looking at elixir's standard lib I did not find any data structures that fit the needed characteristics,
there does exist a package for an aatree an an rbtree, which could potentially be used for this functionality, but It seemed beyond the scope of this project.
Finally the third option implementing a production grade self balancing search tree also seemed outside the scope for this project, and not its intended purpose.
In any case such a migration would be deemed necessary, it would require adding 2 instances of the tree into the restaurant which will index the reservations based on their start_ts for one index, and the end_ts for the other.

## Usage

This module is intended to be used over specifically formatted data,
specifically it expects a restaurant structure which includes in it a map of tables, each of which with a map of reservations.
Each of the maps functions as an index, for the functionality of this library.
Once the data is in the appropriate format using this library is reduced to simply passing the object, as well as a start and end time.

```elixir
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
    ...>Restaurant.find_free_restaurant_tables(restaurant,~N[2019-06-23 17:00:00.000],~N[2019-06-23 18:00:00.000])
    {:ok,[1]}
```

